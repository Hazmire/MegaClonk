class_name RunMinimap
extends Control
var game: Node
var explored: Dictionary={}
var terrain_colors: Dictionary={}
var reveal_all=false
var last_camera_facing=Vector2.UP
func reset(revealed: bool) -> void:
 explored.clear();terrain_colors.clear();reveal_all=revealed
func cell(pos: Vector3) -> Vector2i:return Vector2i(floori((pos.x+96)/12),floori((pos.z+96)/12))
func reveal(pos: Vector3) -> void:
 var c=cell(pos)
 for x in range(c.x-2,c.x+3):
  for y in range(c.y-2,c.y+3):explored[Vector2i(x,y)]=true
func visible_at(pos: Vector3) -> bool:return reveal_all or explored.has(cell(pos))
func extent() -> Vector2:return Vector2.ONE*minf(size.x,size.y)
func origin() -> Vector2:return (size-extent())*0.5
func point(pos: Vector3) -> Vector2:return origin()+Vector2((pos.x+96)/192,(pos.z+96)/192)*extent()
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("10171f"))
 if not is_instance_valid(game) or not is_instance_valid(game.player):return
 var span=extent();var offset=origin();var mark=clampf(span.x/210,1,2.2)
 for x in 16:
  for y in 16:
   var key=Vector2i(x,y)
   if reveal_all or explored.has(key):
    if not terrain_colors.has(key):
     var height=game.terrain_height(x*12-90,y*12-90)
     terrain_colors[key]=Color("222e3a").lerp(Color("4d6257"),clampf(height/48,0,1))
    draw_rect(Rect2(offset+Vector2(x,y)*span/16,span/16+Vector2.ONE),terrain_colors[key])
 for pos in game.landmarks:
  if visible_at(pos):draw_circle(point(pos),2*mark,Color("9fa79d"))
 for obj in game.interactables:
  if obj.used or not visible_at(obj.node.position):continue
  var p=point(obj.node.position);var color=Color("70dcd7")
  match obj.kind:
   "Chest":
    draw_rect(Rect2(p-Vector2(3,2)*mark,Vector2(6,4)*mark),Color("f3cc6f"));draw_line(p-Vector2(3,0)*mark,p+Vector2(3,0)*mark,Color("66502b"),mark);continue
   "Shop":color=Color("83d678")
   "Heal":color=Color("f57579")
   "Elite Statue":color=Color("ffac5e")
   "Boss Statue":color=Color("d78aff")
   "Free Chest":color=Color("ffe79b")
   "Imbue Station":
    var c=Color("ff8a3d");draw_colored_polygon(PackedVector2Array([p+Vector2(0,-4)*mark,p+Vector2(4,0)*mark,p+Vector2(0,4)*mark,p+Vector2(-4,0)*mark]),c);draw_circle(p,1.5*mark,Color("201410"));continue
  draw_colored_polygon(PackedVector2Array([p+Vector2(0,-3)*mark,p+Vector2(3,0)*mark,p+Vector2(0,3)*mark,p+Vector2(-3,0)*mark]),color)
 for chest in game.drop_chests:
  if visible_at(chest.node.position):draw_rect(Rect2(point(chest.node.position)-Vector2.ONE*3*mark,Vector2.ONE*6*mark),Color("ffe79b"))
 for e in game.enemies:
  if e.hp>0 and visible_at(e.pos):draw_circle(point(e.pos),(4 if e.kind>=8 else 3 if e.get("elite",false) else 1.5)*mark,Color("ffd365") if e.get("elite",false) else Color("f387a0"))
 if is_instance_valid(game.portal) and visible_at(game.portal.position):draw_arc(point(game.portal.position),6*mark,0,TAU,20,Color("6bd3ff"),2*mark)
 draw_circle(point(game.player.position),4*mark,Color("fff6dc"))
 var facing=camera_facing()
 draw_line(point(game.player.position),point(game.player.position)+facing*10*mark,Color("fff6dc"),2*mark)
 draw_rect(Rect2(offset,span),Color("b7b4a5"),false,2)

func camera_facing() -> Vector2:
 if not is_instance_valid(game) or not is_instance_valid(game.player):return Vector2.UP
 var camera=game.get_viewport().get_camera_3d()
 if not is_instance_valid(camera):camera=game.player.camera
 var forward=-camera.global_basis.z
 var horizontal=Vector2(forward.x,forward.z)
 if horizontal.length_squared()>0.00000001:last_camera_facing=horizontal.normalized()
 return last_camera_facing

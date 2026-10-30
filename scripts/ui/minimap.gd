class_name RunMinimap
extends Control
var game: Node
var explored: Dictionary={}
var terrain_colors: Dictionary={}
var reveal_all=false
var last_camera_facing=Vector2.UP
var paper_style=false # HUD map: Fog palette markers on the dark checker; the pause map keeps the plain look until its step
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
# Colours per style: the HUD/map "paper" style uses the Fog palette from the RunHUD mockup, the plain style is the
# original look. Only the palette differs; what is shown (and when) is identical.
func palette(key: String) -> Color:
 if paper_style:
  match key:
   "ground_a":return Color("212B26")
   "ground_b":return Color("1B231F")
   "low":return Color("2B3731")
   "high":return Color("4D6257")
   "landmark":return Color("5F6D64")
   "chest":return Color("C9861A")
   "chest_line":return Color("4A2F00")
   "shop":return Color("33772F")
   "heal":return Color("E07B83")
   "elite":return Color("D9763E")
   "boss":return Color("A26DD8")
   "free":return Color("F2C14E")
   "imbue":return Color("7B3FB3")
   "other":return Color("70DCD7")
   "enemy":return Color("F387A0")
   "elite_enemy":return Color("FFD365")
   "portal":return Color("E07B83")
   "player":return Color("F4EFE2")
   "frame":return Color("3A352A")
   "vase":return Color("C9A4FF")
 match key:
  "ground_a","ground_b":return Color("10171f")
  "low":return Color("222e3a")
  "high":return Color("4d6257")
  "landmark":return Color("9fa79d")
  "chest":return Color("f3cc6f")
  "chest_line":return Color("66502b")
  "shop":return Color("83d678")
  "heal":return Color("f57579")
  "elite":return Color("ffac5e")
  "boss":return Color("d78aff")
  "free":return Color("ffe79b")
  "imbue":return Color("ff8a3d")
  "other":return Color("70dcd7")
  "enemy":return Color("f387a0")
  "elite_enemy":return Color("ffd365")
  "portal":return Color("6bd3ff")
  "player":return Color("fff6dc")
  "frame":return Color("b7b4a5")
 return Color.MAGENTA
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),palette("ground_a"))
 if paper_style:
  var cells=Vector2i(ceili(size.x/8.0),ceili(size.y/8.0))
  for x in cells.x:
   for y in cells.y:
    if (x+y)%2==1:draw_rect(Rect2(Vector2(x,y)*8.0,Vector2(8,8)),palette("ground_b"))
 if not is_instance_valid(game) or not is_instance_valid(game.player):return
 var span=extent();var offset=origin();var mark=clampf(span.x/210,1,2.2)
 for x in 16:
  for y in 16:
   var key=Vector2i(x,y)
   if reveal_all or explored.has(key):
    if not terrain_colors.has(key):
     var height=game.terrain_height(x*12-90,y*12-90)
     terrain_colors[key]=palette("low").lerp(palette("high"),clampf(height/48,0,1))
    draw_rect(Rect2(offset+Vector2(x,y)*span/16,span/16+Vector2.ONE),terrain_colors[key])
 for pos in game.landmarks:
  if visible_at(pos):draw_circle(point(pos),2*mark,palette("landmark"))
 var candle=game.irt.has("cartographers_candle")
 if candle:
  for v in game.vases:
   if not v.broken:draw_circle(point(v.pos),1.6*mark,palette("vase"))
 for obj in game.interactables:
  if obj.used:continue
  if not visible_at(obj.node.position) and not (candle and (obj.kind=="Chest" or obj.kind=="Imbue Station")):continue
  var p=point(obj.node.position);var color=palette("other")
  match obj.kind:
   "Chest":
    draw_rect(Rect2(p-Vector2(3,2)*mark,Vector2(6,4)*mark),palette("chest"));draw_line(p-Vector2(3,0)*mark,p+Vector2(3,0)*mark,palette("chest_line"),mark);continue
   "Shop":
    if paper_style:
     draw_rect(Rect2(p-Vector2(3.5,3.5)*mark,Vector2(7,7)*mark),Color("E8E2D0"));draw_rect(Rect2(p-Vector2(3.5,3.5)*mark,Vector2(7,7)*mark),palette("shop"),false,mark);continue
    color=palette("shop")
   "Heal":color=palette("heal")
   "Elite Statue":color=palette("elite")
   "Boss Statue":color=palette("boss")
   "Free Chest":color=palette("free")
   "Imbue Station":
    var c=palette("imbue");draw_colored_polygon(PackedVector2Array([p+Vector2(0,-4)*mark,p+Vector2(4,0)*mark,p+Vector2(0,4)*mark,p+Vector2(-4,0)*mark]),c);draw_circle(p,1.5*mark,Color("201410"));continue
  draw_colored_polygon(PackedVector2Array([p+Vector2(0,-3)*mark,p+Vector2(3,0)*mark,p+Vector2(0,3)*mark,p+Vector2(-3,0)*mark]),color)
 for chest in game.drop_chests:
  if visible_at(chest.node.position):draw_rect(Rect2(point(chest.node.position)-Vector2.ONE*3*mark,Vector2.ONE*6*mark),palette("free"))
 for e in game.enemies:
  if e.hp>0 and visible_at(e.pos):draw_circle(point(e.pos),(4 if e.kind>=8 else 3 if e.get("elite",false) else 1.5)*mark,palette("elite_enemy") if e.get("elite",false) else palette("enemy"))
 if is_instance_valid(game.portal) and visible_at(game.portal.position):draw_arc(point(game.portal.position),6*mark,0,TAU,20,palette("portal"),2*mark)
 var me=point(game.player.position);var facing=camera_facing()
 if paper_style:
  # Arrow pointing the way the camera faces, ink outline like the mockup's "You" marker.
  var side=Vector2(-facing.y,facing.x);var tip=me+facing*9*mark;var back=me-facing*5*mark
  var tri=PackedVector2Array([tip,back+side*6*mark,me-facing*2*mark,back-side*6*mark])
  draw_colored_polygon(tri,palette("player"));draw_polyline(tri+PackedVector2Array([tri[0]]),Color("0E0F0E"),1.5)
 else:
  draw_circle(me,4*mark,palette("player"));draw_line(me,me+facing*10*mark,palette("player"),2*mark)
 draw_rect(Rect2(offset,span),palette("frame"),false,2)

func camera_facing() -> Vector2:
 if not is_instance_valid(game) or not is_instance_valid(game.player):return Vector2.UP
 var camera=game.get_viewport().get_camera_3d()
 if not is_instance_valid(camera):camera=game.player.camera
 var forward=-camera.global_basis.z
 var horizontal=Vector2(forward.x,forward.z)
 if horizontal.length_squared()>0.00000001:last_camera_facing=horizontal.normalized()
 return last_camera_facing

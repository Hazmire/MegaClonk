class_name RunMinimap
extends Control
var game: Node
var explored: Dictionary={}
var reveal_all=false
func reset(revealed: bool) -> void:
 explored.clear(); reveal_all=revealed
func cell(pos: Vector3) -> Vector2i: return Vector2i(floori((pos.x+90)/10),floori((pos.z+90)/10))
func reveal(pos: Vector3) -> void:
 var c=cell(pos)
 for x in range(c.x-2,c.x+3):
  for y in range(c.y-2,c.y+3): explored[Vector2i(x,y)]=true
func visible_at(pos: Vector3) -> bool: return reveal_all or explored.has(cell(pos))
func point(pos: Vector3) -> Vector2: return Vector2((pos.x+90)/180*size.x,(pos.z+90)/180*size.y)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("101c21"))
 for x in 18:
  for y in 18:
   if reveal_all or explored.has(Vector2i(x,y)):
    draw_rect(Rect2(Vector2(x,y)*size/18,size/18+Vector2.ONE),Color("344f42"))
 if not is_instance_valid(game) or not is_instance_valid(game.player): return
 for pos in game.landmarks:
  if visible_at(pos):draw_circle(point(pos),3,Color("c3c7a1"))
 for obj in game.interactables:
  if obj.used or not visible_at(obj.node.position): continue
  var color=Color("f3cc6f") if obj.kind=="Chest" else (Color("b7a6ff") if obj.kind=="Shop" else Color("77d6d1"))
  draw_rect(Rect2(point(obj.node.position)-Vector2.ONE*2,Vector2.ONE*4),color)
 for e in game.enemies:
  if e.kind in [8,9,10] and e.hp>0 and visible_at(e.pos): draw_circle(point(e.pos),2 if e.kind<8 else 4,Color("f3877a"))
 if is_instance_valid(game.portal) and visible_at(game.portal.position): draw_arc(point(game.portal.position),6,0,TAU,20,Color("b3fff1"),2)
 draw_circle(point(game.player.position),4,Color("fff6dc"))
 var angle=game.player.avatar.rotation.y
 var facing=Vector2(sin(angle),cos(angle))
 draw_line(point(game.player.position),point(game.player.position)+facing*10,Color("fff6dc"),2)
 draw_rect(Rect2(Vector2.ZERO,size),Color("c7a564"),false,2)

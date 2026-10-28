class_name SocketPips
extends Control

# Row of small diamonds showing a weapon's sockets: grey outline = empty, element colour with a
# glint = filled. Only unlocked sockets are drawn, so an Amulet's second socket appears once unlocked.
const SPACING=14.0
var unlocked=1
var gems: Array=[]

func setup(state: Dictionary) -> SocketPips:
 unlocked=WeaponSockets.unlocked(state);gems=WeaponSockets.gems(state).duplicate()
 custom_minimum_size=Vector2(maxf(16.0,unlocked*SPACING+2.0),11);mouse_filter=Control.MOUSE_FILTER_IGNORE
 return self
func _draw() -> void:
 for i in unlocked:
  var c=Vector2(7.0+i*SPACING,5.5);var r=5.0
  var shape=PackedVector2Array([c+Vector2(0,-r),c+Vector2(r,0),c+Vector2(0,r),c+Vector2(-r,0)])
  if i<gems.size():
   var color=Elements.color(str(gems[i]))
   draw_colored_polygon(shape,color)
   draw_polyline(shape+PackedVector2Array([shape[0]]),color.lightened(0.45),1.0)
   draw_line(c+Vector2(-1.5,-2.5),c+Vector2(0.5,-0.5),Color(1,1,1,0.9),1.0) # glint
  else:
   draw_colored_polygon(shape,Color("1a1f20"))
   draw_polyline(shape+PackedVector2Array([shape[0]]),Color("6b7370"),1.0)

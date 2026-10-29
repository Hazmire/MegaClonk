class_name DashedPanel
extends PanelContainer
# Container with a dashed outline (the "Does nothing until you own the Fire socket gem" box).
var line_color=FogPalette.MEMO_INK_SOFT
var line_width=2.0
func _init() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE;add_theme_stylebox_override("panel",StyleBoxEmpty.new())
func _draw() -> void:
 var r=Rect2(Vector2.ZERO,size).grow(-line_width*0.5);var dash=7.0
 var x=r.position.x
 while x<r.end.x:
  var w=minf(dash,r.end.x-x);draw_line(Vector2(x,r.position.y),Vector2(x+w,r.position.y),line_color,line_width);draw_line(Vector2(x,r.end.y),Vector2(x+w,r.end.y),line_color,line_width);x+=dash*2.0
 var y=r.position.y
 while y<r.end.y:
  var h=minf(dash,r.end.y-y);draw_line(Vector2(r.position.x,y),Vector2(r.position.x,y+h),line_color,line_width);draw_line(Vector2(r.end.x,y),Vector2(r.end.x,y+h),line_color,line_width);y+=dash*2.0

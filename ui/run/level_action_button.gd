class_name LevelActionButton
extends Button
# Outlined footer button of the Level-up screen (BANISH / SKIP · HEAL 10 / REFRESH · n LEFT): transparent with a 1px frame,
# rust fill on focus, dim and dashed when it cannot be used.
var caption=""
var line=FogPalette.BORDER
var ink=Color("D9D4C4")
func setup(text_value: String,frame: Color,text_color: Color) -> LevelActionButton:
 caption=text_value;line=frame;ink=text_color;name=text_value.replace(" ","").replace("·","");flat=true;text="";focus_mode=Control.FOCUS_ALL;custom_minimum_size=Vector2(0,54)
 for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw);mouse_entered.connect(func():if not disabled and not has_focus():grab_focus())
 pressed.connect(func():MenuScreen.sfx("confirm"))
 return self
func set_caption(value: String) -> void:caption=value;queue_redraw()
func _draw() -> void:
 var r=Rect2(Vector2.ZERO,size);var live=not disabled
 if has_focus() and live:draw_rect(r,Color(0.494,0.094,0.125,0.6))
 var c=line if live else Color(line.r,line.g,line.b,0.45)
 if live:draw_rect(r.grow(-0.5),c,false,1.0)
 else:
  var x=0.0
  while x<r.size.x:draw_line(Vector2(x,0.5),Vector2(minf(x+6.0,r.size.x),0.5),c);draw_line(Vector2(x,r.size.y-0.5),Vector2(minf(x+6.0,r.size.x),r.size.y-0.5),c);x+=12.0
 var shown=MenuStyle.dot(caption);var f=MenuStyle.sans(800,0.2,15);var w=f.get_string_size(shown,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x
 draw_string(f,Vector2((size.x-w)*0.5,(size.y-f.get_height(15))*0.5+f.get_ascent(15)),shown,HORIZONTAL_ALIGNMENT_LEFT,-1,15,ink if live else Color(ink.r,ink.g,ink.b,0.45))

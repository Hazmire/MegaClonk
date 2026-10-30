class_name GemTile
extends Button
# A gem in the Imbue Station tray: a faceted diamond in its element colour, the name and how many you hold. Empty tiles are dashed and
# dimmed; the held gem is lit, bobs and says HELD.
const SIZE_PX=Vector2(182,104)
var element=""
var gem_name=""
var count=0
var color=Color.WHITE
var held=false
var dimmed=false
func setup(d: Dictionary) -> GemTile:
 element=str(d.element);gem_name=str(d.name);count=int(d.count);color=d.color;name="Gem_"+element
 custom_minimum_size=SIZE_PX;size=SIZE_PX;focus_mode=Control.FOCUS_ALL;flat=true;text="";clip_contents=false
 for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 tooltip_text="%s gem — %s"%[gem_name,Elements.summary(element)]
 mouse_entered.connect(func():if count>0 and not has_focus():grab_focus())
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
 return self
func set_state(is_held: bool,is_dim: bool) -> void:
 held=is_held;dimmed=is_dim;queue_redraw();set_process(held)
func _process(_d: float) -> void:queue_redraw()
func _draw() -> void:
 var empty=count<=0;var r=Rect2(Vector2.ZERO,SIZE_PX);var bob=0.0
 if held:bob=-10.0-3.0*sin(Time.get_ticks_msec()*0.0052)
 var a=0.45 if empty else (0.6 if dimmed else 1.0)
 var dark=color.darkened(0.78)
 if held:
  for k in 6:draw_rect(r.grow(float(k+1)*4.0),Color(color.r,color.g,color.b,0.12*(1.0-float(k)/6.0)),false,4.0)
 draw_rect(Rect2(r.position+Vector2(0,6.0 if held else 0.0),r.size),Color(0,0,0,0.5) if held else Color(0,0,0,0))
 draw_rect(Rect2(r.position+Vector2(0,bob),r.size),dark if held else Color("1A1C19"))
 var frame=Rect2(r.position+Vector2(0,bob),r.size)
 if empty:
  var x=0.0
  while x<r.size.x:draw_line(frame.position+Vector2(x,0),frame.position+Vector2(minf(x+5,r.size.x),0),Color("3A3D38"),1.0);draw_line(frame.position+Vector2(x,r.size.y),frame.position+Vector2(minf(x+5,r.size.x),r.size.y),Color("3A3D38"),1.0);x+=9.0
 else:draw_rect(frame,Color(color.r,color.g,color.b,a),false,3.0 if held else 1.0)
 if has_focus():draw_rect(frame.grow(5.0),FogPalette.RUST_BRIGHT,false,3.0)
 var c=frame.position+Vector2(38,52);var s=18.0
 var pts=PackedVector2Array([c+Vector2(0,-s),c+Vector2(s,0),c+Vector2(0,s),c+Vector2(-s,0)])
 if not empty:draw_colored_polygon(pts,Color(color.r,color.g,color.b,a))
 draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[3],pts[0]]),Color(color.r,color.g,color.b,a),2.0)
 if not empty:draw_polyline(PackedVector2Array([c+Vector2(0,-s),c+Vector2(s*0.35,0),c+Vector2(0,s)]),Color(1,1,1,0.35*a),1.5)
 draw_string(MenuStyle.sans(800,0.12,12),frame.position+Vector2(68,40),gem_name.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,110,12,Color(color.r,color.g,color.b,a) if not empty else Color("6A6D66"))
 draw_string(MenuStyle.sans(800,0,30),frame.position+Vector2(68,82),"×%d"%count,HORIZONTAL_ALIGNMENT_LEFT,90,30,Color("F4EFE2") if not empty else Color("6A6D66"))
 if held:draw_string(MenuStyle.sans(800,0.24,11),frame.position+Vector2(0,frame.size.y-8.0),"HELD",HORIZONTAL_ALIGNMENT_RIGHT,frame.size.x-10.0,11,color)

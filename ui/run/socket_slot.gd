class_name SocketSlot
extends Button
# One socket of a weapon in the Imbue Station. States: gem (filled, shows the element), empty (idle outline), ready (a gem is held and
# fits: dashed in the gem colour, SOCKET), target (chosen: solid, READY), blocked (a gem is held but it cannot go here: shows why),
# locked (second socket: needs an Imbued Amulet; clickable when you have one).
const SIZE_PX=Vector2(200,64)
var state="empty"
var color=Color("6E726A")
var held_color=Color.WHITE
var label=""
var reason=""
var justfused=false
var age=0.0
func setup(n: String) -> SocketSlot:
 name=n;custom_minimum_size=SIZE_PX;size=SIZE_PX;focus_mode=Control.FOCUS_ALL;flat=true;text="";clip_contents=false
 for st in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(st,StyleBoxEmpty.new())
 mouse_entered.connect(func():if not disabled and not has_focus():grab_focus())
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw);set_process(true);return self
func set_state(new_state: String,gem_color: Color,text_label: String,why: String="") -> void:
 state=new_state;color=gem_color;label=text_label;reason=why;queue_redraw()
func _process(delta: float) -> void:
 age+=delta
 if justfused or state=="ready":queue_redraw()
func _draw() -> void:
 var r=Rect2(Vector2.ZERO,SIZE_PX);var sans=MenuStyle.sans(800,0.2,13)
 var c=Vector2(34,32)
 match state:
  "gem":
   draw_rect(r,Color(color.r,color.g,color.b,0.1));draw_rect(r,Color(color.r,color.g,color.b,0.7),false,2.0)
   _diamond(c,17.0,color,true);draw_string(sans,Vector2(62,38),label.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,130,13,color)
   if justfused:
    var t=minf(1.0,age/0.9);draw_arc(c,10.0+60.0*t,0.0,TAU,48,Color(color.r,color.g,color.b,1.0-t),4.0)
  "ready","target":
   var tgt=state=="target"
   draw_rect(r,color.darkened(0.78) if tgt else Color("121311"))
   if tgt:draw_rect(r,color,false,3.0)
   else:
    var pulse=0.55+0.45*sin(age*5.0)
    var x=0.0
    while x<r.size.x:
     draw_line(Vector2(x,1),Vector2(minf(x+7,r.size.x),1),Color(color.r,color.g,color.b,pulse),3.0);draw_line(Vector2(x,r.size.y-1),Vector2(minf(x+7,r.size.x),r.size.y-1),Color(color.r,color.g,color.b,pulse),3.0);x+=13.0
    var y=0.0
    while y<r.size.y:
     draw_line(Vector2(1,y),Vector2(1,minf(y+7,r.size.y)),Color(color.r,color.g,color.b,pulse),3.0);draw_line(Vector2(r.size.x-1,y),Vector2(r.size.x-1,minf(y+7,r.size.y)),Color(color.r,color.g,color.b,pulse),3.0);y+=13.0
   _diamond(c,15.0,color,false);draw_string(sans,Vector2(62,38),"READY" if tgt else "SOCKET",HORIZONTAL_ALIGNMENT_LEFT,130,13,color)
  "blocked":
   draw_rect(r,Color("141513"));draw_rect(r,Color("3A3D38"),false,1.0)
   _diamond(c,12.0,Color("4A4D47"),false);draw_multiline_string(MenuStyle.sans(600,0,12),Vector2(58,28),reason,HORIZONTAL_ALIGNMENT_LEFT,136,12,2,Color("8D9188"))
  "locked":
   draw_rect(r,Color("141513"));draw_rect(r,Color("5A4A1F") if not disabled else Color("3A3D38"),false,1.0)
   draw_rect(Rect2(Vector2(23,32),Vector2(22,16)),Color("A9ADA4") if not disabled else Color("5A5D56"),false,3.0);draw_arc(Vector2(34,32),7.0,PI,TAU,12,Color("A9ADA4") if not disabled else Color("5A5D56"),3.0)
   draw_string(sans,Vector2(62,38),label.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,134,12,Color("E0A33A") if not disabled else Color("6E726A"))
  _:
   draw_rect(r,Color("141513"));draw_rect(r,Color("3A3D38"),false,1.0);_diamond(c,12.0,Color("6E726A"),false)
   draw_string(sans,Vector2(62,38),"EMPTY SOCKET",HORIZONTAL_ALIGNMENT_LEFT,134,12,Color("6E726A"))
 if has_focus():draw_rect(r.grow(5.0),FogPalette.RUST_BRIGHT,false,3.0)
func _diamond(c: Vector2,s: float,col: Color,fill: bool) -> void:
 var pts=PackedVector2Array([c+Vector2(0,-s),c+Vector2(s,0),c+Vector2(0,s),c+Vector2(-s,0)])
 if fill:draw_colored_polygon(pts,col)
 draw_polyline(PackedVector2Array([pts[0],pts[1],pts[2],pts[3],pts[0]]),col,2.0)

class_name ChestFx
extends Control
# Reveal glow behind the card: slowly turning gold rays, three expanding rings and a fixed pool of rising embers. Drawn only; the pool
# is built once. Tinted by the item's tier and scaled by the visual-intensity setting.
const EMBERS=18
var tint=Color("F2C14E")
var strength=1.0
var rays=true
var age=0.0
var embers=[]
func setup(color: Color,power: float,with_rays: bool) -> ChestFx:
 tint=color;strength=power;rays=with_rays;mouse_filter=Control.MOUSE_FILTER_IGNORE;size=Vector2(1920,1080)
 for i in EMBERS:embers.append({"x":420.0+float((i*397)%1080),"y":640.0+float((i*131)%300),"s":4.0+float(i%3)*3.0,"d":2.2+float(i%5)*0.4,"delay":float(i%6)*0.35,"hot":i%3==0})
 return self
func _process(delta: float) -> void:
 age+=delta;queue_redraw()
func _draw() -> void:
 if strength<=0.0:return
 var c=Vector2(960,500)
 if rays:
  var a0=age*TAU/24.0
  for i in 20:
   var a=a0+float(i)*TAU/20.0;var w=TAU/60.0
   draw_colored_polygon(PackedVector2Array([c,c+Vector2.from_angle(a)*1500.0,c+Vector2.from_angle(a+w)*1500.0]),Color(tint.r,tint.g,tint.b,0.2*strength))
 for k in 3:
  var t=(age-0.18*float(k))/(1.0+0.1*float(k))
  if t>0.0 and t<1.0:draw_arc(c,230.0*(0.15+3.45*t),0.0,TAU,64,Color([tint,Color("FFF1C2"),tint.darkened(0.3)][k],1.0-t),[10.0,5.0,3.0][k]*(1.0-t*0.5))
 for e in embers:
  var t=fposmod(age-float(e.delay),float(e.d))/float(e.d)
  var a=minf(1.0,t*5.0)*(1.0-t)
  draw_rect(Rect2(Vector2(float(e.x),float(e.y)-260.0*t),Vector2(float(e.s),float(e.s))),Color(1.0,0.945,0.76,a) if e.hot else Color(tint.r,tint.g,tint.b,a))

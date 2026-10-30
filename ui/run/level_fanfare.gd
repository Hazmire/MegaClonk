class_name LevelFanfare
extends Control
# The Level-up entrance (RunLevelUp): gold flash, rays, three expanding rings, "THE BELL TOLLS" and the level number slammed in.
# Driven by one clock so it can be skipped (any key) and so tests can step it. Pure presentation, ~1.7 s.
signal finished
const DURATION=1.7
const FADE_AT=1.25
const CENTER=Vector2(960,520)
var t=0.0
var level=1
var bell: Label
var number: Label
var prompt: Label
var vignette: TextureRect
var done=false
func setup(new_level: int) -> LevelFanfare:
 level=new_level;name="Fanfare";size=Vector2(MenuStyle.W,MenuStyle.H);mouse_filter=Control.MOUSE_FILTER_IGNORE
 var g=Gradient.new();g.offsets=PackedFloat32Array([0.0,0.18,0.62,1.0]);g.colors=PackedColorArray([Color(0.02,0.024,0.02,0),Color(0.02,0.024,0.02,0),Color(0.02,0.024,0.02,0.9),Color(0.02,0.024,0.02,0.9)])
 var gt=GradientTexture2D.new();gt.gradient=g;gt.fill=GradientTexture2D.FILL_RADIAL;gt.fill_from=Vector2(0.5,0.48);gt.fill_to=Vector2(1.0,0.48);gt.width=256;gt.height=144
 vignette=TextureRect.new();vignette.texture=gt;vignette.stretch_mode=TextureRect.STRETCH_SCALE;vignette.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;vignette.size=size;vignette.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(vignette)
 bell=MenuStyle.label("THE BELL TOLLS",MenuStyle.sans(800,0.6,24),24,FogPalette.GOLD,0,self);bell.size=Vector2(MenuStyle.W,34);bell.position=Vector2(0,330);bell.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 number=MenuStyle.label("Level %d"%level,MenuStyle.serif_sc(),230,FogPalette.BONE_BRIGHT,6,self);number.size=Vector2(MenuStyle.W,240);number.position=Vector2(0,372);number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;number.pivot_offset=Vector2(MenuStyle.W*0.5,120)
 prompt=MenuStyle.label("CHOOSE 1 OF 3 · ANY KEY TO SKIP",MenuStyle.sans(800,0.3,20),20,Color("D9D4C4"),0,self);prompt.size=Vector2(MenuStyle.W,28);prompt.position=Vector2(0,636);prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _apply();return self
func _process(delta: float) -> void:advance(delta)
func advance(delta: float) -> void:
 if done:return
 t+=delta
 if t>=DURATION:done=true;visible=false;finished.emit();return
 _apply();queue_redraw()
func skip() -> void:
 if done:return
 t=DURATION;done=true;visible=false;finished.emit()
static func _ease_out_back(x: float) -> float:
 var c1=1.70158*1.2;var c3=c1+1.0;return 1.0+c3*pow(x-1.0,3.0)+c1*pow(x-1.0,2.0)
func _apply() -> void:
 modulate.a=1.0 if t<FADE_AT else clampf(1.0-(t-FADE_AT)/(DURATION-FADE_AT),0.0,1.0)
 bell.modulate.a=clampf((t-0.15)/0.3,0.0,1.0);bell.position.y=330.0+12.0*(1.0-clampf((t-0.15)/0.3,0.0,1.0))
 var k=clampf((t-0.05)/0.55,0.0,1.0);var s=lerpf(2.8,0.93,k/0.45) if k<0.45 else (lerpf(0.93,1.05,(k-0.45)/0.17) if k<0.62 else lerpf(1.05,1.0,(k-0.62)/0.38))
 number.scale=Vector2(s,s);number.modulate.a=clampf(k/0.45,0.0,1.0)
 prompt.modulate.a=clampf((t-0.45)/0.3,0.0,1.0)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.024,0.02,0.62))
 var spin=deg_to_rad(t/DURATION*45.0)
 for i in 24:
  var a0=spin+deg_to_rad(i*15.0);var a1=a0+deg_to_rad(5.0)
  draw_colored_polygon(PackedVector2Array([CENTER,CENTER+Vector2.from_angle(a0)*2000.0,CENTER+Vector2.from_angle(a1)*2000.0]),Color(0.949,0.757,0.306,0.24))
 var rings=[[0.05,0.9,8.0,Color("F2C14E")],[0.2,1.0,5.0,Color("F7DFA0")],[0.35,1.1,3.0,Color("B3363F")]]
 for ring in rings:
  var k=(t-float(ring[0]))/float(ring[1])
  if k<=0.0 or k>=1.0:continue
  var rad=210.0*lerpf(0.15,3.4,1.0-pow(1.0-k,2.0));var c: Color=ring[3];draw_arc(CENTER,rad,0.0,TAU,96,Color(c.r,c.g,c.b,1.0-k),float(ring[2]))
 if t<0.35:draw_rect(Rect2(Vector2.ZERO,size),Color(1.0,0.929,0.76,0.9*(1.0-t/0.35)))

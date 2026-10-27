class_name RewardCelebration
extends Control
# A fixed draw-particle pool: recycle phase instead of allocating UI nodes.
var age=0.0
var rainbow=false
var rays=false
var center=Vector2(620,350)
var tint=Color.WHITE
var strength=1.0
var particles=[]
var confetti=true
var fading=false
var fade_age=0.0
var burst_age=100.0
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE;process_mode=Node.PROCESS_MODE_ALWAYS
 var rng=RandomNumberGenerator.new();rng.seed=42191
 for i in int(32+48*clampf(strength,0,1)):
  particles.append({"start":Vector2(rng.randf_range(0,1280),rng.randf_range(-150,800)),"speed":rng.randf_range(100,230),"phase":rng.randf()*TAU,"color":Color.from_hsv(rng.randf(),0.65,1),"gem":i%3==0})
func burst(color: Color,power: float) -> void:
 tint=color;strength=power;burst_age=0
func fade_out() -> void:
 if not visible:queue_free();return
 fading=true;fade_age=0;set_process(true)
func _process(delta: float) -> void:
 if not is_visible_in_tree():return
 age+=delta;burst_age+=delta
 if fading:
  fade_age+=delta;modulate.a=maxf(0,1-fade_age/0.4)
  if fade_age>=0.4:queue_free();return
 queue_redraw()
func _draw() -> void:
 if rainbow:
  for i in 48:draw_rect(Rect2(i*1280.0/48,0,1280.0/48+1,7),Color.from_hsv(fmod(float(i)/48+age*0.16,1),0.85,1))
 if rays:
  for i in 16:
   var angle=i*TAU/16+age*0.07
   draw_colored_polygon(PackedVector2Array([center+Vector2.from_angle(angle)*35,center+Vector2.from_angle(angle-0.035)*(130+100*strength),center+Vector2.from_angle(angle+0.035)*(130+100*strength)]),Color(tint,0.08+strength*0.08+sin(age*2+i)*0.04))
 for p in particles:
  var y=fposmod(p.start.y+age*p.speed,1000)-150
  var point=Vector2(p.start.x+sin(age*2+p.phase)*25,y)
  var color=Color(p.color,0.75)
  if confetti and p.gem:draw_colored_polygon(PackedVector2Array([point+Vector2(0,-8),point+Vector2(4,0),point+Vector2(0,8),point+Vector2(-4,0)]),color)
  elif confetti:draw_line(point,point+Vector2(sin(p.phase+age)*6,4),color,3)
  var sparkle=0.5+0.5*sin(age*4+p.phase)
  if confetti and sparkle>0.9:draw_line(point-Vector2(5,0),point+Vector2(5,0),Color.WHITE,1)
  if burst_age<0.85:
   var ray=Vector2.from_angle(p.phase);var burst_point=center+ray*burst_age*(180+strength*350)
   draw_circle(burst_point,2+strength*3,Color(tint,1-burst_age/0.85))

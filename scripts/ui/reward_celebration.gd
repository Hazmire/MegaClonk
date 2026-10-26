class_name RewardCelebration
extends Control
var age=0.0
var rainbow=false
var rays=false
var center=Vector2(620,350)
var tint=Color.WHITE
var strength=1.0
var particles=[]
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE;process_mode=Node.PROCESS_MODE_ALWAYS
 var rng=RandomNumberGenerator.new();rng.seed=42191
 for i in int(12+20*strength):
  particles.append({"start":Vector2(rng.randf_range(0,1280),rng.randf_range(-300,-10)),"speed":rng.randf_range(100,230),"phase":rng.randf()*TAU,"color":Color.from_hsv(rng.randf(),0.65,1),"gem":i%3==0})
func _process(delta: float) -> void:
 if not is_visible_in_tree():set_process(false);return
 age+=delta;queue_redraw()
 if age>3 and not rainbow and not rays:set_process(false)
func _draw() -> void:
 if rainbow:
  for i in 48:draw_rect(Rect2(i*1280.0/48,0,1280.0/48+1,7),Color.from_hsv(fmod(float(i)/48+age*0.16,1),0.85,1))
 if rays:
  for i in 16:
   var angle=i*TAU/16+age*0.07
   var a=center+Vector2.from_angle(angle)*35;var b=center+Vector2.from_angle(angle-0.035)*(130+100*strength);var c=center+Vector2.from_angle(angle+0.035)*(130+100*strength)
   draw_colored_polygon(PackedVector2Array([a,b,c]),Color(tint,0.08+strength*0.08+sin(age*2+i)*0.04))
 if age<3:
  for p in particles:
   var point=p.start+Vector2(sin(age*2+p.phase)*25,age*p.speed)
   var color=Color(p.color,clampf(3-age,0,1))
   if p.gem:draw_colored_polygon(PackedVector2Array([point+Vector2(0,-8),point+Vector2(4,0),point+Vector2(0,8),point+Vector2(-4,0)]),color)
   else:draw_line(point,point+Vector2(sin(p.phase+age)*6,4),color,3)

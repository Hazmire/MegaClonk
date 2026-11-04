class_name EndlessTimerFx
extends Node
# The look of the run timer once it has become the endless timer. It owns no digits of its own: the HUD's one timer Label stays the same node before and
# after the switch, and this restyles it (colour, edge, glow, pulse, smoulder, twitch) and adds what sits behind and across it (glow copy, blood-red
# ghost copy, split band, scanline, embers, smoke). Particles are children of the timer with show_behind_parent, so they draw behind the digits and the
# ENDLESS line, never over them. Every colour, time and cap comes from EndlessTimerStyle. Nothing here allocates per frame.
const SIZE=Vector2(600,76)
var timer: Label
var glow: Label
var ghost: Label
var band: Control
var embers: CPUParticles2D
var smoke: CPUParticles2D
var active=false
var tier=-1
var reduce_motion=false
var glitch_t=-1.0
var clock=0.0
var glitches=0 # how many times the glitch has played this run (the start, then every tier change)
var tier_changes=0
func setup(label: Label) -> EndlessTimerFx:
 name="EndlessTimerFx";timer=label;var style=EndlessTimerStyle.data();var font: Font=label.get_theme_font("font")
 # behind the digits: smoke, embers, glow copy
 smoke=_particles(true);label.add_child(smoke);embers=_particles(false);label.add_child(embers)
 glow=_copy(font,Color(0,0,0,0));glow.add_theme_constant_override("outline_size",14);glow.add_theme_color_override("font_outline_color",Color(0,0,0,0));glow.show_behind_parent=true;label.add_child(glow)
 ghost=_copy(font,Color(style.glitch.ghost_color));ghost.visible=false;label.add_child(ghost)
 band=GlitchBand.new();band.name="GlitchBand";band.mouse_filter=Control.MOUSE_FILTER_IGNORE;band.set("timer",label);band.visible=false;label.add_child(band)
 label.pivot_offset=SIZE*0.5
 return self
func _copy(font: Font,color: Color) -> Label:
 var l=Label.new();l.mouse_filter=Control.MOUSE_FILTER_IGNORE;l.add_theme_font_override("font",font);l.add_theme_font_size_override("font_size",timer.get_theme_font_size("font_size"))
 l.add_theme_color_override("font_color",color);l.add_theme_color_override("font_shadow_color",Color(0,0,0,0));l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.size=SIZE;l.pivot_offset=SIZE*0.5;l.text=timer.text
 return l
func _particles(is_smoke: bool) -> CPUParticles2D:
 var style=EndlessTimerStyle.data();var p=CPUParticles2D.new();p.name="Smoke" if is_smoke else "Embers"
 p.emitting=false;p.amount=int(style.caps.smoke if is_smoke else style.caps.embers);p.show_behind_parent=true
 p.position=Vector2(300,30);p.emission_shape=CPUParticles2D.EMISSION_SHAPE_RECTANGLE;p.emission_rect_extents=Vector2(110 if is_smoke else 130,18)
 p.direction=Vector2(0,-1);p.spread=18.0;p.gravity=Vector2(0,-12 if is_smoke else -20)
 p.initial_velocity_min=18.0 if is_smoke else 22.0;p.initial_velocity_max=30.0 if is_smoke else 40.0
 p.lifetime=3.0 if is_smoke else 2.0;p.preprocess=p.lifetime
 var fade=Gradient.new();fade.set_color(0,Color(1,1,1,0));fade.add_point(0.15,Color(1,1,1,0.9));fade.set_color(fade.get_point_count()-1,Color(1,1,1,0));p.color_ramp=fade
 if is_smoke:
  var g=Gradient.new();g.set_color(0,Color(1,1,1,1));g.set_color(1,Color(1,1,1,0))
  var tex=GradientTexture2D.new();tex.gradient=g;tex.fill=GradientTexture2D.FILL_RADIAL;tex.fill_from=Vector2(0.5,0.5);tex.fill_to=Vector2(1.0,0.5);tex.width=32;tex.height=32
  p.texture=tex;p.scale_amount_min=0.8;p.scale_amount_max=1.4
  var grow=Curve.new();grow.add_point(Vector2(0,0.5));grow.add_point(Vector2(1,1.8));p.scale_amount_curve=grow
 else:
  p.scale_amount_min=4.0;p.scale_amount_max=6.0 # untextured: pixel squares
 return p
# Restored mid-endless (Save & quit and reload): the look is in force at once, with no glitch.
func resume() -> void:
 if active:return
 active=true;tier=-1;glitch_t=-1.0
# A new run: the timer goes back to its normal look.
func reset() -> void:
 active=false;tier=-1;glitch_t=-1.0;clock=0.0;glitches=0;tier_changes=0
 for key in ["font_outline_color"]:timer.remove_theme_color_override(key)
 timer.remove_theme_constant_override("outline_size");timer.scale=Vector2.ONE;timer.modulate=Color.WHITE;timer.position.x=0.0
 ghost.visible=false;band.visible=false;embers.emitting=false;smoke.emitting=false
 glow.add_theme_color_override("font_outline_color",Color(0,0,0,0))
# The stage clock reached 0:00: tear the timer, then it comes back as red 00:00. Called once per run.
func start_endless() -> void:
 if active:return
 active=true;tier=-1;glitch_t=0.0;glitches=1
func set_text(text: String) -> void:
 if glow.text!=text:glow.text=text;ghost.text=text
 band.set("text",text)
func active_particles() -> int:
 return (embers.amount if embers.emitting else 0)+(smoke.amount if smoke.emitting else 0)
# Per frame while the run is simulating (the HUD passes the game's mode; effects pause with the game).
func tick(delta: float,endless_seconds: float,running: bool) -> void:
 if not active:return
 var style=EndlessTimerStyle.data()
 embers.speed_scale=1.0 if running else 0.0;smoke.speed_scale=embers.speed_scale
 if not running:return
 clock+=delta
 var want=EndlessTimerStyle.tier_index(endless_seconds)
 if want!=tier:
  var first=tier==-1;tier=want;_apply_tier()
  if not first:glitch_t=0.0;glitches+=1;tier_changes+=1 # every tier change replays the glitch, without the banshee
 var g: Dictionary=style.glitch;var d=float(g.duration_s)
 if glitch_t>=0.0:
  glitch_t+=delta
  if glitch_t<d:
   ghost.visible=true;band.visible=not reduce_motion;ghost.position=Vector2(g.ghost_offset[0],g.ghost_offset[1])
   var step=int(glitch_t/float(g.shake_step_s));timer.position.x=0.0 if reduce_motion else float(g.shake_px)*(1.0 if step%2==0 else -1.0)
   band.queue_redraw();return
  ghost.visible=false;band.visible=false;timer.position.x=0.0
  var k=clampf((glitch_t-d)/float(g.settle_s),0.0,1.0)
  var s=lerpf(float(g.settle_scale),1.0,1.0-pow(1.0-k,3.0)) if not reduce_motion else 1.0
  timer.scale=Vector2.ONE*s;glow.scale=Vector2.ONE
  # double brightness down to 1x while settling
  timer.modulate=Color(1,1,1,1).lerp(Color(2,2,2,1),1.0-k) if not reduce_motion else Color.WHITE
  if k>=1.0:glitch_t=-1.0;timer.scale=Vector2.ONE;timer.modulate=Color.WHITE
 if tier<0 or reduce_motion:return
 var tt: Dictionary=style.tiers[tier]
 if bool(tt.smoulder):
  var cols: Array=tt.smoulder_colors;var n=int(tt.smoulder_steps);var i=int(fmod(clock,float(tt.smoulder_s))/float(tt.smoulder_s)*n)%cols.size()
  var edge=Color(cols[i]);timer.add_theme_color_override("font_outline_color",edge);var gc=edge;gc.a=float(tt.glow_alpha);glow.add_theme_color_override("font_outline_color",gc)
 elif float(tt.pulse_s)>0.0:
  var p=0.5+0.5*sin(clock/float(tt.pulse_s)*TAU);var gc=Color(tt.glow);gc.a=float(tt.glow_alpha)*(0.6+0.4*p);glow.add_theme_color_override("font_outline_color",gc)
 if float(tt.twitch_s)>0.0 and glitch_t<0.0:
  var ph=fmod(clock,float(tt.twitch_s))/float(tt.twitch_s)
  timer.position=Vector2(-2,1) if ph>0.92 and ph<0.95 else (Vector2(2,-1) if ph>=0.95 and ph<0.97 else Vector2.ZERO)
func _apply_tier() -> void:
 var tt: Dictionary=EndlessTimerStyle.tiers()[tier]
 timer.add_theme_color_override("font_color",Color(tt.digits));timer.add_theme_color_override("font_outline_color",Color(tt.edge));timer.add_theme_constant_override("outline_size",2)
 var gc=Color(tt.glow);gc.a=float(tt.glow_alpha);glow.add_theme_color_override("font_outline_color",gc)
 var e=int(tt.embers);var s=int(tt.smoke);var caps: Dictionary=EndlessTimerStyle.data().caps
 embers.emitting=e>0 and not reduce_motion
 if e>0:embers.amount=mini(e,int(caps.embers));embers.color=Color(tt.get("ember_color","#FF6A3A"))
 smoke.emitting=s>0 and not reduce_motion
 if s>0:smoke.amount=mini(s,int(caps.smoke));smoke.color=Color(tt.get("smoke_color","#120808"))
# The glitch's split band and dashed scanline, drawn over the digits while the glitch plays. The control is a thin strip through the middle of the
# timer with clip_contents on, so the cream copy of the digits is cut to a band and shifted sideways: the digits "split".
class GlitchBand extends Control:
 const SIZE_X=600.0
 const SIZE_Y=76.0
 const BAND=18.0
 var timer: Label
 var text=""
 func _ready() -> void:
  clip_contents=true;position=Vector2(0,SIZE_Y*0.5-BAND*0.5);size=Vector2(SIZE_X,BAND)
 func _draw() -> void:
  if timer==null:return
  var font: Font=timer.get_theme_font("font");var font_size=timer.get_theme_font_size("font_size");var style=EndlessTimerStyle.data()
  draw_rect(Rect2(0,0,SIZE_X,BAND),Color(0.02,0.02,0.02,0.55))
  var text_size=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size)
  var origin=Vector2((SIZE_X-text_size.x)*0.5+9.0,(SIZE_Y+font.get_ascent(font_size)-font.get_descent(font_size))*0.5-(SIZE_Y*0.5-BAND*0.5))
  draw_string(font,origin,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,Color(style.normal.digits))
  var x=0.0
  while x<SIZE_X:
   draw_line(Vector2(x,BAND*0.5),Vector2(minf(x+10.0,SIZE_X),BAND*0.5),Color(style.glitch.ghost_color),2.0);x+=16.0

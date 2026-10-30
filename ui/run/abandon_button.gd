class_name AbandonButton
extends Button
# "Abandon run": dashed red frame under a dashed rule, "Hold to confirm". Needs a 1 s hold of Enter / A / the mouse button;
# the fill grows across the button while held, letting go (or leaving focus) drains it. Selected it fills #5A1418.
signal confirmed
const HOLD_TIME=1.0
const DRAIN=3.0
var progress=0.0
var holding=false
var fired=false
func _init() -> void:
 name="AbandonRun";focus_mode=Control.FOCUS_ALL;flat=true;text="";custom_minimum_size=Vector2(520,84);tooltip_text="Hold Enter for one second to abandon this run"
 for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 action_mode=BaseButton.ACTION_MODE_BUTTON_RELEASE
 focus_entered.connect(queue_redraw);focus_exited.connect(func():holding=false;queue_redraw())
 mouse_entered.connect(func():if not has_focus():grab_focus())
func _gui_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_accept") and not event.is_echo():holding=true;accept_event()
 elif event.is_action_released("ui_accept"):holding=false;accept_event()
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  holding=event.pressed;accept_event()
# Holding the activation key must not trigger Button.pressed (it would act as a normal click): swallow it.
func _pressed() -> void:pass
func _process(delta: float) -> void:step(delta)
# Advances the hold; separate from _process so tests can drive time.
func step(delta: float) -> void:
 var before=progress
 if holding and is_visible_in_tree():progress=minf(1.0,progress+delta/HOLD_TIME)
 else:progress=maxf(0.0,progress-delta*DRAIN);fired=false
 if progress>=1.0 and not fired:fired=true;confirmed.emit()
 if progress!=before:queue_redraw()
func _draw() -> void:
 var r=Rect2(Vector2.ZERO,size);var selected=has_focus()
 if selected:draw_rect(r,Color("5A1418"))
 if progress>0.0:draw_rect(Rect2(0,0,size.x*progress,size.y),Color("9A2A30") if progress<1.0 else FogPalette.RUST_BRIGHT)
 var line=FogPalette.RUST_TEXT;var dash=8.0;var rr=r.grow(-1.0)
 for x in range(0,int(rr.size.x),int(dash*2)):
  var x2=minf(x+dash,rr.size.x);draw_line(rr.position+Vector2(x,0),rr.position+Vector2(x2,0),line,2.0);draw_line(rr.position+Vector2(x,rr.size.y),rr.position+Vector2(x2,rr.size.y),line,2.0)
 for y in range(0,int(rr.size.y),int(dash*2)):
  var y2=minf(y+dash,rr.size.y);draw_line(rr.position+Vector2(0,y),rr.position+Vector2(0,y2),line,2.0);draw_line(rr.position+Vector2(rr.size.x,y),rr.position+Vector2(rr.size.x,y2),line,2.0)
 var f=MenuStyle.serif();var head="Abandon run"
 draw_string(f,Vector2(28,36),head,HORIZONTAL_ALIGNMENT_LEFT,-1,30,FogPalette.BONE_BRIGHT if selected else FogPalette.RUST_TEXT)
 var key="A" if MenuScreen.pad_active() else "Enter"
 var sub="Hold %s · run is lost"%key if selected else "Hold to confirm"
 draw_string(MenuStyle.sans(800,0.2,14),Vector2(28,66),MenuStyle.dot(sub.to_upper()),HORIZONTAL_ALIGNMENT_LEFT,-1,14,FogPalette.BONE if selected else FogPalette.RUST_TEXT)

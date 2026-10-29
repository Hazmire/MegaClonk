class_name Stepper
extends Button
# Choice control for a short fixed list (resolution, quality): "‹ HIGH ›". Left / Right keys step it, a click on either half steps that way.
signal changed(index: int)
var options: Array=[]
var index=0
func setup(values: Array,current: int) -> Stepper:
 options=values;index=clampi(current,0,maxi(0,values.size()-1));custom_minimum_size=Vector2(300,48);return self
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL;text="";flat=true
 for s in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(s,StyleBoxEmpty.new())
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
 pressed.connect(func():step(-1 if (is_hovered() and get_local_mouse_position().x<size.x*0.5) else 1))
func step(direction: int) -> void:
 if options.is_empty():return
 index=posmod(index+direction,options.size());MenuScreen.sfx("hover");queue_redraw();changed.emit(index)
func _gui_input(event: InputEvent) -> void:
 if event.is_action_pressed("ui_left"):accept_event();step(-1)
 elif event.is_action_pressed("ui_right"):accept_event();step(1)
func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.055,0.059,0.055,0.85))
 draw_rect(Rect2(Vector2.ONE*0.5,size-Vector2.ONE),FogPalette.RUST_BRIGHT if has_focus() else FogPalette.BORDER_LIGHT,false,2.0 if has_focus() else 1.0)
 var f=MenuStyle.sans(800,0.2,16)
 var word=String(options[index]).to_upper() if not options.is_empty() else ""
 var s=f.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,16)
 var y=(size.y-f.get_height(16))*0.5+f.get_ascent(16)
 draw_string(f,Vector2((size.x-s.x)*0.5,y),word,HORIZONTAL_ALIGNMENT_LEFT,-1,16,FogPalette.BONE_BRIGHT)
 var c=FogPalette.BONE if has_focus() else FogPalette.ASH_DIM
 draw_colored_polygon(PackedVector2Array([Vector2(16,size.y*0.5),Vector2(26,size.y*0.5-7),Vector2(26,size.y*0.5+7)]),c)
 draw_colored_polygon(PackedVector2Array([Vector2(size.x-16,size.y*0.5),Vector2(size.x-26,size.y*0.5-7),Vector2(size.x-26,size.y*0.5+7)]),c)

class_name OnOffToggle
extends Button
# Segmented ON / OFF switch ("Appears in runs"). Ink frame, the active half is filled ink. Enter/Space/click flips it.
signal changed(on: bool)
var on=true
var enabled_look=true
func setup(value: bool) -> OnOffToggle:
 on=value;toggle_mode=false;queue_redraw();return self
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL;text="";flat=true;custom_minimum_size=Vector2(116,40)
 for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 pressed.connect(func():set_on(not on);MenuScreen.sfx("confirm"))
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
func set_on(value: bool,emit: bool=true) -> void:
 if value==on:return
 on=value;queue_redraw()
 if emit:changed.emit(on)
func _draw() -> void:
 var font=MenuStyle.sans(800,0.2,14)
 var half=size.x*0.5
 draw_rect(Rect2(0,0,half,size.y),FogPalette.MEMO_INK if on else Color(0,0,0,0))
 draw_rect(Rect2(half,0,half,size.y),Color(0,0,0,0) if on else FogPalette.MEMO_INK)
 for i in 2:
  var word="ON" if i==0 else "OFF";var active=(i==0)==on
  var s=font.get_string_size(word,HORIZONTAL_ALIGNMENT_LEFT,-1,14)
  draw_string(font,Vector2(half*i+(half-s.x)*0.5,(size.y-font.get_height(14))*0.5+font.get_ascent(14)),word,HORIZONTAL_ALIGNMENT_LEFT,-1,14,FogPalette.MEMO if active else FogPalette.MEMO_INK)
 draw_rect(Rect2(Vector2.ONE,size-Vector2(2,2)),FogPalette.RUST_BRIGHT if has_focus() else FogPalette.MEMO_INK,false,2.0)

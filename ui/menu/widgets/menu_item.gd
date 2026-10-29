class_name MenuItem
extends Button
# Main-menu row. Default: ash serif text indented 56px. Selected (focus or hover): rust fill, bone text, square cursor,
# bigger type. Pressed: one-frame colour invert. Locked: grey with a strike-through.
signal chosen
var label_text=""
var locked=false
var size_normal=38
var size_selected=48
var row_normal=64
var row_selected=76
var flash=0.0
func setup(value: String,normal_size: int=38,selected_size: int=48,is_locked: bool=false) -> MenuItem:
 label_text=value;locked=is_locked;size_normal=normal_size;size_selected=selected_size
 name=value.replace(" ","");tooltip_text=value
 return self
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL;text="";alignment=HORIZONTAL_ALIGNMENT_LEFT;flat=true
 for state in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(state,StyleBoxEmpty.new())
 focus_entered.connect(_refresh);focus_exited.connect(_refresh)
 mouse_entered.connect(func():if not has_focus():grab_focus();MenuScreen.sfx("hover"))
 pressed.connect(_on_pressed)
 _refresh()
func _on_pressed() -> void:
 if locked:return
 MenuScreen.sfx("confirm");flash=0.08;set_process(true);queue_redraw();chosen.emit()
func _process(delta: float) -> void:
 flash-=delta;queue_redraw()
 if flash<=0.0:set_process(false)
func _refresh() -> void:
 custom_minimum_size.y=row_selected if has_focus() else row_normal
 queue_redraw()
func _draw() -> void:
 var selected=has_focus()
 var px=size_selected if selected else size_normal
 var font=MenuStyle.serif()
 var color=FogPalette.ASH
 if selected:
  var inverted=flash>0.0
  draw_rect(Rect2(Vector2.ZERO,size),FogPalette.BONE if inverted else FogPalette.RUST)
  draw_rect(Rect2(24,(size.y-14)*0.5,14,14),FogPalette.RUST if inverted else FogPalette.BONE_BRIGHT)
  color=FogPalette.RUST if inverted else FogPalette.BONE_BRIGHT
 if locked:color=MenuStyle.LOCKED_TEXT
 var s=font.get_string_size(label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,px)
 var base=Vector2(56,(size.y-font.get_height(px))*0.5+font.get_ascent(px))
 if selected and flash<=0.0:draw_string(font,base+Vector2(3,3),label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,FogPalette.INK)
 draw_string(font,base,label_text,HORIZONTAL_ALIGNMENT_LEFT,-1,px,color)
 if locked:draw_rect(Rect2(56,size.y*0.5,s.x,2),color)

class_name LoadoutSlot
extends Button
# One 104px row on "Prepare your run": icon, name, short stats and the dropdown chevron. Space / click opens the list;
# Enter on the row starts the run (the screen listens for `start_requested`).
signal open_requested
signal start_requested
var category=""
var slot_label=""
var current: Dictionary={}
var chips: Array=[]
var detail=""
var open_state=false
func setup(cat: String,label: String) -> LoadoutSlot:
 category=cat;slot_label=label;name="Slot_"+cat;custom_minimum_size=Vector2(660,104);return self
func show_entry(entry: Dictionary,chip_texts: Array,detail_text: String) -> void:
 current=entry;chips=chip_texts;detail=detail_text;tooltip_text=String(entry.get("name",""));queue_redraw()
func set_open(value: bool) -> void:open_state=value;queue_redraw()
func _ready() -> void:
 focus_mode=Control.FOCUS_ALL;text="";flat=true;action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
 for s in ["normal","hover","pressed","focus","disabled","hover_pressed"]:add_theme_stylebox_override(s,StyleBoxEmpty.new())
 focus_entered.connect(queue_redraw);focus_exited.connect(queue_redraw)
 mouse_entered.connect(func():if not has_focus():grab_focus())
 pressed.connect(func():MenuScreen.sfx("confirm");open_requested.emit())
func _gui_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ENTER or event.keycode==KEY_KP_ENTER:
   accept_event();start_requested.emit()
func _draw() -> void:
 var active=has_focus() or open_state
 draw_rect(Rect2(Vector2.ZERO,size),Color(0.055,0.059,0.055,0.88 if category=="weapons" else 0.78))
 draw_rect(Rect2(Vector2.ONE,size-Vector2(2,2)),FogPalette.RUST if active else FogPalette.BORDER,false,2.0 if active else 1.0)
 if current.is_empty():return
 var box=Rect2(16,(size.y-76.0)*0.5,76,76)
 draw_texture_rect(UIAssets.icon(category,String(current.id)),Rect2(box.position+Vector2(6,6),Vector2(64,64)),false)
 draw_rect(box.grow(-1.0),FogPalette.BORDER,false,2.0)
 var serif=MenuStyle.serif();var title_px=36 if category=="weapons" else 34
 var x=112.0
 var top=22.0 if not chips.is_empty() else 16.0
 draw_string(serif,Vector2(x,top+serif.get_ascent(title_px)),String(current.name),HORIZONTAL_ALIGNMENT_LEFT,size.x-x-100.0,title_px,FogPalette.BONE if active or category=="weapons" else Color("D9D4C4"))
 if not chips.is_empty():
  var f=MenuStyle.sans(600,0.14,14);var cx=x;var cy=top+title_px+10.0
  for c in chips:
   var s=f.get_string_size(String(c),HORIZONTAL_ALIGNMENT_LEFT,-1,14)
   draw_rect(Rect2(cx,cy,s.x+16,f.get_height(14)+4),Color("2A2C28"))
   draw_string(f,Vector2(cx+8,cy+2+f.get_ascent(14)),String(c),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("D9D4C4"));cx+=s.x+16+8
 elif detail!="":
  var f=MenuStyle.sans(600,0.0,17)
  draw_multiline_string(f,Vector2(x,top+title_px+6+f.get_ascent(17)),detail,HORIZONTAL_ALIGNMENT_LEFT,size.x-x-90.0,17,2,FogPalette.ASH)
 # chevron button: rust and pointing up while the list is open
 var b=Rect2(size.x-16-52,(size.y-52.0)*0.5,52,52)
 if open_state:draw_rect(b,FogPalette.RUST);draw_rect(b.grow(-0.5),FogPalette.RUST_BRIGHT,false,1.0)
 else:draw_rect(b.grow(-0.5),MenuStyle.OUTLINE,false,1.0)
 var c=b.get_center();var col=FogPalette.BONE_BRIGHT if open_state else FogPalette.ASH
 if open_state:draw_polyline(PackedVector2Array([c+Vector2(-6,3),c+Vector2(0,-3),c+Vector2(6,3)]),col,3.0)
 else:draw_polyline(PackedVector2Array([c+Vector2(-6,-3),c+Vector2(0,3),c+Vector2(6,-3)]),col,3.0)

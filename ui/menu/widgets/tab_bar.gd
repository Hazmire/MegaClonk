class_name MenuTabBar
extends Control
# Category tabs: Overpass 800 caps, the active tab underlined in rust. Q / E (or shoulders) step through them.
signal tab_selected(id: String)
var tabs: Array=[]
var buttons: Dictionary={}
var active=""
var note=""
var row: HBoxContainer
func _init() -> void:
 custom_minimum_size=Vector2(1690,53);mouse_filter=Control.MOUSE_FILTER_IGNORE
 row=HBoxContainer.new();row.add_theme_constant_override("separation",40);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(row)
func set_tabs(entries: Array,current: String) -> void:
 tabs=entries;active=current
 for c in row.get_children():row.remove_child(c);c.queue_free()
 buttons.clear()
 for e in entries:
  var b=Button.new();b.name="Tab"+String(e.id).capitalize();b.text=String(e.label).to_upper();b.focus_mode=Control.FOCUS_ALL;b.custom_minimum_size=Vector2(0,52)
  var id=String(e.id)
  b.add_theme_font_override("font",MenuStyle.sans(800,0.26,18));b.add_theme_font_size_override("font_size",18)
  b.pressed.connect(func():select(id));b.mouse_entered.connect(func():MenuScreen.sfx("hover"))
  row.add_child(b);buttons[id]=b
 _style()
func select(id: String,emit: bool=true) -> void:
 if id==active or not buttons.has(id):return
 active=id;_style()
 if emit:MenuScreen.sfx("confirm");tab_selected.emit(id)
func step(direction: int) -> void:
 if tabs.is_empty():return
 var index=0
 for i in tabs.size():
  if String(tabs[i].id)==active:index=i
 select(String(tabs[posmod(index+direction,tabs.size())].id))
func set_note(value: String) -> void:note=value;queue_redraw()
func _style() -> void:
 for id in buttons:
  var b: Button=buttons[id];var is_active=id==active
  var under=FogTheme.flat(Color(0,0,0,0));under.border_width_bottom=4;under.border_color=FogPalette.RUST if is_active else Color(0,0,0,0)
  var focus=FogTheme.flat(Color(0.494,0.094,0.125,0.25));focus.border_width_bottom=4;focus.border_color=FogPalette.RUST_BRIGHT
  for state in ["normal","hover","pressed","hover_pressed"]:b.add_theme_stylebox_override(state,under)
  b.add_theme_stylebox_override("focus",focus)
  var col=FogPalette.BONE_BRIGHT if is_active else FogPalette.ASH_DIM
  for key in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:b.add_theme_color_override(key,col if key!="font_hover_color" else FogPalette.BONE)
func _draw() -> void:
 draw_rect(Rect2(0,52,size.x,1),FogPalette.BORDER)
 if note!="":
  var f=MenuStyle.sans(800,0.2,15);var s=f.get_string_size(note,HORIZONTAL_ALIGNMENT_LEFT,-1,15)
  draw_string(f,Vector2(size.x-s.x,34),note,HORIZONTAL_ALIGNMENT_LEFT,-1,15,FogPalette.ASH_DIM)

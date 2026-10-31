class_name SlotDropdown
extends PanelContainer
# The list under a loadout slot: text filter, category tags (weapons only), rows with a tick on the current pick,
# and a footer ("4 OF 8 UNLOCKED · SCROLLS"). Arrow keys move, Enter picks, Esc closes just the list.
signal picked(id: String)
signal closed
const ROW=60
const MAX_ROWS=6
var options: Array=[]
var current=""
var tags: Array=[]
var tag="All"
var filter: LineEdit
var tag_box: HBoxContainer
var scroll: ScrollContainer
var rows: VBoxContainer
var footer_left: Label
var tag_buttons: Dictionary={}
func _init() -> void:
 var style=FogTheme.flat(Color("121311"),FogPalette.RUST,2);style.border_width_top=0;style.shadow_color=Color(0,0,0,0.7);style.shadow_size=18;style.shadow_offset=Vector2(0,18)
 style.set_content_margin_all(0);add_theme_stylebox_override("panel",style);name="Dropdown"
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",0);add_child(column)
 var bar=HBoxContainer.new();bar.add_theme_constant_override("separation",12);bar.name="FilterRow"
 var bar_margin=MarginContainer.new();for side in ["left","right"]:bar_margin.add_theme_constant_override("margin_"+side,16)
 bar_margin.add_theme_constant_override("margin_top",8);bar_margin.add_theme_constant_override("margin_bottom",8);bar_margin.add_child(bar);column.add_child(bar_margin)
 var glass=SearchGlass.new();glass.custom_minimum_size=Vector2(18,18);bar.add_child(glass)
 filter=LineEdit.new();filter.name="Filter";filter.size_flags_horizontal=Control.SIZE_EXPAND_FILL;filter.custom_minimum_size.y=34;filter.placeholder_text="Type to filter…"
 filter.add_theme_font_override("font",MenuStyle.sans(600,0.0,18));filter.add_theme_font_size_override("font_size",18)
 for k in ["font_color","caret_color"]:filter.add_theme_color_override(k,FogPalette.BONE)
 filter.add_theme_color_override("font_placeholder_color",FogPalette.ASH_FAINT)
 for k in ["normal","focus","read_only"]:filter.add_theme_stylebox_override(k,StyleBoxEmpty.new())
 filter.text_changed.connect(func(_t):rebuild());bar.add_child(filter)
 tag_box=HBoxContainer.new();tag_box.name="Tags";tag_box.add_theme_constant_override("separation",10);bar.add_child(tag_box)
 var rule=ColorRect.new();rule.color=FogPalette.DIVIDER;rule.custom_minimum_size.y=1;column.add_child(rule)
 scroll=ScrollContainer.new();scroll.name="Scroll";scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll)
 rows=VBoxContainer.new();rows.add_theme_constant_override("separation",0);rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(rows)
 var foot=HBoxContainer.new();foot.name="Footer";var foot_margin=MarginContainer.new();for side in ["left","right"]:foot_margin.add_theme_constant_override("margin_"+side,16)
 foot_margin.add_theme_constant_override("margin_top",10);foot_margin.add_theme_constant_override("margin_bottom",10);foot_margin.add_child(foot);column.add_child(foot_margin)
 footer_left=MenuStyle.label("",MenuStyle.sans(600,0.16,13),13,FogPalette.ASH_FAINT);footer_left.size_flags_horizontal=Control.SIZE_EXPAND_FILL;foot.add_child(footer_left)
 MenuStyle.label("↑↓ MOVE · ENTER PICK",MenuStyle.sans(600,0.16,13),13,FogPalette.ASH_FAINT,0,foot)
 visible=false
func open(list: Array,pick: String,category_tags: Array=[]) -> void:
 options=list;current=pick;tags=category_tags;tag="All";filter.text=""
 for c in tag_box.get_children():tag_box.remove_child(c);c.queue_free()
 tag_buttons.clear()
 for t in tags:
  var b=Button.new();b.name="Tag_"+String(t);b.text=String(t).to_upper();b.flat=true;b.focus_mode=Control.FOCUS_ALL
  b.add_theme_font_override("font",MenuStyle.sans(800,0.2,12));b.add_theme_font_size_override("font_size",12)
  var tname=String(t);b.pressed.connect(func():tag=tname;rebuild());tag_box.add_child(b);tag_buttons[tname]=b
 rebuild();show()
 for c in rows.get_children():
  if c is DropdownOption and c.current:c.grab_focus.call_deferred();return
 if rows.get_child_count()>0:rows.get_child(0).grab_focus.call_deferred()
func close() -> void:
 hide();closed.emit()
func matches(o: Dictionary) -> bool:
 var q=filter.text.strip_edges().to_lower()
 if q!="" and not (String(o.name).to_lower().contains(q) or String(o.get("stats","")).to_lower().contains(q)):return false
 return tag=="All" or String(o.get("tag","All"))==tag
func rebuild() -> void:
 for c in rows.get_children():rows.remove_child(c);c.queue_free()
 var shown=0;var open_count=0
 for o in options:
  if bool(o.get("unlocked",true)):open_count+=1
  if not matches(o):continue
  var row=(MenuStyle.spawn("dropdown_option") as DropdownOption).setup(o,String(o.id)==current);row.pressed.connect(func():_pick(row));rows.add_child(row);shown+=1
 scroll.custom_minimum_size.y=ROW*mini(MAX_ROWS,maxi(1,shown))
 footer_left.text="%d OF %d UNLOCKED%s"%[open_count,options.size()," · SCROLLS" if shown>MAX_ROWS else ""]
 for t in tag_buttons:
  var b: Button=tag_buttons[t];var on=t==tag
  var under=FogTheme.flat(Color(0,0,0,0));under.border_width_bottom=2;under.border_color=FogPalette.RUST_BRIGHT if on else Color(0,0,0,0)
  for k in ["normal","hover","pressed","focus","hover_pressed"]:b.add_theme_stylebox_override(k,under)
  for k in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:b.add_theme_color_override(k,FogPalette.BONE_BRIGHT if on else FogPalette.ASH_FAINT)
func _pick(row: DropdownOption) -> void:
 if not bool(row.info.get("unlocked",true)):
  MenuScreen.sfx("locked");return # locked rows are visible but cannot be picked
 MenuScreen.sfx("weapon_select");picked.emit(String(row.info.id));close()
func _input(event: InputEvent) -> void:
 if not visible:return
 if event.is_action_pressed("ui_cancel"):
  get_viewport().set_input_as_handled();close();return
 # typing while a row has focus goes to the filter ("Type to filter")
 if event is InputEventKey and event.pressed and not event.echo and event.unicode>32 and not filter.has_focus() and is_ancestor_of(get_viewport().gui_get_focus_owner() if get_viewport().gui_get_focus_owner()!=null else self):
  filter.grab_focus();filter.text+=char(event.unicode);filter.caret_column=filter.text.length();rebuild();get_viewport().set_input_as_handled()
class SearchGlass extends Control:
 func _draw() -> void:
  draw_arc(Vector2(7.5,7.5),6.0,0,TAU,24,FogPalette.ASH_DIM,2.0);draw_line(Vector2(12,12),Vector2(17,17),FogPalette.ASH_DIM,2.0)

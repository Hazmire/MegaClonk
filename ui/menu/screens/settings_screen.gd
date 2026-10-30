class_name SettingsScreen
extends FrameScreen
# Settings: the same options and the same effects as before, restyled with the Fog frame. Tabs, section rows, ON/OFF switches,
# sliders, steppers and key-binding buttons. Values are written straight into game.settings / game.bindings and applied at once;
# "Back" (Esc) saves, like the old "Save & back".
const TABS=[{"id":"Display","label":"Display"},{"id":"Graphics","label":"Graphics"},{"id":"Audio","label":"Audio"},{"id":"Gameplay","label":"Gameplay"}]
const RESOLUTIONS=[Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]
const AUDIO_NAMES={"master":"Master volume","music":"Music volume","effects":"Sound effects volume","ui_volume":"UI volume","ambience":"Ambient volume","fps":"Debug: show FPS counter"}
const KEYS={"Graphics":["render_scale","retro_scale","psx_warp","psx_snap","psx_dither","visual_intensity","reduced","numbers","shake","fps"],"Audio":["master","music","effects","ui_volume","ambience"],"Gameplay":["sensitivity","invert","focus_pause"]}
static var last_tab="Display"
var group="Display"
var scroll: ScrollContainer
var list: VBoxContainer
var binding_buttons: Dictionary={}
var quit_button: MenuItem
func _build_backdrop() -> void:
 if frontend!=null and frontend.settings_from_pause() and frozen_backdrop(0.55):return
 super._build_backdrop()
func build() -> void:
 group=last_tab
 build_frame("Settings","Changes apply at once",TABS,group,false,"Back")
 tab_bar.tab_selected.connect(func(id: String):group=id;last_tab=id;fill())
 scroll=ScrollContainer.new();scroll.name="Scroll";scroll.position=Vector2(120,322);scroll.size=Vector2(1300,600);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_SHOW_NEVER;scroll.follow_focus=true;content.add_child(scroll)
 var pad=MarginContainer.new();pad.add_theme_constant_override("margin_top",8);pad.add_theme_constant_override("margin_right",8);pad.add_theme_constant_override("margin_bottom",24);pad.mouse_filter=Control.MOUSE_FILTER_IGNORE;scroll.add_child(pad)
 list=VBoxContainer.new();list.name="Rows";list.custom_minimum_size.x=1280;list.add_theme_constant_override("separation",12);list.mouse_filter=Control.MOUSE_FILTER_IGNORE;pad.add_child(list)
 quit_button=MenuStyle.spawn("menu_item") as MenuItem;quit_button.setup("Quit game",32,32,false,Vector2(56,56));quit_button.position=Vector2(120,MenuStyle.H-32-24-72);quit_button.size=Vector2(420,56);quit_button.chosen.connect(func():game.get_tree().quit());content.add_child(quit_button)
 fill()
 set_hints([["↑ ↓","Option","D-PAD"],["← →","Adjust","D-PAD"],["Q / E","Category"],["ESC","Back"]])
func go_back() -> void:navigate(frontend.leave_settings)
func _process(_delta: float) -> void:
 for key in binding_buttons:
  var want="%s"%OS.get_keycode_string(game.bindings[key]);var b: Button=binding_buttons[key]
  if game.pending_binding==key:want="PRESS A KEY"
  if b.text!=want:b.text=want
func fill() -> void:
 for c in list.get_children():list.remove_child(c);c.queue_free()
 binding_buttons.clear()
 match group:
  "Display":
   var fullscreen=MenuStyle.spawn("on_off_toggle") as OnOffToggle;fullscreen.setup(DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN,true)
   fullscreen.changed.connect(func(on): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED))
   add_row("Fullscreen",fullscreen)
   var names=[];var current=0
   for i in RESOLUTIONS.size():
    names.append("%d × %d"%[RESOLUTIONS[i].x,RESOLUTIONS[i].y])
    if DisplayServer.window_get_size()==RESOLUTIONS[i]:current=i
   var stepper=MenuStyle.spawn("stepper") as Stepper;stepper.setup(names,current);stepper.changed.connect(func(i):DisplayServer.window_set_size(RESOLUTIONS[i]));add_row("Resolution",stepper)
  _:
   for key in KEYS[group]:add_setting(key)
   if group=="Graphics":
    var quality=MenuStyle.spawn("stepper") as Stepper;quality.setup(["Low","Medium","High"],int(game.settings.quality));quality.changed.connect(func(i):game.settings.quality=i;game.apply_settings());add_row("Quality",quality)
   if group=="Gameplay":
    var head=SmallCapsLabel.new().setup("Key bindings",15,FogPalette.ASH_DIM,800,0.3);head.custom_minimum_size.y=44;head.vertical_alignment=VERTICAL_ALIGNMENT_BOTTOM;list.add_child(head)
    for key in game.bindings:
     var button=binding_button(String(key));binding_buttons[key]=button;add_row(String(key).replace("_"," ").capitalize(),button)
 var first=first_focusable(list)
 if first!=null:focus_later(first)
func first_focusable(node: Node) -> Control:
 for c in node.get_children():
  if c is Control and c.focus_mode==Control.FOCUS_ALL:return c
  var deeper=first_focusable(c)
  if deeper!=null:return deeper
 return null
func add_row(label: String,control: Control) -> HBoxContainer:
 var panel=PanelContainer.new();panel.custom_minimum_size.y=64;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var st=FogTheme.flat(Color(0.055,0.059,0.055,0.78),FogPalette.BORDER,1);st.content_margin_left=24;st.content_margin_right=24;panel.add_theme_stylebox_override("panel",st);list.add_child(panel)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",24);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(row)
 var name_label=MenuStyle.label(label,MenuStyle.serif(),28,FogPalette.BONE,0,row);name_label.name="Label";name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_label.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 control.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(control)
 control.focus_entered.connect(func():panel.add_theme_stylebox_override("panel",focused_style()))
 control.focus_exited.connect(func():panel.add_theme_stylebox_override("panel",st))
 return row
func focused_style() -> StyleBoxFlat:
 var st=FogTheme.flat(Color(0.165,0.078,0.086,0.85),FogPalette.RUST_BRIGHT,2);st.content_margin_left=24;st.content_margin_right=24;return st
func add_setting(key: String) -> void:
 var label=AUDIO_NAMES.get(key,key.replace("_"," ").capitalize())
 if game.settings[key] is bool:
  var toggle=MenuStyle.spawn("on_off_toggle") as OnOffToggle;toggle.setup(game.settings[key],true)
  toggle.changed.connect(func(on):game.settings[key]=on;game.apply_settings())
  add_row(label,toggle);return
 var lo=0.0;var hi=1.0;var step=0.05
 match key:
  "sensitivity":lo=0.0005;hi=0.008;step=0.0001
  "render_scale":lo=0.5
  "retro_scale":lo=0.25
 var slider=MenuStyle.slider(lo,hi,step,float(game.settings[key]),480.0)
 var readout=MenuStyle.label(value_text(key,float(game.settings[key])),MenuStyle.sans(800,0.1,18),18,FogPalette.BONE_BRIGHT);readout.custom_minimum_size.x=70;readout.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;readout.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 var pair=HBoxContainer.new();pair.add_theme_constant_override("separation",20);pair.mouse_filter=Control.MOUSE_FILTER_IGNORE;pair.add_child(slider);pair.add_child(readout)
 slider.value_changed.connect(func(value):
  game.settings[key]=value;game.apply_settings();readout.text=value_text(key,value)
  if group=="Audio":game.progress.data.settings=game.settings.duplicate(true);game.progress.save())
 var row=add_row(label,pair)
 slider.focus_entered.connect(func():row.get_parent().add_theme_stylebox_override("panel",focused_style()))
 slider.focus_exited.connect(func():row.get_parent().remove_theme_stylebox_override("panel"))
func value_text(key: String,value: float) -> String:
 if key=="sensitivity":return "%.1f"%(value*1000.0)
 return "%d%%"%roundi(value*100.0)
func binding_button(key: String) -> Button:
 var b=Button.new();b.name="Bind_"+key;b.focus_mode=Control.FOCUS_ALL;b.custom_minimum_size=Vector2(220,44);b.alignment=HORIZONTAL_ALIGNMENT_CENTER
 b.add_theme_font_override("font",MenuStyle.sans(800,0.16,16));b.add_theme_font_size_override("font_size",16)
 for c in ["font_color","font_hover_color","font_focus_color","font_pressed_color"]:b.add_theme_color_override(c,FogPalette.BONE)
 b.add_theme_stylebox_override("normal",FogTheme.flat(Color(0,0,0,0),FogPalette.BORDER_LIGHT,1));b.add_theme_stylebox_override("hover",FogTheme.flat(FogPalette.RUST,FogPalette.RUST_BRIGHT,1))
 b.add_theme_stylebox_override("focus",FogTheme.flat(FogPalette.RUST,FogPalette.RUST_BRIGHT,2));b.add_theme_stylebox_override("pressed",FogTheme.flat(FogPalette.BONE,FogPalette.BONE,1))
 b.add_theme_color_override("font_pressed_color",FogPalette.RUST)
 b.mouse_entered.connect(func():MenuScreen.sfx("hover"))
 b.pressed.connect(func():sfx("confirm");game.pending_binding=key;game.toast("Press a key for "+key))
 return b

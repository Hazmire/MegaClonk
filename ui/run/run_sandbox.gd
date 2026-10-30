class_name RunSandbox
extends MenuScreen
# RunSandbox: the sandbox developer menu (Game.sandbox_menu) in the kit: a scrolling list of tool buttons with the weapon picker and
# map-seed field. Only the presentation changed; each entry runs the same callback the old button did.
var entries: Array=[] # [{label, call}]
var select: OptionButton
var seed_input: LineEdit
var seed_line=""
var list: VBoxContainer
func _init() -> void:
 super._init();backdrop_kind="frozen";allow_back=false
func build() -> void:
 var panel=Panel.new();panel.name="Panel";panel.position=Vector2(572,90);panel.size=Vector2(776,900);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",FogTheme.flat(Color(0.055,0.059,0.055,0.94),FogPalette.BORDER,1));content.add_child(panel)
 var cap=SmallCapsLabel.new().setup("Sandbox · progression isolated",14,Color("A9ADA4"),800,0.3);cap.position=Vector2(612,120);content.add_child(cap)
 var title=MenuStyle.label("Sandbox tools",MenuStyle.serif(),52,FogPalette.BONE,0,content);title.name="Title";title.position=Vector2(612,142)
 var scroll=ScrollContainer.new();scroll.name="Scroll";scroll.position=Vector2(612,230);scroll.size=Vector2(696,690);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;content.add_child(scroll)
 list=VBoxContainer.new();list.add_theme_constant_override("separation",4);list.custom_minimum_size=Vector2(676,0);scroll.add_child(list)
 select=OptionButton.new();select.name="WeaponPicker";select.custom_minimum_size=Vector2(676,44)
 for id in Catalog.ACTIVE_WEAPONS:select.add_item(Catalog.WEAPONS[id][0],id)
 list.add_child(select)
 var first: Control=null
 for e in entries:
  if str(e.label)=="@seed":
   var l=MenuStyle.label(seed_line,MenuStyle.sans(400,0,16),16,Color("8D9188"),0,list);l.name="SeedLine"
   seed_input=LineEdit.new();seed_input.name="SeedInput";seed_input.text=str(e.get("text",""));seed_input.placeholder_text="Map seed";seed_input.custom_minimum_size=Vector2(676,44);list.add_child(seed_input);continue
  var item=MenuStyle.spawn("menu_item") as MenuItem;item.setup(str(e.label),26,26);item.custom_minimum_size=Vector2(676,44);item.size=Vector2(676,44);item.indent=24.0;list.add_child(item)
  var call: Callable=e.call;item.chosen.connect(func():call.call())
  if first==null:first=item
 set_hints([["↑↓","Move","D-PAD"],["ENTER","Select","A"],["ESC","Resume","B"]]);focus_later(first if first!=null else select)

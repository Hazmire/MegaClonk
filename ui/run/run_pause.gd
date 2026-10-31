class_name RunPause
extends MenuScreen
# RunPause: the frozen, blurred gameplay frame with the Inventory panel on the left, the Stats panel on the right and the
# pause menu between them. Figures come from RunData / the game; nothing here changes gameplay. Esc resumes through Game's own
# handler, so this screen does not take Esc itself.
var items: Dictionary={}
var order: Array=[]
var abandon: AbandonButton
var counters: Dictionary={}
var inventory_panel: InventoryPanel
var stats_panel: StatsPanel
func _init() -> void:
 super._init();backdrop_kind="frozen";allow_back=false
func build() -> void:
 inventory_panel=InventoryPanel.new().setup(game);inventory_panel.name="Inventory";inventory_panel.position=Vector2(60,105);content.add_child(inventory_panel)
 stats_panel=StatsPanel.new().setup(game);stats_panel.name="Stats";stats_panel.position=Vector2(MenuStyle.W-60-420,105);content.add_child(stats_panel)
 var title=MenuStyle.label("Paused",MenuStyle.serif(),104,FogPalette.BONE,4,content);title.name="Title"
 title.position=Vector2(480,96);title.size=Vector2(960,130);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var stage_line=SmallCapsLabel.new().setup("Stage %d — %s"%[game.stage,StageThemes.config(game.stage).title],20,Color("A9ADA4"),600,0.3);stage_line.name="StageLine"
 stage_line.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;stage_line.position=Vector2(480,238);stage_line.size=Vector2(960,28);content.add_child(stage_line)
 build_counters()
 var nav=VBoxContainer.new();nav.name="Nav";nav.position=Vector2(700,424);nav.size=Vector2(520,420);nav.add_theme_constant_override("separation",4);nav.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(nav)
 var entries=[["resume","Resume","ESC",game.resume],["map","Map","M",func():frontend.world_map(true)],["inspect","Inspect build","TAB",game.show_build],["settings","Settings","",func():game.settings_menu(game.pause_menu)],["save","Save & quit","",save_and_quit]]
 if game.sandbox:entries.append(["sandbox","Sandbox tools","",game.sandbox_menu])
 entries.append(["restart","Restart run","",game.begin_run])
 for e in entries:
  var item=MenuStyle.spawn("menu_item") as MenuItem;item.setup(e[1],34,40,false,Vector2(54,62));item.hint_text=e[2];item.indent=40.0;item.cursor_x=14.0;nav.add_child(item);items[e[0]]=item;order.append(item)
  var target: Callable=e[3];item.chosen.connect(func():target.call())
 var rule=Control.new();rule.name="AbandonRule";rule.custom_minimum_size=Vector2(520,22);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE
 rule.draw.connect(func():
  var x=0.0
  while x<rule.size.x:rule.draw_line(Vector2(x,11),Vector2(minf(x+8.0,rule.size.x),11),FogPalette.BORDER,1.0);x+=16.0)
 nav.add_child(rule)
 abandon=AbandonButton.new();nav.add_child(abandon);abandon.confirmed.connect(func():game.finish_run(false))
 order.append(abandon);items["abandon"]=abandon
 set_hints([["↑↓","Navigate"],["ENTER","Select"],["ESC","Resume"]])
 focus_later(items["resume"])
func build_counters() -> void:
 var strip=HBoxContainer.new();strip.name="Counters";strip.position=Vector2(560,296);strip.size=Vector2(800,92);strip.add_theme_constant_override("separation",0);strip.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(strip)
 var data=counter_values(game)
 for i in data.size():
  if i>0:
   var div=ColorRect.new();div.color=FogPalette.DIVIDER;div.custom_minimum_size=Vector2(1,64);div.size_flags_vertical=Control.SIZE_SHRINK_CENTER;div.mouse_filter=Control.MOUSE_FILTER_IGNORE;strip.add_child(div)
  var cell=VBoxContainer.new();cell.custom_minimum_size=Vector2(199,0);cell.add_theme_constant_override("separation",2);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;strip.add_child(cell)
  var cap=SmallCapsLabel.new().setup(data[i][0],14,FogPalette.ASH_DIM,800,0.28);cap.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cell.add_child(cap)
  var value=HudNumber.new().setup(data[i][1],48,FogPalette.BONE_BRIGHT,3);cell.add_child(value);value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;counters[data[i][0].to_lower()]=value
# The four header counters as [caption, text]; also what tests compare against the game.
static func counter_values(game_node: Node) -> Array:
 var t=int(game_node.elapsed)
 return [["Level",str(game_node.level)],["Time","%02d:%02d"%[t/60,t%60]],["Kills",str(game_node.kills)],["Gold",str(game_node.gold)]]
# "Save & quit" replaces the old "Save run": the checkpoint is written and the run is left for the main menu, where "Resume saved run" picks it up.
func save_and_quit() -> void:
 if game.save_run():game.build_menu_world();game.main_menu()
 else:game.toast("Save failed")

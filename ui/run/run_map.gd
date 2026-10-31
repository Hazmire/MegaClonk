class_name RunMap
extends RunPanelScreen
# RunMap: the full world map between the Inventory and Stats panels. It is the same RunMinimap the HUD uses (same explored cells, same
# markers) drawn large in the Fog palette, with a legend built from the map's own palette so it can never disagree with what is drawn.
var from_pause=false
var map: RunMinimap
var back: MenuItem
const LEGEND=[["chest","Chest"],["shop","Shop"],["heal","Healing"],["other","Shrine"],["imbue","Imbue station"],["elite","Elite"],["boss","Boss statue"],["portal","Portal"],["free","Free reward chest"],["player","You"],["enemy","Enemies"]]
func build() -> void:
 build_panels();build_status();build_section()
 var head=Control.new();head.name="Header";head.position=Vector2(572,182);head.size=Vector2(776,100);head.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(head)
 head.add_child(SmallCapsLabel.new().setup("World map",14,Color("A9ADA4"),800,0.3))
 var title=MenuStyle.label("Stage %d — %s"%[game.stage,StageThemes.config(game.stage).title],MenuStyle.serif(),46,FogPalette.BONE,0,head);title.name="Title";title.position=Vector2(0,22)
 var rule=ColorRect.new();rule.color=FogPalette.RUST;rule.position=Vector2(0,84);rule.size=Vector2(48,5);rule.mouse_filter=Control.MOUSE_FILTER_IGNORE;head.add_child(rule)
 map=RunMinimap.new();map.name="Map";map.game=game;map.paper_style=true;map.reveal_all=frontend.minimap.reveal_all;map.explored=frontend.minimap.explored;map.terrain_colors=frontend.minimap.terrain_colors
 map.position=Vector2(572,296);map.size=Vector2(776,560);map.custom_minimum_size=map.size;content.add_child(map)
 var legend=GridContainer.new();legend.name="Legend";legend.columns=3;legend.position=Vector2(572,870);legend.add_theme_constant_override("h_separation",28);legend.add_theme_constant_override("v_separation",6);legend.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(legend)
 for e in LEGEND:
  var cell=HBoxContainer.new();cell.add_theme_constant_override("separation",8);cell.custom_minimum_size=Vector2(240,22);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;legend.add_child(cell)
  var sw=ColorRect.new();sw.color=map.palette(str(e[0]));sw.custom_minimum_size=Vector2(12,12);sw.size_flags_vertical=Control.SIZE_SHRINK_CENTER;sw.mouse_filter=Control.MOUSE_FILTER_IGNORE;cell.add_child(sw)
  MenuStyle.label(str(e[1]),MenuStyle.sans(400,0,15),15,Color("B9BAB1"),0,cell)
 back=MenuStyle.spawn("menu_item") as MenuItem;back.name="Back";back.setup("Back" if from_pause else "Resume",30,30).make_primary("M",60,30);back.size=Vector2(220,48);back.position=Vector2(1128,966);back.indent=52.0
 back.chosen.connect(func():if from_pause:game.pause_menu() else:game.resume());content.add_child(back)
 set_hints([["M","Close","Y"],["ESC","Back","B"]]);focus_later(back)

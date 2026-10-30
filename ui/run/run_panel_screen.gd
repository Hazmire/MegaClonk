class_name RunPanelScreen
extends MenuScreen
# Shared frame of the in-run screens that sit over the frozen world with the Inventory panel on the left, the Stats panel on the
# right and a 856x870 section between them (Level up, Shop, Shrine, Imbue): the status strip, the panels and the section panel.
var inventory_panel: InventoryPanel
var stats_panel: StatsPanel
func _init() -> void:
 super._init();backdrop_kind="frozen";allow_back=false
func build_panels() -> void:
 inventory_panel=InventoryPanel.new().setup(game);inventory_panel.name="Inventory";inventory_panel.position=Vector2(72,150);content.add_child(inventory_panel)
 stats_panel=StatsPanel.new().setup(game);stats_panel.name="Stats";stats_panel.position=Vector2(1428,150);content.add_child(stats_panel)
func build_section() -> Panel:
 var section=Panel.new();section.name="Section";section.position=Vector2(532,150);section.size=Vector2(856,870);section.mouse_filter=Control.MOUSE_FILTER_IGNORE
 section.add_theme_stylebox_override("panel",FogTheme.flat(Color(0.055,0.059,0.055,0.94),FogPalette.BORDER,1));content.add_child(section);return section
func build_status() -> void:
 var row=HBoxContainer.new();row.name="Status";row.position=Vector2(72,36);row.add_theme_constant_override("separation",48);row.mouse_filter=Control.MOUSE_FILTER_IGNORE;content.add_child(row)
 var t=int(game.elapsed)
 for pair in [["LVL",str(game.level),FogPalette.GOLD],["STAGE",str(game.stage),FogPalette.BONE_BRIGHT]]:
  var cell=VBoxContainer.new();cell.add_theme_constant_override("separation",2);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(cell)
  MenuStyle.label(pair[0],MenuStyle.sans(600,0.3,13),13,Color("A9ADA4"),0,cell);cell.add_child(HudNumber.new().setup(pair[1],32,pair[2],3))
 var hp=VBoxContainer.new();hp.add_theme_constant_override("separation",6);hp.custom_minimum_size=Vector2(240,0);hp.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(hp)
 MenuStyle.label("HP",MenuStyle.sans(600,0.3,13),13,Color("A9ADA4"),0,hp)
 var bar=Control.new();bar.name="Hp";bar.custom_minimum_size=Vector2(240,24);bar.mouse_filter=Control.MOUSE_FILTER_IGNORE;hp.add_child(bar)
 var frac=clampf(float(game.health)/maxf(1.0,float(game.stats.max_health)),0.0,1.0)
 bar.draw.connect(func():
  bar.draw_rect(Rect2(Vector2.ZERO,bar.size),Color("2A1416"));bar.draw_rect(Rect2(Vector2(2,2),Vector2((bar.size.x-4.0)*frac,bar.size.y-4.0)),FogPalette.RUST);bar.draw_rect(Rect2(Vector2.ZERO,bar.size).grow(-1.0),Color("050505"),false,2.0))
 var hpl=MenuStyle.label("%d / %d"%[roundi(game.health),roundi(game.stats.max_health)],MenuStyle.sans(800,0,14),14,FogPalette.BONE_BRIGHT,0,bar);hpl.position=Vector2(8,2)
 for pair in [["GOLD",str(game.gold)],["TIME","%02d:%02d"%[t/60,t%60]]]:
  var cell=VBoxContainer.new();cell.add_theme_constant_override("separation",2);cell.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(cell)
  MenuStyle.label(pair[0],MenuStyle.sans(600,0.3,13),13,Color("A9ADA4"),0,cell);cell.add_child(HudNumber.new().setup(pair[1],32,FogPalette.BONE_BRIGHT,3))

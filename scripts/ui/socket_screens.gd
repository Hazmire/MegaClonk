class_name SocketScreens
extends RefCounted

# Imbue Station screen, shop gem offers, gem inventory panel and socket helpers for the build UI.
static func tooltip(state: Dictionary) -> String:
 var gems=WeaponSockets.gems(state);var lines=["Sockets %d/%d"%[gems.size(),WeaponSockets.unlocked(state)]]
 for g in gems:lines.append("• %s — %s"%[Elements.display_name(str(g)),Elements.summary(str(g))])
 var combo=WeaponSockets.combo(state)
 if not combo.is_empty():lines.append("Combination: %s"%combo.name)
 return "\n".join(lines)
static func add_pips(tile: Control,state: Dictionary) -> void:
 if tile.get_child_count()==0:return
 var body=tile.get_child(0)
 var pips=SocketPips.new().setup(state);body.add_child(pips)
static func gem_inventory(ui: FrontEnd,parent: Node) -> void:
 ui.heading("Socket gems",parent,20)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
 for element in Elements.IDS:
  var cell=PanelContainer.new();cell.custom_minimum_size=Vector2(60,46);cell.add_theme_stylebox_override("panel",RewardScreens.style(Elements.color(element),Color("152321")))
  cell.tooltip_text="%s gem — %s"%[Elements.display_name(element),Elements.summary(element)];row.add_child(cell)
  var label=ui.text("◆ %d"%ui.game.gems.count(element),cell,16);label.add_theme_color_override("font_color",Elements.color(element) if ui.game.gems.count(element)>0 else Color("6e7875"));label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
static func imbue_station(ui: FrontEnd,object: Dictionary) -> void:
 var game=ui.game
 if game.mode=="run":ui.capture_pause_frame()
 game.mode="imbue";ui.shop_object=object;ui.clear()
 var screen=RunImbue.new();screen.object=object;MenuScreen.set_audio_owner(game);screen.bind(ui);ui.menu.add_child(screen)

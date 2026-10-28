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
 var game=ui.game;game.mode="imbue";ui.shop_object=object
 var cost=ImbueRules.cost(game.stage)
 var center=RewardScreens.layout(ui,"Imbue Station · %d gold per gem"%cost)
 ui.paragraph("Fuse an elemental gem into a weapon socket. Installing is permanent, costs %d gold and consumes one gem."%cost,center,520)
 gem_inventory(ui,center)
 var amulet_row=HBoxContainer.new();amulet_row.add_theme_constant_override("separation",8);center.add_child(amulet_row)
 ui.text("Imbued Amulets: %d"%game.amulets,amulet_row,16).add_theme_color_override("font_color",Color("ffcf65"))
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(560,300);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;center.add_child(scroll)
 var list=VBoxContainer.new();list.add_theme_constant_override("separation",8);list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
 for id in game.weapons:
  var state: Dictionary=game.weapons[id]
  var head=HBoxContainer.new();head.add_theme_constant_override("separation",10);list.add_child(head)
  ui.heading("%s · Lv %d"%[Catalog.WEAPONS[id][0],state.level],head,18)
  head.add_child(SocketPips.new().setup(state))
  var detail=ui.text(tooltip(state).replace("\n","  "),list,13);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  if WeaponSockets.can_unlock_second(state):
   var amulet=RewardScreens.button(ui,list,"Use Imbued Amulet · unlock 2nd socket",func():
    var used=GemRewards.use_amulet(game,int(id))
    if used.ok:game.play_sound("imbue.install");game.toast("%s gained a second socket"%Catalog.WEAPONS[id][0])
    else:game.toast(ImbueRules.reason_text(str(used.reason)))
    ui.reward_consumed=false;imbue_station(ui,object),Color("8a6a1f"))
   amulet.custom_minimum_size=Vector2(360,36);amulet.disabled=game.amulets<1
   amulet.tooltip_text="Permanently adds a second socket to this weapon. Two different elements form a combination."
  var buttons=HBoxContainer.new();buttons.add_theme_constant_override("separation",6);list.add_child(buttons)
  for element in Elements.IDS:
   var reason=ImbueRules.problem(game,int(id),element)
   var label="%s ×%d"%[Elements.display_name(element),game.gems.count(element)]
   var button=RewardScreens.button(ui,buttons,label,func():
    var result=ImbueRules.install(game,int(id),element)
    if result.ok:
     game.play_sound("imbue.install");game.toast("%s imbued with %s"%[Catalog.WEAPONS[id][0],Elements.display_name(element)])
    else:game.toast(ImbueRules.reason_text(str(result.reason)))
    ui.reward_consumed=false;imbue_station(ui,object),Elements.color(element).darkened(0.45))
   button.custom_minimum_size=Vector2(128,38);button.disabled=reason!=""
   var tip="%s\n%s"%[Elements.display_name(element),Elements.summary(element)]
   var gems=WeaponSockets.gems(state)
   if gems.size()==1 and WeaponSockets.unlocked(state)>=2 and gems[0]!=element:
    var combo=Elements.combo(str(gems[0]),element)
    if not combo.is_empty():tip+="\nForms combination: %s"%combo.name
   if reason!="":tip+="\n✗ "+ImbueRules.reason_text(reason)
   button.tooltip_text=tip
 if game.weapons.is_empty():ui.text("You have no weapons.",list,16)
 RewardScreens.button(ui,center,"LEAVE",game.resume).grab_focus()

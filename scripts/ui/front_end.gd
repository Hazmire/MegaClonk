class_name FrontEnd
extends CanvasLayer
var game: Node
var root: Control
var menu: Control
var hud_root: Control
var stopwatch_overlay: StopwatchOverlay
var loadout_label: Label
var gold_label: Label
var boss_panel: VBoxContainer
var boss_fingerprint=""
var boss_widgets: Array=[]
var ultimate_badge: Label
var xp_label: Label
var event_label: Label
var timer_label: Label
var status_label: Label
var minimap: RunMinimap
var menu_camera: Camera3D
var preview_mode="home"
var orbit=0.0
var menu_shop: Node3D
var menu_focus=Vector3.ZERO
var menu_player_position=Vector3.ZERO
var menu_world_instance=0
var map_tick=0.0
var settings_back: Callable
var in_run=false
const HEALTH_COLOR=Color("801421")
var health_text: Label
var character_health: ProgressBar
var loadout_icons: VBoxContainer
var icon_fingerprint=""
var active_tab="weapons"
var shop_object: Dictionary={}
var shop_offers: Array=[]
var headline_font: Font
var card_gold=Color("d8b575")
var reward_generation=0
var reward_consumed=false
var reward_focus: Dictionary={}
var reward_tweens: Array=[]
var map_return_to_pause=false
var stage_banner: Control
var quest_definitions: Array=[]
var quest_tracker: Label
var chest_skip: Callable

func setup(owner_game: Node) -> void:
 process_mode=Node.PROCESS_MODE_ALWAYS
 game=owner_game
 quest_definitions=LoadoutCatalog.quests()
 layer=2
 root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(root)
 var theme=Theme.new();theme.default_font_size=18;theme.default_font=load("res://assets/fonts/Kurland.ttf")
 for state in ["normal","hover","pressed","focus"]:
  var style=StyleBoxFlat.new();style.bg_color=Color("172a30") if state=="normal" else Color("29464b")
  style.border_color=Color("5b7775") if state=="normal" else card_gold
  style.set_border_width_all(1);style.set_corner_radius_all(5)
  style.content_margin_left=14;style.content_margin_right=14;style.content_margin_top=10;style.content_margin_bottom=10
  theme.set_stylebox(state,"Button",style)
 var track=StyleBoxFlat.new();track.bg_color=Color("263c40");track.border_color=Color("425c5b");track.set_border_width_all(1)
 var bar_fill=StyleBoxFlat.new();bar_fill.bg_color=card_gold
 theme.set_stylebox("background","ProgressBar",track);theme.set_stylebox("fill","ProgressBar",bar_fill)
 theme.set_color("font_color","Label",Color("f0e8d4"))
 root.theme=theme
 headline_font=load("res://assets/fonts/Kurland.ttf") if ResourceLoader.exists("res://assets/fonts/Kurland.ttf") else load("res://assets/fonts/PixelatedElegance.ttf")
 menu=Control.new();menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(menu)
 hud_root=Control.new();hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud_root.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(hud_root)
 stopwatch_overlay=StopwatchOverlay.new();stopwatch_overlay.setup(root,hud_root);hud_root.add_child(stopwatch_overlay)
 game.ui=self
 game.hud=text("",hud_root,18);game.hud.hide()
 game.health_bar=ProgressBar.new();game.health_bar.position=Vector2(28,220);game.health_bar.size=Vector2(270,22);game.health_bar.show_percentage=false;hud_root.add_child(game.health_bar)
 game.xp_bar=ProgressBar.new();game.xp_bar.position=Vector2(0,698);game.xp_bar.size=Vector2(1280,22);game.xp_bar.show_percentage=false;hud_root.add_child(game.xp_bar)
 for pair in [[game.health_bar,HEALTH_COLOR],[game.xp_bar,Color("75cdb2")]]:
  var fill=StyleBoxFlat.new();fill.bg_color=pair[1];pair[0].add_theme_stylebox_override("fill",fill)
 var hp_background=StyleBoxFlat.new();hp_background.bg_color=Color("26090f");hp_background.border_color=Color("13070a");hp_background.set_border_width_all(1);game.health_bar.add_theme_stylebox_override("background",hp_background)
 health_text=Label.new();health_text.name="HealthValue";health_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);health_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;health_text.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;health_text.add_theme_font_size_override("font_size",15);health_text.mouse_filter=Control.MOUSE_FILTER_IGNORE;game.health_bar.add_child(health_text)
 character_health=ProgressBar.new();character_health.name="CharacterHealth";character_health.size=Vector2(64,7);character_health.show_percentage=false;character_health.mouse_filter=Control.MOUSE_FILTER_IGNORE;character_health.add_theme_stylebox_override("background",hp_background.duplicate());var hp_fill=StyleBoxFlat.new();hp_fill.bg_color=HEALTH_COLOR;character_health.add_theme_stylebox_override("fill",hp_fill);character_health.add_theme_font_size_override("font_size",1);character_health.size=Vector2(64,7);hud_root.add_child(character_health)
 xp_label=text("",hud_root,14);xp_label.position=Vector2(450,698);xp_label.custom_minimum_size.x=380;xp_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 loadout_label=text("",hud_root,14);loadout_label.position=Vector2(28,14)
 loadout_icons=VBoxContainer.new();loadout_icons.position=Vector2(28,38);loadout_icons.add_theme_constant_override("separation",5);hud_root.add_child(loadout_icons)
 gold_label=text("",hud_root,20);gold_label.position=Vector2(1010,25)
 timer_label=text("",hud_root,30);timer_label.position=Vector2(525,24);timer_label.custom_minimum_size.x=230;timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 event_label=text("",hud_root,16);event_label.position=Vector2(380,62);event_label.custom_minimum_size.x=520;event_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 boss_panel=VBoxContainer.new();boss_panel.position=Vector2(415,95);boss_panel.custom_minimum_size.x=450;hud_root.add_child(boss_panel)
 status_label=text("",hud_root,16);status_label.position=Vector2(28,252)
 quest_tracker=text("",hud_root,13);quest_tracker.position=Vector2(28,375);quest_tracker.custom_minimum_size=Vector2(270,0);quest_tracker.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 minimap=RunMinimap.new();minimap.game=game;minimap.position=Vector2(1040,450);minimap.size=Vector2(210,210);hud_root.add_child(minimap)
 var legend=text("YOU • PORTAL • TREASURE",hud_root,12);legend.position=Vector2(1040,670)
 game.notice=text("",root,18);game.notice.position=Vector2(350,646);game.notice.custom_minimum_size.x=590;game.notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 hud_root.hide()
func text(value: String, parent: Node, size_value: int = 18) -> Label:
 var label=Label.new();label.text=value;label.add_theme_font_size_override("font_size",size_value);parent.add_child(label);return label
func heading(value: String, parent: Node, size_value: int = 28) -> Label:
 var label=text(value,parent,size_value);label.add_theme_font_override("font",headline_font);return label
func action(value: String, parent: Node, callback: Callable) -> Button:
 var button=Button.new();button.text=value;button.custom_minimum_size.y=42;parent.add_child(button)
 button.mouse_entered.connect(func():game.play_sound("ui.hover"))
 button.pressed.connect(func(): game.play_sound("ui.confirm");callback.call())
 return button
func card(parent: Node, pos: Vector2, dimensions: Vector2) -> VBoxContainer:
 var panel=PanelContainer.new();panel.position=pos;panel.size=dimensions;panel.custom_minimum_size=dimensions
 var style=StyleBoxFlat.new();style.bg_color=Color(0.045,0.085,0.10,0.95);style.border_color=Color("49645f");style.set_border_width_all(1);style.set_corner_radius_all(8)
 style.content_margin_left=20;style.content_margin_right=20;style.content_margin_top=18;style.content_margin_bottom=18
 panel.add_theme_stylebox_override("panel",style);parent.add_child(panel)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll)
 var column=VBoxContainer.new();column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;column.add_theme_constant_override("separation",10);scroll.add_child(column)
 game.panel=panel
 return column
func stop_reward_animations() -> void:
 if is_instance_valid(game.audio):game.audio.stop_event("reward.chest.tick")
 for tween in reward_tweens:
  if tween!=null and tween.is_valid():tween.kill()
 reward_tweens.clear()
func _exit_tree() -> void:
 stop_reward_animations()
func clear() -> void:
 if is_instance_valid(game.audio):game.audio.emit("ui.open")
 if is_instance_valid(stage_banner):stage_banner.hide()
 fade_celebrations();chest_skip=Callable()
 stop_reward_animations()
 reward_generation+=1;reward_consumed=false
 if is_instance_valid(game.notice):game.notice.text=""
 for child in menu.get_children():menu.remove_child(child);child.queue_free()
 menu.show();hud_root.hide();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 if is_instance_valid(game.player):game.player.active=false
func page(label: String) -> VBoxContainer:
 clear()
 var column=card(menu,Vector2(32,26),Vector2(1216,640))
 var row=HBoxContainer.new();column.add_child(row)
 heading(label,row)
 var spacer=Control.new();spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(spacer)
 if game.mode!="upgrade":action("Resume" if in_run and game.mode!="results" else "Home",row,game.resume if in_run and game.mode!="results" else home)
 return column
func paragraph(value: String, parent: Node, width: float = 500) -> Label:
 var label=text(value,parent,16);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.custom_minimum_size.x=width;return label
func icon_row(parent: Node, category: String, id: String, label: String, golden: bool = false, grey: bool = false) -> HBoxContainer:
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",12);parent.add_child(row)
 var slot=Control.new();slot.custom_minimum_size=Vector2(48,48);row.add_child(slot)
 var image=TextureRect.new();image.texture=UIAssets.icon(category,id);image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);slot.add_child(image)
 if grey:image.modulate=Color(0.3,0.3,0.3,0.8)
 if golden and category!="traits":
  var border=ColorRect.new();border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);border.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var material=ShaderMaterial.new();material.shader=preload("res://shaders/gold_frame.gdshader");border.material=material;slot.add_child(border)
 paragraph(label,row,260)
 return row
func prepare_backdrop() -> void:
 game.mode="menu"
 if not is_instance_valid(game.player) or not is_instance_valid(game.enemy_view):
  game.variants.initialize(0);game.biome=0;game.run_seed=12;game.build_stage()
 if not is_instance_valid(menu_camera) or menu_camera.get_parent()!=game.world:
  menu_camera=Camera3D.new();game.world.add_child(menu_camera)
 if menu_world_instance!=game.world.get_instance_id() or not is_instance_valid(menu_shop) or not menu_shop.is_inside_tree():
  # The protected spawn clearing keeps the close camera away from cliffs/trees.
  # This is the native shop visual, not an interactive merchant added to the run.
  menu_shop=Node3D.new();menu_shop.name="MenuShopBackdrop";game.world.add_child(menu_shop)
  menu_shop.position=game.map_layout.spawn
  GrimdarkObjects.populate(menu_shop,"Shop",game.stage)
  menu_world_instance=game.world.get_instance_id();orbit=0.0
  var forward=menu_shop.basis.z.normalized()
  menu_player_position=menu_shop.position+forward*3.2
  menu_player_position.y=game.terrain_height(menu_player_position.x,menu_player_position.z)+.1
  menu_focus=menu_player_position+Vector3.UP*1.1
 menu_camera.current=true
 game.player.active=false;game.player.position=menu_player_position
 game.player.avatar.rotation.y=atan2(menu_shop.basis.z.x,menu_shop.basis.z.z)
 game.player.avatar.set_damage_flash(false);game.player.avatar.animate("idle",0,.1)
 game.enemy_view.hide();game.player.avatar.show()
 game.notice.text="";game.message_time=0
 if is_instance_valid(game.audio):game.audio.music_menu()
 update_menu_camera(0)
func update_menu_camera(delta: float) -> void:
 if not is_instance_valid(menu_camera) or not is_instance_valid(menu_shop):return
 orbit+=delta*.12
 # A bounded arc keeps the shop behind the adventurer and avoids terrain clipping.
 var yaw=atan2(menu_shop.basis.z.x,menu_shop.basis.z.z)+sin(orbit)*.22
 var radius=7.0 if preview_mode=="home" else 5.7
 menu_camera.position=menu_focus+Vector3(sin(yaw)*radius,1.65,cos(yaw)*radius)
 menu_camera.h_offset=-3.1 if preview_mode=="home" else -1.3
 menu_camera.fov=55;menu_camera.look_at(menu_focus)
func home() -> void:
 in_run=false;game.mode="menu";preview_mode="home";prepare_backdrop();clear()
 if is_instance_valid(game.audio):game.audio.music_menu()
 var title=text("MEGACLONK",menu,54);title.add_theme_font_override("font",headline_font);title.position=Vector2(390,135);title.custom_minimum_size.x=500;title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var buttons=card(menu,Vector2(490,270),Vector2(300,295))
 action("PLAY",buttons,play_screen).grab_focus();action("UNLOCKS",buttons,unlocks);action("QUESTS",buttons,quests);action("SETTINGS",buttons,func(): settings(home))
 var closest=card(menu,Vector2(24,28),Vector2(310,410));heading("Within reach",closest,19)
 var pending=[]
 for q in quest_definitions:
  if MetaProgress.quest_state(game.progress.data,q)=="active":pending.append({"quest":q,"ratio":minf(1,MetaProgress.quest_value(game.progress.data,q.metric)/q.target)})
 pending.sort_custom(func(a,b):return a.ratio>b.ratio)
 for i in mini(4,pending.size()):
  var q=pending[i].quest;paragraph(q.name,closest,260)
  paragraph(quest_description(q),closest,260)
  var bar=ProgressBar.new();bar.max_value=q.target;bar.value=MetaProgress.quest_value(game.progress.data,q.metric);bar.custom_minimum_size.y=10;bar.show_percentage=false;closest.add_child(bar)
 var currency=text(wallet(),menu,18);currency.position=Vector2(880,30)
func wallet() -> String:
 return "SILVER %d"%game.progress.data.silver
func play_screen() -> void:
 game.mode="play";preview_mode="play";prepare_backdrop();game.mode="play";clear()
 var left=card(menu,Vector2(28,25),Vector2(460,645));left.add_theme_constant_override("separation",6);heading("Prepare your run",left,23)
 text("ONE ADVENTURER • ONE LOADOUT",left,14)
 for category in ["weapons","traits","ultimates"]:
  heading(category.capitalize(),left,18)
  var select=OptionButton.new();select.custom_minimum_size.y=40
  var ids=[]
  for e in LoadoutCatalog.entries(category):
   if MetaProgress.unlocked(game.progress.data,category,e.id):
    ids.append(e.id);select.add_item(e.name)
  var selected=str(game.selected_weapon) if category=="weapons" else (game.selected_trait if category=="traits" else game.selected_ultimate)
  select.selected=maxi(0,ids.find(selected));left.add_child(select)
  var entry=LoadoutCatalog.entry(category,selected)
  if not entry.is_empty():icon_row(left,category,selected,entry.description,category!="weapons")
  select.item_selected.connect(func(index):
   if category=="weapons":game.selected_weapon=int(ids[index])
   elif category=="traits":game.selected_trait=ids[index]
   else:game.selected_ultimate=ids[index]
   game.progress.data.loadout={"weapon":game.selected_weapon,"trait":game.selected_trait,"ultimate":game.selected_ultimate};game.progress.save();play_screen())
 heading("Destination",left,18);text("THE VERDANT HOLLOW • Forest",left,16)
 action("ENTER THE HOLLOW",left,func():game.selected_biome=0;game.selected_tier=1;game.sandbox=false;game.begin_run())
 if FileAccess.file_exists("user://active-run.json"):
  action("Resume saved run",left,func():
   if not game.load_run():game.toast("Saved run could not be read"))
 action("Back",left,home)
 var right=card(menu,Vector2(990,25),Vector2(264,535));heading("Personal bests",right,19)
 if game.progress.data.leaderboard.is_empty():paragraph("Your greatest runs will be recorded here.",right,214)
 for i in mini(5,game.progress.data.leaderboard.size()):
  var record=game.progress.data.leaderboard[i]
  paragraph("#%d • %d kills • %02d:%02d\n%s\n%s / %s"%[i+1,record.kills,int(record.time)/60,int(record.time)%60,Catalog.WEAPONS[int(record.weapon)][0],LoadoutCatalog.entry("traits",str(record.trait)).get("name",record.trait),LoadoutCatalog.entry("ultimates",str(record.ultimate)).get("name",record.ultimate)],right,210)
func unlocks() -> void:
 game.mode="unlocks";preview_mode="home"
 var col=page("Unlocks & collection");paragraph(wallet(),col,800)
 var tabs=HBoxContainer.new();col.add_child(tabs)
 for category in ["weapons","tomes","traits","items","ultimates"]:
  action(category.capitalize(),tabs,func():active_tab=category;unlocks())
 var body=HBoxContainer.new();col.add_child(body)
 var grid=GridContainer.new();grid.columns=5;body.add_child(grid)
 var detail=VBoxContainer.new();detail.custom_minimum_size.x=390;body.add_child(detail)
 paragraph("Select an entry to inspect it. Enabled entries may appear during runs. Starting weapons ignore this toggle.",detail,370)
 for e in LoadoutCatalog.entries(active_tab):
  var open=MetaProgress.unlocked(game.progress.data,active_tab,e.id)
  var button=Button.new();button.custom_minimum_size=Vector2(130,86);button.clip_text=true;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP;button.add_theme_font_size_override("font_size",14);button.tooltip_text=e.name;button.text=(e.name.trim_suffix(" Tome")+"\nTome" if active_tab=="tomes" else e.name)+("\nON" if MetaProgress.enabled(game.progress.data,active_tab,e.id) else ("\nOFF" if open else "\nLOCKED"));button.icon=UIAssets.icon(active_tab,e.id);button.expand_icon=true;button.add_theme_constant_override("icon_max_width",40 if active_tab=="tomes" else 30)
  if active_tab=="tomes":button.custom_minimum_size.y=108
  grid.add_child(button)
  if not open:button.modulate=Color("82908b")
  button.pressed.connect(func():
   for child in detail.get_children():detail.remove_child(child);child.queue_free()
   heading(e.name,detail,22)
   if open:
    paragraph(e.description,detail,370)
    if active_tab in ["traits","ultimates"]:paragraph("Always available for loadout selection.",detail,370)
    else:action("Disable from runs" if MetaProgress.enabled(game.progress.data,active_tab,e.id) else "Enable in runs",detail,func():MetaProgress.toggle(game.progress.data,active_tab,e.id);game.progress.save();unlocks())
   else:
    # Locked entries reveal their requirement, never their effect text.
    var requirement="Unlock: %d silver"%e.cost if active_tab=="weapons" else "Unlock: %d lifetime kills"%e.goal
    if active_tab=="tomes":requirement="Unlock: %d lifetime kills and %d silver"%[e.goal,e.cost]
    paragraph(requirement,detail,370)
    if active_tab in ["weapons","tomes"]:
     action("Unlock for %d silver"%e.cost,detail,func():
      if MetaProgress.purchase(game.progress.data,active_tab,e.id):game.progress.save();unlocks()
      else:game.toast("Meet the kill milestone and silver cost"))
   )
 heading("Account upgrades",col,21)
 for kind in ["weapon","tome"]:
  var slots=int(game.progress.data[kind+"_slots"])
  var required=2 if slots==2 else 4
  action("%s slots: %d/4  •  %s"%[kind.capitalize(),slots,"MAXIMUM" if slots>=4 else "%d silver"%MetaProgress.slot_cost(game.progress.data,kind)],col,func():
   if MetaProgress.buy_slot(game.progress.data,kind):game.progress.save();unlocks()
   else:game.toast("Complete quests and claim silver rewards"))
func quest_description(q: Dictionary) -> String:
 if q.metric.begins_with("weapon:"):return "%d kills using %s"%[q.target,Catalog.WEAPONS[int(q.metric.get_slice(":",1))][0]]
 match q.metric:
  "kills":return "Defeat %d enemies"%q.target
  "survival":return "Survive %d seconds in one run"%q.target
  "fast_clear":return "Clear the forest in under five minutes"
  "bosses":return "Defeat a main boss"
  "minibosses":return "Defeat a miniboss"
  "stage":return "Reach stage 2"
  "endless":return "Survive until endless mode"
  "early_stage":return "Escape a stage before the timer reaches zero"
  "legendary_shop":return "Purchase from a Legendary shop"
  "chests":return "Open %d chests"%q.target
  _:return "Use an ultimate %d times"%q.target
func quests() -> void:
 game.mode="quests";var col=page("Quests");paragraph(wallet(),col,800)
 var tabs=TabContainer.new();tabs.custom_minimum_size=Vector2(1130,440);col.add_child(tabs)
 for category in ["Hunting","Arsenal","Survival","Exploration"]:
  var scroll=ScrollContainer.new();scroll.name=category;tabs.add_child(scroll)
  var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
  for q in quest_definitions:
   if q.category!=category:continue
   heading(q.name,list,20);paragraph(quest_description(q)+" • Reward: %d silver"%LoadoutCatalog.quest_reward(q),list,900)
   var bar=ProgressBar.new();bar.max_value=q.target;bar.value=MetaProgress.quest_value(game.progress.data,q.metric);list.add_child(bar)
   var claimed=q.id in game.progress.data.claimed
   var claim=action("Claimed" if claimed else "Claim reward" if MetaProgress.quest_state(game.progress.data,q)=="completed" else "In progress",list,func():
    if MetaProgress.claim(game.progress.data,q.id):
     game.play_sound("ui.purchase");game.progress.save();claim_quest_button(list,q.id);wallet_refresh(col))
   claim.set_meta("quest_id",q.id)
   claim.disabled=claimed or MetaProgress.quest_value(game.progress.data,q.metric)<q.target
func claim_quest_button(list: Node,id: String) -> void:
 for child in list.get_children():
  if child is Button and child.get_meta("quest_id","")==id:child.text="Claimed";child.disabled=true
func wallet_refresh(column: Node) -> void:
 for child in column.get_children():
  if child is Label and child.text.begins_with("SILVER"):child.text=wallet()
func fade_celebrations() -> void:
 for child in RewardScreens.descendants(menu):
  if child is RewardCelebration:
   var position=child.global_position;child.reparent(root);child.global_position=position;child.fade_out()
func enter_run() -> void:
 fade_celebrations();chest_skip=Callable()
 stop_reward_animations()
 in_run=true;icon_fingerprint=""
 menu.hide();hud_root.show();game.player.camera.current=true
func update_hud() -> void:
 if stopwatch_overlay:stopwatch_overlay.update_state(game.world_time,get_process_delta_time())
 var weapon_names: Array[String]=[]
 for id in game.weapons:weapon_names.append("%s %d"%[Catalog.WEAPONS[id][0],game.weapons[id].level])
 var tome_names: Array[String]=[]
 for id in game.tomes:tome_names.append("%s %d"%[id,game.tomes[id]])
 loadout_label.text="ARSENAL %d/%d • TOMES %d/%d"%[game.weapons.size(),game.weapon_limit(),game.tomes.size(),game.tome_limit()]
 var equipment=[]
 for id in game.weapons:equipment.append(str(id)+":"+str(game.weapons[id].level)+":"+str(game.weapons[id].get("rarity","common")))
 var fingerprint=str(equipment)+str(game.tomes)+str(game.tome_rarities)+str(game.weapon_limit())+str(game.tome_limit())+game.loadout_runtime.trait_id+game.loadout_runtime.ultimate_id
 if fingerprint!=icon_fingerprint:
  icon_fingerprint=fingerprint
  for child in loadout_icons.get_children():loadout_icons.remove_child(child);child.queue_free()
  var equipment_rows=VBoxContainer.new();equipment_rows.name="EquippedItems";equipment_rows.add_theme_constant_override("separation",4);loadout_icons.add_child(equipment_rows)
  var weapon_row=HBoxContainer.new();weapon_row.name="Weapons";weapon_row.add_theme_constant_override("separation",4);equipment_rows.add_child(weapon_row)
  for id in game.weapons:
   var meta=game.equipment_meta("weapons",id,int(game.weapons[id].level));var tile=RewardScreens.icon(self,weapon_row,"weapons",str(id),"Lv. %d"%int(game.weapons[id].level),Rarity.definition(meta.rarity).color,40);tile.tooltip_text=meta.name;tile.set_meta("equipment_uid",meta.uid)
  var tome_row=HBoxContainer.new();tome_row.name="Tomes";tome_row.add_theme_constant_override("separation",4);equipment_rows.add_child(tome_row)
  for id in game.tomes:
   var meta=game.equipment_meta("tomes",id,int(game.tomes[id]));var tile=RewardScreens.icon(self,tome_row,"tomes",str(id),"Lv. %d"%int(game.tomes[id]),Rarity.definition(meta.rarity).color,40);tile.tooltip_text=meta.name;tile.set_meta("equipment_uid",meta.uid)
  var ability_row=HBoxContainer.new();loadout_icons.add_child(ability_row)
  icon_tile(ability_row,"traits",game.loadout_runtime.trait_id,LoadoutCatalog.entry("traits",game.loadout_runtime.trait_id).get("name","Trait"),true)
  icon_tile(ability_row,"ultimates",game.loadout_runtime.ultimate_id,LoadoutCatalog.entry("ultimates",game.loadout_runtime.ultimate_id).get("name","Ultimate"),true)
 gold_label.text="GOLD  %d\nCHESTS  %d"%[game.gold,game.chest_cost()]
 var left=maxf(0,game.STAGE_SECONDS-game.stage_time)
 timer_label.text="%02d:%02d"%[int(left)/60,int(left)%60] if left>0 else "00:00 • ENDLESS"
 timer_label.modulate=Color("f68c7a") if left<=0 else Color("f2e5c4")
 game.health_bar.max_value=game.stats.max_health;game.health_bar.value=game.health
 health_text.text="%d / %d"%[ceili(maxf(0,game.health)),ceili(game.stats.max_health)]
 character_health.max_value=game.stats.max_health;character_health.value=game.health
 update_character_health()
 xp_label.text="LEVEL %d • %.0f / %.0f XP"%[game.level,game.xp,Catalog.threshold(game.level)]
 if is_instance_valid(ultimate_badge):ultimate_badge.text="READY" if game.loadout_runtime.cooldown<=0 else str(ceili(game.loadout_runtime.cooldown))+"s"
 game.xp_bar.max_value=Catalog.threshold(game.level);game.xp_bar.value=game.xp;game.xp_bar.tooltip_text="Level %d • %.0f / %.0f XP"%[game.level,game.xp,Catalog.threshold(game.level)]
 status_label.text="HP %d/%d  •  LV %d  •  KILLS %d\nTab • Build & stats"%[maxf(0,game.health),game.stats.max_health,game.level,game.kills]
 status_label.text+="\n[%s] %s • %s"%[OS.get_keycode_string(game.bindings.ultimate),LoadoutCatalog.entry("ultimates",game.loadout_runtime.ultimate_id).get("name","Ultimate"),"READY" if game.loadout_runtime.cooldown<=0 else "%ds"%ceili(game.loadout_runtime.cooldown)]
 if game.loadout_runtime.remaining>0:status_label.text+="\nULTIMATE ACTIVE • %.1fs"%game.loadout_runtime.remaining
 quest_tracker.text="";quest_tracker.hide()
 update_boss_bars()
 if game.settings.fps:status_label.text+="\n%d FPS"%Engine.get_frames_per_second()
func pause() -> void:
 RewardScreens.pause(self)
func world_map(from_pause: bool=false) -> void:
 RewardScreens.world_map(self,from_pause)
func inventory() -> void:
 RewardScreens.inventory(self)
func upgrades() -> void:
 RewardScreens.upgrades(self)
func shop(object: Dictionary) -> void:
 RewardScreens.shop(self,object)
func reward(item: Array) -> void:
 RewardScreens.reward(self,item)
func settings(back: Callable) -> void:
 settings_back=back
 game.mode="settings";var col=page("Settings")
 var tabs=TabContainer.new();tabs.custom_minimum_size=Vector2(1130,440);col.add_child(tabs)
 for group in ["Display","Graphics","Audio","Gameplay"]:
  var scroll=ScrollContainer.new();scroll.name=group;tabs.add_child(scroll)
  var list=VBoxContainer.new();list.custom_minimum_size.x=1000;list.add_theme_constant_override("separation",12);scroll.add_child(list)
  if group=="Display":
   var fullscreen=CheckButton.new();fullscreen.text="Fullscreen";fullscreen.button_pressed=DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN;list.add_child(fullscreen)
   fullscreen.toggled.connect(func(enabled):DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))
   var resolution=OptionButton.new()
   for label in ["1280 × 720","1600 × 900","1920 × 1080"]:resolution.add_item(label)
   list.add_child(resolution);resolution.item_selected.connect(func(i):DisplayServer.window_set_size([Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)][i]))
  var keys=[]
  if group=="Graphics":keys=["render_scale","retro_scale","psx_warp","psx_snap","psx_dither","visual_intensity","reduced","numbers","shake","fps"]
  if group=="Audio":keys=["master","music","effects","ui_volume","ambience"]
  if group=="Gameplay":keys=["sensitivity","invert","focus_pause"]
  for key in keys:
   if game.settings[key] is bool:
    var check=CheckButton.new();check.text=key.replace("_"," ").capitalize();check.button_pressed=game.settings[key];list.add_child(check)
    check.toggled.connect(func(value):game.settings[key]=value;game.apply_settings())
   else:
    var caption=text(({"master":"Master volume","music":"Music volume","effects":"Sound effects volume","ui_volume":"UI volume","ambience":"Ambient volume"}).get(key,key.replace("_"," ").capitalize()),list,16)
    if group=="Audio":caption.text+=" · %d%%"%roundi(float(game.settings[key])*100)
    var slider=HSlider.new();slider.min_value=0.0005 if key=="sensitivity" else (0.5 if key=="render_scale" else (0.25 if key=="retro_scale" else 0.0));slider.max_value=0.008 if key=="sensitivity" else 1.0;slider.step=0.0001 if key=="sensitivity" else 0.05;slider.value=game.settings[key];slider.custom_minimum_size.x=700;list.add_child(slider)
    slider.value_changed.connect(func(value):
     game.settings[key]=value;game.apply_settings()
     if group=="Audio":
      caption.text=({"master":"Master volume","music":"Music volume","effects":"Sound effects volume","ui_volume":"UI volume","ambience":"Ambient volume"})[key]+" · %d%%"%roundi(value*100);game.progress.data.settings=game.settings.duplicate(true);game.progress.save())
  if group=="Graphics":
   var quality=OptionButton.new()
   for label in ["Low","Medium","High"]:quality.add_item(label)
   quality.selected=int(game.settings.quality);list.add_child(quality);quality.item_selected.connect(func(i):game.settings.quality=i;game.apply_settings())
  if group=="Gameplay":
   var keys_grid=GridContainer.new();keys_grid.columns=3;list.add_child(keys_grid)
   for key in game.bindings:
    action("%s: %s"%[key,OS.get_keycode_string(game.bindings[key])],keys_grid,func():game.pending_binding=key;game.toast("Press a key for "+key))
 action("Save & back",col,func():game.progress.data.settings=game.settings;game.progress.data.settings.bindings=game.bindings;game.progress.save();back.call())
 action("Quit game",col,func():get_tree().quit())
func update_character_health() -> void:
 if not is_instance_valid(game) or game.mode!="run" or not is_instance_valid(game.player) or not is_instance_valid(game.player.camera):character_health.hide();return
 character_health.size=Vector2(64,7) # Apply after inherited theme minimum-size recalculation.
 var point=game.player.global_position+Vector3.UP*0.05;var camera=game.player.camera
 if (point-camera.global_position).dot(-camera.global_basis.z)<=0.05:character_health.hide();return
 var screen=camera.unproject_position(point);character_health.position=screen+Vector2(-32,12)
 character_health.visible=game.mode=="run" and not camera.is_position_behind(point) and Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).has_point(screen)
func _process(delta: float) -> void:
 update_character_health()
 if not is_instance_valid(game):return
 if game.mode!="run":
  for object in game.interactables:
   if ShrineCharging.is_shrine(object) and is_instance_valid(object.node):
    var label=object.node.get_node_or_null("ChargeProgress")
    if label:label.hide()
  game.message_time-=delta
  if game.message_time<=0:game.notice.text=""
 if menu.visible and is_instance_valid(menu_camera) and menu_camera.is_inside_tree() and game.mode in ["menu","play","unlocks","quests","settings"]:
  update_menu_camera(delta)
  if is_instance_valid(game.player):game.player.avatar.animate("idle",0,delta)
 if game.mode=="run":
  map_tick+=delta
  if map_tick>=0.12:map_tick=0;minimap.reveal(game.player.position);minimap.queue_redraw()

func icon_tile(parent: Node, category: String, id: String, hint: String, golden: bool, rank: int = 0) -> void:
 var slot=Control.new();slot.custom_minimum_size=Vector2(34,34);slot.tooltip_text=hint;parent.add_child(slot)
 var image=TextureRect.new();image.texture=UIAssets.icon(category,id);image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);slot.add_child(image)
 if rank>0:
  var number=text(str(rank),slot,12);number.position=Vector2(24,20)
 if golden and category!="traits":
  var border=ColorRect.new();border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);border.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var material=ShaderMaterial.new();material.shader=preload("res://shaders/gold_frame.gdshader");border.material=material;slot.add_child(border)
 if category=="ultimates":
  ultimate_badge=text("",slot,11);ultimate_badge.position=Vector2(0,20);ultimate_badge.add_theme_color_override("font_shadow_color",Color.BLACK);ultimate_badge.add_theme_constant_override("shadow_offset_x",1);ultimate_badge.add_theme_constant_override("shadow_offset_y",1)
func leave_settings() -> void:
 game.progress.data.settings=game.settings;game.progress.data.settings.bindings=game.bindings;game.progress.save()
 if settings_back.is_valid():settings_back.call()
 else:home()

func empty_slot(parent: Node, label: String) -> void:
 var slot=PanelContainer.new();slot.custom_minimum_size=Vector2(34,34);slot.tooltip_text=label;parent.add_child(slot)
 var mark=text("—",slot,18);mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func update_boss_bars() -> void:
 var bosses=[]
 for e in game.enemies:
  if e.kind in [8,9,10] and e.hp>0:bosses.append(e)
 bosses.sort_custom(func(a,b):return a.kind<b.kind)
 var rows=[]
 for e in bosses.slice(0,3 if bosses.size()>4 else 4):rows.append({"name":e.variant.name,"hp":e.hp,"max_hp":e.max_hp,"kind":e.kind})
 if bosses.size()>4:
  var hp=0.0;var maximum=0.0
  for e in bosses.slice(3):hp+=maxf(0,e.hp);maximum+=e.max_hp
  rows.append({"name":"%d more bosses (combined)"%(bosses.size()-3),"hp":hp,"max_hp":maximum,"kind":8})
 var fingerprint=""
 for row in rows:fingerprint+=row.name+str(row.kind)
 if fingerprint!=boss_fingerprint:
  boss_fingerprint=fingerprint
  for child in boss_panel.get_children():boss_panel.remove_child(child);child.queue_free()
  boss_widgets.clear()
  for row in rows:
   var label=text("",boss_panel,15);var bar=ProgressBar.new();bar.custom_minimum_size=Vector2(450,8);bar.show_percentage=false;boss_panel.add_child(bar)
   var fill=StyleBoxFlat.new();fill.bg_color=Color("e56f73") if row.kind==8 else Color("d9a95f");bar.add_theme_stylebox_override("fill",fill)
   boss_widgets.append({"label":label,"bar":bar})
 for i in rows.size():
  var row=rows[i];boss_widgets[i].label.text="%s  %d / %d"%[row.name,maxf(0,row.hp),row.max_hp];boss_widgets[i].bar.max_value=row.max_hp;boss_widgets[i].bar.value=maxf(0,row.hp)

func stage_intro(number: int) -> void:
 if is_instance_valid(stage_banner):stage_banner.queue_free()
 var banner=Label.new();stage_banner=banner;banner.mouse_filter=Control.MOUSE_FILTER_IGNORE;banner.process_mode=Node.PROCESS_MODE_ALWAYS
 banner.text="STAGE %d — %s"%[number,StageThemes.config(number).title];banner.position=Vector2(300,102);banner.custom_minimum_size=Vector2(680,60);banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;banner.add_theme_font_size_override("font_size",32)
 banner.add_theme_color_override("font_color",StageThemes.config(number).accent);banner.add_theme_color_override("font_shadow_color",Color("121522"));banner.add_theme_constant_override("shadow_offset_x",2);banner.add_theme_constant_override("shadow_offset_y",2)
 root.add_child(banner);banner.modulate.a=0;banner.scale=Vector2.ONE*0.92;banner.pivot_offset=Vector2(340,30)
 var tween=banner.create_tween();tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
 tween.tween_property(banner,"modulate:a",1.0,0.3)
 if not game.settings.reduced:
  tween.parallel().tween_property(banner,"scale",Vector2.ONE,0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  tween.tween_property(banner,"self_modulate",Color(1.25,1.25,1.25),0.25);tween.tween_property(banner,"self_modulate",Color.WHITE,0.25)
 tween.tween_interval(1.5);tween.tween_property(banner,"modulate:a",0.0,0.6);tween.tween_callback(banner.queue_free)

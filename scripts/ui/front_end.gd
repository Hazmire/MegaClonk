class_name FrontEnd
extends CanvasLayer
var game: Node
var root: Control
var menu: Control
var hud_root: Control
var loadout_label: Label
var gold_label: Label
var timer_label: Label
var status_label: Label
var minimap: RunMinimap
var menu_camera: Camera3D
var preview_mode="home"
var orbit=0.0
var map_tick=0.0
var settings_back: Callable
var in_run=false
var loadout_icons: VBoxContainer
var icon_fingerprint=""
var active_tab="weapons"
var shop_object: Dictionary={}
var shop_offers: Array=[]
var headline_font: Font
var card_gold=Color("d8b575")

func setup(owner_game: Node) -> void:
 game=owner_game
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
 game.ui=self
 game.hud=text("",hud_root,18);game.hud.hide()
 game.health_bar=ProgressBar.new();game.health_bar.position=Vector2(28,162);game.health_bar.size=Vector2(270,15);game.health_bar.show_percentage=false;hud_root.add_child(game.health_bar)
 game.xp_bar=ProgressBar.new();game.xp_bar.position=Vector2(0,698);game.xp_bar.size=Vector2(1280,22);game.xp_bar.show_percentage=false;hud_root.add_child(game.xp_bar)
 for pair in [[game.health_bar,Color("e17f83")],[game.xp_bar,Color("75cdb2")]]:
  var fill=StyleBoxFlat.new();fill.bg_color=pair[1];pair[0].add_theme_stylebox_override("fill",fill)
 loadout_label=text("",hud_root,14);loadout_label.position=Vector2(28,14)
 loadout_icons=VBoxContainer.new();loadout_icons.position=Vector2(28,38);loadout_icons.add_theme_constant_override("separation",5);hud_root.add_child(loadout_icons)
 gold_label=text("",hud_root,20);gold_label.position=Vector2(1010,25)
 timer_label=text("",hud_root,30);timer_label.position=Vector2(525,24);timer_label.custom_minimum_size.x=230;timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 status_label=text("",hud_root,16);status_label.position=Vector2(28,184)
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
 button.pressed.connect(func(): game.tone(600,0.04);callback.call())
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
func clear() -> void:
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
 if golden:
  var border=ColorRect.new();border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);border.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var material=ShaderMaterial.new();material.shader=preload("res://shaders/gold_frame.gdshader");border.material=material;slot.add_child(border)
 paragraph(label,row,260)
 return row
func prepare_backdrop() -> void:
 game.mode="menu"
 if not is_instance_valid(game.player) or not is_instance_valid(game.enemy_view):
  game.variants.initialize(0);game.biome=0;game.run_seed=12;game.build_stage()
 if not is_instance_valid(menu_camera):
  menu_camera=Camera3D.new();game.world.add_child(menu_camera)
 menu_camera.current=true
 game.player.active=false
 game.player.position=Vector3(0,game.terrain_height(0,0),0)
 game.notice.text="";game.message_time=0
 game.player.avatar.show()
func home() -> void:
 in_run=false;game.mode="menu";preview_mode="home";prepare_backdrop();clear()
 var title=text("MEGACLONK",menu,54);title.add_theme_font_override("font",headline_font);title.position=Vector2(390,135);title.custom_minimum_size.x=500;title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 var buttons=card(menu,Vector2(490,270),Vector2(300,295))
 action("PLAY",buttons,play_screen).grab_focus();action("UNLOCKS",buttons,unlocks);action("QUESTS",buttons,quests);action("SETTINGS",buttons,func(): settings(home))
 var closest=card(menu,Vector2(24,28),Vector2(310,410));heading("Within reach",closest,19)
 var pending=[]
 for category in ["weapons","traits","items","ultimates"]:
  for entry in LoadoutCatalog.entries(category):
   if not MetaProgress.unlocked(game.progress.data,category,entry.id):
    pending.append({"entry":entry,"ratio":minf(1,float(game.progress.data.kills)/maxf(1,entry.goal))})
 pending.sort_custom(func(a,b):return a.entry.goal<b.entry.goal if is_equal_approx(a.ratio,b.ratio) else a.ratio>b.ratio)
 for i in mini(4,pending.size()):
  var e=pending[i].entry;paragraph(e.name,closest,260)
  text("%d / %d kills • %d credits"%[mini(game.progress.data.kills,e.goal),e.goal,e.cost],closest,13)
  var bar=ProgressBar.new();bar.max_value=maxf(1,e.goal);bar.value=mini(game.progress.data.kills,e.goal);bar.custom_minimum_size.y=10;bar.show_percentage=false;closest.add_child(bar)
 var currency=text(wallet(),menu,18);currency.position=Vector2(880,30)
func wallet() -> String:
 return "CREDITS %d   •   QUEST GOLD %d\nACCOUNT LEVEL %d"%[game.progress.data.credits,game.progress.data.quest_gold,MetaProgress.account_level(game.progress.data)]
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
 for category in ["weapons","traits","items","ultimates"]:
  action(category.capitalize(),tabs,func():active_tab=category;unlocks())
 var body=HBoxContainer.new();col.add_child(body)
 var grid=GridContainer.new();grid.columns=5;body.add_child(grid)
 var detail=VBoxContainer.new();detail.custom_minimum_size.x=390;body.add_child(detail)
 paragraph("Select an entry to inspect it. Enabled entries may appear during runs. Starting weapons ignore this toggle.",detail,370)
 for e in LoadoutCatalog.entries(active_tab):
  var open=MetaProgress.unlocked(game.progress.data,active_tab,e.id)
  var button=Button.new();button.custom_minimum_size=Vector2(130,86);button.clip_text=true;button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;button.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;button.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP;button.add_theme_font_size_override("font_size",14);button.tooltip_text=e.name;button.text=e.name+("\nON" if MetaProgress.enabled(game.progress.data,active_tab,e.id) else ("\nOFF" if open else "\nLOCKED"));button.icon=UIAssets.icon(active_tab,e.id);button.expand_icon=true;button.add_theme_constant_override("icon_max_width",30);grid.add_child(button)
  if not open:button.modulate=Color("82908b")
  button.pressed.connect(func():
   for child in detail.get_children():detail.remove_child(child);child.queue_free()
   heading(e.name,detail,22)
   if open:
    paragraph(e.description,detail,370)
    action("Disable from runs" if MetaProgress.enabled(game.progress.data,active_tab,e.id) else "Enable in runs",detail,func():MetaProgress.toggle(game.progress.data,active_tab,e.id);game.progress.save();unlocks())
   else:
    # Locked entries reveal their requirement, never their effect text.
    paragraph("Unlock: %d lifetime kills and %d credits.\nProgress: %d / %d kills."%[e.goal,e.cost,mini(game.progress.data.kills,e.goal),e.goal],detail,370)
    action("Unlock for %d credits"%e.cost,detail,func():
     if MetaProgress.purchase(game.progress.data,active_tab,e.id):game.progress.save();unlocks()
     else:game.toast("Requirement or credits missing")))
 heading("Account upgrades",col,21)
 for kind in ["weapon","tome"]:
  var slots=int(game.progress.data[kind+"_slots"])
  var required=2 if slots==2 else 4
  action("%s slots: %d/4  •  %s"%[kind.capitalize(),slots,"MAXIMUM" if slots>=4 else "Level %d + %d quest gold"%[required,MetaProgress.slot_cost(game.progress.data,kind)]],col,func():
   if MetaProgress.buy_slot(game.progress.data,kind):game.progress.save();unlocks()
   else:game.toast("Earn and claim quests to raise your level and quest gold"))
func quest_description(q: Dictionary) -> String:
 if q.metric.begins_with("weapon:"):return "%d kills using %s"%[q.target,Catalog.WEAPONS[int(q.metric.get_slice(":",1))][0]]
 match q.metric:
  "kills":return "Defeat %d enemies"%q.target
  "survival":return "Survive %d seconds in one run"%q.target
  "fast_clear":return "Clear the forest in under five minutes"
  "bosses":return "Defeat a Warden"
  "chests":return "Open %d chests"%q.target
  _:return "Use an ultimate %d times"%q.target
func quests() -> void:
 game.mode="quests";var col=page("Quests");paragraph(wallet(),col,800)
 var tabs=TabContainer.new();tabs.custom_minimum_size=Vector2(1130,440);col.add_child(tabs)
 for category in ["Hunting","Arsenal","Survival","Exploration"]:
  var scroll=ScrollContainer.new();scroll.name=category;tabs.add_child(scroll)
  var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(list)
  for q in LoadoutCatalog.QUESTS:
   if q.category!=category:continue
   heading(q.name,list,20);paragraph(quest_description(q)+" • Reward: %d credits / %d quest gold"%[q.credits,q.gold],list,900)
   var bar=ProgressBar.new();bar.max_value=q.target;bar.value=MetaProgress.quest_value(game.progress.data,q.metric);list.add_child(bar)
   var claimed=q.id in game.progress.data.claimed
   var claim=action("Claimed" if claimed else "Claim reward",list,func():
    if MetaProgress.claim(game.progress.data,q.id):game.progress.save();quests())
   claim.disabled=claimed or MetaProgress.quest_value(game.progress.data,q.metric)<q.target
func enter_run() -> void:
 in_run=true;icon_fingerprint=""
 menu.hide();hud_root.show();game.player.camera.current=true
func update_hud() -> void:
 var weapon_names: Array[String]=[]
 for id in game.weapons:weapon_names.append("%s %d"%[Catalog.WEAPONS[id][0],game.weapons[id].level])
 var tome_names: Array[String]=[]
 for id in game.tomes:tome_names.append("%s %d"%[id,game.tomes[id]])
 loadout_label.text="ARSENAL %d/%d • TOMES %d/%d"%[game.weapons.size(),game.weapon_limit(),game.tomes.size(),game.tome_limit()]
 var equipment=[]
 for id in game.weapons:equipment.append(str(id)+":"+str(game.weapons[id].level))
 var fingerprint=str(equipment)+str(game.tomes)+game.loadout_runtime.trait_id+game.loadout_runtime.ultimate_id
 if fingerprint!=icon_fingerprint:
  icon_fingerprint=fingerprint
  for child in loadout_icons.get_children():loadout_icons.remove_child(child);child.queue_free()
  var weapon_row=HBoxContainer.new();loadout_icons.add_child(weapon_row)
  for id in game.weapons:icon_tile(weapon_row,"weapons",str(id),Catalog.WEAPONS[id][0],false,int(game.weapons[id].level))
  var tome_row=HBoxContainer.new();loadout_icons.add_child(tome_row)
  for id in game.tomes:icon_tile(tome_row,"tomes",str(id),str(id),false,int(game.tomes[id]))
  var ability_row=HBoxContainer.new();loadout_icons.add_child(ability_row)
  icon_tile(ability_row,"traits",game.loadout_runtime.trait_id,LoadoutCatalog.entry("traits",game.loadout_runtime.trait_id).get("name","Trait"),true)
  icon_tile(ability_row,"ultimates",game.loadout_runtime.ultimate_id,LoadoutCatalog.entry("ultimates",game.loadout_runtime.ultimate_id).get("name","Ultimate"),true)
 gold_label.text="GOLD  %d\nCHESTS  %d"%[game.gold,game.chest_cost()]
 var left=maxf(0,game.STAGE_SECONDS-game.stage_time)
 timer_label.text="%02d:%02d"%[int(left)/60,int(left)%60] if left>0 else "00:00 • ENDLESS"
 timer_label.modulate=Color("f68c7a") if left<=0 else Color("f2e5c4")
 game.health_bar.max_value=game.stats.max_health;game.health_bar.value=game.health
 game.xp_bar.max_value=Catalog.threshold(game.level);game.xp_bar.value=game.xp
 status_label.text="HP %d/%d  •  LV %d  •  KILLS %d\nTab • Build & stats"%[maxf(0,game.health),game.stats.max_health,game.level,game.kills]
 status_label.text+="\n[%s] %s • %s"%[OS.get_keycode_string(game.bindings.ultimate),LoadoutCatalog.entry("ultimates",game.loadout_runtime.ultimate_id).get("name","Ultimate"),"READY" if game.loadout_runtime.cooldown<=0 else "%ds"%ceili(game.loadout_runtime.cooldown)]
 if game.loadout_runtime.remaining>0:status_label.text+="\nULTIMATE ACTIVE • %.1fs"%game.loadout_runtime.remaining
 for e in game.enemies:
  if e.kind==8:status_label.text+="\nWARDEN %d / %d"%[maxf(0,e.hp),e.max_hp]
 if game.settings.fps:status_label.text+="\n%d FPS"%Engine.get_frames_per_second()
func inventory() -> void:
 game.mode="build";var col=page("Your build & character stats")
 var row=HBoxContainer.new();col.add_child(row)
 var left=VBoxContainer.new();row.add_child(left)
 heading("Equipment",left,22)
 for id in game.weapons:icon_row(left,"weapons",str(id),"%s • Level %d"%[Catalog.WEAPONS[id][0],game.weapons[id].level])
 for id in game.tomes:icon_row(left,"tomes",str(id),"%s • Level %d"%[id,game.tomes[id]])
 for category in ["traits","ultimates"]:
  var id=game.loadout_runtime.trait_id if category=="traits" else game.loadout_runtime.ultimate_id
  icon_row(left,category,id,LoadoutCatalog.entry(category,id).get("name",id),true)
 var middle=VBoxContainer.new();row.add_child(middle);heading("Items",middle,22)
 if game.items.is_empty():text("No items yet",middle,16)
 var counts={}
 for id in game.items:counts[id]=int(counts.get(id,0))+1
 for name in counts:
  var index=0
  for i in Catalog.ITEMS.size():
   if Catalog.ITEMS[i][0]==name:index=i;break
  icon_row(middle,"items",str(index),"%s ×%d"%[name,counts[name]])
 var right=VBoxContainer.new();row.add_child(right);heading("Live statistics",right,22)
 var stats_grid=GridContainer.new();stats_grid.columns=2;right.add_child(stats_grid)
 for key in game.stats:
  text(key.replace("_"," ").capitalize(),stats_grid,15);text("%.2f"%game.stats[key],stats_grid,15)
 text("Trait/ultimate damage ×%.2f"%game.loadout_runtime.damage_multiplier(),right,14)
 action("Resume",col,game.resume)
func upgrades() -> void:
 game.mode="upgrade";var col=page("Level %d • Choose your power"%game.level)
 game.choices.clear();var pool=game.upgrade_pool()
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",16);col.add_child(row)
 for i in mini(3,pool.size()):
  var choice=pool.pop_at(game.rng.randi_range(0,pool.size()-1));game.choices.append(choice)
  var container=PanelContainer.new();container.custom_minimum_size=Vector2(365,340)
  var style=StyleBoxFlat.new();style.bg_color=Color("1b3035");style.border_color=Color("4c6d68");style.set_border_width_all(1);style.set_corner_radius_all(5);style.content_margin_left=14;style.content_margin_right=14;style.content_margin_top=14;style.content_margin_bottom=14;container.add_theme_stylebox_override("panel",style);row.add_child(container)
  var card_body=VBoxContainer.new();card_body.add_theme_constant_override("separation",18);container.add_child(card_body)
  var title="";var description="";var category="weapons"
  if choice.type=="weapon":
   var id=int(choice.id);var rank=int(game.weapons[id].level) if game.weapons.has(id) else 0
   title=Catalog.WEAPONS[id][0];description="Level %d → %d\nDamage %.0f → %.0f\n%s"%[rank,rank+1,Catalog.WEAPONS[id][2]*(1+maxi(0,rank-1)*0.23),Catalog.WEAPONS[id][2]*(1+rank*0.23),Catalog.WEAPONS[id][1]]
  elif choice.type=="tome":
   category="tomes";var stat=Catalog.TOMES[choice.id][0];title=str(choice.id)+" Tome";description="Level %d → %d\n%s %.2f → %.2f"%[game.tomes.get(choice.id,0),game.tomes.get(choice.id,0)+1,stat,game.stats[stat],game.stats[stat]+Catalog.TOMES[choice.id][1]]
  else:title="Field supplies";description="Restore 25 health."
  icon_row(card_body,category,str(choice.id),title);paragraph(description,card_body,300).custom_minimum_size.y=110
  action("Choose",card_body,func():game.apply_upgrade(choice);game.resume())
  action("Banish",card_body,func():game.banished.append(choice.key);game.resume())
 var controls=HBoxContainer.new();col.add_child(controls)
 action("Reroll (%d)"%game.rerolls,controls,func():
  if game.rerolls>0:game.rerolls-=1;upgrades()).disabled=game.rerolls<=0
 action("Skip • heal 10",controls,func():game.health=minf(game.stats.max_health,game.health+10);game.resume())
func shop(object: Dictionary) -> void:
 game.mode="shop";shop_object=object
 if not object.has("offers"):object.offers=game.available_items();object.offers.shuffle();object.offers=object.offers.slice(0,3)
 shop_offers=object.offers
 var col=page("Wanderer's shop");paragraph("Run gold: %d • Choose an item. Purchased stock stays sold."%game.gold,col,850)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",15);col.add_child(row)
 for i in shop_offers.size():
  var id=int(shop_offers[i]);var item=Catalog.ITEMS[id];var price=15 if item[1]=="common" else (25 if item[1]=="rare" else 40)
  var box=VBoxContainer.new();box.custom_minimum_size=Vector2(345,280);row.add_child(box)
  icon_row(box,"items",str(id),item[0]);paragraph("%s\n+%s %s"%[item[1],item[3],item[2]],box,300)
  var sold=id in object.get("sold",[])
  var buy=action("SOLD" if sold else "Buy • %d gold"%price,box,func():
   if game.buy_shop(object,id,price):shop(object)
   else:game.toast("Not enough run gold"))
  buy.disabled=sold or game.gold<price
 if shop_offers.is_empty():paragraph("No enabled items are available. Enable items from Unlocks between runs.",col,900)
 action("Leave shop",col,game.resume)
func reward(item: Array) -> void:
 game.mode="reward";var col=page("Treasure discovered")
 var id=Catalog.ITEMS.find(item);icon_row(col,"items",str(id),item[0]);paragraph("%s • +%s %s\nApplied to your build immediately."%[item[1],item[3],item[2]],col,850)
 action("Continue",col,game.resume)
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
  if group=="Graphics":keys=["render_scale","visual_intensity","reduced","numbers","shake","fps"]
  if group=="Audio":keys=["master","music","effects"]
  if group=="Gameplay":keys=["sensitivity","invert","focus_pause"]
  for key in keys:
   if game.settings[key] is bool:
    var check=CheckButton.new();check.text=key.replace("_"," ").capitalize();check.button_pressed=game.settings[key];list.add_child(check)
    check.toggled.connect(func(value):game.settings[key]=value;game.apply_settings())
   else:
    text(key.replace("_"," ").capitalize(),list,16)
    var slider=HSlider.new();slider.min_value=0.0005 if key=="sensitivity" else (0.5 if key=="render_scale" else 0.0);slider.max_value=0.008 if key=="sensitivity" else 1.0;slider.step=0.0001 if key=="sensitivity" else 0.05;slider.value=game.settings[key];slider.custom_minimum_size.x=700;list.add_child(slider)
    slider.value_changed.connect(func(value):game.settings[key]=value;game.apply_settings())
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
func _process(delta: float) -> void:
 if not is_instance_valid(game):return
 if game.mode!="run":
  game.message_time-=delta
  if game.message_time<=0:game.notice.text=""
 if menu.visible and is_instance_valid(menu_camera) and game.mode in ["menu","play","unlocks","quests","settings"]:
  if preview_mode=="home":
   orbit+=delta*0.035;menu_camera.h_offset=0;menu_camera.position=Vector3(cos(orbit)*28,16,sin(orbit)*28);menu_camera.look_at(Vector3(0,0,0))
  else:
   menu_camera.h_offset=-1.6;menu_camera.position=Vector3(0,2.5,5.5);menu_camera.look_at(Vector3(0,1,0))
  if is_instance_valid(game.player):game.player.avatar.animate("idle",0,delta)
 if game.mode=="run":
  map_tick+=delta
  if map_tick>=0.12:map_tick=0;minimap.reveal(game.player.position);minimap.queue_redraw()

func icon_tile(parent: Node, category: String, id: String, hint: String, golden: bool, rank: int = 0) -> void:
 var slot=Control.new();slot.custom_minimum_size=Vector2(34,34);slot.tooltip_text=hint;parent.add_child(slot)
 var image=TextureRect.new();image.texture=UIAssets.icon(category,id);image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);slot.add_child(image)
 if rank>0:
  var number=text(str(rank),slot,12);number.position=Vector2(24,20)
 if golden:
  var border=ColorRect.new();border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);border.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var material=ShaderMaterial.new();material.shader=preload("res://shaders/gold_frame.gdshader");border.material=material;slot.add_child(border)
func leave_settings() -> void:
 game.progress.data.settings=game.settings;game.progress.data.settings.bindings=game.bindings;game.progress.save()
 if settings_back.is_valid():settings_back.call()
 else:home()

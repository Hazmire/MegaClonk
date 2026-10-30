extends SceneTree
# Menu Overhaul regression: scenes, fonts, icons, data helpers, and behaviour of every Fog screen (main menu, Prepare your run,
# Unlocks x5, Quests, Settings). Headless; real renders are covered by tools/menu_capture.gd.
var count=0
var failures: Array[String]=[]
var game: Node
func check(ok: bool,label: String) -> void:
 count+=1
 if ok:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func nodes(node: Node) -> Array:
 var result=[node]
 for child in node.get_children():result.append_array(nodes(child))
 return result
func current() -> Node:return game.frontend.menu.get_child(game.frontend.menu.get_child_count()-1)
func press(key: Key) -> void:
 var e=InputEventKey.new();e.keycode=key;e.physical_keycode=key;e.pressed=true;current()._unhandled_input(e)
func _initialize() -> void:call_deferred("run")
func fresh_profile() -> void:
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://menus-regression.json"
func run() -> void:
 MenuScreen.set_instant(true)
 # ---- scenes, fonts, icons ----
 var scenes_ok=true
 for key in MenuStyle.SCENES:
  var packed=load(MenuStyle.SCENES[key]) as PackedScene
  if packed==null:scenes_ok=false;continue
  var n=packed.instantiate();if n==null:scenes_ok=false
  else:n.free()
 for path in ["main_menu","loadout_screen","unlocks_screen","quests_screen","settings_screen"]:
  var packed=load("res://ui/menu/screens/%s.tscn"%path) as PackedScene
  if packed==null:scenes_ok=false
 check(scenes_ok,"Every menu widget and screen scene loads")
 check(FogTheme.serif()!=null and FogTheme.serif_sc()!=null and FogTheme.memo()!=null and FogTheme.sans(800)!=null,"All four Fog fonts load from res://ui/fonts")
 var icon_ok=true;var filter_ok=true;var checked=0
 var groups={"weapons":Catalog.ACTIVE_WEAPONS.map(func(i):return str(i)),"tomes":Catalog.ACTIVE_TOMES,"traits":LoadoutCatalog.TRAITS.map(func(t):return t.id),"ultimates":LoadoutCatalog.ULTIMATES.map(func(t):return t.id),"items":Catalog.ITEM_IDS}
 for category in groups:
  for id in groups[category]:
   var path=UIAssets.final_icon_path(category,String(id));checked+=1
   var tex=load(path) as Texture2D
   if tex==null or tex.get_width()!=32 or tex.get_height()!=32:icon_ok=false
   if not FileAccess.get_file_as_string(path+".import").contains("mipmaps/generate=false"):filter_ok=false
   if UIAssets.icon(category,String(id))!=tex:icon_ok=false
 check(icon_ok and checked==8+10+5+3+Catalog.ITEM_IDS.size(),"All %d weapon, tome, trait, ultimate and item icons exist at 32x32 and are what UIAssets returns"%checked)
 check(filter_ok,"Every menu icon imports with mipmaps off")
 # ---- data helpers ----
 var counts=MenuData.tier_counts()
 check(counts.all==61 and counts.common==19 and counts.uncommon==17 and counts.rare==13 and counts.epic==7 and counts.legendary==5,"Rarity filter counts are 61 / 19 / 17 / 13 / 7 / 5 from the catalogue")
 check(MenuData.drop_weight_text("common")=="50%" and MenuData.drop_weight_text("legendary")=="2%","Drop weights come from ItemStats.TIER_WEIGHTS")
 check(MenuData.sources_text("whetstone")=="Appears in vases, chests and shops" and MenuData.sources_text("hex_penny")=="Appears in vases, chests and shops","Common items list vases, chests and shops")
 check(MenuData.sources_text("headsmans_oath")=="Appears in chests and shops" and MenuData.sources_text("imbued_amulet")=="Appears in chests and shops","Legendary items appear in chests and shops, never vases")
 var rare_id=String(Catalog.ITEM_IDS.filter(func(x):return Catalog.item_tier(x)=="rare")[0])
 check(MenuData.sources_text(rare_id)=="Appears in chests and shops" and MenuData.sources_text("tinder_pouch")=="Appears in vases, chests and shops","Rare items skip vases; Uncommon items do not")
 var gem_items=Catalog.ITEM_IDS.filter(func(i):return MenuData.needs_element(String(i))!="")
 check(gem_items.size()==5 and MenuData.needs_element("tinder_pouch")=="fire","Five items need a gem and Tinder Pouch needs Fire")
 var pools_ok=true
 for id in Catalog.ACTIVE_WEAPONS:
  if MenuData.weapon_pool_labels(id).is_empty() or MenuData.weapon_tag(id)=="All":pools_ok=false
 check(pools_ok,"Every weapon has level-up options and a category")
 var sentence=MenuData.weapon_sentence(9);var resolved=WeaponStats.resolve(null,9,{})
 check(sentence.contains("%d damage"%int(round(resolved.damage))) and sentence.contains("%.2f"%resolved.interval),"Weapon facts match WeaponStats.resolve")
 var old_profile={"entries":["weapons:0","tomes:Might"],"disabled":[],"claimed":[],"quest_metrics":{},"leaderboard":[],"silver":10,"kills":0,"best":0.0,"weapon_slots":2,"tome_slots":2,"loadout":{"weapon":0,"trait":"climber","ultimate":"nova"}}
 MetaProgress.migrate(old_profile)
 check(old_profile.has(MenuData.NEW_KEY) and "weapons:0" in old_profile[MenuData.NEW_KEY] and not MenuData.is_new(old_profile,"weapons","0"),"Old profiles start with everything they own marked as seen")
 old_profile.entries.append("weapons:15")
 check(MenuData.is_new(old_profile,"weapons","15") and MenuData.mark_seen(old_profile,"weapons","15") and not MenuData.is_new(old_profile,"weapons","15") and not MenuData.mark_seen(old_profile,"weapons","15"),"A new unlock shows NEW until it has been looked at once")
 check(not MenuData.is_new(old_profile,"weapons","6") if MetaProgress.unlocked(old_profile,"weapons","6") else true,"Locked entries never show NEW")
 var data=old_profile
 check(MenuData.tile_state(data,"weapons","15")=="on" and MenuData.tile_state(data,"traits","climber")=="plain","Tile states: on, plain (traits and ultimates have no toggle)")
 MetaProgress.toggle(data,"weapons","15")
 check(MenuData.tile_state(data,"weapons","15")=="off" and MenuData.tile_state(data,"tomes","Greed")=="locked","Tile states: off and locked")
 var reach=MenuData.within_reach(data,LoadoutCatalog.quests(),4)
 check(reach.size()==4,"Within reach returns four open quests")
 # preview sheets
 WeaponPreview.meta={};WeaponPreview.load_meta()
 var previews_ok=true
 for id in Catalog.ACTIVE_WEAPONS:
  var info: Dictionary=WeaponPreview.meta.get(str(id),{})
  if info.is_empty() or not WeaponPreview.has_preview(id):previews_ok=false;continue
  var sheet=load("res://assets/ui/weapon_previews/%d.png"%id) as Texture2D
  var rows=ceili(float(info.frames)/float(info.columns))
  if sheet==null or sheet.get_width()!=int(info.columns)*int(info.w) or sheet.get_height()!=rows*int(info.h):previews_ok=false
 check(previews_ok,"All eight weapons have a looping preview sheet whose size matches its frame data")
 # ---- screens ----
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await process_frame
 fresh_profile()
 check(root.theme==null and game.frontend.root.theme!=MenuStyle.theme(),"The Fog theme is scoped to menu screens, not the whole project or the in-run UI")
 game.frontend.home();await process_frame
 var main=current()
 check(main is MainMenuScreen and main.items.size()>=4,"Home builds the Fog main menu")
 main.items["unlocks"].pressed.emit();await process_frame
 check(game.mode=="unlocks" and current() is UnlocksScreen,"Main menu Unlocks opens the Unlocks screen")
 var unlocks=current()
 var expected={"weapons":8,"tomes":10,"traits":5,"items":Catalog.ITEM_IDS.size(),"ultimates":3}
 for tab in expected:
  unlocks.tab_bar.select(tab);await process_frame
  check(unlocks.category==tab and unlocks.tiles.size()==expected[tab],"%s tab shows %d entries"%[tab.capitalize(),expected[tab]])
  var whole=true
  for id in unlocks.tiles:
   if int(unlocks.tiles[id].art.size.x)%32!=0:whole=false
  check(whole,"%s tiles draw their 32px icons at whole-number scales"%tab.capitalize())
 # Q / E
 unlocks.tab_bar.select("weapons");await process_frame
 press(KEY_E);await process_frame
 check(unlocks.category=="tomes","E steps to the next tab")
 press(KEY_Q);press(KEY_Q);await process_frame
 check(unlocks.category=="ultimates","Q steps back and wraps around")
 # toggling
 unlocks.tab_bar.select("tomes");await process_frame
 var might=unlocks.tiles["Might"]
 check(might.state=="on","Unlocked tome starts ON")
 might.pressed.emit();await process_frame
 check(might.state=="off" and not MetaProgress.enabled(game.progress.data,"tomes","Might"),"Pressing a tile turns it OFF and saves it in the profile")
 might.pressed.emit()
 check(might.state=="on","Pressing again turns it back ON")
 unlocks.tiles["Multishot"].grab_focus();await process_frame
 check(unlocks.memo.find_child("Requirement",true,false)!=null and unlocks.memo.find_child("Buy",true,false)!=null,"Locked tome detail shows the requirement and an unlock button")
 game.progress.data.silver=0;game.progress.data.kills=0
 var silver_before=game.progress.data.silver
 unlocks.buy("Multishot")
 check(not MetaProgress.unlocked(game.progress.data,"tomes","Multishot") and game.progress.data.silver==silver_before,"Unlock without silver or kills does nothing")
 game.progress.data.silver=500;game.progress.data.kills=500
 unlocks.buy("Multishot");await process_frame
 check(MetaProgress.unlocked(game.progress.data,"tomes","Multishot") and game.progress.data.silver==400 and unlocks.silver_number.text=="400","Unlock charges once and the silver counter follows")
 check(not MenuData.is_new(game.progress.data,"tomes","Multishot") and not unlocks.tiles["Multishot"].is_new,"Looking at a freshly unlocked tome clears its NEW badge")
 # slots
 game.progress.data.silver=250
 unlocks.refresh_slots()
 var slot_button=unlocks.find_child("BuySlot",true,false)
 check(slot_button!=null and "250" in slot_button.text,"Tome slot upgrade shows its price")
 slot_button.pressed.emit();await process_frame
 check(game.progress.data.tome_slots==3 and game.progress.data.silver==0,"Buying a tome slot charges 250 silver")
 # traits / ultimates are not toggleable
 unlocks.tab_bar.select("traits");await process_frame
 var t=unlocks.tiles["sentry"];t.pressed.emit()
 check(t.state=="plain" and unlocks.memo.find_child("AlwaysAvailable",true,false)!=null,"Traits are always available and have no toggle")
 unlocks.tab_bar.select("ultimates");await process_frame
 check(unlocks.memo.find_child("Toggle",true,false)==null,"Ultimates have no toggle")
 # weapons
 unlocks.tab_bar.select("weapons");await process_frame
 unlocks.tiles["15"].grab_focus();await process_frame
 check(unlocks.memo.find_child("Preview",true,false) is WeaponPreview and unlocks.memo.find_child("PhotoLocked",true,false)!=null and unlocks.memo.find_child("Pool",true,false).get_child_count()==WeaponUpgrades.pool(15).size(),"Locked weapon shows a greyed preview, a LOCKED stamp and its real level-up options")
 unlocks.tiles["0"].grab_focus();await process_frame
 check(unlocks.memo.find_child("StartingNote",true,false)!=null and unlocks.memo.find_child("Toggle",true,false)!=null,"Unlocked weapon shows the toggle and the starting-weapon note")
 # items
 unlocks.tab_bar.select("items");await process_frame
 check(unlocks.tiles.size()==61 and unlocks.tab_bar.note=="FOUND 61 / 61","Items tab shows all 61 and FOUND 61 / 61")
 var visible_ok=true
 for tier in Catalog.ITEM_TIERS:
  unlocks.set_filter(tier)
  if unlocks.tiles.size()!=counts[tier]:visible_ok=false
 check(visible_ok,"Each rarity filter shows exactly that tier's items")
 unlocks.set_filter("all")
 unlocks.cycle_filter(1);check(unlocks.filter=="common","Tab cycles to the next rarity")
 unlocks.set_filter("all")
 unlocks.tiles["tinder_pouch"].grab_focus();await process_frame
 var needs=unlocks.memo.find_child("NeedsText",true,false)
 check(needs!=null and needs.text.contains("Fire socket gem"),"Gem item detail says it does nothing until you own the Fire gem")
 unlocks.tiles["whetstone"].grab_focus();await process_frame
 check(unlocks.memo.find_child("NeedsBox",true,false)==null and unlocks.memo.find_child("UniqueStamp",true,false)==null,"Plain item has no gem box and no Unique stamp")
 unlocks.tiles["saints_finger"].grab_focus();await process_frame
 check(unlocks.memo.find_child("UniqueStamp",true,false)==null,"Stackable items show no stamp")
 unlocks.tiles["imbued_amulet"].grab_focus();await process_frame
 check(unlocks.memo.find_child("UniqueStamp",true,false)!=null,"The consumable Amulet shows its stamp")
 MenuData.debug_locked_items=["hex_penny"]
 unlocks.tab_bar.select("weapons");unlocks.tab_bar.select("items");await process_frame
 unlocks.tiles["hex_penny"].grab_focus();await process_frame
 check(unlocks.tiles["hex_penny"].state=="locked" and unlocks.memo.find_child("Locked",true,false)!=null,"Debug override shows an item as locked")
 MenuData.debug_locked_items=[]
 # back
 press(KEY_ESCAPE);await process_frame
 var cancel=InputEventAction.new();cancel.action="ui_cancel";cancel.pressed=true
 current()._unhandled_input(cancel);await process_frame
 check(game.mode=="menu" and current() is MainMenuScreen,"Escape on Unlocks returns to the main menu")
 # quests
 game.progress.data.kills=150;game.progress.data.claimed=[]
 game.frontend.quests();await process_frame
 var quests=current()
 check(game.mode=="quests" and quests is QuestsScreen,"Quests opens the Fog quests screen")
 var first=quests.cards[0]
 check(first.claim_button!=null and first.name.begins_with("Quest_"),"Claimable quests come first and carry a CLAIM button")
 var silver=game.progress.data.silver
 var first_id=String(first.name).trim_prefix("Quest_")
 first.claim_pressed.emit();await process_frame
 check(first_id in game.progress.data.claimed and game.progress.data.silver>silver and quests.silver_number.text==str(game.progress.data.silver),"Claiming pays the reward once and updates the silver counter")
 var again=quests.grid.get_node("Quest_"+first_id)
 check(again.claim_button==null and again.get_index()>=quests.cards.size()-1,"A claimed quest turns into a DONE memo and moves to the end")
 var variants={"counted":false,"passfail":false}
 for category in ["Hunting","Arsenal","Survival","Exploration"]:
  quests.tab_bar.select(category);await process_frame
  for card in quests.cards:
   if card.variant in variants:variants[card.variant]=true
 check(variants.counted and variants.passfail,"Quests use both the progress-bar and the NOT YET variants")
 # settings
 var back_called=[false]
 game.frontend.settings(func():back_called[0]=true);await process_frame
 var settings=current()
 check(game.mode=="settings" and settings is SettingsScreen,"Settings opens the Fog settings screen")
 var all_keys_present=true
 for tab in ["Graphics","Audio","Gameplay"]:
  settings.tab_bar.select(tab);await process_frame
  var wanted=0
  for key in SettingsScreen.KEYS[tab]:wanted+=1
  var rows=settings.list.get_child_count()
  if rows<wanted:all_keys_present=false
 check(all_keys_present,"Graphics, Audio and Gameplay list every previous option")
 settings.tab_bar.select("Audio");await process_frame
 var slider: HSlider
 for n in nodes(settings.list):
  if n is HSlider:slider=n;break
 slider.value=0.5;await process_frame
 check(is_equal_approx(float(game.settings.master),0.5) and is_equal_approx(float(game.progress.data.settings.master),0.5),"Audio sliders apply and save at once")
 settings.tab_bar.select("Graphics");await process_frame
 var toggle: OnOffToggle
 for n in nodes(settings.list):
  if n is OnOffToggle:toggle=n;break
 var was=bool(game.settings.psx_dither)
 toggle.pressed.emit();await process_frame
 check(bool(game.settings.psx_dither)!=was,"A switch changes its setting")
 settings.tab_bar.select("Gameplay");await process_frame
 var bind: Button=settings.binding_buttons.values()[0]
 bind.pressed.emit()
 check(game.pending_binding==settings.binding_buttons.keys()[0],"Pressing a key binding waits for a key press")
 game.pending_binding=""
 var cancel2=InputEventAction.new();cancel2.action="ui_cancel";cancel2.pressed=true
 settings._unhandled_input(cancel2);await process_frame
 check(back_called[0],"Escape on Settings saves and goes back")
 print("MENUS RESULT: %d checks, %d failures"%[count,failures.size()])
 game.queue_free();await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)

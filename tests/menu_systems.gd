extends SceneTree
var count=0
var failures: Array[String]=[]
var game: Node
func check(ok: bool, label: String) -> void:
 count+=1
 if ok:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func widgets(node: Node, type_name: String) -> Array:
 var result=[]
 if node.is_class(type_name):result.append(node)
 for child in node.get_children():result.append_array(widgets(child,type_name))
 return result
func screen_text() -> String:
 var result=""
 for label in widgets(game.frontend.menu,"Label"):result+=label.text+"\n"
 return result
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var profile=Progress.new();profile.storage_path="user://menu-test-profile.json"
 MetaProgress.migrate(profile.data)
 check(profile.data.version==3 and profile.data.weapon_slots==2 and profile.data.tome_slots==2,"New profile starts with 2+2 slots")
 var old=FileAccess.open("user://legacy-menu-profile.json",FileAccess.WRITE)
 old.store_string(JSON.stringify({"version":1,"currency":123,"kills":200,"runs":4,"wins":1,"best":240.0,"unlocked":[0,1,2],"completed":[0],"settings":{}}));old.close()
 var legacy=Progress.new()
 check(legacy.load_save("user://legacy-menu-profile.json") and legacy.data.silver==123 and legacy.data.kills==200,"V1 migration preserves currency and lifetime stats")
 check(MetaProgress.unlocked(profile.data,"weapons","1") and not MetaProgress.unlocked(profile.data,"weapons","35"),"Default and locked weapon entries")
 check(MetaProgress.toggle(profile.data,"weapons","1") and not MetaProgress.enabled(profile.data,"weapons","1"),"Unlocked entry disable toggle")
 check(not MetaProgress.toggle(profile.data,"weapons","35"),"Locked entry cannot be enabled")
 profile.data.kills=500;profile.data.silver=100
 check(MetaProgress.purchase(profile.data,"weapons","2") and profile.data.silver==79,"Weapon purchase charges silver once")
 check(not MetaProgress.purchase(profile.data,"weapons","2") and profile.data.silver==79,"Already owned unlock cannot charge again")
 check(MetaProgress.claim(profile.data,"first_hunt") and not MetaProgress.claim(profile.data,"first_hunt"),"Quest claims are idempotent")
 MetaProgress.claim(profile.data,"hunter")
 profile.data.silver=250
 check(MetaProgress.buy_slot(profile.data,"weapon") and profile.data.weapon_slots==3 and profile.data.silver==0,"250 silver buys third slot")
 profile.data.silver=749
 check(not MetaProgress.buy_slot(profile.data,"weapon"),"Fourth slot requires 750 silver")
 for quest in LoadoutCatalog.QUESTS:profile.data.quest_metrics[quest.metric]=1000
 for quest in LoadoutCatalog.QUESTS:MetaProgress.claim(profile.data,quest.id)
 profile.data.silver=750
 check(MetaProgress.buy_slot(profile.data,"weapon") and profile.data.weapon_slots==4,"Fourth slot purchase")
 check(not MetaProgress.buy_slot(profile.data,"weapon"),"Slot capacity cannot exceed four")
 var before=profile.data.duplicate(true)
 MetaProgress.record(profile.data,{"time":200,"kills":500,"victory":true,"weapon":1,"trait":"climber","ultimate":"nova","metrics":{"bosses":1}},true)
 check(before==profile.data,"Sandbox cannot change quests or leaderboard")
 MetaProgress.record(profile.data,{"time":200,"kills":500,"victory":true,"weapon":1,"trait":"climber","ultimate":"nova","metrics":{"bosses":1}},false)
 check(profile.data.leaderboard.size()==1 and profile.data.leaderboard[0].ultimate=="nova","Leaderboard records complete loadout")
 check(profile.save(),"V2 atomic save succeeds")
 var restored=Progress.new()
 check(restored.load_save(profile.storage_path) and restored.data.weapon_slots==4 and restored.data.leaderboard.size()==1,"V2 slot, quest and leaderboard persistence")
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://menu-game-test.json"
 game.frontend.home()
 check(game.mode=="menu" and is_instance_valid(game.frontend.menu_camera),"Main menu uses a real map camera")
 check(widgets(game.frontend.menu,"Button").size()==4,"Main menu contains exactly four action buttons")
 check(widgets(game.frontend.menu,"ProgressBar").size()==4,"Main menu shows four closest unlock progress bars")
 var old_camera=game.frontend.menu_camera.position
 game.frontend._process(0.5)
 check(old_camera!=game.frontend.menu_camera.position,"Main menu map camera rotates")
 game.selected_weapon=1
 game.frontend.play_screen()
 check(game.mode=="play" and game.selected_weapon==1,"Play opens independent loadout selection")
 game.sandbox=false;game.selected_trait="momentum";game.selected_ultimate="nova";game.next_run_seed=900
 # Deterministic flat combat fixture; map variety has separate 100-seed coverage.
 game.map_seed_override=9
 game.begin_run();game.spawn_clock=999
 check(game.character==-1 and game.weapons.has(1) and game.weapon_limit()==2,"One adventurer starts selected weapon with normal capacity")
 game.equip(0);game.equip(6)
 check(game.weapons.size()==2,"Normal run enforces two weapon slots")
 game.apply_upgrade({"type":"tome","id":"Might"});game.apply_upgrade({"type":"tome","id":"Haste"});game.apply_upgrade({"type":"tome","id":"Wind"})
 check(game.tomes.size()==2,"Normal run enforces two tome slots")
 MetaProgress.toggle(game.progress.data,"weapons","1")
 game.weapons.clear();game.equip(1)
 check(game.weapons.has(1),"Disabled weapon remains usable as a starting weapon")
 MetaProgress.toggle(game.progress.data,"weapons","0")
 var no_disabled=true
 for choice in game.upgrade_pool():
  if choice.type=="weapon" and int(choice.id)==0:no_disabled=false
 check(no_disabled,"Disabled unowned weapons excluded from upgrades")
 game.loadout_runtime.movement_charge=20
 check(is_equal_approx(game.loadout_runtime.damage_multiplier(),1.4),"Moving trait caps at +40 percent")
 game.loadout_runtime.reset("sentry","berserk");game.loadout_runtime.still_charge=10
 check(is_equal_approx(game.loadout_runtime.damage_multiplier(),1.5),"Standing trait caps at +50 percent")
 game.loadout_runtime.reset("climber","nova");game.enemies.clear()
 var e=game.spawn_enemy(0,game.player.position+Vector3(3,0,0));e.hp=10000;e.max_hp=10000
 game.rebuild_grid();var hp=e.hp
 check(game.loadout_runtime.activate(game) and e.hp<hp,"Nova damages nearby targets")
 check(not game.loadout_runtime.activate(game) and game.loadout_runtime.cooldown==90,"Ultimate cooldown prevents reuse")
 game.loadout_runtime.reset("climber","berserk");game.loadout_runtime.activate(game)
 check(game.loadout_runtime.damage_multiplier()==1.75 and game.loadout_runtime.incoming_multiplier()==0.7,"Berserker damage and defense are functional")
 game.loadout_runtime.reset("glider","ghost");game.loadout_runtime.activate(game);game.loadout_runtime.tick(game,0.1)
 check(game.loadout_runtime.immune() and game.player.movement_multiplier==2 and game.player.jump_multiplier==2,"Ghost grants immunity, speed and jump")
 game.health=100;game.invulnerability=0;game.hurt(20)
 check(game.health==100,"Ghost prevents incoming damage")
 game.loadout_runtime.tick(game,9)
 check(not game.loadout_runtime.immune() and game.player.movement_multiplier==1,"Ghost expires and restores base movement")
 game.loadout_runtime.reset("climber","nova");game.loadout_runtime.tick(game,0.1)
 check(game.player.can_climb,"Climbing trait wires wall movement")
 game.loadout_runtime.reset("glider","nova");game.loadout_runtime.tick(game,0.1)
 check(game.player.can_glide and not game.player.can_climb,"Gliding trait is exclusive")
 game.mode="pause";game.player.active=true;game.player.position=Vector3(0,10,0);game.player.velocity=Vector3(0,-8,0)
 Input.action_press("jump")
 for i in 5:await physics_frame
 Input.action_release("jump")
 check(game.player.velocity.y>=-3.01,"Holding jump slows descent while gliding")
 game.player.active=false
 game.frontend.minimap.reset(false)
 check(not game.frontend.minimap.visible_at(Vector3(60,0,60)),"Minimap begins with fog")
 game.frontend.minimap.reveal(Vector3.ZERO)
 check(game.frontend.minimap.visible_at(Vector3.ZERO) and not game.frontend.minimap.visible_at(Vector3(60,0,60)),"Exploration reveals nearby cells only")
 game.frontend.minimap.reset(true)
 check(game.frontend.minimap.visible_at(Vector3(80,0,80)),"Seer reveals the entire minimap")
 game.gold=30;game.mode="shop"
 var shop={"offers":[1],"sold":[]}
 check(game.buy_shop(shop,1,15) and game.gold==15 and shop.sold==[1],"Shop purchase applies item and deducts gold")
 check(not game.buy_shop(shop,1,15) and game.gold==15,"Shop stock cannot be purchased twice")
 check(not game.buy_shop({"offers":[1]},1,1),"Shop validates configured price")
 check(game.terrain_height(106,0)>18 and game.terrain_height(-106,0)>18 and game.terrain_height(0,106)>18,"Forest cliff boundary covers world edges")
 game.loadout_runtime.reset("seer","ghost");game.loadout_runtime.cooldown=42;game.selected_trait="seer";game.selected_ultimate="ghost";game.frontend.minimap.reset(true)
 check(game.save_run("user://menu-loadout-run.json"),"Run saves loadout and ultimate state")
 game.begin_run()
 check(game.load_run("user://menu-loadout-run.json") and game.loadout_runtime.ultimate_id=="ghost" and game.loadout_runtime.cooldown==42 and game.frontend.minimap.reveal_all,"Run resume retains ultimate cooldown and minimap")
 game.mode="pause";game.player.active=false
 game.frontend.unlocks();check(game.mode=="unlocks","Unlock browser opens")
 game.frontend.active_tab="weapons";game.frontend.unlocks()
 for button in widgets(game.frontend.menu,"Button"):
  if button.text.begins_with(Catalog.WEAPONS[16][0]):button.pressed.emit();break
 check(screen_text().contains("Unlock:") and not screen_text().contains(LoadoutCatalog.entry("weapons","16").description),"Locked detail reveals requirements without revealing effect")
 game.frontend.quests();check(game.mode=="quests","Categorized quest screen opens")
 game.frontend.settings(game.frontend.home);check(game.mode=="settings","Grouped settings open")
 game.frontend.inventory();check(game.mode=="build","Stats and item inventory open")
 game.loadout_runtime.cooldown=35
 game._physics_process(1)
 check(game.loadout_runtime.cooldown==35,"Ultimate cooldown pauses in menus")
 game.frontend.settings(game.pause_menu)
 var cancel=InputEventAction.new();cancel.action="ui_cancel";cancel.pressed=true
 game._unhandled_input(cancel)
 check(game.mode=="pause","Escape returns settings to pause rather than starting a menu run")
 game.enemies.clear();game.stage_time=0;game.elapsed=0
 var ordinary=game.spawn_enemy(0,Vector3(10,0,0)).max_hp
 game.stage_time=game.STAGE_SECONDS+120
 var overtime=game.spawn_enemy(0,Vector3(12,0,0)).max_hp
 check(overtime>ordinary*2,"Post-zero enemies escalate in strength")
 var invalid=FileAccess.open("user://menu-corrupt-test.json",FileAccess.WRITE);invalid.store_string("not json");invalid.close()
 var safe=Progress.new()
 check(not safe.load_save("user://menu-corrupt-test.json") and safe.data.has("loadout"),"Corrupt profile falls back to complete defaults")
 print("MENU RESULT: %d checks, %d failures"%[count,failures.size()])
 game.queue_free();await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)

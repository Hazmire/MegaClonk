extends SceneTree
var count=0
var failures: Array[String]=[]
var game: Node
func check(value: bool,label: String):
 count+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func run():
 var profile=Progress.new()
 check(profile.data.silver==0,"Fresh profile starts with zero silver")
 for category in ["traits","ultimates"]:
  for e in LoadoutCatalog.entries(category):check(MetaProgress.unlocked(profile.data,category,e.id),"Available from start: "+e.id)
 profile.data.silver=1000
 check(MetaProgress.buy_slot(profile.data,"weapon") and profile.data.silver==750 and profile.data.weapon_slots==3,"Third weapon slot costs 250 silver")
 check(MetaProgress.buy_slot(profile.data,"weapon") and profile.data.silver==0 and profile.data.weapon_slots==4,"Fourth weapon slot costs 750 silver in sequence")
 check(profile.data.tome_slots==2 and not MetaProgress.buy_slot(profile.data,"tome"),"Tome capacity independent and insufficient balance rejected")
 var old={"credits":40,"quest_gold":70,"kills":0};MetaProgress.migrate(old);MetaProgress.migrate(old)
 check(old.silver==110,"Legacy wallet migration preserves combined balance exactly once")
 var all_reachable=true;var smooth=true
 for seed_value in range(30):
  for point in [Vector2(48,24),Vector2(-48,-24),Vector2(0,48),Vector2(-42,30)]:all_reachable=all_reachable and ForestMap.reachable(seed_value,point)
  for x in range(-66,67,6):
   for z in range(-66,67,6):smooth=smooth and ForestMap.normal(seed_value,x,z).y>=cos(deg_to_rad(28))
 check(all_reachable,"30 forest seeds have connected portal/objective regions")
 check(smooth,"Broad planar terrain has no steep internal noise spikes")
 var random=RandomNumberGenerator.new();random.seed=25
 for id in Catalog.ACTIVE_WEAPONS:
  var proposals={}
  for i in 40:proposals[WeaponUpgrades.proposal(id,random).attribute]=true
  check(proposals.size()>=3,"Weapon %d has meaningful distinct upgrade attributes"%id)
 check("ricochet" in WeaponUpgrades.pool(7) and "velocity" in WeaponUpgrades.pool(7),"Revolver supports ricochet and velocity")
 check(not "ricochet" in WeaponUpgrades.pool(0) and not "count" in WeaponUpgrades.pool(13),"Inapplicable attributes excluded from melee/beam pools")
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://milestone-profile.json";game.selected_weapon=7;game.next_run_seed=453;game.selected_trait="momentum";game.map_seed_override=9;game.begin_run();game.terrain_version=3;game.build_stage();game.resume();game.mode="pause";game.player.active=false;game.enemies.clear();game.stats.crit=0
 check(ImportedArt.mesh("res://assets/quaternius/nature/CommonTree_1.gltf",7).get_surface_count()>0,"Supplied forest model loads and batches")
 check(UIAssets.icon("weapons","0").resource_path.contains("assets/icons/weapons"),"Undead skill icon is used")
 check(UIAssets.icon("items","whetstone").resource_path=="res://assets/icons/items/whetstone.png","Final item art is used")
 check(game.sound_bank.has("hit") and game.sound_bank.has("level"),"Supplied sound events load")
 for id in ["blood_burst","impact_concrete","explosion_small","smoke_puff","sparks_shower","fire_torch","muzzle_front"]:
  check(CombatFX.sprite_frames(id).get_frame_count("default")>1,"PSX flipbook imports: "+id)
 var e=game.spawn_enemy(0,game.player.position+Vector3(2,0,0));e.hp=5;game.rebuild_grid();game.hit(e,500,7)
 check(is_equal_approx(game.measured_dps(7),0.5),"Measured DPS excludes overkill")
 check(e.hit_time>0,"Enemy hit starts brief white flash timer")
 game.stats.evasion=0;game.invulnerability=0;game.hurt(5)
 check(game.player.avatar.flashing and game.player.hurt_time>0,"Actual player damage starts red flash")
 var hp=game.health;game.hurt(5)
 check(game.health==hp,"Invulnerability prevents repeated damage flashes/hits")
 game.player.avatar.set_damage_flash(false)
 check(not game.player.avatar.flashing,"Player overlay restores without changing base materials")
 game.elapsed+=11;check(game.measured_dps(7)==0,"Measured DPS decays to zero after inactive window")
 var state=game.weapons[7];var previous=WeaponUpgrades.damage(7,state)
 game.apply_upgrade({"type":"weapon","id":7,"attribute":"damage","step":0.06,"expected_level":1})
 check(WeaponUpgrades.damage(7,state)>previous and state.level==2,"Damage upgrade applies immediately")
 game.apply_upgrade({"type":"weapon","id":7,"attribute":"damage","step":0.06,"expected_level":1})
 check(state.level==2,"Stale upgrade card cannot apply twice")
 check(game.weapon_tooltip(7).contains("Measured DPS") and game.weapon_tooltip(7).contains("Estimated"),"Build tooltip distinguishes actual and estimated DPS")
 check(not WeaponUpgrades.apply(0,{}, {"attribute":"ricochet","step":1}),"Impossible weapon upgrade rejected")
 game.mode="run";game.enemies.clear();game.loadout_runtime.reset("momentum","nova");game.player.velocity=Vector3(4,0,0);game.loadout_runtime.tick(game,20)
 check(is_equal_approx(game.loadout_runtime.damage_multiplier(),1.4),"Momentum reaches 40 percent in 20 moving seconds")
 game.player.velocity=Vector3.ZERO;game.loadout_runtime.tick(game,1)
 check(is_equal_approx(game.loadout_runtime.damage_multiplier(),1.4),"Momentum retains bonus through one-second grace")
 game.loadout_runtime.tick(game,5)
 check(game.loadout_runtime.damage_multiplier()==1,"Momentum decays fully over five stationary seconds")
 game.loadout_runtime.reset("sentry","berserk");game.loadout_runtime.tick(game,11)
 check(game.loadout_runtime.damage_multiplier()==1.5,"Stationary trait reaches cap after grace plus ten seconds")
 game.loadout_runtime.activate(game)
 check(game.loadout_runtime.cooldown==90 and is_equal_approx(game.loadout_runtime.damage_multiplier(),2.625) and game.loadout_runtime.incoming_multiplier()==0.7,"Berserker uses revised values and multiplicative stacking")
 game.loadout_runtime.reset("climber","ghost");game.loadout_runtime.activate(game);game.loadout_runtime.tick(game,0)
 check(game.loadout_runtime.cooldown==120 and game.player.jump_multiplier==2 and game.player.collision_mask==1,"Ghost uses 120s cooldown and preserves terrain collision")
 game.mode="pause";game.player.active=false;game.enemies.clear()
 game.stage_event("miniboss_1");game.stage_event("miniboss_2")
 check(game.enemies.size()==2 and game.enemies.all(func(e):return e.encounter in BossEncounters.MINI),"Timed encounters use the existing miniboss variant pool")
 for id in ["colossus","sovereign"]:
  game.boss_variant=id;var boss=game.spawn_enemy(8,game.player.position+Vector3(10,0,0))
  check(boss.variant.attacks.size()==3 and boss.variant.mesh!=null,"Three specials and unique model: "+id)
  for action in boss.variant.attacks:
   boss.action=action;boss.target=game.player.position+Vector3(5,0,0);boss.windup=0
   Encounters.execute(game,boss)
   check(boss.state in ["recover","charging","waves"],"Boss action executes: "+action)
  if boss.state=="waves":
   var before=game.projectiles.size();Encounters.step(game,boss,0.1);check(game.projectiles.size()>before,"Soul barrage emits damaging projectiles")
 game.frontend.update_hud()
 check(game.frontend.boss_widgets.size()>=3,"Main and miniboss health bars coexist")
 var ghost=game.spawn_enemy(11,game.player.position+Vector3(20,0,0));game.stage_time=720;Encounters.step(game,ghost,0.1)
 check(ghost.speed>5.5 and ghost.speed<=10,"Endless ghost speed escalates within bounds")
 game.gold=1000;game.mode="shop"
 var shop={"tier":"Common","offers":["whetstone","salted_pork","knucklebone"],"sold":[],"used":false}
 check(game.buy_shop(shop,"whetstone",ShopSystem.price("whetstone")) and shop.used and game.mode=="run" and game.item_stacks("whetstone")==1,"Shop consumes itself and closes only after a valid purchase")
 game.mode="shop"
 check(not game.buy_shop(shop,"salted_pork",ShopSystem.price("salted_pork")) and game.gold==1000-ShopSystem.price("whetstone"),"One-purchase rule covers all items at seller")
 var offer=ShopSystem.offers("Common",game.available_items(),random);var valid=true
 var seen_tiers={}
 for i in 200:
  for id in ShopSystem.offers("Common",game.available_items(),random):seen_tiers[Catalog.item_tier(id)]=true
 check(offer.size()==3 and seen_tiers.size()==5,"Standard shop can stock every tier ("+str(seen_tiers.keys())+")")
 game.mode="pause";game.player.active=false
 check(BuildStats.value("damage",1.35)=="+35%" and not BuildStats.help("armor").is_empty(),"Stat percentages and explanatory tooltips")
 var before_count=game.combat_fx.active.size()
 for i in 100:game.combat_fx.burst("blood_burst",Vector3.ZERO)
 check(game.combat_fx.active.size()<=CombatFX.LIMIT,"Combat flipbooks respect horde budget")
 game.combat_fx.tick(20)
 check(game.combat_fx.active.is_empty() and not game.combat_fx.idle.is_empty(),"Completed effects recycle instead of leaking nodes")
 game.combat_fx.intensity=0
 check(not game.combat_fx.burst("blood_burst",Vector3.ZERO),"Zero VFX intensity disables decorative effects")
 game.mode="run";game.loadout_runtime.reset("climber","nova");game.invulnerability=0;game.health=100;game.stats.armor=0;game.stats.evasion=0;game.player.position=Vector3.ZERO
 game.enemies.clear();game.boss_variant="sovereign";var sovereign=game.spawn_enemy(8,Vector3(12,0,0));sovereign.target=Vector3.ZERO;sovereign.action="souls";game.projectiles.clear()
 Encounters.execute(game,sovereign)
 for i in 3:Encounters.step(game,sovereign,0.6)
 check(game.projectiles.size()==24 and game.projectiles[0].damage>0 and game.projectiles[0].life==4,"Soul Barrage emits three finite damaging waves")
 sovereign.action="phantom";sovereign.target=Vector3(20,0,0);var hp_before=game.health;Encounters.execute(game,sovereign)
 check(game.health==hp_before,"Phantom Explosion can be dodged by leaving marked position")
 sovereign.target=game.player.position;Encounters.execute(game,sovereign)
 check(game.health<hp_before,"Phantom Explosion damages the marked area")
 game.boss_variant="colossus";var colossus=game.spawn_enemy(8,Vector3.ZERO);colossus.action="slam";game.invulnerability=0;game.player.position=Vector3(0,3,0);hp_before=game.health;Encounters.execute(game,colossus)
 check(game.health==hp_before,"Ground Slam is avoided with a correctly timed jump")
 game.player.position=Vector3.ZERO;Encounters.execute(game,colossus)
 check(game.health<hp_before,"Ground Slam damages a grounded player in radius")
 colossus.action="thorns";game.projectiles.clear();Encounters.execute(game,colossus)
 check(game.projectiles.size()==12,"Thorn Barrage fires twelve radial projectiles")
 sovereign.action="dash";sovereign.pos=Vector3(-4,0,0);sovereign.target=Vector3(6,0,0);sovereign.charge_hit=false;game.invulnerability=0;game.player.position=Vector3.ZERO;hp_before=game.health;Encounters.execute(game,sovereign);Encounters.step(game,sovereign,0.25)
 check(game.health<hp_before and sovereign.charge_hit,"Spectral Dash damages along its swept path")
 hp_before=game.health;game.invulnerability=0;game.player.position=sovereign.pos;Encounters.step(game,sovereign,0.1)
 check(game.health==hp_before,"Spectral Dash cannot hit twice during one dash")
 var seller={}
 for object in game.interactables:
  if object.kind=="Shop":seller=object;break
 seller.used=false;seller.offers=["whetstone"];seller.sold=[];game.gold=100;game.mode="shop"
 check(game.buy_shop(seller,"whetstone",15) and not seller.node.visible,"Actual seller disappears after purchase")
 game.mode="pause";game.player.active=false
 check(game.save_run("user://milestone-run.json") and game.load_run("user://milestone-run.json"),"New encounters, weapon attributes and shops serialize together")
 game.mode="pause";game.player.active=false
 var consumed=false
 for object in game.interactables:
  if object.kind=="Shop" and object.used:consumed=consumed or not object.node.visible
 check(consumed,"Consumed seller remains absent after save/load")
 check(not game.stats.has("revives") and not game.stats.has("ultimate_haste"),"Retired Phoenix Seal / Timekeeper stats no longer exist")
 game.mode="pause";game.player.active=false
 if FileAccess.file_exists("user://milestone-run.json"):DirAccess.remove_absolute("user://milestone-run.json")
 game.queue_free();await process_frame;await process_frame
 print("MILESTONE RESULT: %d checks, %d failures"%[count,failures.size()]);quit(0 if failures.is_empty() else 1)

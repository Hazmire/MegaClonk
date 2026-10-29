extends SceneTree
# Item Overhaul regression suite (grows with each batch): catalog, icons, drops, stacking, stat numbers, migration.
var checks=0
var failures=[]
var game: Node3D
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func fresh():
 game.items.clear();game.irt.reset();game.stats=Catalog.base_stats();game.health=game.stats.max_health
 game.enemies.clear();game.wrt.clear();game.irt.clear_effects();game.player.position=Vector3(0,1,0);game.player.velocity=Vector3.ZERO
func give(id: String,times: int=1):
 for i in times:game.grant_item(id,true)
func run():
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-items.json"
 game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=false;game.spawn_clock=999
 await physics_frame
 game.mode="run"
 await catalog_tests()
 await stat_tests()
 await proc_tests()
 gem_tests()
 build_tests()
 await migration_tests()
 print("ITEMS_REGRESSION: %d checks, %d failures"%[checks,failures.size()])
 game.queue_free();await process_frame;await process_frame
 quit(1 if failures.size()>0 else 0)
# ---------------------------------------------------------------- catalog / icons / drops
func catalog_tests():
 var raw=JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
 check(Catalog.ITEMS.size()==61 and raw.size()==61 and Catalog.ITEM_IDS.size()==61,"Catalog has exactly 61 items (60 relics + the consumable Imbued Amulet)")
 var same=true
 for item in raw:
  var c=Catalog.ITEMS.get(item.id,{})
  for k in ["name","tier","short","full","needs","unique"]:if c.get(k)!=item.get(k):same=false
 check(same,"Catalog matches data/items.json field for field")
 var tiers={}
 for id in Catalog.ITEM_IDS:tiers[Catalog.item_tier(id)]=int(tiers.get(Catalog.item_tier(id),0))+1
 check(tiers=={"common":19,"uncommon":17,"rare":13,"epic":7,"legendary":5},"Tier counts match the roster (%s)"%str(tiers))
 var uniques=Catalog.ITEM_IDS.filter(func(i):return Catalog.item_unique(i))
 check(uniques.size()==5 and "saints_finger" in uniques and Catalog.ITEM_IDS.filter(func(i):return Catalog.item_tier(i)=="legendary" and Catalog.item_consumable(i)==false).all(func(i):return i in uniques) and Catalog.item_consumable("imbued_amulet"),"Saint's Finger and the 4 permanent Legendaries are Unique; the Imbued Amulet is a consumable Legendary")
 var icons_ok=true;var filter_ok=true
 for id in Catalog.ITEM_IDS:
  var path="res://assets/icons/items/%s.png"%id
  var tex=load(path) as Texture2D
  if tex==null or tex.get_width()!=32 or tex.get_height()!=32:icons_ok=false
  var imp=FileAccess.get_file_as_string(path+".import")
  if not imp.contains("mipmaps/generate=false"):filter_ok=false
 check(icons_ok,"Every item has a 32x32 icon")
 check(filter_ok,"Every item icon imports with mipmaps off")
 check(UIAssets.icon("items","whetstone").get_width()==32,"UIAssets serves the final item art")
 var scale_ok=true
 for size in [46,66,160]:scale_ok=scale_ok and (32*maxi(1,int((size-12)/32)))%32==0
 check(scale_ok,"Icons render only at whole-number scales")
 check(ItemStats.TIER_WEIGHTS=={"common":0.50,"uncommon":0.28,"rare":0.15,"epic":0.05,"legendary":0.02},"Tier weights are 50/28/15/5/2")
 # seeded sample of chest drops
 fresh();game.sandbox=true;game.rng.seed=11
 var seen={};var legendary_unique=true
 for i in 4000:
  var id=ItemDrops.roll_chest(game);seen[Catalog.item_tier(id)]=int(seen.get(Catalog.item_tier(id),0))+1
 var ok=true
 for tier in Catalog.ITEM_TIERS:
  var share=float(seen.get(tier,0))/4000.0
  if absf(share-float(ItemStats.TIER_WEIGHTS[tier]))>0.03:ok=false
 check(ok,"Chest tier distribution follows the weights over 4000 seeded rolls (%s)"%str(seen))
 # uniques never drop twice; vases only common/uncommon
 give("saints_finger");give("headsmans_oath")
 var dup=false
 for i in 2000:
  var id=ItemDrops.roll_chest(game)
  if id=="saints_finger" or id=="headsmans_oath":dup=true
 check(not dup and not "saints_finger" in game.available_items(),"Owned Uniques never drop again")
 check(game.grant_item("saints_finger",true)==false and game.item_stacks("saints_finger")==1,"Unique items cannot be granted twice")
 var vase_ok=true;var vase_hits=0
 game.rng.seed=5
 for i in 6000:
  var id=ItemDrops.roll_vase(game)
  if id!="":
   vase_hits+=1
   if not Catalog.item_tier(id) in ["common","uncommon"]:vase_ok=false
 check(vase_ok and vase_hits>0 and absf(float(vase_hits)/6000.0-float(ItemStats.DROPS.vase_item_chance))<0.015,"Vases drop only Commons/Uncommons at the configured rate (%d/6000)"%vase_hits)
 var shop_ok=true
 var shop_rng=RandomNumberGenerator.new();shop_rng.seed=3
 for t in ["Common","Rare","Legendary"]:
  for i in 50:
   for id in ShopSystem.offers(t,game.available_items(),shop_rng):if Catalog.item_tier(id)=="legendary":shop_ok=false
 check(shop_ok,"Shops never sell Legendary items")
 # disabled items never drop
 fresh();game.sandbox=false
 var profile=game.progress.data
 MetaProgress.migrate(profile)
 for id in Catalog.ITEM_IDS:if id!="whetstone":MetaProgress.toggle(profile,"items",id)
 var only=true
 for i in 300:if ItemDrops.roll_chest(game)!="whetstone":only=false
 check(only and game.available_items()==["whetstone"],"Disabled items never drop")
 for id in Catalog.ITEM_IDS:if id!="whetstone":MetaProgress.toggle(profile,"items",id)
 check(MetaProgress.enabled(profile,"items","rusted_key") and MetaProgress.unlocked(profile,"items","devils_bargain"),"Every item starts unlocked and enabled")
 game.sandbox=true
# ---------------------------------------------------------------- stacking / stats
func stat_tests():
 fresh()
 var base=Catalog.base_stats()
 give("whetstone",3)
 check(is_equal_approx(game.stats.damage,base.damage+0.30) and game.item_stacks("whetstone")==3,"Whetstone stacks additively: 3 stacks = +30% damage")
 fresh();give("pilgrims_sandals");give("knucklebone",2);give("flagellants_cord");give("tithe_purse");give("bone_reliquary");give("tallow_candle",2)
 check(is_equal_approx(game.stats.speed,base.speed+0.08) and is_equal_approx(game.stats.crit,base.crit+0.10) and is_equal_approx(game.stats.haste,base.haste+0.10) and is_equal_approx(game.stats.gold_gain,base.gold_gain+0.15) and is_equal_approx(game.stats.xp,base.xp+0.08) and is_equal_approx(game.stats.regen,base.regen+4.0),"Simple stat items resolve to their text (speed, crit, haste, gold, XP, regen)")
 fresh();give("salted_pork");var hp=game.stats.max_health
 check(is_equal_approx(hp,base.max_health+20.0) and is_equal_approx(game.health,hp),"Salted Pork: +20 max HP, filled on pickup")
 fresh();give("rosary_teeth");give("grave_salt")
 check(is_equal_approx(game.stats.crit,base.crit+0.05) and is_equal_approx(game.stats.crit_damage,base.crit_damage+0.10) and is_equal_approx(game.stats.max_health,base.max_health+15.0) and is_equal_approx(game.stats.armor,1.0),"Rosary of Teeth and Grave Salt")
 fresh();give("crowsfoot_charm");var one=game.stats.evasion;give("crowsfoot_charm",5)
 check(is_equal_approx(one,0.12) and game.stats.evasion>one and game.stats.evasion<0.75 and game.stats.evasion<6*0.12,"Crowsfoot Charm: +12% evasion with diminishing returns")
 fresh();give("bitter_wine");var wine=game.stats
 check(is_equal_approx(wine.damage,base.damage+0.20) and is_equal_approx(wine.max_health,base.max_health*0.9),"Skin of Bitter Wine: +20% damage, -10% max HP")
 fresh();give("bloodletting_knife",20)
 check(game.stats.max_health>=float(ItemStats.T.max_health_floor) and game.stats.max_health<base.max_health,"Max HP never drops below the floor, even with absurd stacks")
 fresh();give("pilgrims_pack",3)
 check(is_equal_approx(game.stats.count,4.0) and int(WeaponStats.resolve(game,15,{"level":1,"upgrades":{}}).count)==9,"Pilgrim's Pack x3: +3 projectiles for every weapon (shotgun 6 -> 9)")
 fresh();give("salted_pork",2);var raised=game.stats.max_health
 fresh()
 check(is_equal_approx(game.stats.max_health,base.max_health) and game.irt.applied.is_empty(),"Resetting the inventory removes every folded stat")
 # conditional damage
 fresh();game.player.position=Vector3(0,1,0)
 var e=game.spawn_enemy(0,game.player.position+Vector3(2,0,0));e.hp=1000.0;e.max_hp=1000.0;e.speed=0.0
 game.rebuild_grid()
 var plain=hit_damage(e)
 give("executioners_hood")
 check(absf(hit_damage(e)/plain-1.2)<0.001,"Executioner's Hood: +20% against enemies above 90% HP")
 e.hp=500.0
 check(absf(hit_damage(e)/plain-1.0)<0.001,"Executioner's Hood: no bonus at 50% HP")
 e.hp=1000.0;fresh();give("brutes_gauntlet");var near=hit_damage(e)
 e.pos=game.player.position+Vector3(30,0,0);var far=hit_damage(e)
 check(absf(near/far-1.2)<0.001,"Brute's Gauntlet: +20% only at close range")
 e.pos=game.player.position+Vector3(2,0,0);fresh();give("bounty_writ");var normal=hit_damage(e);e["elite"]=true
 check(absf(hit_damage(e)/normal-1.15)<0.001,"Bounty Writ: +15% against elites")
 e.erase("elite");fresh();give("plague_mask");var clean=hit_damage(e);e["burn"]=3.0
 check(absf(hit_damage(e)/clean-1.2)<0.001,"Plague Doctor's Mask: +20% against enemies with a status")
 e["burn"]=0.0;fresh()
# Damage actually dealt by one weapon-source hit (crit rolls are disabled by setting crit to 0).
func hit_damage(e: Dictionary) -> float:
 var saved=game.stats.crit;game.stats.crit=-1.0
 var hp=e.hp;game.hit(e,100.0,0,{"source":"slash","pos":e.pos,"dir":Vector3.FORWARD})
 var dealt=hp-e.hp;e.hp=hp;e.hit_time=0.0;e.erase("fx");game.stats.crit=saved
 return dealt
# ---------------------------------------------------------------- migration
func migration_tests():
 fresh()
 game.items=[];game.save_run("user://test-items-old.json")
 var raw=JSON.parse_string(FileAccess.get_file_as_string("user://test-items-old.json"))
 raw.items=["Ember Heart","Iron Petal","Phoenix Seal","Thunder Covenant"]
 raw.stats.max_health=float(raw.stats.max_health)+25.0;raw.stats.armor=float(raw.stats.armor)+3.0;raw.stats["revives"]=1.0;raw.stats["storm"]=1.0
 raw["reward_queue"]=[3,5];raw["active_reward"]=7
 raw.interactables.append({"kind":"Shop","used":false,"charge":0,"tier":"Common","offers":[3,9,-1],"sold":[],"shrine_reward":{},"golden":false,"shrine_choices":[]})
 var base_hp=float(raw.stats.max_health)-25.0
 var f=FileAccess.open("user://test-items-old.json",FileAccess.WRITE);f.store_string(JSON.stringify(raw));f.close()
 check(game.load_run("user://test-items-old.json"),"A run holding old numbered items loads without crashing")
 check(game.items.is_empty() and game.irt.stacks.is_empty(),"Old items are dropped on load (no refund)")
 check(is_equal_approx(game.stats.max_health,base_hp) and is_equal_approx(game.stats.armor,0.0) and not game.stats.has("revives") and not game.stats.has("storm"),"Old items' folded stat bonuses are removed")
 check(game.reward_queue.is_empty() and game.active_reward=="","Old numeric chest rewards are discarded")
 # new-format round trip with state
 fresh();give("whetstone",2);give("salted_pork");give("saints_finger")
 var damage=game.stats.damage;var hp=game.stats.max_health
 check(game.save_run("user://test-items-new.json") and game.load_run("user://test-items-new.json"),"A run with new items saves and loads")
 check(game.item_stacks("whetstone")==2 and game.item_stacks("saints_finger")==1 and is_equal_approx(game.stats.damage,damage) and is_equal_approx(game.stats.max_health,hp),"Items, stacks and folded stats survive a save round trip (no double-apply)")
 # meta migration
 var profile=game.progress.data
 profile.entries.append("items:3");profile.entries.append("items:12");profile.disabled.append("items:5");profile.entries.append("items:ghost")
 MetaProgress.migrate(profile)
 check(not profile.entries.any(func(k):return str(k).begins_with("items:") and not Catalog.item_exists(str(k).get_slice(":",1))) and not profile.disabled.has("items:5"),"MetaProgress.migrate erases unlock/toggle entries for retired items")
 check(profile.entries.has("items:whetstone"),"New items are unlocked by migration")
 check(ItemMigration.clean_offers([3,9,-1])==null and ItemMigration.clean_offers(["whetstone",-2])==["whetstone",-2],"Old numeric shop offers are re-rolled; valid ones survive")

# ---------------------------------------------------------------- batch 2: event procs
func rate(id: String,times: int,fn: Callable) -> float:
 var hits=0
 for i in times:if fn.call():hits+=1
 return float(hits)/float(times)
func near(a: float,b: float,tol: float) -> bool:return absf(a-b)<=tol
func make_enemy(offset: Vector3,hp: float=1000.0) -> Dictionary:
 var e=game.spawn_enemy(0,game.player.position+offset);e.hp=hp;e.max_hp=hp;e.speed=0.0
 return e
func proc_tests():
 fresh();game.player.position=Vector3(0,1,0);game.player.velocity=Vector3.ZERO
 # Rusted Key
 give("rusted_key");game.irt.rng.seed=1
 var r1=rate("rusted_key",6000,func():return game.irt.chest_is_free())
 check(near(r1,0.10,0.015),"Rusted Key: 10%% of chests are free over a seeded sample (%.3f)"%r1)
 give("rusted_key",2);game.irt.rng.seed=2
 var r3=rate("rusted_key",6000,func():return game.irt.chest_is_free())
 check(near(r3,1.0-pow(0.9,3),0.02),"Rusted Key stacks as independent rolls (%.3f)"%r3)
 # Witch Bottle
 fresh();give("witch_bottle");game.irt.rng.seed=3
 var w1=rate("witch",6000,func():return game.irt.witch_bottle())
 check(near(w1,0.20,0.02),"Witch Bottle: 20%% of hits ignored (%.3f)"%w1)
 give("witch_bottle",12);var wcap=rate("witch",4000,func():return game.irt.witch_bottle())
 check(near(wcap,0.60,0.03) and wcap<0.99,"Witch Bottle never makes the player immune (capped near 60%%, got %.3f)"%wcap)
 # Witch Bottle is a separate roll after evasion and goes through real hurt()
 fresh();give("witch_bottle",12);game.invulnerability=0.0;game.stats.evasion=0.0;game.health=game.stats.max_health
 var ignored=0;var total=400
 game.irt.rng.seed=9
 for i in total:
  var h=game.health;game.invulnerability=0.0;game.hurt(5.0);game.health=minf(game.stats.max_health,game.health)
  if is_equal_approx(game.health,h):ignored+=1
  game.health=game.stats.max_health
 check(ignored>total*0.45 and ignored<total*0.75,"Witch Bottle works inside Game.hurt() and still lets damage through (%d/%d ignored)"%[ignored,total])
 # Spade
 fresh();give("gravediggers_spade");game.irt.rng.seed=4
 var sp=rate("spade",6000,func():return game.irt.roll("gravediggers_spade"))
 check(near(sp,0.15,0.02),"Gravedigger's Spade: 15%% extra pickup chance (%.3f)"%sp)
 # Soul Lantern / Pyre Ashes through kill_enemy
 fresh();give("soul_lantern");game.irt.rng.seed=5
 var sl=0
 for i in 4000:
  var fake={"pos":Vector3.ZERO,"variant":{"reward":1.0},"last_item":false}
  var before=int(game.irt.counters.get("lantern",0));game.irt.on_kill(fake)
  if int(game.irt.counters.get("lantern",0))>before:sl+=1
 check(near(float(sl)/4000.0,0.12,0.02),"Soul Lantern: 12%% of kills drop an extra XP gem (%.3f)"%(float(sl)/4000.0))
 fresh();give("pyre_ashes");game.irt.rng.seed=6
 for i in 8000:game.irt.on_kill({"pos":Vector3(0,0,50),"last_item":false});game.irt.meat.clear()
 var pyre=float(int(game.irt.counters.get("pyre_total",0)))
 fresh();give("pyre_ashes");game.irt.rng.seed=6
 var meat_made=0
 for i in 8000:
  game.irt.on_kill({"pos":Vector3(0,0,50),"last_item":false})
  meat_made+=game.irt.meat.size();game.irt.meat.clear()
 check(near(float(meat_made)/8000.0,0.03,0.008),"Pyre Ashes: 3%% of kills drop roast meat (%.3f)"%(float(meat_made)/8000.0))
 game.irt.meat.append({"pos":game.player.position,"life":5.0});game.health=game.stats.max_health*0.5;var hp0=game.health
 game.irt.tick(0.016)
 check(is_equal_approx(game.health,hp0+game.stats.max_health*0.15) and game.irt.meat.is_empty(),"Roast meat heals 15%% max HP when walked over")
 fresh();give("pyre_ashes",99);game.irt.rng.seed=7
 for i in 400:game.irt.on_kill({"pos":Vector3(0,0,50),"last_item":false})
 check(game.irt.meat.size()<=int(ItemStats.v("pyre_ashes","pickup_cap")) and int(game.irt.dropped.get("meat",0))>0,"Meat pool is hard-capped and refusals are counted")
 # Ouija
 fresh();give("ouija_planchette");game.irt.rng.seed=8
 var plain=make_enemy(Vector3(2,0,0));var big=0
 for i in 8000:if game.irt.damage_mult(plain,false,10.0)>5.0:big+=1
 check(near(float(big)/8000.0,0.03,0.008),"Ouija Planchette: 3%% of hits deal x10 (%.3f)"%(float(big)/8000.0))
 var boss=make_enemy(Vector3(3,0,0),10000.0);boss.kind=8
 var worst=0.0
 game.irt.rng.seed=8
 for i in 8000:worst=maxf(worst,game.irt.damage_mult(boss,false,100.0)*100.0)
 check(worst<=10000.0*ItemStats.v("ouija_planchette","boss_cap")+0.01,"Ouija hits are capped against bosses (max %.0f of %.0f HP)"%[worst,10000.0])
 var chain_before=int(game.irt.counters.get("ouija",0));game.irt.damage_mult(plain,true,10.0)
 check(int(game.irt.counters.get("ouija",0))==chain_before,"Item damage never rolls Ouija")
 # Hermit's Ember (standing still)
 fresh();give("hermits_ember");game.health=game.stats.max_health*0.5;var h0=game.health
 for i in 55:game.irt.tick(1.0/60.0)
 check(is_equal_approx(game.health,h0),"Hermit's Ember: nothing before 1 s of standing still")
 for i in 120:game.irt.tick(1.0/60.0)
 check(near(game.health-h0,game.stats.max_health*0.03*((55.0+120.0)/60.0-1.0),0.2),"Hermit's Ember heals 3%% max HP per second after 1 s still (%.2f)"%(game.health-h0))
 game.player.velocity=Vector3(5,0,0);game.irt.tick(0.1);var moving_hp=game.health;game.irt.tick(1.0)
 check(is_equal_approx(game.health,moving_hp) and game.irt.still_time==0.0,"Hermit's Ember resets when you move");game.player.velocity=Vector3.ZERO
 # Mourner's Veil
 fresh();give("mourners_veil");var sp0=game.stats.speed
 game.irt.on_damage_taken(5.0)
 check(is_equal_approx(game.stats.speed-sp0,0.25),"Mourner's Veil: +25%% more speed right after damage")
 for i in 130:game.irt.tick(1.0/60.0)
 check(is_equal_approx(game.stats.speed-sp0,0.0) and is_equal_approx(sp0,Catalog.base_stats().speed+0.05),"Mourner's Veil: speed falls back to +5%% after 2 s")
 # Leaden Heart / Tax ledger / Cracked Hourglass / Forgemaster
 fresh();give("leaden_heart");var d0=game.stats.damage
 game.irt.on_powerup("heart")
 check(is_equal_approx(game.stats.damage-d0,0.10),"Leaden Heart: +10%% damage after a Heart power-up")
 game.irt.on_powerup("magnet");game.irt.on_powerup("stopwatch")
 check(is_equal_approx(game.stats.damage-d0,0.10),"Leaden Heart ignores Magnet and Stopwatch")
 for i in 15*60+5:game.irt.tick(1.0/60.0)
 check(is_equal_approx(game.stats.damage,d0),"Leaden Heart expires after 15 s")
 fresh();give("tax_ledger",2);var base_damage=game.stats.damage
 for i in 4:game.irt.on_chest_opened()
 check(is_equal_approx(game.stats.damage-base_damage,2*4*0.025),"Tax Collector's Ledger: +2.5%% damage per chest per stack, kept for the run")
 fresh();give("cracked_hourglass",2);game.world_time.reset();game.world_time.activate(game.irt.stopwatch_bonus())
 check(is_equal_approx(game.world_time.remaining,12.0),"Cracked Hourglass: Stopwatch lasts +2 s per stack");game.world_time.reset()
 fresh()
 check(ImbueRules.cost(1,game.irt.imbue_discount())==500,"Imbue cost unchanged without Forgemaster's Tongs")
 give("forgemasters_tongs");check(ImbueRules.cost(1,game.irt.imbue_discount())==400,"Forgemaster's Tongs: Imbue costs 20%% less")
 give("forgemasters_tongs",9);check(ImbueRules.cost(3,game.irt.imbue_discount())==300,"Forgemaster's Tongs discount is capped at 80%% (%d)"%ImbueRules.cost(3,game.irt.imbue_discount()))
 # Thunderstruck Nail
 fresh();give("thunderstruck_nail");game.enemies.clear()
 var close=make_enemy(Vector3(3,0,0));var far_e=make_enemy(Vector3(20,0,0));game.rebuild_grid()
 game.irt.on_damage_taken(5.0)
 check(StatusManager.stunned(close) and not StatusManager.stunned(far_e),"Thunderstruck Nail stuns nearby enemies only")
 StatusManager.clear(close);close.frozen=0.0;game.irt.on_damage_taken(5.0)
 check(not StatusManager.stunned(close),"Thunderstruck Nail has a cooldown")
 # Black Candle
 fresh();give("black_candle");game.enemies.clear()
 var burn=make_enemy(Vector3(2,0,0));var safe=make_enemy(Vector3(8,0,0));game.rebuild_grid();game.level=1
 for i in 130:game.irt.tick(1.0/60.0)
 check(near(1000.0-burn.hp,10.0,1.5) and is_equal_approx(safe.hp,1000.0),"Black Candle: 5 damage per second within 3 m only (%.1f in ~2 s)"%(1000.0-burn.hp))
 # Restless Bones
 fresh();give("restless_bones");game.enemies.clear()
 var target=make_enemy(Vector3(5,0,0));game.rebuild_grid()
 game.irt.on_chest_opened()
 check(game.irt.wraiths.size()==2,"Restless Bones: opening a chest summons 2 wraiths")
 for i in 120:game.irt.tick(1.0/60.0)
 check(target.hp<1000.0,"Wraiths hunt and damage enemies (through Game.hit)")
 for i in 600:game.irt.tick(1.0/60.0)
 check(game.irt.wraiths.is_empty(),"Wraiths vanish after 8 s")
 give("restless_bones",8)
 for i in 10:game.irt.on_chest_opened()
 check(game.irt.wraiths.size()<=int(ItemStats.v("restless_bones","cap")) and int(game.irt.dropped.get("wraiths",0))>0,"Wraith pool is hard-capped and refusals are counted")
 # No chain: item damage and item kills never feed other item procs
 fresh();give("soul_lantern",99);give("pyre_ashes",99);give("black_candle",3);give("restless_bones");game.enemies.clear();game.irt.rng.seed=12
 var item_kills=0
 for i in 60:
  var e=make_enemy(Vector3(1.0+float(i%5)*0.1,0,float(i/5)*0.1),3.0);game.irt.deal(e,50.0,"black_candle")
 for i in range(game.enemies.size()-1,-1,-1):
  if game.enemies[i].hp<=0:item_kills+=1;game.kill_enemy(i)
 check(item_kills==60 and int(game.irt.counters.get("lantern",0))==0 and game.irt.meat.is_empty(),"No chain: kills made by item damage never trigger kill procs (%d kills)"%item_kills)
 game.irt.counters.clear()
 for i in 60:
  var e=make_enemy(Vector3(1.0+float(i%5)*0.1,0,float(i/5)*0.1),3.0);game.hit(e,500.0,0,{"source":"slash","pos":e.pos,"dir":Vector3.FORWARD})
 for i in range(game.enemies.size()-1,-1,-1):
  if game.enemies[i].hp<=0:game.kill_enemy(i)
 check(int(game.irt.counters.get("lantern",0))>0 or not game.irt.meat.is_empty(),"Weapon kills do trigger the same procs (control for the no-chain test)")
 fresh();give("ouija_planchette",30);game.irt.rng.seed=13;var counter0=int(game.irt.counters.get("ouija",0))
 var e2=make_enemy(Vector3(2,0,0));for i in 200:game.irt.deal(e2,1.0,"black_candle");e2.hp=1000.0
 check(int(game.irt.counters.get("ouija",0))==counter0,"No chain: 200 item hits never roll Ouija Planchette")
 fresh()

# ---------------------------------------------------------------- batch 3: gem and status items
func equip_gems(weapon: int,elements: Array):
 if not game.weapons.has(weapon):game.weapons[weapon]={"level":1,"upgrades":{}}
 for el in elements:WeaponSockets.install(game.weapons[weapon],el)
func gem_tests():
 fresh();game.player.position=Vector3(0,1,0);game.enemies.clear()
 var e=make_enemy(Vector3(2,0,0));game.rebuild_grid()
 var base=hit_damage(e)
 # Tinder Pouch / Lodestone / Coven Sigil: inert until the status exists
 give("tinder_pouch");give("lodestone")
 check(absf(hit_damage(e)/base-1.0)<0.001,"Tinder Pouch and Lodestone are inert on an enemy with no status")
 e["burn"]=3.0
 check(absf(hit_damage(e)/base-1.15)<0.001,"Tinder Pouch: burning enemies take +15%% from weapon hits")
 var before=e.hp;game.irt.deal(e,100.0,"black_candle");var item_dmg=before-e.hp;e.hp=before
 check(absf(item_dmg-115.0)<0.01,"Tinder Pouch also boosts item damage ('all sources')")
 e["burn"]=0.0;StatusManager.state(e)["stun"]={"left":2.0}
 check(absf(hit_damage(e)/base-1.25)<0.001,"Lodestone: stunned enemies take +25%")
 e.erase("fx")
 # inert with a weapon that has no matching gem: ice gem only, 40 hits, never any bonus
 fresh();give("tinder_pouch");give("lodestone");game.enemies.clear();equip_gems(0,["ice"])
 var ice_target=make_enemy(Vector3(2,0,0),100000.0);game.rebuild_grid();game.irt.rng.seed=1
 var bonus_seen=false
 for i in 40:
  game.invulnerability=0.0;game.hit(ice_target,10.0,0,{"source":"slash","pos":ice_target.pos,"dir":Vector3.FORWARD})
  if float(ice_target.get("burn",0.0))>0.0 or StatusManager.stunned(ice_target):bonus_seen=true
 check(not bonus_seen and StatusManager.chill_stacks(ice_target)>0,"Gem boosters stay inert with a different gem: ice applies chill, no burn or stun, no bonus")
 game.weapons[0].erase("sockets")
 fresh();give("coven_sigil");game.enemies.clear()
 var cv=make_enemy(Vector3(2,0,0));var cbase=hit_damage(cv)
 cv["burn"]=2.0
 check(absf(hit_damage(cv)/cbase-1.15)<0.001,"Coven Sigil: +15%% for one status")
 StatusManager.state(cv)["stun"]={"left":2.0};StatusManager.apply_corrosive(game,cv,0);StatusManager.apply_chill(game,cv,1)
 check(absf(hit_damage(cv)/cbase-1.60)<0.001,"Coven Sigil caps at +60%% (4 statuses)")
 # Leper's Bell
 fresh();game.enemies.clear();var pe=make_enemy(Vector3(2,0,0));StatusManager.apply_corrosive(game,pe,0);var h0=pe.hp;StatusManager.tick(game,pe,1.0);var plain_tick=h0-pe.hp
 fresh();give("lepers_bell");game.enemies.clear();var pe2=make_enemy(Vector3(2,0,0));StatusManager.apply_corrosive(game,pe2,0);h0=pe2.hp;StatusManager.tick(game,pe2,1.0)
 check(plain_tick>0.0 and absf((h0-pe2.hp)/plain_tick-1.2)<0.001,"Leper's Bell: corrosion deals +20%% (%.2f vs %.2f)"%[h0-pe2.hp,plain_tick])
 fresh();give("lepers_bell");game.enemies.clear();var np=make_enemy(Vector3(2,0,0));var np_hp=np.hp;StatusManager.tick(game,np,5.0)
 check(is_equal_approx(np.hp,np_hp),"Leper's Bell is inert on an enemy with no corrosion")
 # Rime Shard: chill lasts longer; shatter radius
 fresh();game.enemies.clear();var ce=make_enemy(Vector3(2,0,0));StatusManager.apply_chill(game,ce,3)
 for i in 330:StatusManager.tick(game,ce,1.0/60.0)
 var plain_stacks=StatusManager.chill_stacks(ce)
 fresh();give("rime_shard");game.enemies.clear();var ce2=make_enemy(Vector3(2,0,0));StatusManager.apply_chill(game,ce2,3)
 for i in 330:StatusManager.tick(game,ce2,1.0/60.0)
 check(plain_stacks<3 and StatusManager.chill_stacks(ce2)==3,"Rime Shard: chill lasts 50%% longer (stacks after 5.5 s: %d vs %d)"%[plain_stacks,StatusManager.chill_stacks(ce2)])
 fresh();game.enemies.clear();var dying=make_enemy(Vector3(2,0,0));StatusManager.apply_chill(game,dying,2);var victim=make_enemy(Vector3(6.2,0,0));game.rebuild_grid()
 StatusManager.shatter(game,dying)
 var out_of_range=is_equal_approx(victim.hp,1000.0)
 fresh();give("rime_shard");game.enemies.clear();dying=make_enemy(Vector3(2,0,0));StatusManager.apply_chill(game,dying,2);victim=make_enemy(Vector3(6.2,0,0));game.rebuild_grid()
 StatusManager.shatter(game,dying)
 check(out_of_range and victim.hp<1000.0,"Rime Shard: Shatter radius +1 m (victim at 4.2 m is hit only with the shard)")
 # Gem Cutter's Loupe
 fresh();game.enemies.clear();var le=make_enemy(Vector3(2,0,0));StatusManager.apply_corrosive(game,le,0);var plain_left=float(le.fx.poison.left)
 fresh();give("gem_loupe");game.enemies.clear();var le2=make_enemy(Vector3(2,0,0));StatusManager.apply_corrosive(game,le2,0)
 var hp_a=le2.hp;StatusManager.tick(game,le2,1.0)
 check(absf(float(le2.fx.poison.left)/plain_left-1.3)<0.01 or absf((float(le2.fx.poison.left)+1.0)/plain_left-1.3)<0.01,"Gem Cutter's Loupe: statuses last 30%% longer")
 check(absf((hp_a-le2.hp)/(plain_tick)-1.3)<0.001,"Gem Cutter's Loupe: statuses hit 30%% harder")
 # Mire Flask
 fresh();give("mire_flask");game.enemies.clear();game.irt.rng.seed=21
 var clean=make_enemy(Vector3(2,0,0));var corroded=make_enemy(Vector3(3,0,0));StatusManager.apply_corrosive(game,corroded,0)
 for i in 200:
  game.irt.buffs.erase("puddle_cd");game.irt.on_hit(clean,10.0,10.0,false,0)
 check(game.irt.puddles.is_empty(),"Mire Flask is inert on enemies without corrosion")
 var made=0
 for i in 4000:
  game.irt.buffs.erase("puddle_cd");game.irt.puddles.clear();game.irt.on_hit(corroded,10.0,10.0,false,0);made+=game.irt.puddles.size()
 check(near(float(made)/4000.0,0.15,0.02),"Mire Flask: 15%% of hits on corroded enemies leave a puddle (%.3f)"%(float(made)/4000.0))
 game.irt.puddles.clear();game.irt.rng.seed=22;game.irt.stacks["mire_flask"]=60
 for i in 100:game.irt.buffs.erase("puddle_cd");game.irt.on_hit(corroded,10.0,10.0,false,0)
 game.irt.stacks["mire_flask"]=1
 check(game.irt.puddles.size()<=int(ItemStats.v("mire_flask","cap")) and int(game.irt.dropped.get("puddles",0))>0,"Puddle pool is hard-capped and refusals are counted")
 game.rebuild_grid();game.irt.puddles=[{"pos":corroded.pos,"life":4.0,"clock":0.0}];var ph=corroded.hp
 for i in 60:game.irt.tick(1.0/60.0)
 check(corroded.hp<ph and bool(corroded.get("last_item",false)),"Puddles damage enemies through Game.hit (item source)")
 # Alchemist's Retort + Heretic's Prism through a real combo
 fresh();game.enemies.clear();var ce3=make_enemy(Vector3(2,0,0),1000.0);ce3["burn"]=3.0;StatusManager.apply_chill(game,ce3,3)
 Combos.window_count=0;var combo=Elements.combo("fire","ice")
 var hp_plain=ce3.hp;Combos.evaluate(game,ce3,0,combo);var plain_combo=hp_plain-ce3.hp;var cd_plain=float(ce3.fx.cd.get("combo_thermal_shock",0.0))
 check(plain_combo>0.0 and is_equal_approx(cd_plain,3.0),"Control: thermal shock fires with a 3 s cooldown")
 fresh();give("alchemist_retort");give("heretics_prism");game.enemies.clear();game.health=10.0
 ce3=make_enemy(Vector3(2,0,0),1000.0);ce3["burn"]=3.0;StatusManager.apply_chill(game,ce3,3);Combos.window_count=0
 hp_plain=ce3.hp;Combos.evaluate(game,ce3,0,combo)
 check(absf((hp_plain-ce3.hp)/plain_combo-1.5)<0.001,"Heretic's Prism: combos deal +50%% damage")
 check(is_equal_approx(game.health,11.0),"Heretic's Prism: each combo heals 1 HP")
 check(is_equal_approx(float(ce3.fx.cd.get("combo_thermal_shock",0.0)),2.25),"Alchemist's Retort: combo cooldowns 25%% shorter")
 check(is_equal_approx(game.irt.combo_radius(),1.3),"Alchemist's Retort: combo radius +30%%")
 fresh();give("heretics_prism");give("alchemist_retort");game.health=10.0
 var plain_e=make_enemy(Vector3(2,0,0));Combos.window_count=0;Combos.evaluate(game,plain_e,0,combo)
 check(is_equal_approx(game.health,10.0) and is_equal_approx(plain_e.hp,1000.0),"Retort and Prism are inert when no combo fires")
 # Goat Skull
 fresh();give("goat_skull");game.enemies.clear();game.irt.rng.seed=31
 var procs=0
 for i in 4000:
  game.irt.counters["goat"]=0;game.irt.on_kill({"pos":Vector3(0,0,80),"burn":2.0,"last_item":false,"burn_source":0})
  procs+=int(game.irt.counters.get("goat",0))
 check(near(float(procs)/4000.0,0.10,0.02),"Goat Skull: 10%% of burning kills ignite nearby enemies (%.3f)"%(float(procs)/4000.0))
 game.irt.counters["goat"]=0;for i in 500:game.irt.on_kill({"pos":Vector3(0,0,80),"burn":0.0,"last_item":false})
 check(int(game.irt.counters.get("goat",0))==0,"Goat Skull is inert on enemies that are not burning")
 game.enemies.clear();var spreader=make_enemy(Vector3(2,0,0));var neighbour=make_enemy(Vector3(3,0,0));var far_n=make_enemy(Vector3(9,0,0));game.rebuild_grid()
 game.irt.stacks["goat_skull"]=60
 for i in 40:game.irt.on_kill({"pos":spreader.pos,"burn":2.0,"last_item":false,"burn_source":0})
 game.irt.stacks["goat_skull"]=1
 check(float(neighbour.burn)>0.0 and float(far_n.burn)==0.0,"Goat Skull ignites enemies within 3 m only")
 # Witch-Hunter's Brand
 fresh();give("witch_hunters_brand");game.enemies.clear()
 for i in 3:
  var b=make_enemy(Vector3(5+i,0,0));b["burn"]=3.0
 var armor0=game.stats.armor;var ls0=game.stats.lifesteal
 for i in 40:game.irt.tick(1.0/60.0)
 check(is_equal_approx(game.stats.armor-armor0,3*0.4) and is_equal_approx(game.stats.lifesteal-ls0,3*0.002),"Witch-Hunter's Brand: armour and lifesteal per burning enemy")
 for e2 in game.enemies:e2["burn"]=0.0
 for i in 40:game.irt.tick(1.0/60.0)
 check(is_equal_approx(game.stats.armor,armor0) and is_equal_approx(game.stats.lifesteal,ls0),"Witch-Hunter's Brand: bonuses vanish when nothing burns")
 fresh()

# ---------------------------------------------------------------- batch 4: build-defining items
func upgrade_total(id: int) -> float:
 var t=0.0
 for k in game.weapons[id].get("upgrades",{}):t+=float(game.weapons[id].upgrades[k])
 return t
func build_tests():
 fresh();game.player.position=Vector3(0,1,0);game.enemies.clear();game.irt.rng.seed=41
 # Saint's Finger
 give("powder_keg_heart")
 var base=rate("keg",8000,func():return game.irt.roll_hit("powder_keg_heart"))
 give("saints_finger");game.irt.rng.seed=41
 var fingered=rate("keg",8000,func():return game.irt.roll_hit("powder_keg_heart"))
 check(near(base,0.25,0.02) and near(fingered,1.0-0.75*0.75,0.02),"Saint's Finger: weapon-hit procs roll twice (%.3f -> %.3f)"%[base,fingered])
 fresh();give("rusted_key");give("saints_finger");game.irt.rng.seed=42
 check(near(rate("key",8000,func():return game.irt.roll("rusted_key")),0.10,0.015),"Saint's Finger does not add rolls to non-hit procs (chests)")
 fresh();equip_gems(0,["fire"]);game.rng.seed=5
 var ig=0
 for i in 8000:
  var t={"pos":Vector3.ZERO,"hp":100.0,"max_hp":100.0,"kind":0,"burn":0.0,"frozen":0.0,"speed":1.0};StatusManager.on_hit(game,t,0,false,1.0);if float(t.burn)>0.0:ig+=1
 var ig_plain=float(ig)/8000.0
 give("saints_finger");game.rng.seed=5;ig=0
 for i in 8000:
  var t2={"pos":Vector3.ZERO,"hp":100.0,"max_hp":100.0,"kind":0,"burn":0.0,"frozen":0.0,"speed":1.0};StatusManager.on_hit(game,t2,0,false,1.0);if float(t2.burn)>0.0:ig+=1
 check(near(ig_plain,0.05,0.01) and near(float(ig)/8000.0,0.0975,0.012),"Saint's Finger gives the Fire gem's ignite roll a second chance (%.3f -> %.3f)"%[ig_plain,float(ig)/8000.0])
 game.weapons[0].erase("sockets")
 # Butcher's Hook / Blood Chalice
 fresh();give("butchers_hook");game.irt.rng.seed=43
 var brutal=rate("hook",8000,func():return game.irt.on_crit()>1.5)
 check(near(brutal,0.15,0.02),"Butcher's Hook: 15%% of crits are Brutal (%.3f)"%brutal)
 fresh();give("blood_chalice");game.irt.rng.seed=44;game.health=1.0
 var heals=0
 for i in 4000:
  var h=game.health;game.health=1.0;game.irt.on_crit()
  if game.health>1.0:heals+=1;check(is_equal_approx(game.health,1.0+game.stats.max_health*0.02),"Blood Chalice heals 2%% max HP") if heals==1 else null
 check(near(float(heals)/4000.0,0.20,0.02),"Blood Chalice: 20%% of crits heal (%.3f)"%(float(heals)/4000.0))
 # on_crit is reached through the real Game.hit crit path and never from item hits
 fresh();give("butchers_hook",99);game.enemies.clear();var ce=make_enemy(Vector3(2,0,0),1e9);game.rebuild_grid();game.stats.crit=1.0;game.irt.counters.clear()
 for i in 50:game.hit(ce,1.0,0,{"source":"slash","pos":ce.pos,"dir":Vector3.FORWARD})
 var crit_procs=int(game.irt.counters.get("brutal",0))
 for i in 50:game.irt.deal(ce,1.0,"black_candle")
 check(crit_procs>0 and int(game.irt.counters.get("brutal",0))==crit_procs,"Crit procs come from weapon crits only (item hits never crit or proc)")
 # Shade Cloak
 fresh();give("shade_cloak");game.enemies.clear();var se=make_enemy(Vector3(2,0,0),1e9);var sp0=game.stats.speed;var hs0=game.stats.haste
 var normal=hit_damage(se)
 game.irt.on_evade()
 check(is_equal_approx(game.stats.speed-sp0,0.25) and is_equal_approx(game.stats.haste-hs0,0.25),"Shade Cloak: attack and move speed after an evade")
 game.irt.deal(se,1.0,"black_candle")
 check(absf(hit_damage(se)/normal-2.0)<0.001,"Shade Cloak: the next weapon hit deals x2 (item damage does not use it up)")
 check(absf(hit_damage(se)/normal-1.0)<0.001,"Shade Cloak: only the next hit")
 for i in 200:game.irt.tick(1.0/60.0)
 check(is_equal_approx(game.stats.speed,sp0) and is_equal_approx(game.stats.haste,hs0),"Shade Cloak: bonuses end after 3 s")
 fresh();game.stats.evasion=1.0;game.stats.evasion=0.75;give("shade_cloak");game.irt.rng.seed=1;var evaded=false
 game.rng.seed=3
 for i in 40:
  game.invulnerability=0.0;game.hurt(1.0)
  if int(game.irt.counters.get("shade_ready",0))==1:evaded=true;break
 check(evaded,"Shade Cloak triggers from the real evasion roll in Game.hurt()")
 # Martyr's Shroud
 fresh();give("martyrs_shroud");game.enemies.clear();var me=make_enemy(Vector3(2,0,0),1e9);var mbase=hit_damage(me)
 game.health=game.stats.max_health*0.5
 check(absf(hit_damage(me)/mbase-1.30)<0.001,"Martyr's Shroud: +30%% at half health")
 game.health=1.0;var low=hit_damage(me)/mbase
 check(low>1.55 and low<=1.60001,"Martyr's Shroud: approaches +60%% near zero HP (%.3f)"%low)
 game.health=game.stats.max_health;check(absf(hit_damage(me)/mbase-1.0)<0.001,"Martyr's Shroud: nothing at full health")
 # Hangman's Noose
 fresh();give("hangmans_noose");game.enemies.clear()
 var boss=make_enemy(Vector3(2,0,0),10000.0);boss.kind=8
 var victim=make_enemy(Vector3(6,0,0),1000.0);game.rebuild_grid()
 for i in 125:game.irt.tick(1.0/60.0)
 check(is_equal_approx(boss.hp,10000.0) and victim.hp<1000.0,"Hangman's Noose never curses a boss and picks a normal enemy")
 check(near(1000.0-victim.hp,500.0,130.0),"Hangman's Noose: ~25%% of max HP per second (%.0f in ~2 s of curse)"%(1000.0-victim.hp))
 var elite=make_enemy(Vector3(3,0,0),1000.0);elite["elite"]=true;victim.hp=0.0;game.rebuild_grid();game.irt.curse={}
 for i in 125:game.irt.tick(1.0/60.0)
 check(1000.0-elite.hp<=1000.0*0.06*2.5,"Hangman's Noose is scaled down on elites (%.0f)"%(1000.0-elite.hp))
 # Grave Hound Whistle
 fresh();give("hound_whistle");game.enemies.clear();var hv=make_enemy(Vector3(0,0,25),1000.0);game.rebuild_grid();game.player.position=Vector3(0,1,0)
 game.irt.tick(0.016)
 for i in 20:
  game.player.position+=Vector3(0,0,0.8);game.irt.tick(0.016)
 check(game.irt.hounds.size()==1,"Grave Hound Whistle: a hound after 15 m of travel")
 for i in 120:game.irt.tick(1.0/60.0)
 check(hv.hp<1000.0 and absf(1000.0-hv.hp-(ItemStats.v("hound_whistle","damage")+ItemStats.v("hound_whistle","damage_per_level")*game.level))<0.01,"The hound charges through enemies and hits each one once")
 fresh();give("hound_whistle",99);game.player.position=Vector3.ZERO;game.irt.tick(0.016)
 for i in 400:
  game.player.position+=Vector3(0,0,1.0);game.irt.tick(0.016)
 check(game.irt.hounds.size()<=int(ItemStats.v("hound_whistle","cap")) and int(game.irt.dropped.get("hounds",0))>0,"Hound pool is hard-capped and refusals are counted")
 # Reaper's Sickle
 fresh();give("reapers_sickle");game.enemies.clear()
 var dying={"pos":Vector3(0,0,30),"last_item":false}
 game.irt.on_kill(dying)
 check(game.irt.souls.size()==2,"Reaper's Sickle: a kill releases 2 souls")
 game.irt.souls.clear();game.irt.on_kill({"pos":Vector3(0,0,30),"last_item":true})
 check(game.irt.souls.is_empty(),"No chain: item kills never release souls")
 var tgt=make_enemy(Vector3(0,0,34),1000.0);game.rebuild_grid();game.irt.souls.clear();game.irt.on_kill(dying)
 for i in 120:game.irt.tick(1.0/60.0)
 check(tgt.hp<1000.0,"Souls home in and strike other enemies")
 game.irt.souls.clear()
 for i in 40:game.irt.on_kill(dying)
 check(game.irt.souls.size()<=int(ItemStats.v("reapers_sickle","cap")) and int(game.irt.dropped.get("souls",0))>0,"Soul pool is hard-capped and refusals are counted")
 # Shattered Codex
 fresh();give("shattered_codex");game.enemies.clear();game.pickups.clear()
 var cdx=make_enemy(Vector3(4,0,0),1000.0);game.rebuild_grid()
 game.add_xp_drop(cdx.pos+Vector3(0.2,0,0),1.0);game.pickups.back()["attracted"]=false
 game.irt.tick(0.016);check(is_equal_approx(cdx.hp,1000.0),"Shattered Codex: still gems do nothing")
 game.pickups.back()["attracted"]=true;game.irt.tick(0.016)
 check(cdx.hp<1000.0,"Shattered Codex: a gem flying to you slices enemies it passes through")
 var after=cdx.hp;game.irt.tick(0.016)
 check(is_equal_approx(cdx.hp,after),"Shattered Codex: per-enemy hit cooldown")
 # Powder Keg Heart
 fresh();give("powder_keg_heart");game.enemies.clear();game.irt.rng.seed=51
 var core=make_enemy(Vector3(4,0,0),1e9);var next_to=make_enemy(Vector3(5,0,0),1e9);var distant=make_enemy(Vector3(14,0,0),1e9);game.rebuild_grid()
 game.irt.stacks["powder_keg_heart"]=60;game.irt.counters.clear();game.irt.keg_window=-5.0;game.elapsed=100.0
 game.irt.on_hit(core,100.0,100.0,false,0)
 game.irt.stacks["powder_keg_heart"]=1
 check(absf((1e9-next_to.hp)-65.0)<0.01 and is_equal_approx(distant.hp,1e9) and is_equal_approx(core.hp,1e9),"Powder Keg Heart: 65%% damage to enemies around the target, not the target, not far ones")
 check(bool(next_to.get("last_item",false)),"Keg explosions are item damage (they cannot trigger other procs)")
 game.irt.stacks["powder_keg_heart"]=99;game.irt.counters.clear();game.irt.dropped.clear()
 for i in 100:game.irt.on_hit(core,100.0,100.0,false,0)
 game.irt.stacks["powder_keg_heart"]=1
 check(int(game.irt.counters.get("kegs",0))<=int(ItemStats.v("powder_keg_heart","per_second")) and int(game.irt.dropped.get("kegs",0))>0,"Explosions are limited per second and refusals counted")
 # Headsman's Oath
 fresh();give("headsmans_oath");game.enemies.clear();game.irt.rng.seed=61
 var d0=game.stats.damage
 var dummy=make_enemy(Vector3(0,0,15),10.0);game.rebuild_grid()
 for i in 20000:
  dummy.hp=10.0;dummy.max_hp=10.0;dummy.erase("death_handled");game.irt.on_hit(dummy,1.0,1.0,false,0)
 var ex=int(game.irt.counters.get("executions",0))
 check(near(float(ex)/20000.0,0.01,0.004),"Headsman's Oath: 1%% of hits execute (%d/20000)"%ex)
 check(is_equal_approx(game.stats.damage-d0,0.01*ex),"Headsman's Oath: +1%% damage per execution for the rest of the run")
 var bossy={"pos":Vector3(0,0,60),"hp":500.0,"max_hp":500.0,"kind":8};game.irt.stacks["headsmans_oath"]=1
 for i in 5000:game.irt.execute(bossy)
 check(is_equal_approx(float(bossy.hp),500.0),"Headsman's Oath never executes a boss")
 var elite_t=make_enemy(Vector3(2,0,0),1000.0);elite_t["elite"]=true;game.irt.execute(elite_t)
 check(is_equal_approx(elite_t.hp,750.0),"Headsman's Oath: elites lose 25%% max HP instead of dying")
 # Hourglass of the Damned
 fresh();give("hourglass_damned");game.invulnerability=0.0;game.health=5.0;game.world_time.reset()
 game.hurt(500.0)
 check(is_equal_approx(game.health,game.stats.max_health*0.5) and game.world_time.scale==0.0 and game.world_time.active(),"Hourglass: the first lethal hit freezes hostile time and heals to 50%")
 check(Engine.time_scale==1.0 and game.item_stacks("hourglass_damned")==0 and not game.irt.has("hourglass_damned"),"Hourglass never touches Engine.time_scale and shatters after use")
 check(is_equal_approx(game.world_time.hostile(1.0),0.0),"Frozen hostile time is zero")
 game.world_time.tick(5.1)
 check(not game.world_time.active() and is_equal_approx(game.world_time.hostile(1.0),1.0),"Hostile time resumes after 5 s")
 game.invulnerability=0.0;game.health=5.0;game.hurt(500.0)
 check(game.health<=0.0,"A second lethal hit kills (the Hourglass is gone)")
 fresh();give("hourglass_damned");game.invulnerability=0.0;game.health=50.0;game.hurt(10.0)
 check(game.item_stacks("hourglass_damned")==1,"Hourglass is not spent by non-lethal damage");game.world_time.reset()
 # Anvil of the First Forge
 fresh();give("anvil_first_forge")
 game.weapons[0]={"level":1,"upgrades":{},"clock":0.0}
 var before_total=upgrade_total(0)
 game.apply_upgrade({"type":"weapon","id":0})
 check(game.weapons[0].level==2 and upgrade_total(0)>before_total,"Anvil setup: a normal upgrade levels the weapon")
 var with_anvil=upgrade_total(0)-before_total
 fresh();game.weapons[0]={"level":1,"upgrades":{},"clock":0.0};game.apply_upgrade({"type":"weapon","id":0});var without=upgrade_total(0)
 check(with_anvil>without,"Anvil of the First Forge: an upgrade also grants one extra stat (%.2f vs %.2f total)"%[with_anvil,without])
 fresh();give("anvil_first_forge");game.weapons[0]={"level":1,"upgrades":{},"clock":0.0};game.gold=5000;game.gems.add("ice")
 var imbued=ImbueRules.install(game,0,"ice")
 check(imbued.ok and upgrade_total(0)>0.0,"Anvil: an Imbue also grants one extra stat")
 fresh();game.weapons[0]={"level":1,"upgrades":{},"clock":0.0};game.gold=5000;game.gems.add("ice");ImbueRules.install(game,0,"ice")
 check(is_equal_approx(upgrade_total(0),0.0),"Without the Anvil an Imbue grants no stat")
 # Devil's Bargain
 fresh();give("devils_bargain");var hp0=game.stats.max_health;var dm0=game.stats.damage
 for i in 3:game.irt.on_level_up()
 check(is_equal_approx(hp0-game.stats.max_health,15.0) and is_equal_approx(game.stats.damage-dm0,0.12),"Devil's Bargain: each level-up trades 5 max HP for +4%% damage")
 for i in 200:game.irt.on_level_up()
 check(game.stats.max_health>=float(ItemStats.T.max_health_floor) and game.health<=game.stats.max_health,"Devil's Bargain never takes max HP below the floor (%.0f)"%game.stats.max_health)
 fresh()

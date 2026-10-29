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
 game.enemies.clear();game.wrt.clear();game.irt.clear_effects()
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
 await migration_tests()
 print("ITEMS_REGRESSION: %d checks, %d failures"%[checks,failures.size()])
 game.queue_free();await process_frame;await process_frame
 quit(1 if failures.size()>0 else 0)
# ---------------------------------------------------------------- catalog / icons / drops
func catalog_tests():
 var raw=JSON.parse_string(FileAccess.get_file_as_string("res://data/items.json")).items
 check(Catalog.ITEMS.size()==60 and raw.size()==60 and Catalog.ITEM_IDS.size()==60,"Catalog has exactly 60 items")
 var same=true
 for item in raw:
  var c=Catalog.ITEMS.get(item.id,{})
  for k in ["name","tier","short","full","needs","unique"]:if c.get(k)!=item.get(k):same=false
 check(same,"Catalog matches data/items.json field for field")
 var tiers={}
 for id in Catalog.ITEM_IDS:tiers[Catalog.item_tier(id)]=int(tiers.get(Catalog.item_tier(id),0))+1
 check(tiers=={"common":19,"uncommon":17,"rare":13,"epic":7,"legendary":4},"Tier counts match the roster (%s)"%str(tiers))
 var uniques=Catalog.ITEM_IDS.filter(func(i):return Catalog.item_unique(i))
 check(uniques.size()==5 and "saints_finger" in uniques and Catalog.ITEM_IDS.filter(func(i):return Catalog.item_tier(i)=="legendary").all(func(i):return i in uniques),"Saint's Finger and all 4 Legendaries are Unique")
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

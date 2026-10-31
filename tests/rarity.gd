extends SceneTree
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error(label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func run():
 var colors=["a8adb5","46c878","418fff","ad65f5","ffbf45"];var total=0.0
 for i in Rarity.IDS.size():
  var tier=Rarity.definition(Rarity.IDS[i]);total+=tier.weight
  check(tier.color.to_html(false)==colors[i] and tier.border_width>0,"Exact color and UI metadata: "+tier.id)
 check(is_equal_approx(total,100),"Weights sum to 100")
 var ids={};var counts={};var candidates=[]
 for entry in RewardCatalog.all_entries():
  check(not ids.has(entry.uid) and Rarity.valid(entry.rarity) and not entry.description.is_empty() and entry.icon!=null and not entry.name.is_empty(),"Valid unique metadata: "+entry.uid)
  ids[entry.uid]=true
  if entry.category=="weapons":check(entry.effects.keys()==WeaponUpgrades.pool(int(entry.id)),"Metadata exposes only supported upgrades: "+entry.uid)
 for tier in Rarity.IDS:
  counts[tier]=0;candidates.append({"metadata":{"uid":tier,"rarity":tier,"level":0,"max_level":10}})
 var rng=RandomNumberGenerator.new();rng.seed=123456
 var start=Time.get_ticks_usec()
 for i in 100000:
  var reward=RewardSelector.choose(candidates,rng);counts[reward.metadata.rarity]+=1
 for tier in Rarity.IDS:
  var percent=counts[tier]/1000.0
  check(absf(percent-Rarity.TIERS[tier].weight)<0.6,"100000 rolls: %s %.3f%%"%[tier,percent])
 print("DISTRIBUTION "+JSON.stringify(counts)+"; elapsed_ms="+str((Time.get_ticks_usec()-start)/1000.0))
 var subset=[candidates[1],candidates[4]];var legendary=0
 for i in 10000:
  var selected=RewardSelector.choose(subset,rng)
  check_selection(selected)
  if selected.metadata.rarity=="legendary":legendary+=1
 check(absf(legendary/10000.0-2.0/30.0)<0.015,"Missing tiers renormalize to 28:2")
 check(Rarity.reward_weights(0).common==50.0 and Rarity.reward_weights(2).common<50.0 and Rarity.reward_weights(2).legendary>2.0,"Luck preserves bounded upward chest bias")
 var maxed=candidates[0].duplicate(true);maxed.metadata.level=10
 var locked=candidates[1].duplicate(true);locked.enabled=false
 check(RewardSelector.choose([maxed,locked],rng).is_empty(),"Maxed and disabled rewards excluded")
 check(RewardSelector.choose([],rng).is_empty(),"Empty pool safe")
 check(RewardSelector.choose(candidates,rng,{"common":0,"uncommon":0,"rare":0,"epic":0,"legendary":0}).is_empty(),"Zero configured weights safe")
 check(RewardSelector.draw(candidates,8,rng).size()==5,"Without replacement never duplicates")
 var first=RandomNumberGenerator.new();var second=RandomNumberGenerator.new();first.seed=77;second.seed=77
 var deterministic=true
 for i in 100:deterministic=deterministic and RewardSelector.choose(candidates,first).metadata.uid==RewardSelector.choose(candidates,second).metadata.uid
 check(deterministic,"Seeded reward sequences deterministic")
 var original=candidates.duplicate(true);RewardSelector.draw(candidates,3,rng)
 check(candidates==original,"Selector does not mutate caller data")
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.map_seed_override=9;game.begin_run();game.mode="pause";game.player.active=false
 game.weapons.clear();game.tomes.clear();game.equip(0);game.weapons[0].level=Economy.WEAPON_MAX_LEVEL;game.tomes.Might=Economy.TOME_MAX_LEVEL
 var pool=game.upgrade_pool();var exclusions=true
 for choice in pool:exclusions=exclusions and choice.key!="w0" and choice.key!="Might"
 check(exclusions,"Real level-up pool excludes maxed weapons/tomes")
 game.sandbox=false;game.progress=Progress.new();MetaProgress.migrate(game.progress.data)
 var permitted=true
 for choice in game.upgrade_pool():
  if choice.type=="weapon" and not game.weapons.has(choice.id):permitted=permitted and MetaProgress.enabled(game.progress.data,"weapons",str(choice.id))
 check(permitted,"Actual locked weapons are excluded")
 MetaProgress.toggle(game.progress.data,"weapons","1")
 check(game.upgrade_choices().all(func(c):return c.type!="weapon" or int(c.id)!=1),"Disabled unowned weapons are excluded")
 game.sandbox=true
 game.banished=["Haste"]
 check(game.upgrade_choices().all(func(c):return c.key!="Haste"),"Banish eligibility retained")
 game.tomes.clear();var damage=game.stats.damage;game.apply_upgrade({"type":"tome","id":"Might"})
 check(is_equal_approx(game.stats.damage,damage+0.06) and game.tomes.Might==1,"Existing tome power unchanged")
 game.weapons[0].level=1;var before=WeaponUpgrades.damage(0,game.weapons[0]);game.apply_upgrade({"type":"weapon","id":0,"attribute":"damage","step":0.06,"expected_level":1})
 check(game.weapons[0].level==2 and is_equal_approx(WeaponUpgrades.damage(0,game.weapons[0]),before*1.06),"Existing weapon upgrade unchanged")
 var snapshot=[game.weapons[0].level,game.tomes.Might,game.stats.damage,game.items.duplicate()]
 check(game.save_run("user://rarity-run.json") and game.load_run("user://rarity-run.json"),"Unchanged version-2 run save round trip")
 check(int(snapshot[0])==int(game.weapons[0].level) and int(snapshot[1])==int(game.tomes.Might) and is_equal_approx(snapshot[2],game.stats.damage) and snapshot[3]==game.items,"Saved levels/stats/items preserved; rarity derived")
 var price_ok=true
 for id in Catalog.ITEM_IDS:price_ok=price_ok and ShopSystem.price(id)==Economy.item_price(Catalog.item_tier(id),1) and ShopSystem.price(id,3)>ShopSystem.price(id,1)
 check(price_ok,"Shop prices come from Economy and grow with stage")
 for tier in ["Common","Rare","Legendary"]:
  var offers=ShopSystem.offers(tier,Catalog.ITEM_IDS,rng);var seen={};var valid=true
  for id in offers:
   valid=valid and not seen.has(id);seen[id]=true
   valid=valid and (Catalog.item_tier(id) in Economy.SHOP_ITEM_TIERS[tier])
  check(valid and not offers.is_empty(),"Seller tier eligibility and unique offers: "+tier)
 game.queue_free();await process_frame;await process_frame
 print("RARITY: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)
func check_selection(selected: Dictionary):
 if selected.is_empty() or not selected.metadata.rarity in ["uncommon","legendary"]:
  failures.append("Subset produced invalid selection")

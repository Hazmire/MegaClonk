extends SceneTree
# Economy Rework regression: luck curve, tier odds, shop types and fairness, prices, chest cost, tier-sized upgrades, caps, stacking.
var count=0
var failures: Array[String]=[]
var game: Node
func check(ok: bool,label: String) -> void:
 count+=1
 if ok:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func share(weights: Dictionary,tier: String) -> float:
 var total=0.0
 for t in weights:total+=float(weights[t])
 return float(weights[tier])/total
func run() -> void:
 # ---- luck: diminishing, bounded
 var b0=Economy.luck_boost(0.0);var b2=Economy.luck_boost(2.0);var b4=Economy.luck_boost(4.0);var b8=Economy.luck_boost(8.0);var b99=Economy.luck_boost(99.0)
 check(b0==0.0 and b2>b0 and b4>b2 and b8>b4,"Luck boost rises with luck")
 check((b4-b2)<(b2-b0) and (b8-b4)<(b4-b2),"Luck has diminishing returns")
 check(b99<Economy.LUCK_MAX_BOOST+0.0001 and b99>0.55,"Luck can never exceed its ceiling")
 var base=ItemStats.TIER_WEIGHTS
 var w0=Economy.tier_weights(base,0.0);var w5=Economy.tier_weights(base,5.0)
 check(is_equal_approx(share(w0,"common"),0.5) and is_equal_approx(share(w0,"legendary"),0.02),"Luck 0 leaves the tier weights untouched")
 check(share(w5,"common")<share(w0,"common") and share(w5,"rare")>share(w0,"rare") and share(w5,"legendary")>share(w0,"legendary")*1.5,"Luck shifts weight from Common to the higher tiers")
 check(share(Economy.tier_weights(base,99.0),"legendary")<0.12,"Even enormous luck keeps Legendary rare in an item roll (%.3f)"%share(Economy.tier_weights(base,99.0),"legendary"))
 # ---- shop types and the per-stage fairness rules
 var odds0=Economy.shop_type_odds(0.0);var odds_hi=Economy.shop_type_odds(99.0)
 check(is_equal_approx(float(odds0.Common)+float(odds0.Rare)+float(odds0.Legendary),1.0) and is_equal_approx(float(odds_hi.Common)+float(odds_hi.Rare)+float(odds_hi.Legendary),1.0),"Shop-type odds sum to 1")
 check(float(odds_hi.Legendary)>float(odds0.Legendary) and float(odds_hi.Rare)>float(odds0.Rare) and float(odds_hi.Legendary)<0.13,"Luck raises Rare and Legendary shop odds, with a low ceiling")
 var worst_legendary=0;var worst_standard=99;var legendary_stages=0;var legendary_stages_hi=0;var stages=3000
 var rng=RandomNumberGenerator.new();rng.seed=77
 for i in stages:
  var types=Economy.roll_stage_shops(3,rng,99.0)
  worst_legendary=maxi(worst_legendary,types.count("Legendary"));worst_standard=mini(worst_standard,types.count("Common"))
  if types.count("Legendary")>0:legendary_stages_hi+=1
 for i in stages:
  if Economy.roll_stage_shops(3,rng,0.0).count("Legendary")>0:legendary_stages+=1
 check(worst_legendary<=1,"Never more than one Legendary shop on a stage, even at enormous luck")
 check(worst_standard>=1,"Every stage keeps at least one Standard shop")
 check(legendary_stages_hi>legendary_stages and legendary_stages_hi<stages*0.35,"High luck makes a Legendary shop likelier but far from guaranteed (%d vs %d of %d stages)"%[legendary_stages_hi,legendary_stages,stages])
 # ---- prices and chests
 var tier_ok=true
 for stage in [1,2,3,4]:
  var last=0
  for tier in Rarity.IDS:
   var p=Economy.item_price(tier,stage)
   if p<=last:tier_ok=false
   last=p
 check(tier_ok,"Prices rise with tier")
 var stage_ok=true
 for tier in Rarity.IDS:
  for stage in [1,2,3]:if Economy.item_price(tier,stage+1)<=Economy.item_price(tier,stage):stage_ok=false
 check(stage_ok,"Prices rise with stage")
 check(Economy.gem_price(2)==Economy.item_price("epic",2),"A socket gem is priced like an Epic item")
 check(Economy.chest_cost(0)==15 and Economy.chest_cost(1)>Economy.chest_cost(0),"First chest costs 15")
 var ratio_ok=true
 for n in range(1,40):
  var r=float(Economy.chest_cost(n+1))/float(Economy.chest_cost(n))
  if absf(r-Economy.CHEST_GROWTH)>0.05:ratio_ok=false
 check(ratio_ok and Economy.chest_cost(30)>=3000 and Economy.chest_cost(10)<Economy.chest_cost(20)/3,"Chest cost grows exponentially, reaching the thousands after ~30 chests (%d)"%Economy.chest_cost(30))
 # ---- game-level behaviour
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.map_seed_override=9;game.begin_run();game.mode="pause";game.player.active=false
 game.world_content_version=2
 var available=ItemDrops.available(game)
 var srng=RandomNumberGenerator.new();srng.seed=11
 var rare_ok=true;var lege_ok=true;var std_tiers={};var gems_rare=0;var gems_std=0;var slots_rare=0;var slots_std=0
 for i in 600:
  for id in ShopSystem.offers("Rare",available,srng,0.0,true):
   slots_rare+=1
   if id is int:gems_rare+=1
   elif not Catalog.item_tier(id) in ["rare","epic","legendary"]:rare_ok=false
  for id in ShopSystem.offers("Legendary",available,srng,0.0,true):
   if id is int or Catalog.item_tier(id)!="legendary":lege_ok=false
  for id in ShopSystem.offers("Common",available,srng,0.0,true):
   slots_std+=1
   if id is int:gems_std+=1
   else:std_tiers[Catalog.item_tier(id)]=true
 check(rare_ok,"Rare shops always sell Rare or better")
 check(lege_ok,"Legendary shops sell only Legendary items")
 check(std_tiers.size()==5,"Standard shops can sell every tier")
 check(gems_rare>0 and gems_std>0 and float(gems_rare)/slots_rare>float(gems_std)/slots_std*2.0,"Gems are stocked like Rare items: common in Rare shops (%d/%d), uncommon in Standard (%d/%d)"%[gems_rare,slots_rare,gems_std,slots_std])
 var legendary_share_std=0;var total_std=0
 for i in 2000:
  for id in ShopSystem.offers("Common",available,srng,0.0,false):
   total_std+=1
   if Catalog.item_tier(id)=="legendary":legendary_share_std+=1
 check(float(legendary_share_std)/total_std<0.06,"Legendaries are very rare in Standard shops (%.1f%%)"%(100.0*float(legendary_share_std)/total_std))
 var hi_legendary=0;var hi_total=0
 for i in 2000:
  for id in ShopSystem.offers("Common",available,srng,8.0,false):
   hi_total+=1
   if Catalog.item_tier(id)=="legendary":hi_legendary+=1
 check(float(hi_legendary)/hi_total>float(legendary_share_std)/total_std,"Luck raises the tier of what a shop stocks")
 # purchase price follows stage
 game.stage=3;game.gold=100000;var shop={"used":false,"offers":["whetstone"],"kind":"Shop","tier":"Common"};game.mode="shop"
 var cost=ShopSystem.price("whetstone",3)
 check(cost==Economy.item_price("common",3) and cost>ShopSystem.price("whetstone",1),"Shop price for a stage-3 purchase is higher")
 check(not game.buy_shop(shop,"whetstone",ShopSystem.price("whetstone",1)) and game.buy_shop(shop,"whetstone",cost) and game.gold==100000-cost,"Buying checks and charges the stage price")
 game.stage=1
 # chest cost comes from Economy
 game.chests_opened=12
 check(game.chest_cost()==Economy.chest_cost(12),"Game chest cost is the exponential curve")
 game.chests_opened=0
 # ---- every item stacks
 game.items.clear()
 var stack_ok=true
 for id in Catalog.ITEM_IDS:
  if Catalog.item_consumable(id):continue
  game.grant_item(id,true);game.grant_item(id,true)
  if game.item_stacks(id)!=2:stack_ok=false
 check(stack_ok,"Every non-consumable item can be held more than once")
 game.items.clear();game.irt.rebuild()
 game.grant_item("hourglass_damned",true);game.grant_item("hourglass_damned",true)
 game.invulnerability=0.0;game.health=5.0;game.world_time.reset();game.hurt(500.0)
 check(game.item_stacks("hourglass_damned")==1,"A lethal hit spends one Hourglass and keeps the other");game.world_time.reset()
 # ---- upgrades: size by tier, any tier for anything
 game.tomes.clear();var stat0=float(game.stats.damage)
 game.apply_upgrade({"type":"tome","id":"Might","tier":"common"})
 check(is_equal_approx(game.stats.damage,stat0+0.06),"Common Damage Tome: +6%")
 game.apply_upgrade({"type":"tome","id":"Might","tier":"legendary"})
 check(is_equal_approx(game.stats.damage,stat0+0.06+0.14),"Legendary Damage Tome: +14% (0.06 -> 0.20)")
 var sizes=[]
 for tier in Rarity.IDS:sizes.append(Economy.scaled(0.06,tier))
 check(sizes[0]<sizes[1] and sizes[1]<sizes[2] and sizes[2]<sizes[3] and sizes[3]<sizes[4],"Tiers give strictly bigger upgrades")
 var count0=int(game.stats.count)
 game.apply_upgrade({"type":"tome","id":"Multishot","tier":"legendary"})
 check(int(game.stats.count)==count0+1,"Whole-number stats (projectiles) are not scaled by tier")
 game.weapons.clear();game.equip(0);game.weapons[0].level=1;game.weapons[0].upgrades={}
 game.apply_upgrade({"type":"weapon","id":0,"attribute":"damage","step":WeaponUpgrades.step_for("damage","legendary"),"expected_level":1})
 check(game.weapons[0].level==2 and is_equal_approx(float(game.weapons[0].upgrades.damage),0.14),"Legendary weapon damage upgrade: +14%")
 check(not WeaponUpgrades.apply(0,{"level":1},{"attribute":"damage","step":0.123}),"A step that matches no tier is rejected")
 var seen_tiers={"weapon":{},"tome":{}};var luck_scale0=0.0;var luck_scale5=0.0;var n=1500
 game.weapons.clear();game.equip(0);game.tomes.clear();game.tomes.Might=1
 game.stats.luck=0.0
 for i in n:
  for c in game.upgrade_choices(3):
   seen_tiers[c.type][c.tier]=true;luck_scale0+=Economy.tier_scale(c.tier)
 game.stats.luck=5.0
 for i in n:
  for c in game.upgrade_choices(3):luck_scale5+=Economy.tier_scale(c.tier)
 check(seen_tiers.weapon.size()==5 and seen_tiers.tome.size()==5,"Weapon and tome upgrades can both roll every tier")
 check(luck_scale5>luck_scale0*1.08,"Luck raises the tier of level-up upgrades (mean size x%.2f -> x%.2f)"%[luck_scale0/(n*3.0),luck_scale5/(n*3.0)])
 game.stats.luck=0.0
 check(Economy.TOME_MAX_LEVEL==80 and Economy.WEAPON_MAX_LEVEL==40,"Tomes cap at 80 upgrades and weapons at 40")
 game.tomes.Haste=79;game.apply_upgrade({"type":"tome","id":"Haste"});game.apply_upgrade({"type":"tome","id":"Haste"})
 check(game.tomes.Haste==80,"A tome stops at 80")
 # shrine tiers also respond to luck
 var r=RandomNumberGenerator.new();r.seed=5;var s0=0;var s5=0
 for i in 4000:
  if ShrineRewards.roll_tier(r,0.0) in ["epic","legendary"]:s0+=1
  if ShrineRewards.roll_tier(r,6.0) in ["epic","legendary"]:s5+=1
 check(s5>s0,"Luck also improves stat-shrine tiers (%d vs %d Epic+ of 4000)"%[s5,s0])
 game.queue_free();await process_frame;await process_frame
 print("ECONOMY RESULT: %d checks, %d failures"%[count,failures.size()])
 quit(0 if failures.is_empty() else 1)

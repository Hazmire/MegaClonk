class_name ItemDrops
extends RefCounted

# Item drop selection. A tier is picked first (ItemStats.TIER_WEIGHTS, nudged by luck exactly like Rarity.reward_weights),
# then an item inside that tier. Candidates exclude disabled items and Uniques the player already owns. The pick is made
# before any animation plays, with the run's seeded game.rng.
static func available(game: Node) -> Array:
 var result=[]
 for id in Catalog.ITEM_IDS:
  if game.sandbox or MetaProgress.enabled(game.progress.data,"items",str(id)):
   if Catalog.item_unique(id) and game.item_stacks(id)>0:continue
   if str(id)=="imbued_amulet" and int(game.amulets_found)>=int(Elements.TUNING.amulet.max_per_run):continue
   result.append(str(id))
 return result
static func weights(luck: float=0.0) -> Dictionary:
 var boost=clampf(luck*0.2,0,0.4);var result={}
 for tier in Catalog.ITEM_TIERS:result[tier]=float(ItemStats.TIER_WEIGHTS[tier])*(1-boost if tier=="common" else 1+boost)
 return result
static func candidates(ids: Array,tiers: Array=[]) -> Array:
 var result=[]
 for id in ids:
  if tiers.is_empty() or Catalog.item_tier(id) in tiers:result.append({"id":str(id),"metadata":RewardCatalog.entry("items",str(id))})
 return result
# Chest reward: tier first, then an item of that tier.
static func roll_chest(game: Node) -> String:
 var selected=RewardSelector.choose(candidates(available(game)),game.rng,weights(float(game.stats.luck)))
 return str(selected.get("id",""))
# Vase reward: Common/Uncommon only, with ItemStats.DROPS.vase_item_chance. Returns "" for no item.
static func roll_vase(game: Node) -> String:
 if game.rng.randf()>=float(ItemStats.DROPS.vase_item_chance):return ""
 var selected=RewardSelector.choose(candidates(available(game),ItemStats.DROPS.vase_tiers),game.rng,weights(float(game.stats.luck)))
 return str(selected.get("id",""))
static func shop_tiers(tier_name: String) -> Array:
 match tier_name:
  "Common":return ["common","uncommon"]
  "Rare":return ["rare","epic"]
 return ["epic"] # the "Legendary" shop tier sells the best tier that shops stock; Legendary items never sell
static func shop_offers(game: Node,tier_name: String,rng: RandomNumberGenerator) -> Array:
 var pool=candidates(available(game),shop_tiers(tier_name))
 var result=[]
 for c in RewardSelector.draw(pool,3,rng):result.append(str(c.id))
 return result
static func price(id: String) -> int:
 return int(ItemStats.DROPS.shop_price[Catalog.item_tier(id)])

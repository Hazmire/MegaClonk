class_name ItemDrops
extends RefCounted

# Item drop selection. A tier is picked first (ItemStats.TIER_WEIGHTS, nudged by luck exactly like Rarity.reward_weights),
# then an item inside that tier (luck from Economy). Candidates exclude only disabled items. The pick is made
# before any animation plays, with the run's seeded game.rng.
static func available(game: Node) -> Array:
 var result=[]
 for id in Catalog.ITEM_IDS:
  if game.sandbox or MetaProgress.enabled(game.progress.data,"items",str(id)):
   result.append(str(id)) # every item stacks, so owning one never removes it from the pool
 return result
static func weights(luck: float=0.0) -> Dictionary:return Economy.tier_weights(ItemStats.TIER_WEIGHTS,luck)
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
static func price(id: String,stage: int=1) -> int:return Economy.item_price(Catalog.item_tier(id),stage)

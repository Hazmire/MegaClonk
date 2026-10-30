class_name ShopSystem
extends RefCounted
# Shop stock. Types ("Common" = Standard, "Rare", "Legendary"), odds and prices live in Economy.
# Socket gems are stocked as Rare-tier candidates, so they compete with Rare items for slots instead of having their own chance.
static func tier(rng: RandomNumberGenerator,luck: float=0.0) -> String:return Economy.roll_shop_type(rng,luck)
static func price(id: Variant,stage: int=1) -> int:return Economy.item_price(Catalog.item_tier(str(id)),stage)
static func gem_price(stage: int=1) -> int:return Economy.gem_price(stage)
static func candidates(tier_name: String,available: Array,with_gems: bool=false) -> Array:
 var tiers: Array=Economy.SHOP_ITEM_TIERS.get(tier_name,Economy.SHOP_ITEM_TIERS.Common)
 var choices=[]
 for id in available:
  if Catalog.item_tier(id) in tiers:choices.append(str(id))
 var result=RewardSelector.items(choices)
 if with_gems and "rare" in tiers:
  for element in Elements.IDS:result.append({"id":GemRewards.offer_code(element),"metadata":{"uid":"gem_"+str(element),"rarity":"rare","name":Elements.display_name(element)+" Socket Gem","description":"","category":"gems","max_level":0,"level":0}})
 return result
# Three distinct offers: item ids (String) and, when with_gems, gem offer codes (negative ints).
static func offers(tier_name: String,available: Array,rng: RandomNumberGenerator,luck: float=0.0,with_gems: bool=false) -> Array:
 var weights=Economy.tier_weights(ItemStats.TIER_WEIGHTS,luck);var result=[]
 for candidate in RewardSelector.draw(candidates(tier_name,available,with_gems),3,rng,weights):
  result.append(candidate.id if candidate.id is int else str(candidate.id))
 return result

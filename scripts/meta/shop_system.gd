class_name ShopSystem
extends RefCounted
const COMMON_CHANCE=0.75
const RARE_CHANCE=0.20
static func tier(rng: RandomNumberGenerator) -> String:
 var roll=rng.randf();return "Common" if roll<COMMON_CHANCE else ("Rare" if roll<COMMON_CHANCE+RARE_CHANCE else "Legendary")
static func price(id: Variant) -> int:return ItemDrops.price(str(id))
static func offers(tier_name: String,available: Array,rng: RandomNumberGenerator) -> Array:
 var tiers=ItemDrops.shop_tiers(tier_name);var choices=[]
 for id in available:
  if Catalog.item_tier(id) in tiers:choices.append(str(id))
 var result=[]
 for candidate in RewardSelector.draw(RewardSelector.items(choices),3,rng):result.append(str(candidate.id))
 return result

class_name ShopSystem
extends RefCounted
const COMMON_CHANCE=0.75
const RARE_CHANCE=0.20
static func tier(rng: RandomNumberGenerator) -> String:
 var roll=rng.randf();return "Common" if roll<COMMON_CHANCE else ("Rare" if roll<COMMON_CHANCE+RARE_CHANCE else "Legendary")
static func price(id: int) -> int:
 return {"common":15,"uncommon":25,"rare":40,"epic":65,"legendary":150}[Catalog.ITEMS[id][1]]
static func offers(tier_name: String, available: Array, rng: RandomNumberGenerator) -> Array:
 var choices=[]
 for id in available:
  var rarity=Catalog.ITEMS[id][1]
  if (tier_name=="Common" and rarity in ["common","uncommon"]) or (tier_name=="Rare" and rarity in ["rare","epic"]) or (tier_name=="Legendary" and rarity=="legendary"):choices.append(id)
 var selected=RewardSelector.draw(RewardSelector.items(choices),3,rng)
 var result=[]
 for candidate in selected:result.append(int(candidate.id))
 return result

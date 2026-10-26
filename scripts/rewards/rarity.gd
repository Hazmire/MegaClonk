class_name Rarity
extends RefCounted
# IDs are save-stable. Level never determines rarity or modifies item power.
const IDS=["common","uncommon","rare","epic","legendary"]
const TIERS={
 "common":{"name":"Common","hex":"A8ADB5","weight":50.0,"border_width":1,"celebration":0.2},
 "uncommon":{"name":"Uncommon","hex":"46C878","weight":28.0,"border_width":2,"celebration":0.4},
 "rare":{"name":"Rare","hex":"418FFF","weight":14.0,"border_width":2,"celebration":0.6},
 "epic":{"name":"Epic","hex":"AD65F5","weight":6.0,"border_width":3,"celebration":0.8},
 "legendary":{"name":"Legendary","hex":"FFBF45","weight":2.0,"border_width":4,"celebration":1.0}}
static func valid(id: String) -> bool:return TIERS.has(id)
static func definition(id: String) -> Dictionary:
 if not valid(id):return {}
 var result=TIERS[id].duplicate();result.id=id;result.color=Color(result.hex);return result
# Preserve the existing chest luck influence while using the new tier selector.
# Zero luck gives the prescribed weights; positive luck favors higher tiers.
static func reward_weights(luck: float=0.0) -> Dictionary:
 var boost=clampf(luck*0.2,0,0.4);var result={}
 for id in IDS:result[id]=float(TIERS[id].weight)*(1-boost if id=="common" else 1+boost)
 return result

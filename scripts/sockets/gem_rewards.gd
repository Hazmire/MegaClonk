class_name GemRewards
extends RefCounted

# Where gems come from besides vases: shop offers and a chance on chest rewards.
const TUNING={
 "chest_chance":0.12,        # GUESS: not specified, kept modest because gems are also sold and dropped by vases
 "shop_offers":2,            # distinct gems on sale in each shop
 "shop_seed_offset":7100113,
 "chest_seed_offset":3300217
}
static func shop_offers(game: Node,index: int) -> Array:
 var rng=RandomNumberGenerator.new();rng.seed=int(game.run_seed)*31+game.stage*977+index*131+int(TUNING.shop_seed_offset)
 var pool=Elements.IDS.duplicate();var result=[]
 for i in mini(int(TUNING.shop_offers),pool.size()):
  var pick=rng.randi_range(0,pool.size()-1);result.append(pool[pick]);pool.remove_at(pick)
 return result
# Buys one gem from a shop. Atomic: gold and gem change together or not at all.
static func buy(game: Node,object: Dictionary,element: String) -> Dictionary:
 if not Elements.valid(element):return {"ok":false,"reason":"invalid_element"}
 if not element in object.get("gem_offers",[]):return {"ok":false,"reason":"not_offered"}
 if element in object.get("gem_sold",[]):return {"ok":false,"reason":"sold"}
 if int(game.gold)<ImbueRules.SHOP_PRICE:return {"ok":false,"reason":"not_enough_gold"}
 game.gold-=ImbueRules.SHOP_PRICE
 game.gems.add(element)
 if not object.has("gem_sold"):object["gem_sold"]=[]
 object["gem_sold"].append(element)
 return {"ok":true,"element":element}
# Called when a chest produces an item. Returns the element granted, or "".
static func roll_chest(game: Node,item_rarity: String="") -> String:
 roll_amulet(game,item_rarity)
 var rng=RandomNumberGenerator.new()
 rng.seed=int(game.run_seed)*53+game.stage*1009+int(game.run_metrics.get("chests",0))*271+game.kills+int(TUNING.chest_seed_offset)
 if game.world_content_version<2 or rng.randf()>=float(TUNING.chest_chance):return ""
 var element: String=Elements.IDS[rng.randi_range(0,Elements.IDS.size()-1)]
 game.gems.add(element);game.chest_gem=element
 game.toast("%s socket gem found in the chest"%Elements.display_name(element));game.play_sound("gem.pickup")
 return element

# Imbued Amulet: only Epic or Legendary chest rewards can carry one, and only
# Elements.TUNING.amulet.max_per_run can be found in a run, so it unlocks a second socket on one weapon.
static func roll_amulet(game: Node,item_rarity: String) -> bool:
 var t: Dictionary=Elements.TUNING.amulet
 if game.world_content_version<2 or not item_rarity in ["epic","legendary"] or game.amulets_found>=int(t.max_per_run):return false
 var rng=RandomNumberGenerator.new()
 rng.seed=int(game.run_seed)*97+game.stage*1013+int(game.run_metrics.get("chests",0))*389+game.kills+int(TUNING.chest_seed_offset)+11
 if rng.randf()>=float(t.chest_chance):return false
 game.amulets+=1;game.amulets_found+=1;game.chest_amulet=true
 game.toast("Imbued Amulet found: unlocks a second socket on one weapon");game.play_sound("gem.pickup")
 return true
# Spends one amulet to give `weapon_id` its second socket. Atomic: both change or neither.
static func use_amulet(game: Node,weapon_id: int) -> Dictionary:
 if int(game.amulets)<1:return {"ok":false,"reason":"no_amulet"}
 if not game.weapons.has(weapon_id):return {"ok":false,"reason":"weapon_not_owned"}
 if not WeaponSockets.can_unlock_second(game.weapons[weapon_id]):return {"ok":false,"reason":"already_unlocked"}
 if not WeaponSockets.unlock_second(game.weapons[weapon_id]):return {"ok":false,"reason":"unlock_failed"}
 game.amulets-=1
 return {"ok":true,"reason":""}

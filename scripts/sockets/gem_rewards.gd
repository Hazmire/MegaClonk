class_name GemRewards
extends RefCounted

# Where gems come from besides vases: shop offers and a chance on chest rewards.
const TUNING={
 "chest_chance":0.12,        # GUESS: not specified, kept modest because gems are also sold and dropped by vases
 "shop_slot_chance":0.25,    # GUESS: chance that each of a shop's three offers is a gem instead of an item
 "shop_seed_offset":7100113,
 "chest_seed_offset":3300217
}
# Shop gems are ordinary slots in a shop's randomised offers, encoded as negative ids so they
# can share the offers array (and its save format) with item ids: -1 = first element, -2 = second...
static func offer_code(element: String) -> int:
 return -(Elements.IDS.find(element)+1)
static func offer_element(code: int) -> String:
 var index=-int(code)-1
 return str(Elements.IDS[index]) if code<0 and index<Elements.IDS.size() else ""
static func is_gem_offer(code: Variant) -> bool:
 return int(code)<0 and offer_element(int(code))!=""
# JSON turns saved ints into floats, so membership must compare as ints.
static func has_code(list: Variant,code: int) -> bool:
 if not list is Array:return false
 for value in list:
  if int(value)==code:return true
 return false
# Turns some of a freshly drawn offers array into gem slots (deterministic per shop).
static func mix_offers(game: Node,object: Dictionary) -> void:
 if game.world_content_version<2 or not object.get("offers") is Array:return
 var offers: Array=object.offers
 var rng=RandomNumberGenerator.new()
 rng.seed=int(game.run_seed)*31+game.stage*977+game.interactables.find(object)*131+int(TUNING.shop_seed_offset)
 var taken=[]
 for i in offers.size():
  if rng.randf()>=float(TUNING.shop_slot_chance):continue
  var pool=Elements.IDS.filter(func(e): return not e in taken)
  if pool.is_empty():break
  var element=str(pool[rng.randi_range(0,pool.size()-1)]);taken.append(element)
  offers[i]=offer_code(element)
# Buys a gem slot. The shop keeps its one-purchase-per-seller rule, like item purchases.
static func buy_offer(game: Node,object: Dictionary,code: int) -> Dictionary:
 if game.mode!="shop" or object.get("used",false):return {"ok":false,"reason":"sold"}
 if not is_gem_offer(code) or not has_code(object.get("offers",[]),code):return {"ok":false,"reason":"not_offered"}
 if has_code(object.get("sold",[]),code):return {"ok":false,"reason":"sold"}
 if int(game.gold)<ImbueRules.SHOP_PRICE:return {"ok":false,"reason":"not_enough_gold"}
 var element=offer_element(code)
 game.gold-=ImbueRules.SHOP_PRICE
 game.gems.add(element)
 object["used"]=true
 if not object.has("sold"):object["sold"]=[]
 object["sold"].append(code)
 if object.has("node") and is_instance_valid(object.node):
  game.combat_fx.burst("smoke_puff",object.node.position+Vector3.UP,2);object.node.hide()
 game.play_sound("purchase");game.toast("%s socket gem purchased"%Elements.display_name(element))
 game.resume()
 return {"ok":true,"element":element}
# Called when a chest produces an item. Returns the element granted, or "".
static func roll_chest(game: Node,item_rarity: String="") -> String:
 roll_amulet(game,item_rarity)
 var rng=RandomNumberGenerator.new()
 rng.seed=int(game.run_seed)*53+game.stage*1009+int(game.run_metrics.get("chests",0))*271+game.kills+int(TUNING.chest_seed_offset)
 if game.world_content_version<2 or rng.randf()>=float(TUNING.chest_chance):return ""
 var element: String=Elements.IDS[rng.randi_range(0,Elements.IDS.size()-1)]
 game.gems.add(element);game.chest_gem=element
 game.gem_discovered(element)
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

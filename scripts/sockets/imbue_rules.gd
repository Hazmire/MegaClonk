class_name ImbueRules
extends RefCounted

# Imbue Station transaction rules. This is pure game logic with no UI, so the station
# interface only has to call install() and show the returned reason.
const COSTS=[500,1000,1500] # Stage 1, 2, 3. Later stages reuse the last entry.
const SHOP_PRICE=250 # legacy; shop gems are now priced by Economy.gem_price(stage)

static func cost(stage: int,discount: float=0.0) -> int:
 return maxi(1,int(round(float(COSTS[clampi(stage-1,0,COSTS.size()-1)])*(1.0-clampf(discount,0.0,0.9)))))
# Returns "" when the installation is allowed, otherwise the first problem found.
static func problem(game: Object, weapon_id: int, element: String) -> String:
 if not game.weapons.has(weapon_id):return "weapon_not_owned"
 var socket_problem=WeaponSockets.install_problem(game.weapons[weapon_id],element)
 if socket_problem!="":return socket_problem
 if game.gems.count(element)<1:return "no_gem"
 if game.gold<cost(game.stage,game.irt.imbue_discount()):return "insufficient_gold"
 return ""
# Same as problem(), for the screen: whether this element could go into this weapon at all, ignoring whether you can afford it is
# reported separately as insufficient_gold (so the screen can still offer the socket and then say why it cannot be fused).
static func problem_for_slot(game: Object, weapon_id: int, element: String) -> String:return problem(game,weapon_id,element)
# Atomic: either the gem is installed, one gem is consumed and the gold is deducted once,
# or nothing changes at all.
static func install(game: Object, weapon_id: int, element: String) -> Dictionary:
 var reason=problem(game,weapon_id,element)
 if reason!="":return {"ok":false,"reason":reason,"cost":0}
 var price=cost(game.stage,game.irt.imbue_discount())
 var state: Dictionary=game.weapons[weapon_id]
 var snapshot=WeaponSockets.serialize(state)
 if not WeaponSockets.install(state,element):return {"ok":false,"reason":"install_failed","cost":0}
 if not game.gems.remove(element,1):
  WeaponSockets.restore(state,snapshot)
  return {"ok":false,"reason":"gem_remove_failed","cost":0}
 game.gold-=price
 game.irt.anvil_bonus(weapon_id)
 return {"ok":true,"reason":"","cost":price}
# Player-facing wording for a problem() / buy() reason code.
static func reason_text(reason: String) -> String:
 match reason:
  "weapon_not_owned":return "Weapon not owned"
  "invalid_element":return "Unknown element"
  "no_free_socket":return "No free socket"
  "duplicate_element":return "This weapon already holds that element"
  "no_gem":return "You have no gem of that element"
  "insufficient_gold":return "Not enough gold"
  "not_enough_gold":return "Not enough gold"
  "no_amulet":return "You have no Imbued Amulet"
  "already_unlocked":return "Second socket already unlocked"
  "sold":return "Sold out"
  "not_offered":return "Not for sale here"
 return reason.replace("_"," ").capitalize()

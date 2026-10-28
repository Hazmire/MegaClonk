class_name ImbueRules
extends RefCounted

# Imbue Station transaction rules. This is pure game logic with no UI, so the station
# interface only has to call install() and show the returned reason.
const COSTS=[500,1000,1500] # Stage 1, 2, 3. Later stages reuse the last entry.
const SHOP_PRICE=250

static func cost(stage: int) -> int:
 return int(COSTS[clampi(stage-1,0,COSTS.size()-1)])
# Returns "" when the installation is allowed, otherwise the first problem found.
static func problem(game: Object, weapon_id: int, element: String) -> String:
 if not game.weapons.has(weapon_id):return "weapon_not_owned"
 var socket_problem=WeaponSockets.install_problem(game.weapons[weapon_id],element)
 if socket_problem!="":return socket_problem
 if game.gems.count(element)<1:return "no_gem"
 if game.gold<cost(game.stage):return "insufficient_gold"
 return ""
# Atomic: either the gem is installed, one gem is consumed and the gold is deducted once,
# or nothing changes at all.
static func install(game: Object, weapon_id: int, element: String) -> Dictionary:
 var reason=problem(game,weapon_id,element)
 if reason!="":return {"ok":false,"reason":reason,"cost":0}
 var price=cost(game.stage)
 var state: Dictionary=game.weapons[weapon_id]
 var snapshot=WeaponSockets.serialize(state)
 if not WeaponSockets.install(state,element):return {"ok":false,"reason":"install_failed","cost":0}
 if not game.gems.remove(element,1):
  WeaponSockets.restore(state,snapshot)
  return {"ok":false,"reason":"gem_remove_failed","cost":0}
 game.gold-=price
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
  "sold":return "Sold out"
  "not_offered":return "Not for sale here"
 return reason.replace("_"," ").capitalize()

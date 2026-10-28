class_name WeaponSockets
extends RefCounted

# Socket state lives inside each weapon's existing state dictionary under "sockets", so it
# follows the weapon through upgrades, rarity changes, stage transitions and saves without
# the weapon's other fields needing to know about it.
#   state.sockets = {"unlocked": 1 or 2, "gems": [element ids in install order]}
const DEFAULT_SOCKETS=1
const MAX_SOCKETS=2

static func ensure(state: Dictionary) -> void:
 if not state.get("sockets") is Dictionary:
  state["sockets"]={"unlocked":DEFAULT_SOCKETS,"gems":[]}
static func unlocked(state: Dictionary) -> int:
 ensure(state);return int(state.sockets.unlocked)
static func gems(state: Dictionary) -> Array:
 ensure(state);return state.sockets.gems
static func free_sockets(state: Dictionary) -> int:
 return unlocked(state)-gems(state).size()
static func has_gem(state: Dictionary, element: String) -> bool:
 return element in gems(state)
# Returns "" when the gem can be installed, otherwise a short machine-readable reason.
static func install_problem(state: Dictionary, element: String) -> String:
 if not Elements.valid(element):return "invalid_element"
 if free_sockets(state)<=0:return "no_free_socket"
 if has_gem(state,element):return "duplicate_element"
 return ""
static func install(state: Dictionary, element: String) -> bool:
 if install_problem(state,element)!="":return false
 gems(state).append(element);return true
static func can_unlock_second(state: Dictionary) -> bool:
 return unlocked(state)<MAX_SOCKETS
static func unlock_second(state: Dictionary) -> bool:
 if not can_unlock_second(state):return false
 state.sockets.unlocked=MAX_SOCKETS;return true
# Dual-element combination for this weapon, or an empty dictionary. Order never matters.
static func combo(state: Dictionary) -> Dictionary:
 var installed=gems(state)
 if installed.size()<2:return {}
 return Elements.combo(str(installed[0]),str(installed[1]))
static func serialize(state: Dictionary) -> Dictionary:
 ensure(state)
 return {"unlocked":unlocked(state),"gems":gems(state).duplicate()}
# Sanitises untrusted data: clamps socket count, drops unknown or duplicate elements and
# never keeps more gems than unlocked sockets.
static func restore(state: Dictionary, data: Variant) -> void:
 state.erase("sockets");ensure(state)
 if not data is Dictionary:return
 state.sockets.unlocked=clampi(int(data.get("unlocked",DEFAULT_SOCKETS)),DEFAULT_SOCKETS,MAX_SOCKETS)
 var saved=data.get("gems",[])
 if not saved is Array:return
 for element in saved:
  install(state,str(element))

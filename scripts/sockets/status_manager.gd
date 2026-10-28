class_name StatusManager
extends RefCounted

# Central entry point for elemental status effects. Combat code never contains element
# logic: game.gd only calls modify_damage(), on_hit(), tick() and on_death() below.
#
# Per-enemy state lives in the enemy dictionary under "fx". It is created lazily on the
# first status, so enemies that never meet a socketed weapon pay nothing, and it holds only
# plain numbers/strings/arrays so it survives the JSON save as-is (note JSON turns ints into
# floats, so read counters with int()).
#   fx = {"cd": {proc cooldown key: seconds left}, ...one entry per active status...}
#
# No timer nodes, no per-hit allocations when nothing is socketed, no materials created here.
const MAX_DEPTH=2 # Re-entrancy bound: an effect may trigger one follow-up, never a loop.
static var depth=0

static func active(e: Dictionary) -> bool:
 return e.get("fx") is Dictionary
static func state(e: Dictionary) -> Dictionary:
 if not active(e):e["fx"]={"cd":{}}
 return e.fx
# Statuses must never outlive the enemy: called on death and whenever an enemy is reset.
static func clear(e: Dictionary) -> void:
 e.erase("fx")
static func is_boss(e: Dictionary) -> bool:
 return Elements.is_boss_kind(int(e.get("kind",0)))
# Elements installed on the weapon that dealt this hit (empty for unsocketed weapons and for
# non-weapon damage sources, which use negative ids).
static func weapon_elements(game: Object, weapon: int) -> Array:
 if weapon<0 or not game.weapons.has(weapon):return []
 return WeaponSockets.gems(game.weapons[weapon])

# Per-target proc cooldowns, shared by every weapon. A cooldown is only started by the
# caller when a proc actually happens, so failed rolls never reset it.
static func cooldown_ready(e: Dictionary, key: String) -> bool:
 return not (active(e) and e.fx.cd.has(key))
static func start_cooldown(e: Dictionary, key: String, seconds: float) -> void:
 if seconds>0:state(e).cd[key]=seconds

# Bounded re-entrancy for effects that deal damage or trigger other effects.
static func enter() -> bool:
 if depth>=MAX_DEPTH:return false
 depth+=1;return true
static func leave() -> void:
 depth=maxi(0,depth-1)

# Called once per enemy per physics tick, only for enemies that have status state.
static func tick(_game: Object, e: Dictionary, delta: float) -> void:
 if not active(e):return
 var cooldowns: Dictionary=e.fx.cd
 for key in cooldowns.keys():
  cooldowns[key]=float(cooldowns[key])-delta
  if cooldowns[key]<=0:cooldowns.erase(key)
 if cooldowns.is_empty() and e.fx.size()==1:clear(e)

# Hook inside Game.hit(), after the final critical/variant damage is known and before it is
# applied. Element effects that scale final damage (Ignite on critical hits) go here.
static func modify_damage(_game: Object, _e: Dictionary, amount: float, _critical: bool, _weapon: int) -> float:
 return amount
# Hook inside Game.hit(), after damage is applied. Fires at most once per hit() call.
static func on_hit(game: Object, e: Dictionary, weapon: int, _critical: bool, _dealt: float) -> void:
 if weapon_elements(game,weapon).is_empty() or not enter():return
 leave()
# Hook inside Game.kill_enemy(), before rewards, so death effects can still read statuses.
static func on_death(_game: Object, e: Dictionary) -> void:
 clear(e)

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

# ---------------------------------------------------------------- shared helpers
# Direct status damage. It never calls Game.hit(), so it cannot roll crits, cannot re-trigger
# on_hit() and cannot recurse. Death is detected by the normal hp<=0 sweep in Game.
static func deal(game: Object, e: Dictionary, amount: float, weapon: int, color: Color=Color("bcff83"), show_number: bool=true) -> float:
 if e.hp<=0 or amount<=0.0:return 0.0
 var actual=minf(amount,float(e.hp))
 e.hp-=amount;e["last_weapon"]=weapon
 game.damage_total+=actual
 game.damage_by_weapon[weapon]=game.damage_by_weapon.get(weapon,0.0)+actual
 if show_number and game.settings.numbers and DisplayServer.get_name()!="headless" and is_instance_valid(game.numbers) and (is_boss(e) or amount>=3.0):
  game.numbers.show_damage(e.pos+Vector3.UP,amount,false,color,game.elapsed)
 return actual
static func stunned(e: Dictionary) -> bool:
 return active(e) and e.fx.has("stun")
# Instance colour for an element status (ordinary enemies and bosses share it).
static func tint(e: Dictionary, fallback: Color) -> Color:
 if not active(e):return fallback
 if e.fx.has("chill"):return Color("8fd8ff")
 if e.fx.has("poison"):return Color("a4ff6a")
 return fallback
static func chill_stacks(e: Dictionary) -> int:
 return int(e.fx.chill.stacks) if active(e) and e.fx.has("chill") else 0
static func poisoned(e: Dictionary) -> bool:
 return active(e) and e.fx.has("poison")

# ---------------------------------------------------------------- application
static func apply_corrosive(game: Object, e: Dictionary, weapon: int) -> void:
 var t: Dictionary=Elements.TUNING.corrosive
 var fx=state(e)
 var started=not fx.has("poison")
 # Refreshes to full duration; it never stacks, so overlapping weapons cannot multiply the damage.
 fx["poison"]={"left":float(t.duration)*game.irt.status_longer(),"clock":float(fx.poison.clock) if not started else float(t.interval),"weapon":weapon}
 if started and cooldown_ready(e,"fx_poison_sound"):
  start_cooldown(e,"fx_poison_sound",float(t.interval));game.play_sound("status.poison")
static func consume_chill(e: Dictionary, stacks: int) -> void:
 if not active(e) or not e.fx.has("chill"):return
 e.fx.chill["stacks"]=maxi(0,int(e.fx.chill.stacks)-stacks)
 if int(e.fx.chill.stacks)<=0:
  restore_speed(e);e.fx.erase("chill")
 else:apply_speed(e)
static func apply_chill(game: Object, e: Dictionary, stacks: int=1) -> void:
 var t: Dictionary=Elements.TUNING.ice
 var fx=state(e)
 var chill: Dictionary=fx.get("chill",{"stacks":0,"since":0.0,"decay":float(t.decay_interval),"base_speed":float(e.speed),"applied":-1.0})
 chill["stacks"]=mini(int(t.max_stacks),int(chill.stacks)+stacks);chill["since"]=0.0
 fx["chill"]=chill
 apply_speed(e)
static func chill_multiplier(e: Dictionary) -> float:
 var t: Dictionary=Elements.TUNING.ice
 var slow=float(t.slow_per_stack)*chill_stacks(e)
 if is_boss(e):slow=minf(slow,float(t.boss_max_slow))
 return 1.0-slow
# Chill scales e.speed in place (every movement routine already reads it) and remembers the
# unchilled value. If another system rewrites e.speed meanwhile, that value becomes the new base.
static func apply_speed(e: Dictionary) -> void:
 var chill: Dictionary=e.fx.chill
 if float(chill.applied)>=0.0 and absf(float(e.speed)-float(chill.applied))>0.001:chill["base_speed"]=float(e.speed)
 e.speed=float(chill.base_speed)*chill_multiplier(e)
 chill["applied"]=float(e.speed)
static func restore_speed(e: Dictionary) -> void:
 if active(e) and e.fx.has("chill"):
  var chill: Dictionary=e.fx.chill
  e.speed=float(chill.base_speed) if absf(float(e.speed)-float(chill.applied))<=0.001 else e.speed
static func apply_ignite(game: Object, e: Dictionary, weapon: int) -> bool:
 var t: Dictionary=Elements.TUNING.fire
 if float(e.get("burn",0.0))>0.0:return false # non-refreshing while already burning
 e.burn=float(t.ignite_duration)*game.irt.status_longer();e["burn_source"]=weapon;e["burn_clock"]=0.0
 game.play_sound("status.ignite")
 return true
# Returns the stun duration actually applied (0 when nothing happened).
static func apply_stun(game: Object, e: Dictionary, weapon: int) -> float:
 var t: Dictionary=Elements.TUNING.electricity
 if not cooldown_ready(e,"stun_proc") or not cooldown_ready(e,"stun_immunity"):return 0.0
 var fx=state(e)
 var dr: Dictionary=fx.get("stun_dr",{"count":0,"since":0.0})
 var index=mini(int(dr.count),t.stun_durations.size()-1)
 var duration=float(t.stun_durations[index])*game.irt.status_longer()
 var boss=is_boss(e)
 if boss:duration=minf(duration,float(t.boss_max_stun))
 dr["count"]=int(dr.count)+1;dr["since"]=0.0;fx["stun_dr"]=dr
 fx["stun"]={"left":maxf(float(fx.get("stun",{}).get("left",0.0)),duration)}
 start_cooldown(e,"stun_proc",float(t.proc_cooldown))
 if boss:start_cooldown(e,"stun_immunity",float(t.boss_immunity))
 e.frozen=maxf(float(e.frozen),duration)
 game.play_sound("status.stun")
 if is_instance_valid(game.combat_fx):game.combat_fx.burst("sparks_shower",e.pos,0.5,0.2)
 return duration

# ---------------------------------------------------------------- per-tick update
# Called once per enemy per physics tick, only for enemies that have status state.
static func tick(game: Object, e: Dictionary, delta: float) -> void:
 if not active(e):return
 var fx: Dictionary=e.fx
 var cooldowns: Dictionary=fx.cd
 for key in cooldowns.keys():
  cooldowns[key]=float(cooldowns[key])-delta
  if cooldowns[key]<=0:cooldowns.erase(key)
 if fx.has("poison"):tick_poison(game,e,fx.poison,delta)
 if fx.has("chill"):tick_chill(e,fx.chill,delta,game.irt.chill_hold())
 if fx.has("stun"):
  var stun: Dictionary=fx.stun
  stun["left"]=float(stun.left)-delta
  if float(stun.left)<=0.0:fx.erase("stun")
  else:e.frozen=maxf(float(e.frozen),float(stun.left)) # existing movement/attack code already honours frozen
 if fx.has("stun_dr"):
  fx.stun_dr["since"]=float(fx.stun_dr.since)+delta
  if float(fx.stun_dr.since)>=float(Elements.TUNING.electricity.diminish_reset):fx.erase("stun_dr")
 if cooldowns.is_empty() and fx.size()==1:clear(e)
static func tick_poison(game: Object, e: Dictionary, poison: Dictionary, delta: float) -> void:
 var t: Dictionary=Elements.TUNING.corrosive
 poison["left"]=float(poison.left)-delta;poison["clock"]=float(poison.clock)-delta
 while float(poison.clock)<=0.0 and e.hp>0:
  poison["clock"]=float(poison.clock)+float(t.interval)
  var boss=is_boss(e)
  var amount=float(e.hp)*(float(t.boss_percent_current_hp) if boss else float(t.percent_current_hp))
  if boss:amount=minf(amount,float(t.boss_tick_cap))
  amount*=game.irt.corrosion_mult()
  deal(game,e,amount,int(poison.weapon),Color("a4ff6a"))
 if float(poison.left)<=0.0:e.fx.erase("poison")
static func tick_chill(e: Dictionary, chill: Dictionary, delta: float,hold: float=1.0) -> void:
 var t: Dictionary=Elements.TUNING.ice
 chill["since"]=float(chill.since)+delta
 if float(chill.since)>=float(t.decay_delay)*hold:
  chill["decay"]=float(chill.decay)-delta
  if float(chill.decay)<=0.0:
   chill["decay"]=float(t.decay_interval);chill["stacks"]=int(chill.stacks)-1
 if int(chill.stacks)<=0:
  restore_speed(e);e.fx.erase("chill");return
 apply_speed(e)

# ---------------------------------------------------------------- hooks used by Game
# Hook inside Game.hit(), after the final critical/variant damage is known and before it is
# applied. Fire adds +20% to the critical damage multiplier (so the bonus is additive to it).
static func modify_damage(game: Object, _e: Dictionary, amount: float, critical: bool, weapon: int) -> float:
 if not critical or weapon<0:return amount
 if not "fire" in weapon_elements(game,weapon):return amount
 var multiplier=float(game.stats.crit_damage)
 if multiplier<=0.0:return amount
 return amount*(multiplier+float(Elements.TUNING.fire.crit_damage_bonus))/multiplier
# Hook inside Game.hit(), after damage is applied. Fires at most once per hit() call.
static func on_hit(game: Object, e: Dictionary, weapon: int, _critical: bool, _dealt: float) -> void:
 var elements=weapon_elements(game,weapon)
 if elements.is_empty() or not enter():return
 if "ice" in elements:
  # Blightfrost (ice + corrosive): poisoned targets gain extra chill per hit.
  var extra=0
  if "corrosive" in elements and poisoned(e):extra=int(Elements.TUNING.combos.blightfrost.extra_chill_stacks)
  apply_chill(game,e,1+extra)
 if e.hp>0:
  if "corrosive" in elements:apply_corrosive(game,e,weapon)
  if "fire" in elements and (game.rng.randf()<float(Elements.TUNING.fire.ignite_chance) or (game.irt.has("saints_finger") and game.rng.randf()<float(Elements.TUNING.fire.ignite_chance))):apply_ignite(game,e,weapon)
  if "electricity" in elements and cooldown_ready(e,"stun_proc") and (game.rng.randf()<float(Elements.TUNING.electricity.stun_chance) or (game.irt.has("saints_finger") and game.rng.randf()<float(Elements.TUNING.electricity.stun_chance))):apply_stun(game,e,weapon)
  if elements.size()>1:Combos.evaluate(game,e,weapon,Elements.combo(str(elements[0]),str(elements[1])))
 leave()
# Ice Shatter: a chilled enemy that dies cracks, hurting its neighbours for a share of THEIR
# max HP (capped). Victims carry a generation number so a chain of shatters stops at the
# configured depth, even though each victim dies on a later tick.
static func shatter(game: Object, e: Dictionary) -> void:
 if chill_stacks(e)<=0:return
 var t: Dictionary=Elements.TUNING.ice
 var generation=int(e.fx.get("shatter_gen",0))
 if generation>=int(t.shatter_max_depth):return
 var weapon=int(e.get("last_weapon",-1))
 for victim in game.nearby(e.pos,float(t.shatter_radius)+game.irt.shatter_bonus_radius()):
  if victim==e or victim.hp<=0:continue
  deal(game,victim,minf(float(t.shatter_damage_cap),float(victim.max_hp)*float(t.shatter_percent_max_hp))*game.irt.status_harder(),weapon,Color("8fd8ff"))
  var vfx=state(victim);vfx["shatter_gen"]=maxi(int(vfx.get("shatter_gen",0)),generation+1)
 game.play_sound("status.ice_shatter")
 if is_instance_valid(game.combat_fx):game.combat_fx.supplied_burst("shatter",e.pos,1.0)
# Hook inside Game.kill_enemy(), before rewards, so death effects can still read statuses.
static func on_death(game: Object, e: Dictionary) -> void:
 if active(e):shatter(game,e)
 clear(e)

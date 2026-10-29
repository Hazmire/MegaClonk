class_name ItemRuntime
extends RefCounted

# Item Overhaul runtime (game.irt). One object owns every relic effect. Rules:
#  * Catalog.ITEMS (data/items.json) is the only place names, tiers and effect text live; ItemStats holds every number.
#  * game.items is the inventory: an Array of {"id": String, "stacks": int}. This object mirrors it in `stacks`.
#  * Stat effects are folded into game.stats as deltas (`applied`), recomputed only when something changes.
#  * Damage dealt BY an item goes through Game.hit() with ctx {"item": true, "source": "item:<id>"} and never triggers
#    on_hit/on_crit item procs (Game.hit only calls on_hit for weapon hits). Kills made by item damage do not trigger
#    on_kill procs either (enemy flag last_item). No item can therefore chain into another.
#  * Saint's Finger adds one extra roll to weapon-hit procs only (roll_hit).
#  * Hooks cost nothing when no owned item uses them: every call site checks a boolean flag first.
#  * Summons live in hard-capped arrays; anything refused is counted in `counters_dropped`.
const SOURCE_PREFIX="item:"

var game: Node
var stacks: Dictionary={}
var counters: Dictionary={}   # persistent run numbers (chests opened, executions, level-ups traded...)
var buffs: Dictionary={}      # timed effects: name -> seconds left
var applied: Dictionary={}    # stat deltas currently folded into game.stats
var rng=RandomNumberGenerator.new()
var dropped: Dictionary={}    # pool name -> refused spawns (reported by the profiler)
# Cheap flags rebuilt whenever the inventory changes.
var any=false
var cond_damage=false
var hit_hooks=false
var kill_hooks=false
var ticking=false

func _init(owner: Node=null) -> void:
 game=owner

# ---------------------------------------------------------------- inventory mirror
func n(id: String) -> int:return int(stacks.get(id,0))
func has(id: String) -> bool:return stacks.has(id)
func reset() -> void:
 stacks.clear();counters.clear();buffs.clear();applied.clear();dropped.clear()
 rng.seed=(int(game.run_seed) if game!=null else 0)+int(ItemStats.DROPS.rng_seed_offset)
 clear_effects()
 rebuild()
# Rebuild the stack mirror and the hook flags from game.items.
func rebuild() -> void:
 stacks.clear()
 for entry in game.items:stacks[str(entry.id)]=int(entry.stacks)
 any=not stacks.is_empty()
 cond_damage=false
 for id in ["executioners_hood","bounty_writ","brutes_gauntlet","plague_mask"]:
  if stacks.has(id):cond_damage=true
 refresh_flags()
func refresh_flags() -> void:
 pass
func clear_effects() -> void:
 pass

# ---------------------------------------------------------------- on_stats
# Stat deltas from every owned item. Percentages are additive within the stat (the base game's stats are multipliers).
func compute_mods() -> Dictionary:
 var m={}
 m["damage"]=n("whetstone")*ItemStats.v("whetstone","damage")+n("bitter_wine")*ItemStats.v("bitter_wine","damage")+n("bloodletting_knife")*ItemStats.v("bloodletting_knife","damage")
 m["speed"]=n("pilgrims_sandals")*ItemStats.v("pilgrims_sandals","speed")+n("mourners_veil")*ItemStats.v("mourners_veil","speed")
 m["crit"]=n("knucklebone")*ItemStats.v("knucklebone","crit")+n("rosary_teeth")*ItemStats.v("rosary_teeth","crit")
 m["crit_damage"]=n("rosary_teeth")*ItemStats.v("rosary_teeth","crit_damage")
 m["haste"]=n("flagellants_cord")*ItemStats.v("flagellants_cord","haste")
 m["regen"]=n("tallow_candle")*ItemStats.v("tallow_candle","regen")
 m["gold_gain"]=n("tithe_purse")*ItemStats.v("tithe_purse","gold_gain")
 m["xp"]=n("bone_reliquary")*ItemStats.v("bone_reliquary","xp")
 m["armor"]=n("grave_salt")*ItemStats.v("grave_salt","armor")
 m["count"]=n("pilgrims_pack")*ItemStats.v("pilgrims_pack","count")
 var evade_n=n("crowsfoot_charm")
 if evade_n>0:m["evasion"]=minf(float(ItemStats.T.evasion_cap),1.0-pow(1.0-ItemStats.v("crowsfoot_charm","evasion"),evade_n))
 # max health: flat + percentage of the health the player would have without items
 var flat=n("salted_pork")*ItemStats.v("salted_pork","max_health")+n("grave_salt")*ItemStats.v("grave_salt","max_health")+n("bloodletting_knife")*ItemStats.v("bloodletting_knife","max_health")
 var pct=n("bitter_wine")*ItemStats.v("bitter_wine","max_health_pct")
 mods_extra(m)
 flat+=float(m.get("max_health_flat",0.0));m.erase("max_health_flat")
 var base=float(game.stats.max_health)-float(applied.get("max_health",0.0))
 var delta=flat+pct*base
 m["max_health"]=maxf(float(ItemStats.T.max_health_floor)-base,delta) if (flat!=0.0 or pct!=0.0) else 0.0
 return m
# Later batches add their own stat contributions here.
func mods_extra(_m: Dictionary) -> void:
 pass
# Folds the difference between the wanted and the already-applied modifiers into game.stats.
func refresh_stats() -> void:
 if game==null or not "stats" in game:return
 var want=compute_mods()
 var keys={}
 for k in want:keys[k]=true
 for k in applied:keys[k]=true
 for k in keys:
  var d=float(want.get(k,0.0))-float(applied.get(k,0.0))
  if absf(d)<0.0000001:continue
  game.stats[k]=float(game.stats.get(k,0.0))+d
  if k=="max_health":
   if d>0.0:game.health=minf(game.stats.max_health,game.health+d)
   else:game.health=minf(game.health,game.stats.max_health)
 applied=want

func vase_gold_mult() -> float:return 1.0+ItemStats.v("hex_penny","vase_gold")*float(n("hex_penny"))

# ---------------------------------------------------------------- acquisition
func on_acquire(id: String) -> void:
 rebuild();refresh_stats()

# ---------------------------------------------------------------- damage modifiers (Game.hit)
func is_boss(e: Dictionary) -> bool:return Elements.is_boss_kind(int(e.get("kind",0)))
func is_elite(e: Dictionary) -> bool:return bool(e.get("elite",false)) or is_boss(e)
# Multiplier for one hit. item_hit damage only receives the "all sources" vulnerability bonuses.
func damage_mult(e: Dictionary,item_hit: bool) -> float:
 var m=1.0
 if not item_hit:
  if stacks.has("executioners_hood") and float(e.hp)>float(e.max_hp)*ItemStats.v("executioners_hood","above"):m*=1.0+ItemStats.v("executioners_hood","bonus")*n("executioners_hood")
  if stacks.has("bounty_writ") and is_elite(e):m*=1.0+ItemStats.v("bounty_writ","bonus")*n("bounty_writ")
  if stacks.has("brutes_gauntlet") and e.pos.distance_to(game.player.position)<=ItemStats.v("brutes_gauntlet","radius"):m*=1.0+ItemStats.v("brutes_gauntlet","bonus")*n("brutes_gauntlet")
  if stacks.has("plague_mask") and status_count(e)>0:m*=1.0+ItemStats.v("plague_mask","bonus")*n("plague_mask")
 return m
# Distinct statuses on an enemy: corrosion, chill, burning, stun.
func status_count(e: Dictionary) -> int:
 var c=0
 if float(e.get("burn",0.0))>0.0:c+=1
 if StatusManager.active(e):
  if e.fx.has("poison"):c+=1
  if e.fx.has("chill"):c+=1
  if e.fx.has("stun"):c+=1
 return c

# ---------------------------------------------------------------- on_hit / on_crit (weapon hits only)
func on_hit(_e: Dictionary,_amount: float,_actual: float,_critical: bool,_weapon: int) -> void:
 pass

# ---------------------------------------------------------------- item damage (always through Game.hit)
# Deals item damage. `id` is the item id; the hit is tagged so it can never trigger on_hit procs or on_kill procs.
func deal(e: Dictionary,amount: float,id: String) -> void:
 if e.is_empty() or float(e.hp)<=0.0 or amount<=0.0:return
 game.hit(e,amount,-5,{"item":true,"source":SOURCE_PREFIX+id})

# ---------------------------------------------------------------- state
func serialize() -> Dictionary:
 return {"counters":counters.duplicate(),"buffs":buffs.duplicate(),"applied":applied.duplicate(),"rng_state":str(rng.state),"dropped":dropped.duplicate()}
func restore(data: Variant) -> void:
 reset()
 if not data is Dictionary:rebuild();return
 counters=data.get("counters",{}).duplicate();buffs=data.get("buffs",{}).duplicate();applied=data.get("applied",{}).duplicate();dropped=data.get("dropped",{}).duplicate()
 if data.has("rng_state"):rng.state=int(str(data.rng_state))
 rebuild()

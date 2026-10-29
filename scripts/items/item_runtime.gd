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
var hurt_hooks=false
var still_time=0.0
var meat: Array=[]            # roast meat pickups (Pyre Ashes): {"pos","life"}
var wraiths: Array=[]         # Restless Bones summons: {"pos","life","cd"} (hard cap, see ItemStats)
var black_clock=0.0

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
 for id in ["executioners_hood","bounty_writ","brutes_gauntlet","plague_mask","ouija_planchette"]:
  if stacks.has(id):cond_damage=true
 refresh_flags()
func refresh_flags() -> void:
 kill_hooks=stacks.has("pyre_ashes") or stacks.has("soul_lantern")
 hurt_hooks=stacks.has("thunderstruck_nail") or stacks.has("mourners_veil") or stacks.has("witch_bottle")
 ticking=stacks.has("hermits_ember") or stacks.has("black_candle") or not meat.is_empty() or not wraiths.is_empty() or not buffs.is_empty()
# Stage changes and run starts: summons and pickups never carry over.
func clear_effects() -> void:
 meat.clear();wraiths.clear();still_time=0.0;black_clock=0.0

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
func mods_extra(m: Dictionary) -> void:
 m["speed"]=float(m.get("speed",0.0))+(ItemStats.v("mourners_veil","hurt_speed")*n("mourners_veil") if float(buffs.get("mourner",0.0))>0.0 else 0.0)
 m["damage"]=float(m.get("damage",0.0))+n("tax_ledger")*ItemStats.v("tax_ledger","per_chest")*float(counters.get("chests",0))
 if float(buffs.get("leaden",0.0))>0.0:m["damage"]=float(m.damage)+ItemStats.v("leaden_heart","damage")*n("leaden_heart")
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
func damage_mult(e: Dictionary,item_hit: bool,amount: float=0.0) -> float:
 var m=1.0
 if not item_hit:
  if stacks.has("executioners_hood") and float(e.hp)>float(e.max_hp)*ItemStats.v("executioners_hood","above"):m*=1.0+ItemStats.v("executioners_hood","bonus")*n("executioners_hood")
  if stacks.has("bounty_writ") and is_elite(e):m*=1.0+ItemStats.v("bounty_writ","bonus")*n("bounty_writ")
  if stacks.has("brutes_gauntlet") and e.pos.distance_to(game.player.position)<=ItemStats.v("brutes_gauntlet","radius"):m*=1.0+ItemStats.v("brutes_gauntlet","bonus")*n("brutes_gauntlet")
  if stacks.has("plague_mask") and status_count(e)>0:m*=1.0+ItemStats.v("plague_mask","bonus")*n("plague_mask")
  if stacks.has("ouija_planchette") and rng.randf()<minf(0.75,ItemStats.v("ouija_planchette","chance")*n("ouija_planchette")):
   var big=ItemStats.v("ouija_planchette","mult")
   if is_boss(e) or is_elite(e):
    var cap=ItemStats.v("ouija_planchette","boss_cap" if is_boss(e) else "elite_cap")*float(e.max_hp)
    big=clampf(cap/maxf(1.0,amount*m),1.0,big)
   m*=big
   counters["ouija"]=int(counters.get("ouija",0))+1
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

# ---------------------------------------------------------------- chance helper
# Stacked chance of an independent per-stack roll, capped. Uses the item RNG so game.rng consumption never changes.
func chance(id: String,key: String="chance") -> float:
 var k=n(id)
 if k<=0:return 0.0
 var p=ItemStats.v(id,key);var cap=ItemStats.v(id,"cap",0.95)
 return minf(cap,1.0-pow(1.0-p,k))
func roll(id: String) -> bool:
 return stacks.has(id) and rng.randf()<chance(id)

# ---------------------------------------------------------------- on_chest_opened / on_vase_smashed / on_powerup / on_level_up
# Rusted Key: asked before a paid chest charges gold.
func chest_is_free() -> bool:
 if roll("rusted_key"):counters["free_chests"]=int(counters.get("free_chests",0))+1;return true
 return false
func on_chest_opened() -> void:
 if not any:return
 counters["chests"]=int(counters.get("chests",0))+1
 if stacks.has("tax_ledger"):refresh_stats()
 if stacks.has("restless_bones"):summon_wraiths(game.player.position)
func on_vase_smashed(pos: Vector3,reward: Dictionary) -> void:
 var found=ItemDrops.roll_vase(game)
 if found!="":
  game.grant_item(found,true);game.toast("Found %s"%Catalog.item_name(found))
 if not any:return
 if roll("gravediggers_spade"):
  WorldPickups.spawn_reward(game,pos+Vector3(0.4,0.0,0.4),reward);counters["spade"]=int(counters.get("spade",0))+1
 if stacks.has("restless_bones"):summon_wraiths(pos)
func on_powerup(kind: String) -> void:
 if kind=="heart" and stacks.has("leaden_heart"):
  buffs["leaden"]=ItemStats.v("leaden_heart","time");ticking=true;refresh_stats()
func on_level_up() -> void:
 pass
func stopwatch_bonus() -> float:return ItemStats.v("cracked_hourglass","seconds")*float(n("cracked_hourglass"))
func imbue_discount() -> float:
 return minf(ItemStats.v("forgemasters_tongs","cap"),ItemStats.v("forgemasters_tongs","discount")*float(n("forgemasters_tongs")))

# ---------------------------------------------------------------- on_damage_taken / on_evade
# Witch Bottle: its own roll after evasion; capped so the player is never fully immune.
func witch_bottle() -> bool:
 if not stacks.has("witch_bottle"):return false
 if rng.randf()<minf(ItemStats.v("witch_bottle","cap"),1.0-pow(1.0-ItemStats.v("witch_bottle","chance"),n("witch_bottle"))):
  counters["witch"]=int(counters.get("witch",0))+1;return true
 return false
func on_damage_taken(_amount: float) -> void:
 if stacks.has("mourners_veil"):
  buffs["mourner"]=ItemStats.v("mourners_veil","hurt_time");ticking=true;refresh_stats()
 if stacks.has("thunderstruck_nail") and float(buffs.get("nail_cd",0.0))<=0.0:
  buffs["nail_cd"]=ItemStats.v("thunderstruck_nail","cooldown");ticking=true
  var radius=ItemStats.v("thunderstruck_nail","radius")
  var seconds=ItemStats.v("thunderstruck_nail","stun")
  for e in game.nearby(game.player.position,radius):
   if e.hp>0:stun(e,seconds)
  if is_instance_valid(game.combat_fx):game.combat_fx.burst("sparks_shower",game.player.position+Vector3.UP,1.0,0.3)
  counters["nail"]=int(counters.get("nail",0))+1
# Item stun: no proc roll, boss stuns are shortened. Statuses stay inside e.fx like every other status.
func stun(e: Dictionary,seconds: float) -> void:
 if is_boss(e):seconds=minf(seconds,ItemStats.v("thunderstruck_nail","boss_stun"))
 var fx=StatusManager.state(e)
 fx["stun"]={"left":maxf(float(fx.get("stun",{}).get("left",0.0)),seconds)}
 e.frozen=maxf(float(e.frozen),seconds)

# ---------------------------------------------------------------- on_kill (weapon kills only: item damage never feeds procs)
func on_kill(e: Dictionary) -> void:
 if bool(e.get("last_item",false)):return
 if stacks.has("soul_lantern") and rng.randf()<chance("soul_lantern"):
  game.add_xp_drop(e.pos+Vector3(0.6,0.0,0.6),float(e.variant.reward if e.has("variant") else 5));counters["lantern"]=int(counters.get("lantern",0))+1
 if stacks.has("pyre_ashes") and rng.randf()<chance("pyre_ashes"):
  if meat.size()>=int(ItemStats.v("pyre_ashes","pickup_cap")):dropped["meat"]=int(dropped.get("meat",0))+1
  else:meat.append({"pos":e.pos,"life":ItemStats.v("pyre_ashes","pickup_life")});ticking=true

# ---------------------------------------------------------------- summons (pooled in plain arrays, hard cap, drops counted)
func summon_wraiths(at: Vector3) -> void:
 var cap=int(ItemStats.v("restless_bones","cap"))
 for i in int(ItemStats.v("restless_bones","wraiths"))*n("restless_bones"):
  if wraiths.size()>=cap:dropped["wraiths"]=int(dropped.get("wraiths",0))+1;continue
  wraiths.append({"pos":at+Vector3(cos(float(i)*2.4),1.0,sin(float(i)*2.4)),"life":ItemStats.v("restless_bones","life"),"cd":0.0})
 ticking=true

# ---------------------------------------------------------------- on_tick / on_still (only called while `ticking`)
func tick(delta: float) -> void:
 # timed buffs
 if not buffs.is_empty():
  var restat=false
  for k in buffs.keys():
   buffs[k]=float(buffs[k])-delta
   if float(buffs[k])<=0.0:
    buffs.erase(k)
    if k=="mourner" or k=="leaden":restat=true
  if restat:refresh_stats()
 # on_still: Hermit's Ember
 if stacks.has("hermits_ember"):
  var v=game.player.velocity
  if Vector2(v.x,v.z).length()<0.3:
   still_time+=delta
   if still_time>=ItemStats.v("hermits_ember","still_time") and game.health<game.stats.max_health:
    game.health=minf(game.stats.max_health,game.health+game.stats.max_health*ItemStats.v("hermits_ember","heal_pct")*float(n("hermits_ember"))*delta)
  else:still_time=0.0
 # Black Candle aura
 if stacks.has("black_candle"):
  black_clock+=delta
  var interval=ItemStats.v("black_candle","interval")
  if black_clock>=interval:
   black_clock-=interval
   var dmg=ItemStats.v("black_candle","dps")*interval*float(n("black_candle"))*(1.0+ItemStats.v("black_candle","level_scale")*float(maxi(0,game.level-1)))
   for e in game.nearby(game.player.position,ItemStats.v("black_candle","radius")):
    if e.hp>0 and e.pos.distance_to(game.player.position)<=ItemStats.v("black_candle","radius"):deal(e,dmg,"black_candle")
 tick_meat(delta)
 tick_wraiths(delta)
 if buffs.is_empty() and meat.is_empty() and wraiths.is_empty() and not stacks.has("hermits_ember") and not stacks.has("black_candle"):ticking=false
func tick_meat(delta: float) -> void:
 if meat.is_empty():return
 var radius=ItemStats.v("pyre_ashes","pickup_radius")
 for i in range(meat.size()-1,-1,-1):
  var m=meat[i];m.life=float(m.life)-delta
  if m.life<=0.0:meat.remove_at(i);continue
  var pos: Vector3=m.pos+Vector3.UP*0.5
  game.psx.draw_square(pos,0.35,Color("9b4f2e"))
  if pos.distance_to(game.player.position+Vector3.UP)<=radius:
   game.health=minf(game.stats.max_health,game.health+game.stats.max_health*ItemStats.v("pyre_ashes","heal_pct"))
   meat.remove_at(i);counters["meat"]=int(counters.get("meat",0))+1
func tick_wraiths(delta: float) -> void:
 if wraiths.is_empty():return
 var search=ItemStats.v("restless_bones","search");var speed=ItemStats.v("restless_bones","speed")
 var hit_r=ItemStats.v("restless_bones","hit_radius");var dmg=ItemStats.v("restless_bones","damage")+ItemStats.v("restless_bones","damage_per_level")*float(game.level)
 for i in range(wraiths.size()-1,-1,-1):
  var w=wraiths[i];w.life=float(w.life)-delta;w.cd=maxf(0.0,float(w.cd)-delta)
  if w.life<=0.0:wraiths.remove_at(i);continue
  var target=game.nearest(w.pos,search)
  if target.is_empty():target={"pos":game.player.position+Vector3.UP,"hp":0.0}
  var to: Vector3=target.pos+Vector3.UP-w.pos
  if to.length()>0.05:w.pos+=to.normalized()*minf(to.length(),speed*delta)
  if float(target.hp)>0.0 and w.cd<=0.0 and w.pos.distance_to(target.pos+Vector3.UP)<=hit_r+0.4:
   w.cd=ItemStats.v("restless_bones","hit_cooldown");deal(target,dmg,"restless_bones")
  game.psx.draw_square(w.pos,0.55,Color("b8d9ff"))
  if int(w.life*10.0)%2==0:game.psx.draw_square(w.pos+Vector3.UP*0.3,0.3,Color("e6f2ff"))

# ---------------------------------------------------------------- item damage (always through Game.hit)
# Deals item damage. `id` is the item id; the hit is tagged so it can never trigger on_hit procs or on_kill procs.
func deal(e: Dictionary,amount: float,id: String) -> void:
 if e.is_empty() or float(e.hp)<=0.0 or amount<=0.0:return
 game.hit(e,amount,-5,{"item":true,"source":SOURCE_PREFIX+id})

# ---------------------------------------------------------------- state
func serialize() -> Dictionary:
 return {"meat":meat.size(),"counters":counters.duplicate(),"buffs":buffs.duplicate(),"applied":applied.duplicate(),"rng_state":str(rng.state),"dropped":dropped.duplicate()}
func restore(data: Variant) -> void:
 reset()
 if not data is Dictionary:rebuild();return
 counters=data.get("counters",{}).duplicate();buffs=data.get("buffs",{}).duplicate();applied=data.get("applied",{}).duplicate();dropped=data.get("dropped",{}).duplicate()
 if data.has("rng_state"):rng.state=int(str(data.rng_state))
 rebuild()

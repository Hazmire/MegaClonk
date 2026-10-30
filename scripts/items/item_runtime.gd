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
var puddles: Array=[]         # Mire Flask: {"pos","life","clock"}
var burning_count=0           # Witch-Hunter's Brand
var brand_clock=0.0
var hounds: Array=[]          # Grave Hound Whistle: {"pos","dir","left","hit"}
var souls: Array=[]           # Reaper's Sickle: {"pos","life","retarget","target"}
var last_pos=Vector3.INF      # on_move
var travelled=0.0
var curse: Dictionary={}      # Hangman's Noose target
var curse_clock=0.0
var codex_cursor=0
var keg_window=0.0
var keg_count=0
var crit_hooks=false

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
 for id in ["executioners_hood","bounty_writ","brutes_gauntlet","plague_mask","ouija_planchette","tinder_pouch","lodestone","coven_sigil","martyrs_shroud","shade_cloak"]:
  if stacks.has(id):cond_damage=true
 refresh_flags()
func refresh_flags() -> void:
 kill_hooks=stacks.has("pyre_ashes") or stacks.has("soul_lantern") or stacks.has("goat_skull") or stacks.has("reapers_sickle")
 hit_hooks=stacks.has("mire_flask") or stacks.has("powder_keg_heart") or stacks.has("headsmans_oath")
 crit_hooks=stacks.has("butchers_hook") or stacks.has("blood_chalice")
 hurt_hooks=stacks.has("thunderstruck_nail") or stacks.has("mourners_veil") or stacks.has("witch_bottle") or stacks.has("hourglass_damned")
 ticking=stacks.has("hermits_ember") or stacks.has("black_candle") or stacks.has("witch_hunters_brand") or stacks.has("grave_hound_whistle") or stacks.has("hound_whistle") or stacks.has("hangmans_noose") or stacks.has("shattered_codex") or not hounds.is_empty() or not souls.is_empty() or not puddles.is_empty() or not meat.is_empty() or not wraiths.is_empty() or not buffs.is_empty()
# Stage changes and run starts: summons and pickups never carry over.
func clear_effects() -> void:
 meat.clear();wraiths.clear();puddles.clear();hounds.clear();souls.clear();curse={};last_pos=Vector3.INF;travelled=0.0;still_time=0.0;black_clock=0.0;burning_count=0;brand_clock=0.0

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
 m["damage"]=float(m.get("damage",0.0))+ItemStats.v("headsmans_oath","per_execution")*float(counters.get("executions",0))*float(n("headsmans_oath"))
 if stacks.has("devils_bargain"):
  var trades=float(counters.get("bargain",0))*float(n("devils_bargain"))
  m["damage"]=float(m.get("damage",0.0))+ItemStats.v("devils_bargain","damage")*trades
  m["max_health_flat"]=float(m.get("max_health_flat",0.0))-ItemStats.v("devils_bargain","hp")*trades
 if float(buffs.get("shade",0.0))>0.0:
  m["haste"]=float(m.get("haste",0.0))+ItemStats.v("shade_cloak","haste")*float(n("shade_cloak"))
  m["speed"]=float(m.get("speed",0.0))+ItemStats.v("shade_cloak","speed")*float(n("shade_cloak"))
 if stacks.has("witch_hunters_brand") and burning_count>0:
  var k=float(n("witch_hunters_brand"))
  m["armor"]=float(m.get("armor",0.0))+minf(ItemStats.v("witch_hunters_brand","armor_cap")*k,ItemStats.v("witch_hunters_brand","armor_each")*float(burning_count)*k)
  m["lifesteal"]=minf(ItemStats.v("witch_hunters_brand","lifesteal_cap")*k,ItemStats.v("witch_hunters_brand","lifesteal_each")*float(burning_count)*k)
 if float(buffs.get("leaden",0.0))>0.0:m["damage"]=float(m.damage)+ItemStats.v("leaden_heart","damage")*n("leaden_heart")
# Stat change one more stack of `id` would cause ({stat: delta}), worked out by the same compute_mods() the game uses; nothing is
# changed. Shops and rewards show it on the Stats panel before the player commits.
func preview(id: String) -> Dictionary:
 var had=stacks.has(id);var old=int(stacks.get(id,0));stacks[id]=old+1
 var want=compute_mods()
 if had:stacks[id]=old
 else:stacks.erase(id)
 var out={}
 for k in want:
  var d=float(want[k])-float(applied.get(k,0.0))
  if absf(d)>0.0000001:out[k]=d
 return out
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
 # "from all sources" effects also apply to item damage
 if stacks.has("tinder_pouch") and float(e.get("burn",0.0))>0.0:m*=1.0+ItemStats.v("tinder_pouch","bonus")*n("tinder_pouch")
 if stacks.has("lodestone") and StatusManager.stunned(e):m*=1.0+ItemStats.v("lodestone","bonus")*n("lodestone")
 if stacks.has("coven_sigil"):
  var c=status_kinds(e)
  if c>0:m*=1.0+minf(ItemStats.v("coven_sigil","cap")*n("coven_sigil"),ItemStats.v("coven_sigil","per_status")*float(c)*n("coven_sigil"))
 if not item_hit:
  if stacks.has("executioners_hood") and float(e.hp)>float(e.max_hp)*ItemStats.v("executioners_hood","above"):m*=1.0+ItemStats.v("executioners_hood","bonus")*n("executioners_hood")
  if stacks.has("bounty_writ") and is_elite(e):m*=1.0+ItemStats.v("bounty_writ","bonus")*n("bounty_writ")
  if stacks.has("brutes_gauntlet") and e.pos.distance_to(game.player.position)<=ItemStats.v("brutes_gauntlet","radius"):m*=1.0+ItemStats.v("brutes_gauntlet","bonus")*n("brutes_gauntlet")
  if stacks.has("martyrs_shroud"):
   m*=1.0+ItemStats.v("martyrs_shroud","max_bonus")*float(n("martyrs_shroud"))*clampf(1.0-float(game.health)/float(game.stats.max_health),0.0,1.0)
  if counters.get("shade_ready",0)==1:
   counters["shade_ready"]=0;m*=ItemStats.v("shade_cloak","mult")
  if stacks.has("plague_mask") and status_count(e)>0:m*=1.0+ItemStats.v("plague_mask","bonus")*n("plague_mask")
  if stacks.has("ouija_planchette") and rng.randf()<minf(0.75,ItemStats.v("ouija_planchette","chance")*n("ouija_planchette")):
   var big=ItemStats.v("ouija_planchette","mult")
   if is_boss(e) or is_elite(e):
    var cap=ItemStats.v("ouija_planchette","boss_cap" if is_boss(e) else "elite_cap")*float(e.max_hp)
    big=clampf(cap/maxf(1.0,amount*m),1.0,big)
   m*=big
   counters["ouija"]=int(counters.get("ouija",0))+1
 return m
func status_kinds(e: Dictionary) -> int:return status_count(e)
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
func on_hit(e: Dictionary,_amount: float,actual: float,_critical: bool,_weapon: int) -> void:
 if e.hp>0 and stacks.has("headsmans_oath") and roll_hit("headsmans_oath"):execute(e)
 if stacks.has("powder_keg_heart") and roll_hit("powder_keg_heart"):explode(e,actual)
 if stacks.has("mire_flask") and e.hp>0 and StatusManager.poisoned(e) and float(buffs.get("puddle_cd",0.0))<=0.0 and roll_hit("mire_flask"):
  buffs["puddle_cd"]=ItemStats.v("mire_flask","cooldown");ticking=true
  if puddles.size()>=int(ItemStats.v("mire_flask","cap")):dropped["puddles"]=int(dropped.get("puddles",0))+1
  else:puddles.append({"pos":e.pos,"life":ItemStats.v("mire_flask","life"),"clock":0.0})

# ---------------------------------------------------------------- status / combo modifiers (read by StatusManager and Combos)
func status_longer() -> float:return 1.0+ItemStats.v("gem_loupe","longer")*float(n("gem_loupe"))
func status_harder() -> float:return 1.0+ItemStats.v("gem_loupe","harder")*float(n("gem_loupe"))
func corrosion_mult() -> float:return status_harder()*(1.0+ItemStats.v("lepers_bell","bonus")*float(n("lepers_bell")))
func chill_hold() -> float:return status_longer()*(1.0+ItemStats.v("rime_shard","chill_longer")*float(n("rime_shard")))
func shatter_bonus_radius() -> float:return ItemStats.v("rime_shard","shatter_radius")*float(n("rime_shard"))
func combo_radius() -> float:return 1.0+ItemStats.v("alchemist_retort","radius")*float(n("alchemist_retort"))
func combo_cooldown() -> float:return maxf(0.25,1.0-ItemStats.v("alchemist_retort","cooldown")*float(n("alchemist_retort")))
func combo_damage() -> float:return status_harder()*(1.0+ItemStats.v("heretics_prism","bonus")*float(n("heretics_prism")))
func on_combo() -> void:
 if stacks.has("heretics_prism"):
  game.health=minf(game.stats.max_health,game.health+ItemStats.v("heretics_prism","heal")*float(n("heretics_prism")))
  counters["prism"]=int(counters.get("prism",0))+1

# ---------------------------------------------------------------- on_crit (weapon crits only; returns an extra damage multiplier)
func on_crit() -> float:
 var mult=1.0
 if stacks.has("blood_chalice") and roll_hit("blood_chalice"):
  game.health=minf(game.stats.max_health,game.health+game.stats.max_health*ItemStats.v("blood_chalice","heal_pct")*float(n("blood_chalice")))
  counters["chalice"]=int(counters.get("chalice",0))+1
 if stacks.has("butchers_hook") and roll_hit("butchers_hook"):
  mult=ItemStats.v("butchers_hook","mult");counters["brutal"]=int(counters.get("brutal",0))+1
 return mult

# ---------------------------------------------------------------- chance helper
# Stacked chance of an independent per-stack roll, capped. Uses the item RNG so game.rng consumption never changes.
func chance(id: String,key: String="chance") -> float:
 var k=n(id)
 if k<=0:return 0.0
 var p=ItemStats.v(id,key);var cap=ItemStats.v(id,"cap",0.95)
 return minf(cap,1.0-pow(1.0-p,k))
func roll(id: String) -> bool:
 return stacks.has(id) and rng.randf()<chance(id)
# Weapon-hit procs only: Saint's Finger (batch 4) adds one more roll here.
func roll_hit(id: String) -> bool:
 var p=chance(id)
 if p<=0.0:return false
 if rng.randf()<p:return true
 for i in n("saints_finger")*int(ItemStats.v("saints_finger","extra_rolls")):
  if rng.randf()<p:return true
 return false

# ---------------------------------------------------------------- Headsman's Oath / Powder Keg Heart
func execute(e: Dictionary) -> void:
 if is_boss(e):return
 if is_elite(e):
  deal(e,float(e.max_hp)*ItemStats.v("headsmans_oath","elite_percent"),"headsmans_oath");return
 deal(e,float(e.hp)+1.0,"headsmans_oath")
 counters["executions"]=int(counters.get("executions",0))+1;refresh_stats()
func explode(e: Dictionary,actual: float) -> void:
 var now=float(game.elapsed)
 if now-keg_window>=1.0:keg_window=now;keg_count=0
 if keg_count>=int(ItemStats.v("powder_keg_heart","per_second")):dropped["kegs"]=int(dropped.get("kegs",0))+1;return
 keg_count+=1;counters["kegs"]=int(counters.get("kegs",0))+1
 var radius=ItemStats.v("powder_keg_heart","radius");var dmg=maxf(1.0,actual)*ItemStats.v("powder_keg_heart","fraction")
 for v in game.nearby(e.pos,radius):
  if v!=e and v.hp>0 and v.pos.distance_to(e.pos)<=radius:deal(v,dmg,"powder_keg_heart")
 game.psx.burst(e.pos+Vector3.UP*0.5,6,[Color("ffb347"),Color("ff6a2a")],5.0,0.3,0.35)

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
 if stacks.has("devils_bargain"):
  counters["bargain"]=int(counters.get("bargain",0))+1;refresh_stats()
# Anvil of the First Forge: one extra random stat from the weapon's own upgrade pool after an upgrade or an Imbue.
func anvil_bonus(id: int) -> void:
 if not stacks.has("anvil_first_forge") or not game.weapons.has(id):return
 var extra=int(ItemStats.v("anvil_first_forge","extra"))*n("anvil_first_forge")
 for i in extra:
  var state: Dictionary=game.weapons[id]
  var proposal=WeaponUpgrades.proposal(id,rng,state)
  if WeaponUpgrades.apply(id,state,proposal):counters["anvil"]=int(counters.get("anvil",0))+1
func stopwatch_bonus() -> float:return ItemStats.v("cracked_hourglass","seconds")*float(n("cracked_hourglass"))
func imbue_discount() -> float:
 return minf(ItemStats.v("forgemasters_tongs","cap"),ItemStats.v("forgemasters_tongs","discount")*float(n("forgemasters_tongs")))

# ---------------------------------------------------------------- on_damage_taken / on_evade
func on_evade() -> void:
 if stacks.has("shade_cloak"):
  counters["shade_ready"]=1;buffs["shade"]=ItemStats.v("shade_cloak","time");ticking=true;refresh_stats()
# Hourglass of the Damned: called from Game.hurt() with the damage about to land. Returns true when it saves the player.
func hourglass(final_damage: float) -> bool:
 if not stacks.has("hourglass_damned") or float(game.health)-final_damage>0.0:return false
 game.health=maxf(1.0,game.stats.max_health*ItemStats.v("hourglass_damned","heal_to"))
 game.world_time.freeze(ItemStats.v("hourglass_damned","freeze"))
 game.invulnerability=1.5
 game.toast("THE HOURGLASS SHATTERS")
 for i in range(game.items.size()-1,-1,-1):
  if game.items[i].id=="hourglass_damned":
   if int(game.items[i].stacks)>1:game.items[i].stacks=int(game.items[i].stacks)-1
   else:game.items.remove_at(i)
 counters["hourglass"]=1
 on_acquire("")
 return true
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
 if stacks.has("reapers_sickle"):
  var cap=int(ItemStats.v("reapers_sickle","cap"))
  for i in int(ItemStats.v("reapers_sickle","souls"))*n("reapers_sickle"):
   if souls.size()>=cap:dropped["souls"]=int(dropped.get("souls",0))+1;continue
   souls.append({"pos":e.pos+Vector3.UP,"life":ItemStats.v("reapers_sickle","life"),"retarget":0.0,"target":{},"phase":float(i)*PI})
  ticking=true
 if stacks.has("goat_skull") and float(e.get("burn",0.0))>0.0 and rng.randf()<chance("goat_skull"):
  counters["goat"]=int(counters.get("goat",0))+1
  for v in game.nearby(e.pos,ItemStats.v("goat_skull","radius")):
   if v!=e and v.hp>0:StatusManager.apply_ignite(game,v,int(e.get("burn_source",1)))
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
    if k=="mourner" or k=="leaden" or k=="shade":restat=true
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
 if stacks.has("witch_hunters_brand"):
  brand_clock+=delta
  if brand_clock>=ItemStats.v("witch_hunters_brand","interval"):
   brand_clock=0.0;var c=0
   for e in game.enemies:
    if float(e.get("burn",0.0))>0.0 and e.hp>0:c+=1
   if c!=burning_count:burning_count=c;refresh_stats()
 if stacks.has("hound_whistle"):on_move(delta)
 if stacks.has("hangmans_noose"):tick_noose(delta)
 if stacks.has("shattered_codex"):tick_codex(delta)
 tick_meat(delta)
 tick_wraiths(delta)
 tick_puddles(delta)
 tick_hounds(delta)
 tick_souls(delta)
 if buffs.is_empty() and hounds.is_empty() and souls.is_empty() and not stacks.has("hound_whistle") and not stacks.has("hangmans_noose") and not stacks.has("shattered_codex") and puddles.is_empty() and not stacks.has("witch_hunters_brand") and meat.is_empty() and wraiths.is_empty() and not stacks.has("hermits_ember") and not stacks.has("black_candle"):ticking=false
# Closest living enemy to `pos` within `radius`; `skip_boss` leaves bosses out. No allocation beyond nearby()'s array.
func find_target(pos: Vector3,radius: float,skip_boss: bool=false) -> Dictionary:
 var best: Dictionary={};var best_d=radius*radius
 for e in game.nearby(pos,radius):
  if e.hp<=0 or (skip_boss and is_boss(e)):continue
  var d=e.pos.distance_squared_to(pos)
  if d<best_d:best_d=d;best=e
 return best
# on_move: distance travelled on foot. Teleports and respawns (>6 m in one frame) are ignored.
func on_move(_delta: float) -> void:
 var here: Vector3=game.player.position
 if last_pos==Vector3.INF:last_pos=here;return
 var step=Vector2(here.x-last_pos.x,here.z-last_pos.z).length()
 var dir=Vector3(here.x-last_pos.x,0.0,here.z-last_pos.z)
 last_pos=here
 if step>6.0 or step<=0.0:return
 travelled+=step
 var need=ItemStats.v("hound_whistle","distance")
 if travelled>=need:
  travelled-=need
  var forward=dir.normalized() if dir.length()>0.0001 else Vector3.FORWARD
  var count=n("hound_whistle")
  for i in count:
   if hounds.size()>=int(ItemStats.v("hound_whistle","cap")):dropped["hounds"]=int(dropped.get("hounds",0))+1;continue
   var angle=(float(i)-float(count-1)*0.5)*0.35
   hounds.append({"pos":here+Vector3.UP*0.6,"dir":forward.rotated(Vector3.UP,angle),"left":ItemStats.v("hound_whistle","length"),"hit":{}})
  counters["hounds"]=int(counters.get("hounds",0))+1
func tick_hounds(delta: float) -> void:
 if hounds.is_empty():return
 var speed=ItemStats.v("hound_whistle","speed");var radius=ItemStats.v("hound_whistle","hit_radius")
 var dmg=ItemStats.v("hound_whistle","damage")+ItemStats.v("hound_whistle","damage_per_level")*float(game.level)
 for i in range(hounds.size()-1,-1,-1):
  var h=hounds[i];var step=minf(speed*delta,float(h.left))
  h.pos+=h.dir*step;h.left=float(h.left)-step
  if float(h.left)<=0.0:hounds.remove_at(i);continue
  for e in game.nearby(h.pos,radius+0.6):
   var key=int(e.get("crowd_id",0))
   if not h.hit.has(key):
    h.hit[key]=true
    deal(e,dmg,"hound_whistle")
  game.psx.draw_square(h.pos,0.7,Color("d8d2c0"))
  game.psx.draw_square(h.pos-h.dir*0.5+Vector3.UP*0.1,0.45,Color("9c9484"))
  game.psx.draw_square(h.pos-h.dir*1.0,0.3,Color("6c665a"))
func tick_noose(delta: float) -> void:
 curse_clock+=delta
 var interval=ItemStats.v("hangmans_noose","interval")
 if curse_clock>=interval:
  curse_clock-=interval
  if curse.is_empty() or curse.hp<=0 or curse.pos.distance_to(game.player.position)>ItemStats.v("hangmans_noose","search")*1.5:
   curse=find_target(game.player.position,ItemStats.v("hangmans_noose","search"),true)
  if not curse.is_empty() and curse.hp>0:
   var pct=ItemStats.v("hangmans_noose","elite_percent") if is_elite(curse) else ItemStats.v("hangmans_noose","percent")
   deal(curse,float(curse.max_hp)*pct*interval*float(n("hangmans_noose")),"hangmans_noose")
 if not curse.is_empty() and curse.hp>0:
  game.psx.draw_segment(game.player.position+Vector3.UP*1.4,curse.pos+Vector3.UP*1.2,0.06,Color("6b2d8a"))
  game.psx.draw_square(curse.pos+Vector3.UP*2.2,0.4,Color("a05cd0"))
func tick_souls(delta: float) -> void:
 if souls.is_empty():return
 var speed=ItemStats.v("reapers_sickle","speed");var radius=ItemStats.v("reapers_sickle","hit_radius")
 var dmg=ItemStats.v("reapers_sickle","damage")+ItemStats.v("reapers_sickle","damage_per_level")*float(game.level)
 for i in range(souls.size()-1,-1,-1):
  var sl=souls[i];sl.life=float(sl.life)-delta;sl.retarget=float(sl.retarget)-delta
  if sl.life<=0.0:souls.remove_at(i);continue
  if sl.target.is_empty() or sl.target.hp<=0 or sl.retarget<=0.0:
   sl.target=find_target(sl.pos,20.0);sl.retarget=0.25
  if sl.target.is_empty():
   sl.pos+=Vector3(cos(float(sl.phase)+float(sl.life)),0.0,sin(float(sl.phase)+float(sl.life)))*delta*2.0
  else:
   var to: Vector3=sl.target.pos+Vector3.UP-sl.pos
   sl.pos+=to.normalized()*minf(to.length(),speed*delta)
   if to.length()<=radius:
    deal(sl.target,dmg,"reapers_sickle");souls.remove_at(i);continue
  game.psx.draw_square(sl.pos,0.4,Color("8de0c0"))
func tick_codex(delta: float) -> void:
 var list=game.pickups
 if list.is_empty():return
 var budget=int(ItemStats.v("shattered_codex","checks_per_frame"))
 var radius=ItemStats.v("shattered_codex","radius");var cd=ItemStats.v("shattered_codex","hit_cooldown")
 var dmg=(ItemStats.v("shattered_codex","damage")+ItemStats.v("shattered_codex","damage_per_level")*float(game.level))*float(n("shattered_codex"))
 var now=float(game.elapsed)
 var count=list.size()
 for k in mini(budget,count):
  codex_cursor=(codex_cursor+1)%count
  var p=list[codex_cursor]
  if not p.get("attracted",false) or not is_instance_valid(p.node):continue
  var pos: Vector3=p.node.position
  for e in game.nearby(pos,radius+0.5):
   if e.hp>0 and now-float(e.get("codex_t",-9.0))>=cd and e.pos.distance_to(pos)<=radius+0.5:
    e["codex_t"]=now;deal(e,dmg,"shattered_codex")
  game.psx.draw_square(pos,0.35,Color("c8f0ff"))
func tick_puddles(delta: float) -> void:
 if puddles.is_empty():return
 var radius=ItemStats.v("mire_flask","radius");var interval=ItemStats.v("mire_flask","interval")
 for i in range(puddles.size()-1,-1,-1):
  var p=puddles[i];p.life=float(p.life)-delta;p.clock=float(p.clock)-delta
  if p.life<=0.0:puddles.remove_at(i);continue
  game.psx.draw_square(p.pos+Vector3.UP*0.08,radius*0.9,Color(0.35,0.75,0.25,0.55))
  if p.clock<=0.0:
   p.clock=interval
   for e in game.nearby(p.pos,radius):
    if e.hp>0 and e.pos.distance_to(p.pos)<=radius:deal(e,ItemStats.v("mire_flask","dps")*interval,"mire_flask")
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

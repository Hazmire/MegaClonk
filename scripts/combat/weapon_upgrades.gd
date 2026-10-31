class_name WeaponUpgrades
extends RefCounted

# Weapon-specific upgrade pools (Weapon Overhaul 2.0). Internal keys stay save-stable:
# damage, haste (Attack Speed), crit, crit_damage, count (Projectile Count), velocity (Projectile Speed),
# ricochet (Projectile Bounces), radius (Size). Only the stats listed per weapon can ever be offered.
# STEPS are the Common-tier sizes. Economy Rework: any upgrade can roll any tier and the tier scales the step (Economy.TIER_SCALE);
# whole-number stats (count, ricochet) are never scaled. Weapons now level to Economy.WEAPON_MAX_LEVEL, so the steps are smaller than before.
const STEPS={"damage":0.06,"haste":0.04,"crit":0.02,"crit_damage":0.10,"count":1.0,"velocity":0.08,"ricochet":1.0,"radius":0.06}
const WHOLE=["count","ricochet"]
static func step_for(key: String,tier: String) -> float:return Economy.scaled(float(STEPS[key]),tier,key in WHOLE)
static func tier_of_step(key: String,step: float) -> String:
 for tier in Rarity.IDS:
  if is_equal_approx(step,step_for(key,tier)):return tier
 return ""
const POOLS={
 0:["count","radius","damage","haste"],
 1:["velocity","count","damage","radius"],
 2:["count","damage","radius","ricochet","haste"],
 6:["damage","haste","crit","crit_damage","count","velocity","radius"],
 7:["damage","haste","crit","crit_damage","count","velocity","ricochet"],
 9:["haste","damage","count","velocity","radius"],
 10:["haste","radius","damage"],
 15:["haste","radius","damage","crit","crit_damage","count"]
}
const LABELS={"damage":"Damage","haste":"Attack Speed","crit":"Crit Chance","crit_damage":"Crit Damage","count":"Projectile Count","velocity":"Projectile Speed","ricochet":"Projectile Bounces","radius":"Size"}
static func label(id: int,key: String) -> String:
 if id==1 and key=="velocity":return "Projectile Velocity"
 if id==10 and key=="haste":return "Attack Speed"
 return LABELS.get(key,key.capitalize())
static func pool(id: int) -> Array:return POOLS.get(id,[]).duplicate()
# Keys that can still grow (a capped bounce/count upgrade is never offered).
static func open_keys(id: int,state: Dictionary) -> Array:
 var keys=[]
 for key in pool(id):
  if key=="ricochet" and value(state,key)>=float(WeaponStats.CAPS.ricochet):continue
  if key=="ricochet" and id==2 and value(state,key)>=float(WeaponStats.LIGHTNING.max_bounces):continue
  if key=="count":
   var cap=count_cap(id)-count_base(id)
   if value(state,key)>=float(cap):continue
  keys.append(key)
 return keys
static func count_base(id: int) -> int:
 return {0:WeaponStats.SWORD.base_count,1:WeaponStats.FIRESTAFF.base_count,2:WeaponStats.LIGHTNING.base_count,6:WeaponStats.BOW.base_count,7:WeaponStats.REVOLVER.base_count,9:WeaponStats.SCYTHES.base_count,15:WeaponStats.SHOTGUN.base_pellets}.get(id,1)
static func count_cap(id: int) -> int:
 return {0:WeaponStats.SWORD.max_count,1:WeaponStats.FIRESTAFF.max_count,2:WeaponStats.LIGHTNING.max_count,6:WeaponStats.BOW.max_count,7:WeaponStats.REVOLVER.max_count,9:WeaponStats.SCYTHES.max_count,15:WeaponStats.SHOTGUN.max_pellets}.get(id,1)
static func proposal(id: int,rng: RandomNumberGenerator,state: Dictionary={},tier: String="common") -> Dictionary:
 var keys=open_keys(id,state)
 if keys.is_empty():keys=["damage"]
 var key=keys[rng.randi_range(0,keys.size()-1)]
 return {"attribute":key,"step":step_for(key,tier),"tier":tier}
static func value(state: Dictionary,key: String) -> float:return float(state.get("upgrades",{}).get(key,0))
static func damage(id: int,state: Dictionary) -> float:return float(Catalog.WEAPONS[id][2])*(1+value(state,"damage"))*float(state.get("legacy_damage",1))
static func apply(id: int,state: Dictionary,proposal: Dictionary) -> bool:
 var key=str(proposal.get("attribute",""))
 if not key in pool(id) or not STEPS.has(key) or tier_of_step(key,float(proposal.get("step",0)))=="":return false
 if not key in open_keys(id,state):return false
 if not state.has("upgrades"):state.upgrades={}
 state.upgrades[key]=value(state,key)+float(proposal.step);return true
# "current -> new" for one upgrade, always computed from WeaponStats so it matches what combat then uses:
# {label, from, to} (the Level-up card shows the rows, description() joins them).
static func change(id: int,state: Dictionary,attribute: String,game: Object=null,step: float=-1.0) -> Dictionary:
 var now=WeaponStats.resolve(game,id,state)
 var next_state=state.duplicate(true)
 if not next_state.has("upgrades"):next_state.upgrades={}
 next_state.upgrades[attribute]=value(state,attribute)+(float(STEPS[attribute]) if step<0.0 else step)
 var later=WeaponStats.resolve(game,id,next_state)
 return {"label":label(id,attribute),"from":format_value(id,attribute,now),"to":format_value(id,attribute,later)}
static func description(id: int,state: Dictionary,attribute: String,game: Object=null,step: float=-1.0) -> String:
 var c=change(id,state,attribute,game,step)
 return "%s: %s → %s"%[c.label,c.from,c.to]
static func format_value(id: int,key: String,r: Dictionary) -> String:
 match key:
  "damage":return "%.0f damage"%(float(r.damage)*(1.0))
  "haste":
   return "%.2f %s/s"%[1.0/maxf(0.05,float(r.interval)),"pulses" if id==10 else ("bursts" if id==0 else "attacks")]
  "crit":return "%.0f%% crit chance"%(float(r.crit_chance)*100.0)
  "crit_damage":return "×%.2f crit damage"%float(r.crit_damage)
  "velocity":return "×%.2f speed"%float(r.speed_mult)
  "ricochet":return "%d %s"%[int(r.bounces),"chain bounces" if id==2 else "ricochets"]
  "count":
   var n=int(r.count)
   match id:
    0:return "%d slash%s per burst"%[n,"" if n==1 else "es"]
    1:return "%d fireball%s"%[n,"" if n==1 else "s"]
    2:return "%d strike%s"%[n,"" if n==1 else "s"]
    6:return "%d arrow%s"%[n,"" if n==1 else "s"]
    7:return "%d bullet%s"%[n,"" if n==1 else "s"]
    9:return "%d scythe%s"%[n,"" if n==1 else "s"]
    15:return "%d pellet%s per blast"%[n,"" if n==1 else "s"]
  "radius":
   match id:
    0:return "%.1fm reach"%float(r.reach)
    1:return "fireball ×%.2f"%float(r.scale)
    2:return "%.1fm strike radius"%float(r.strike_radius)
    6:return "arrow ×%.2f"%float(r.scale)
    9:return "scythe ×%.2f"%float(r.scale)
    10:return "%.1fm radius"%float(r.radius)
    15:return "%.0f° cone"%(float(r.cone_deg)*2.0)
 return key

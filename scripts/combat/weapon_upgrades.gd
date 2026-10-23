class_name WeaponUpgrades
extends RefCounted
const PROJECTILES=["bullet","fireball","bounce","pierce","return","lob","rocket","scatter","poison","spore","dice","wave"]
const AREA=["aura","sweep","corrupt","reap","dash_slash","cone","orbit","chrono","trail","frost_trail","mine","gravity","hammer","vortex"]
const STEPS={"damage":0.15,"haste":0.1,"crit":0.05,"count":1.0,"velocity":0.2,"ricochet":1.0,"radius":0.15,"duration":0.2,"range":0.15}
static func pool(id: int) -> Array:
 var kind=Catalog.WEAPONS[id][1]
 var keys=["damage","haste","crit"]
 if kind in PROJECTILES:keys.append_array(["count","velocity"])
 if kind in ["bullet","bounce"]:keys.append("ricochet")
 if kind in AREA:keys.append("radius")
 if kind in ["trail","frost_trail","mine","gravity","vortex","poison","spore"]:keys.append("duration")
 if kind in ["chain","drain","execute","freeze"]:keys.append_array(["count","range"])
 if kind in ["beam","rail","summon"]:keys.append("range")
 return keys
static func proposal(id: int,rng: RandomNumberGenerator) -> Dictionary:
 var keys=pool(id);keys.append("damage")
 var key=keys[rng.randi_range(0,keys.size()-1)]
 return {"attribute":key,"step":STEPS[key]}
static func value(state: Dictionary,key: String) -> float:return float(state.get("upgrades",{}).get(key,0))
static func damage(id: int,state: Dictionary) -> float:return float(Catalog.WEAPONS[id][2])*(1+value(state,"damage"))*float(state.get("legacy_damage",1))
static func description(id: int,state: Dictionary,attribute: String) -> String:
 var old=value(state,attribute);var step=float(STEPS[attribute])
 if attribute in ["count","ricochet"]:return "%s: +%d → +%d"%[attribute.capitalize(),old,old+step]
 return "%s bonus: +%.0f%% → +%.0f%%"%[attribute.capitalize(),old*100,(old+step)*100]
static func apply(id: int,state: Dictionary,proposal: Dictionary) -> bool:
 var key=str(proposal.get("attribute",""))
 if not key in pool(id) or not is_equal_approx(float(proposal.get("step",0)),float(STEPS[key])):return false
 if not state.has("upgrades"):state.upgrades={}
 state.upgrades[key]=value(state,key)+float(STEPS[key]);return true

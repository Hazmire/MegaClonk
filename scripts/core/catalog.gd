class_name Catalog
extends RefCounted

# Independent balance values. Reference names supplied by the design brief;
# none of these numbers are claimed to reproduce Megabonk formulas.
# Weapon Overhaul 2.0: exactly eight weapons. Ids are stable legacy ids (saves, unlocks and mastery
# metrics key on them), so the roster is a sparse table; ids not listed here no longer exist.
# Row: [name, kind, base damage (per hit / pellet), base cooldown, targeting range, ui colour].
const ACTIVE_WEAPONS=[0,1,2,6,7,9,10,15]
const WEAPONS = {
 0:["Sword", "slash", 22.0, 1.0, 7.0, "#f2f2ec"],
 1:["Firestaff", "fireball", 18.0, 1.1, 24.0, "#ff793b"],
 2:["Lightning Staff", "lightning", 20.0, 1.3, 22.0, "#5b9bff"],
 6:["Bow", "arrow", 22.0, 0.9, 32.0, "#cfd2c4"],
 7:["Revolver", "bullet", 32.0, 0.8, 27.0, "#c4c8cf"],
 9:["Scythes", "scythe", 20.0, 1.3, 18.0, "#b48f5d"],
 10:["Aura", "aura", 8.0, 0.6, 5.0, "#3f9a45"],
 15:["Shotgun", "shotgun", 14.0, 1.3, 11.0, "#ffd178"]
}
# Ids that existed before the overhaul and were deleted (or never shipped); saves drop them safely.
static func weapon_exists(id: int) -> bool:return WEAPONS.has(id)
static func weapon_name(id: int) -> String:return str(WEAPONS[id][0]) if WEAPONS.has(id) else "Retired weapon"
const CHARACTERS = [
 ["Fox", 1, "Luck grows each level", "luck"],
 ["Sir Oofie", 0, "Armor grows each level", "armor"],
 ["Calcium", 5, "Moving builds attack speed", "momentum"],
 ["Megachad", 10, "Periodic flex blocks damage", "flex"],
 ["Ogre", 11, "Damage grows each level", "damage"],
 ["CL4NK", 7, "Critical chance grows each level", "crit"],
 ["Athena", 8, "Low health damage and thorns", "athena"],
 ["Robinette", 6, "Gold increases damage", "gold"],
 ["Monke", 9, "Extra jump and growing health", "monke"],
 ["Tony McZoom", 17, "Movement discharges lightning", "electric"],
 ["Bush", 13, "Critical damage and marked targets", "mark"],
 ["Birdo", 19, "Triple jump and air control", "air"],
 ["Noelle", 18, "Frozen kills restore health", "freeze"],
 ["Amog", 23, "Poisoned deaths spread poison", "poison"],
 ["Spaceman", 22, "Increased experience gain", "xp"],
 ["Bandit", 20, "Attack speed grows each level", "haste"],
 ["Ninja", 24, "Evasion and low-health executions", "ninja"],
 ["Vlad", 21, "Damage restores health", "drain"],
 ["Sir Chadwell", 28, "Damage scales with tier", "tier"],
 ["Dicehead", 26, "Random stat each level", "random"],
 ["Roberto", 29, "Free item every minute", "chest"]
]
# Stable internal IDs preserve old saves; only these ten enter new reward pools.
const ACTIVE_TOMES=["Precision","Might","Multishot","Colossus","Haste","Wind","Vitality","Vampire","Wisdom","Greed"]
const TOME_NAMES={"Precision":"Crit Tome","Might":"Damage Tome","Multishot":"Projectile Tome","Colossus":"Size Tome","Haste":"Attack Speed Tome","Wind":"Movement Speed Tome","Vitality":"Max HP Tome","Vampire":"Lifesteal Tome","Wisdom":"XP Tome","Greed":"Gold Tome"}
static func tome_name(id: String) -> String:return TOME_NAMES.get(id,id+" Tome")
static func tome_description(id: String) -> String:
 if not TOMES.has(id):return ""
 var data=TOMES[id]
 if id=="Multishot":return "+1 total weapon projectile per level."
 if id=="Vitality":return "+20 maximum HP per level."
 var labels={"Precision":"critical-hit chance","Might":"damage","Colossus":"attack size","Haste":"attack speed","Wind":"movement speed","Vampire":"lifesteal","Wisdom":"XP gain","Greed":"gold gain"}
 if not TOME_NAMES.has(id):return "%s %+.2f per level"%[str(data[0]).replace("_"," "),data[1]]
 return "+%.0f%% %s per level."%[float(data[1])*100,labels.get(id,str(data[0]).replace("_"," "))]
const TOMES = {
 "Might": ["damage", 0.15], "Haste": ["haste", 0.12],
 "Precision": ["crit", 0.06], "Ruin": ["crit_damage", 0.25],
 "Vitality": ["max_health", 20.0], "Recovery": ["regen", 0.5],
 "Iron": ["armor", 2.0], "Dodge": ["evasion", 0.04],
 "Wind": ["speed", 0.1], "Feather": ["jump", 0.12],
 "Magnet": ["pickup", 0.25], "Wisdom": ["xp", 0.15],
 "Fortune": ["luck", 0.1], "Multishot": ["count", 1.0],
 "Velocity": ["projectile_speed", 0.15], "Colossus": ["size", 0.15],
 "Persistence": ["duration", 0.2], "Force": ["knockback", 0.2],
 "Briar": ["thorns", 3.0], "Vampire": ["lifesteal", 0.01],
 "Thermal": ["glide",0.15], "Gecko": ["climb",0.15], "Air Step": ["air_jumps",1.0], "Skater": ["slide_speed",0.15], "Wax": ["slide_friction",-0.08],
 "Greed": ["gold_gain", 0.2], "Curse": ["difficulty", 0.15]
}
const ITEMS = [
 ["Ember Heart", "rare", "max_health", 25.0],
 ["Runner's Knot", "common", "speed", 0.12],
 ["Lucky Claw", "rare", "crit", 0.07],
 ["Copper Crown", "common", "gold_gain", 0.25],
 ["Soul Lantern", "rare", "xp", 0.2],
 ["Iron Petal", "common", "armor", 3.0],
 ["Vampire Fang", "epic", "lifesteal", 0.02],
 ["Storm Lens", "epic", "count", 1.0],
 ["Giant's Ring", "rare", "size", 0.2],
 ["Briar Halo", "common", "thorns", 5.0],
 ["Phoenix Seal", "legendary", "revives",1.0],
 ["Thunder Covenant", "legendary", "storm",1.0],
 ["Timekeeper", "legendary", "ultimate_haste",0.25]
]
static func base_stats() -> Dictionary:
 return {"damage":1.0,"haste":1.0,"crit":0.05,"crit_damage":2.0,
 "max_health":100.0,"regen":0.2,"armor":0.0,"evasion":0.0,
 "speed":1.0,"jump":1.0,"pickup":1.0,"xp":1.0,"luck":0.0,
 "count":1.0,"projectile_speed":1.0,"size":1.0,"duration":1.0,
 "knockback":1.0,"thorns":0.0,"lifesteal":0.0,"gold_gain":1.0,"difficulty":1.0,"air_jumps":0.0,"glide":1.0,"climb":1.0,"slide_speed":1.0,"slide_friction":1.0}
static func threshold(level: int) -> float:
 return 10.0 + level * 7.0 + pow(level, 1.4)
static func damage(base: float, stats: Dictionary, critical: bool) -> float:
 return base * stats.damage * (stats.crit_damage if critical else 1.0)

static func item_description(id: int) -> String:
 match id:
  10:return "Revive once at full health after a fatal hit, with 3 seconds of protection."
  11:return "Automatically strike a nearby enemy with lightning each second. Stacks increase damage."
  12:return "Recover ultimate cooldown 25% faster during active gameplay."
 var item=ITEMS[id];var stat=str(item[2]).replace("_"," ")
 if item[2] in ["max_health","armor","count","thorns"]:return "+%.0f %s"%[item[3],stat]
 return "+%.0f%% %s"%[item[3]*100,stat]

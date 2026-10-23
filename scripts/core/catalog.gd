class_name Catalog
extends RefCounted

# Independent balance values. Reference names supplied by the design brief;
# none of these numbers are claimed to reproduce Megabonk formulas.
const WEAPONS = [
 ["Sword", "sweep", 22.0, 0.85, 5.0, "#ffe2a1"],
 ["Firestaff", "fireball", 18.0, 1.0, 24.0, "#ff793b"],
 ["Lightning Staff", "chain", 20.0, 1.3, 22.0, "#8bdfff"],
 ["Flamewalker", "trail", 10.0, 0.7, 3.0, "#ff5c23"],
 ["Chunkers", "orbit", 17.0, 0.75, 4.0, "#c4a0ff"],
 ["Bone", "bounce", 16.0, 0.9, 20.0, "#f1edd1"],
 ["Bow", "pierce", 22.0, 0.9, 32.0, "#b7e978"],
 ["Revolver", "bullet", 32.0, 0.8, 27.0, "#ffe5a6"],
 ["Aegis", "orbit", 18.0, 0.8, 4.0, "#69c5ff"],
 ["Bananarang", "return", 20.0, 1.0, 18.0, "#ffdf43"],
 ["Aura", "aura", 8.0, 0.6, 5.0, "#f5a7ff"],
 ["Axe", "lob", 38.0, 1.5, 16.0, "#b8cfdf"],
 ["Space Noodle", "chain", 15.0, 0.9, 18.0, "#efb3ff"],
 ["Sniper Rifle", "beam", 65.0, 1.9, 52.0, "#ffeac0"],
 ["Slutty Rocket", "rocket", 44.0, 1.8, 35.0, "#ff995e"],
 ["Shotgun", "scatter", 14.0, 1.2, 14.0, "#ffd178"],
 ["Mines", "mine", 55.0, 1.6, 4.0, "#e9be50"],
 ["Wireless Dagger", "chain", 18.0, 0.7, 18.0, "#67f9ff"],
 ["Frostwalker", "frost_trail", 9.0, 0.7, 4.0, "#8ce8ff"],
 ["Tornado", "vortex", 13.0, 1.4, 22.0, "#c5f9ef"],
 ["Dexecutioner", "execute", 32.0, 1.2, 18.0, "#e58bff"],
 ["Blood Magic", "drain", 24.0, 1.1, 20.0, "#ef5272"],
 ["Black Hole", "gravity", 18.0, 2.5, 25.0, "#a978ff"],
 ["Poison Flask", "poison", 9.0, 1.5, 22.0, "#a3ef5f"],
 ["Katana", "dash_slash", 35.0, 1.0, 8.0, "#ffbadd"],
 ["Dragon's Breath", "cone", 12.0, 0.45, 9.0, "#ff7a40"],
 ["Dice", "dice", 25.0, 1.2, 25.0, "#ffffff"],
 ["Hero Sword", "wave", 30.0, 1.1, 28.0, "#ffe278"],
 ["Corrupted Sword", "corrupt", 42.0, 1.5, 7.0, "#bb64ff"],
 ["Scythe", "reap", 34.0, 1.3, 7.0, "#89f0bd"],
 ["Ice Crystal", "freeze", 24.0, 1.4, 23.0, "#91dfff"],
 ["Chrono Slicer", "chrono", 21.0, 0.8, 5.0, "#5fffe3"],
 ["Thunder Rail", "rail", 55.0, 1.6, 50.0, "#79afff"],
 ["Spore Cannon", "spore", 15.0, 1.5, 26.0, "#b4fc73"],
 ["Gravity Hammer", "hammer", 65.0, 2.2, 20.0, "#bda1ff"],
 ["Phantom Legion", "summon", 25.0, 1.0, 22.0, "#7affce"]
]
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

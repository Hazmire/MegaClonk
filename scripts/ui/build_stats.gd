class_name BuildStats
extends RefCounted
const HELP={
 "damage":"Multiplies weapon damage. Higher increases damage before critical hits and trait/ultimate multipliers.",
 "haste":"Multiplies attacks per second; higher reduces cooldown. Per-weapon haste multiplies this bonus.",
 "crit":"Chance per hit to critically strike. Higher is better; effective chance is bounded at 100%.",
 "crit_damage":"Damage multiplier of a critical hit. 100% bonus means a critical hit deals twice normal damage.",
 "armor":"Armour points: incoming damage is multiplied by 100 / (100 + 5 × armour). Higher reduces damage; Berserker then multiplies incoming damage by 0.70.",
 "evasion":"Chance to dodge all damage from a hit, bounded at 75%. Higher is better.",
 "speed":"Multiplies running speed and the practical slide speed limit. Higher is faster.",
 "jump":"Multiplies jump height. Jump impulse uses its square root; Ghost Form multiplies height again.",
 "air_jumps":"Additional jumps while airborne. One means double jump; two means triple jump.",
 "slide_speed":"Additional multiplier of practical slide speed. Higher allows faster downhill slides.",
 "slide_friction":"Multiplies friction during a slide; lower retains momentum longer. Minimum 15% of default friction.",
 "xp":"Multiplies XP collected from orbs. Higher levels the player faster.",
 "glide":"Reduces glide descent speed and gravity; higher gives more airtime without upward flight.",
 "climb":"Multiplies wall climbing speed for Wall Climber. Higher climbs faster; outer boundaries remain forbidden."}
static func value(key: String, number: float) -> String:
 if key in ["max_health","armor","count","air_jumps","thorns"]:return "%.0f"%number
 if key=="regen":return "%.1f HP/s"%number
 if key in ["crit","evasion","luck","lifesteal"]:return "%.0f%%"%(number*100)
 if key=="crit_damage":return "+%.0f%%"%((number-1)*100)
 return "%+.0f%%"%((number-1)*100)
static func help(key: String) -> String:
 return HELP.get(key,{"count":"Base projectile or attack target count. Higher adds shots for weapons that support them.","projectile_speed":"Multiplies projectile travel speed. Higher gives faster shots, with less time for enemies to move away.","size":"Multiplies area and projectile size. Higher increases coverage.","duration":"Multiplies status and field duration. Higher extends their effects.","pickup":"Multiplies XP pickup radius. Higher collects orbs farther away.","gold_gain":"Multiplies gold earned from kills, with fractional rewards carried forward.","difficulty":"Multiplies enemy durability. Higher makes the run harder.","knockback":"Multiplies knockback strength; heavy enemies resist it.","max_health":"Maximum health points. Higher lets you survive more damage.","regen":"Health recovered per active gameplay second. Higher heals faster.","thorns":"Base damage returned to nearby attackers. Higher deals more retaliation damage."}.get(key,"Current gameplay modifier. Higher increases this effect."))

class_name VaseLoot
extends RefCounted

# Data-driven vase reward table. Edit the numbers here; nothing else needs to change.
# Every vase always yields exactly one reward: there is no "nothing" entry and the weights are
# normalised, so they do not have to sum to exactly 100.
const TABLE=[
 {"id":"xp","weight":35.0},
 {"id":"gold","weight":25.0},
 {"id":"heart","weight":10.0},
 {"id":"magnet","weight":10.0},
 {"id":"stopwatch","weight":10.0},
 {"id":"gem","weight":10.0}
]
# A small bundle of XP gems. Value per gem grows with the stage.
const XP={"gems_min":3,"gems_max":5,"value_base":6.0,"value_stage_growth":0.5}
# A few coins; value per coin by stage (later stages reuse the last entry).
const GOLD={"coins_min":2,"coins_max":4,"value_by_stage":[6,12,18]}

static func total_weight() -> float:
 var sum=0.0
 for entry in TABLE:sum+=float(entry.weight)
 return sum
# Picks a table entry id from one random draw.
static func choose(rng: RandomNumberGenerator) -> String:
 var roll=rng.randf()*total_weight();var running=0.0
 for entry in TABLE:
  running+=float(entry.weight)
  if roll<running:return str(entry.id)
 return str(TABLE[TABLE.size()-1].id)
# Rolls a complete reward description (kind, quantity, value, element) for a given stage.
static func roll(rng: RandomNumberGenerator,stage: int) -> Dictionary:
 var kind=choose(rng)
 match kind:
  "xp":
   return {"kind":kind,"count":rng.randi_range(int(XP.gems_min),int(XP.gems_max)),"value":float(XP.value_base)*(1.0+float(XP.value_stage_growth)*maxi(0,stage-1))}
  "gold":
   var values: Array=GOLD.value_by_stage
   return {"kind":kind,"count":rng.randi_range(int(GOLD.coins_min),int(GOLD.coins_max)),"value":int(values[clampi(stage-1,0,values.size()-1)])}
  "gem":
   return {"kind":kind,"count":1,"element":str(Elements.IDS[rng.randi_range(0,Elements.IDS.size()-1)])}
 return {"kind":kind,"count":1}

class_name MenuData
extends RefCounted
# Everything the menu screens show that is derived from game data lives here, so no screen types it twice and the
# regression test can check it without building a screen.
const MENU_TAGLINE="" # placeholder from the design ("[TAGLINE OR COUNTY NAME]"): empty hides the line
const STAGE_NAMES=["The Verdant Hollow"]
const STAGE_SHORT=["Hollow"] # "Enter the Hollow"
const BIOME_NAMES=["Forest"]
const WEAPON_TAGS={0:"Melee",9:"Melee",10:"Melee",1:"Staff",2:"Staff",6:"Ranged",7:"Ranged",15:"Ranged"} # no category exists in Catalog; this is the only place it is defined
const TAG_ORDER=["All","Staff","Ranged","Melee"]
const NEW_KEY="seen_new"
static func quest_description(q: Dictionary) -> String:
 if q.metric.begins_with("weapon:"):return "%d kills using %s"%[q.target,Catalog.weapon_name(int(q.metric.get_slice(":",1)))]
 match q.metric:
  "kills":return "Defeat %d enemies"%q.target
  "survival":return "Survive %d seconds in one run"%q.target
  "fast_clear":return "Clear the forest in under five minutes"
  "bosses":return "Defeat a main boss"
  "minibosses":return "Defeat a miniboss"
  "stage":return "Reach stage 2"
  "endless":return "Survive until endless mode"
  "early_stage":return "Escape a stage before the timer reaches zero"
  "legendary_shop":return "Purchase from a Legendary shop"
  "chests":return "Open %d chests"%q.target
  _:return "Use an ultimate %d times"%q.target
# A quest is pass/fail when it can only ever be 0 or 1 (nothing to count).
static func is_pass_fail(q: Dictionary) -> bool:return int(q.target)<=1
static func quest_ratio(data: Dictionary,q: Dictionary) -> float:
 return clampf(MetaProgress.quest_value(data,q.metric)/maxf(1.0,float(q.target)),0.0,1.0)
# "Within reach": the open quests closest to completion. Ties keep catalogue order. Completed and claimed quests are not "within reach".
static func within_reach(data: Dictionary,quests: Array,count: int=4) -> Array:
 var open=[]
 for i in quests.size():
  var q: Dictionary=quests[i]
  if MetaProgress.quest_state(data,q)=="active":open.append({"quest":q,"ratio":quest_ratio(data,q),"order":i})
 open.sort_custom(func(a,b):return a.ratio>b.ratio or (a.ratio==b.ratio and a.order<b.order))
 var result=[]
 for i in mini(count,open.size()):result.append(open[i].quest)
 return result
static func personal_bests(data: Dictionary,count: int=5) -> Array:
 var records: Array=data.get("leaderboard",[]).duplicate(true)
 records.sort_custom(func(a,b):return int(a.kills)>int(b.kills) or (int(a.kills)==int(b.kills) and float(a.time)>float(b.time)))
 return records.slice(0,count)
static func clock(seconds: float) -> String:return "%02d:%02d"%[int(seconds)/60,int(seconds)%60]
static func stage_name(biome: int) -> String:return STAGE_NAMES[clampi(biome,0,STAGE_NAMES.size()-1)]
static func stage_short(biome: int) -> String:return STAGE_SHORT[clampi(biome,0,STAGE_SHORT.size()-1)]
static func biome_name(biome: int) -> String:return BIOME_NAMES[clampi(biome,0,BIOME_NAMES.size()-1)]
static func weapon_tag(id: Variant) -> String:return WEAPON_TAGS.get(int(id),"All")

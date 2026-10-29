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
# ---- Unlocks & collection -------------------------------------------------------------------------------------
const TABS=[["weapons","Weapons"],["tomes","Tomes"],["traits","Traits"],["items","Items"],["ultimates","Ultimates"]]
const TOGGLE_CATEGORIES=["weapons","tomes","items"]
const NEW_ENTRIES=["weapons:15"] # entries the game marks NEW until the player has looked at them (profile key "seen")
const STARTING_WEAPONS=[0,1,6,7] # ignore the Appears-in-runs toggle (LoadoutCatalog gives them cost 0)
const GEM_ON_PAPER={"fire":Color("C4552A"),"ice":Color("3F86A6"),"corrosive":Color("4E8A36"),"electricity":Color("7A5CB8")} # darker than FogPalette.ELEMENT for contrast on memo paper
const UNIQUE_INK=Color("8A5A0E")
static var debug_locked: Array=[] # "category:id" keys shown as locked without touching the save (F9 on the Unlocks screen in debug builds)
static func entry_unlocked(data: Dictionary,category: String,id: String) -> bool:
 return MetaProgress.unlocked(data,category,id) and not (category+":"+id) in debug_locked
# "on" / "off" for entries with an Appears-in-runs toggle, "plain" for traits and ultimates (always available), "locked".
static func entry_state(data: Dictionary,category: String,id: String) -> String:
 if not entry_unlocked(data,category,id):return "locked"
 if category not in TOGGLE_CATEGORIES:return "plain"
 return "on" if MetaProgress.enabled(data,category,id) else "off"
static func unlock_requirement(category: String,e: Dictionary) -> String:
 var silver=int(e.get("cost",0));var kills=int(e.get("goal",0))
 if kills>0 and silver>0:return "%d lifetime kills and %d silver"%[kills,silver]
 if kills>0:return "%d lifetime kills"%kills
 if silver>0:return "%d silver"%silver
 return ""
static func is_new(data: Dictionary,category: String,id: String) -> bool:
 return (category+":"+id) in NEW_ENTRIES and not (category+":"+id) in data.get("seen",[])
static func mark_seen(data: Dictionary,category: String,id: String) -> bool:
 var key=category+":"+id
 if key in NEW_ENTRIES and not key in data.seen:data.seen.append(key);return true
 return false
static func weapon_blurb(id: Variant) -> String:return str(LoadoutCatalog.WEAPON_BLURBS.get(int(id),""))
static func effect_text(category: String,e: Dictionary) -> String:
 match category:
  "weapons":return weapon_blurb(e.id)
  "items":return str(Catalog.ITEMS[e.id].full)
 return str(e.description)
# Element id ("fire") of the socket gem an item needs, or "".
static func item_gem(id: String) -> String:
 var needs=Catalog.ITEMS.get(id,{}).get("needs")
 return "" if needs==null else str(needs).trim_suffix(" GEM").to_lower()
static func tier_counts() -> Dictionary:
 var counts={"all":Catalog.ITEM_IDS.size()}
 for t in Catalog.ITEM_TIERS:counts[t]=0
 for id in Catalog.ITEM_IDS:counts[Catalog.item_tier(id)]+=1
 return counts
static func drop_percent(tier: String) -> String:return "%d%%"%roundi(float(ItemStats.TIER_WEIGHTS[tier])*100.0)
static func found_items(data: Dictionary) -> int:
 var n=0
 for id in Catalog.ITEM_IDS:
  if entry_unlocked(data,"items",id):n+=1
 return n
static func level_up_options(id: Variant) -> Array:
 var result=[]
 for key in WeaponUpgrades.pool(int(id)):result.append(WeaponUpgrades.label(int(id),key).to_upper())
 return result

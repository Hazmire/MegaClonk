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
# ---- Unlocks & collection ----
const UNLOCK_TABS=[{"id":"weapons","label":"Weapons"},{"id":"tomes","label":"Tomes"},{"id":"traits","label":"Traits"},{"id":"items","label":"Items"},{"id":"ultimates","label":"Ultimates"}]
const TIER_LABELS={"common":"Common","uncommon":"Uncommon","rare":"Rare","epic":"Epic","legendary":"Legendary"}
const ELEMENT_OF_GEM={"FIRE GEM":"fire","ICE GEM":"ice","CORROSIVE GEM":"corrosive","ELECTRICITY GEM":"electricity"}
static var debug_locked_items: Array=[] # capture / test override: item ids drawn and described as locked (every item ships unlocked)
static func key_of(category: String,id: String) -> String:return category+":"+id
static func is_locked(data: Dictionary,category: String,id: String) -> bool:
 if category=="items" and id in debug_locked_items:return true
 return not MetaProgress.unlocked(data,category,id)
# "locked" | "off" | "on" | "plain" (traits and ultimates have no toggle: they are always offered once unlocked)
static func tile_state(data: Dictionary,category: String,id: String) -> String:
 if is_locked(data,category,id):return "locked"
 if category in ["traits","ultimates"]:return "plain"
 return "on" if MetaProgress.enabled(data,category,id) else "off"
static func is_new(data: Dictionary,category: String,id: String) -> bool:
 var key=key_of(category,id)
 return MetaProgress.unlocked(data,category,id) and not key in data.get(NEW_KEY,[])
static func mark_seen(data: Dictionary,category: String,id: String) -> bool:
 var key=key_of(category,id)
 if not MetaProgress.unlocked(data,category,id) or key in data.get(NEW_KEY,[]):return false
 if not data.has(NEW_KEY):data[NEW_KEY]=[]
 data[NEW_KEY].append(key);return true
static func unlock_text(category: String,entry: Dictionary) -> String:
 match category:
  "weapons":return "To unlock: %d silver"%int(entry.cost)
  "tomes":return "To unlock: %d lifetime kills and %d silver"%[int(entry.goal),int(entry.cost)]
 return "To unlock: conditions are not set yet" # items (and anything else) ship unlocked; the rule comes later
static func can_buy(category: String) -> bool:return category in ["weapons","tomes"]
static func tier_counts() -> Dictionary:
 var counts={"all":Catalog.ITEM_IDS.size()}
 for tier in Catalog.ITEM_TIERS:counts[tier]=0
 for id in Catalog.ITEM_IDS:counts[Catalog.item_tier(id)]+=1
 return counts
static func drop_weight_text(tier: String) -> String:return "%d%%"%roundi(float(ItemStats.TIER_WEIGHTS[tier])*100.0)
# Element of the socket gem an item needs ("fire", ...) or "" when it needs none.
static func needs_element(id: String) -> String:
 var needs: Variant=Catalog.ITEMS.get(id,{}).get("needs")
 return "" if needs==null else String(ELEMENT_OF_GEM.get(String(needs),""))
static func items_found(data: Dictionary) -> int:
 var n=0
 for id in Catalog.ITEM_IDS:
  if not is_locked(data,"items",String(id)):n+=1
 return n
static func ultimate_chips(entry: Dictionary) -> Array:
 var chips=["%ds COOLDOWN"%int(entry.cooldown)]
 if float(entry.duration)>0.0:chips.append("%ds DURATION"%int(entry.duration))
 return chips
# Weapon facts straight from the stat resolver, so the numbers cannot drift from the game.
static func weapon_sentence(id: int) -> String:
 var r=WeaponStats.resolve(null,id,{})
 return "%s · %d damage · one attack every %.2f seconds. %s weapon."%[String(r.kind).capitalize(),int(round(r.damage)),r.interval,weapon_tag(id)]
static func weapon_pool_labels(id: int) -> Array:
 var labels=[]
 for key in WeaponUpgrades.pool(id):labels.append(WeaponUpgrades.label(id,String(key)).to_upper())
 return labels
# Where an item can drop, read from ItemStats so the memo never promises a source the drop rules do not have.
static func sources_text(id: String) -> String:
 var tier=Catalog.item_tier(id)
 var places=["chests"]
 if tier in ItemStats.DROPS.shop_tiers:places.append("shops")
 if tier in ItemStats.DROPS.vase_tiers:places.insert(0,"vases")
 if places.size()==1:return "Appears in %s only"%places[0]
 return "Appears in "+", ".join(places.slice(0,places.size()-1))+" and "+places[places.size()-1]

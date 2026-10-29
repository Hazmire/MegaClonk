class_name ItemMigration
extends RefCounted

# Item Overhaul save migration. The 13 numbered items of the old system were stored as display names in the run save and
# their stat bonuses were folded straight into the saved stats. Loading such a run drops the items and takes those exact
# bonuses back out, so the player is not left with invisible stat boosts. No refund is given.
const LEGACY={
 "Ember Heart":["max_health",25.0],"Runner's Knot":["speed",0.12],"Lucky Claw":["crit",0.07],"Copper Crown":["gold_gain",0.25],
 "Soul Lantern":["xp",0.2],"Iron Petal":["armor",3.0],"Vampire Fang":["lifesteal",0.02],"Storm Lens":["count",1.0],
 "Giant's Ring":["size",0.2],"Briar Halo":["thorns",5.0],"Phoenix Seal":["revives",1.0],"Thunder Covenant":["storm",1.0],"Timekeeper":["ultimate_haste",0.25]
}
const LEGACY_ONLY_STATS=["revives","storm","ultimate_haste"]
# Returns the sanitised inventory (only entries in the new {"id","stacks"} format with a known id) and edits `stats` in place.
static func sanitize(saved_items: Variant,stats: Dictionary) -> Array:
 var result=[]
 if not saved_items is Array:return result
 for entry in saved_items:
  if entry is String:
   if LEGACY.has(entry):
    var rule: Array=LEGACY[entry]
    stats[rule[0]]=float(stats.get(rule[0],0.0))-float(rule[1])
   continue
  if entry is Dictionary and Catalog.item_exists(entry.get("id","")):
   var id=str(entry.id)
   var stacks=clampi(int(entry.get("stacks",1)),1,int(ItemStats.T.bounds.max_stacks))
   if Catalog.item_unique(id):stacks=1
   var merged=false
   for owned in result:
    if owned.id==id:merged=true
   if not merged:result.append({"id":id,"stacks":stacks})
 for key in LEGACY_ONLY_STATS:stats.erase(key)
 if stats.has("max_health"):stats["max_health"]=maxf(1.0,float(stats.max_health))
 return result
# Shop offers saved by the old system were numeric item indices. Gem offers are negative ints and stay valid.
static func clean_offers(offers: Variant) -> Variant:
 if not offers is Array:return offers
 var result=[]
 for value in offers:
  if value is String:
   if Catalog.item_exists(value):result.append(value)
  elif int(value)<0:result.append(int(value))
 return result if result.size()==offers.size() else null

class_name RewardCatalog
extends RefCounted
# References existing balance/unlock registries; these tables assign rarity only.
const WEAPON_RARITIES=["common","common","rare","uncommon","uncommon","common","common","common","rare","uncommon","uncommon","common","rare","rare","epic","uncommon","uncommon","rare","uncommon","rare","epic","epic","legendary","uncommon","rare","epic","uncommon","epic","legendary","rare","rare","epic","epic","rare","epic","legendary"]
const TOME_RARITIES={"Ruin":"rare","Dodge":"uncommon","Multishot":"epic","Vampire":"legendary","Air Step":"epic","Thermal":"uncommon","Gecko":"uncommon","Skater":"uncommon","Wax":"uncommon","Fortune":"rare","Colossus":"rare","Persistence":"uncommon","Force":"uncommon","Briar":"uncommon","Curse":"rare"}
# Existing items are intentionally repeatable; zero means no stack cap.
static func entry(category: String,id: Variant,level: int=0) -> Dictionary:
 var name="";var description="";var rarity="common";var effects={};var maximum=10;var cost=0;var unlock={}
 match category:
  "weapons":
   if int(id)<0 or int(id)>=Catalog.WEAPONS.size():return {}
   var w=Catalog.WEAPONS[int(id)];name=w[0];description="%s • %.0f base damage • %.2fs cooldown"%[w[1],w[2],w[3]];rarity=WEAPON_RARITIES[int(id)];unlock=LoadoutCatalog.entry(category,str(id))
   for attribute in WeaponUpgrades.pool(int(id)):effects[attribute]=WeaponUpgrades.STEPS[attribute]
  "tomes":
   if not Catalog.TOMES.has(str(id)):return {}
   var t=Catalog.TOMES[str(id)];name=Catalog.tome_name(str(id));description=Catalog.tome_description(str(id));rarity=TOME_RARITIES.get(str(id),"common");effects={t[0]:t[1]}
  "items":
   if int(id)<0 or int(id)>=Catalog.ITEMS.size():return {}
   var item=Catalog.ITEMS[int(id)];name=item[0];description=Catalog.item_description(int(id));rarity=item[1];effects={item[2]:item[3]};maximum=0;cost=ShopSystem.price(int(id));unlock=LoadoutCatalog.entry(category,str(id))
  _:return {}
 return {"uid":category+":"+str(id),"id":id,"name":name,"description":description,"icon":UIAssets.icon(category,str(id)),"category":category,"rarity":rarity,"level":level,"max_level":maximum,"effects":effects,"unlock":unlock,"shop_cost":cost}
static func all_entries() -> Array:
 var result=[]
 for id in Catalog.ACTIVE_WEAPONS:result.append(entry("weapons",id))
 for id in Catalog.ACTIVE_TOMES:result.append(entry("tomes",id))
 for id in Catalog.ITEMS.size():result.append(entry("items",id))
 return result

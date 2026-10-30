class_name RunData
extends RefCounted
# Single source of truth for every in-run panel and the HUD: turns live game state into plain Dictionaries/Arrays.
# Panels and the HUD never read game internals themselves (same pattern as MenuData for the menus), so a value is
# worked out in exactly one place and tests can compare a screen against this.
const TIER_IDS=["common","uncommon","rare","epic","legendary"]
const GROUPS=[
 ["Survival",["max_health","regen","armor","evasion","lifesteal","thorns"]],
 ["Combat",["damage","crit","crit_damage","haste","count","size","projectile_speed","duration","knockback"]],
 ["Movement",["speed","air_jumps","jump","slide_speed","slide_friction","glide","climb"]],
 ["Rewards",["pickup","xp","gold_gain","luck","difficulty"]]]
const LABELS={"max_health":"Max health","crit_damage":"Crit damage","projectile_speed":"Projectile speed","air_jumps":"Air jumps","slide_speed":"Slide speed","slide_friction":"Slide friction","gold_gain":"Gold gain","xp":"XP gain","pickup":"Pickup range","regen":"Regeneration"}
static func tier_index(tier: String) -> int:return maxi(0,TIER_IDS.find(tier))
static func label(key: String) -> String:return LABELS.get(key,key.replace("_"," ").capitalize())
# --- stats -------------------------------------------------------------------------------------------------------
# Value shown for a stat: crit and evasion are shown at their effective (capped) value, as the old panel did.
static func shown(key: String,value: float) -> float:
 if key=="crit":return minf(1.0,value)
 if key=="evasion":return minf(0.75,value)
 return value
static func stat_text(key: String,value: float) -> String:return BuildStats.value(key,shown(key,value))
# True when the stat differs from its starting value (neutral values are drawn dim).
static func changed(key: String,value: float,base: Dictionary) -> bool:return absf(float(value)-float(base.get(key,value)))>0.0001
# Rows for the Stats panel, generated from game.stats so a new stat can never be missing: the fixed groups come first
# in their order, then every other stat the game has goes under "Other". Dictionaries: {title, rows:[{key,label,value,
# text,changed}]}.
static func stat_sections(game: Node) -> Array:
 var base=Catalog.base_stats();var out=[];var seen={}
 for group in GROUPS:
  var rows=[]
  for key in group[1]:
   if not game.stats.has(key):continue
   seen[key]=true;rows.append(stat_row(key,float(game.stats[key]),base))
  out.append({"title":group[0],"rows":rows})
 var other=[]
 for key in game.stats:
  if seen.has(key):continue
  other.append(stat_row(key,float(game.stats[key]),base))
 if not other.is_empty():out.append({"title":"Other","rows":other})
 return out
static func stat_row(key: String,value: float,base: Dictionary) -> Dictionary:
 return {"key":key,"label":label(key),"value":value,"text":stat_text(key,value),"changed":changed(key,value,base)}
# --- build ---------------------------------------------------------------------------------------------------------
static func weapons(game: Node) -> Array:
 var out=[]
 for id in game.weapons:
  var state: Dictionary=game.weapons[id];var meta=game.equipment_meta("weapons",id,int(state.level))
  var gems=WeaponSockets.gems(state)
  out.append({"id":int(id),"name":str(meta.name),"level":int(state.level),"tier":tier_index(str(meta.rarity)),"gems":gems,"sockets":WeaponSockets.unlocked(state)})
 return out
static func tomes(game: Node) -> Array:
 var out=[]
 for id in game.tomes:
  var meta=game.equipment_meta("tomes",id,int(game.tomes[id]))
  out.append({"id":str(id),"name":str(meta.name),"level":int(game.tomes[id]),"tier":tier_index(str(meta.rarity))})
 return out
# Light rows only (name, stacks, tier): the HUD rebuilds these when the build changes, so the expensive text is looked up
# on hover through item_description() instead of for every item every time.
static func items(game: Node) -> Array:
 var out=[]
 for entry in game.items:
  var id=str(entry.id);var data: Dictionary=Catalog.ITEMS.get(id,{})
  out.append({"id":id,"name":str(data.get("name",id)),"stacks":int(entry.stacks),"tier":tier_index(str(data.get("tier","common")))})
 return out
static func item_description(id: String) -> String:return Catalog.item_description(id)
# Sets tooltip_text only when the pointer arrives (tooltips show after a delay), so building a row costs no text work.
static func lazy_tip(control: Control,text_for: Callable) -> void:
 control.mouse_entered.connect(func():control.tooltip_text=str(text_for.call()))
static func gem_counts(game: Node) -> Dictionary:
 var out={}
 for element in Elements.IDS:out[element]=game.gems.count(element)
 return out
# Trait and ultimate for the Inventory panel and the HUD tiles. cooldown_left is seconds until Q is ready (0 = ready).
static func loadout(game: Node) -> Dictionary:
 var l=game.loadout_runtime
 return {"trait":str(l.trait_id),"ultimate":str(l.ultimate_id),"cooldown":float(l.cooldown),"cooldown_left":maxf(0.0,float(l.cooldown)),"total":maxf(0.001,float(LoadoutCatalog.entry("ultimates",str(l.ultimate_id)).get("cooldown",1.0))),"active":float(l.remaining)>0.0,"ready":float(l.cooldown)<=0.0 and float(l.remaining)<=0.0}
# Cheap strings that change exactly when a part of the build changes: panels and the HUD rebuild only that part.
static func weapons_signature(game: Node) -> String:
 var parts=PackedStringArray()
 for id in game.weapons:
  var w: Dictionary=game.weapons[id];parts.append("w%s:%d:%s:%s"%[id,int(w.level),str(w.get("rarity","")),",".join(PackedStringArray(WeaponSockets.gems(w)))+"/"+str(WeaponSockets.unlocked(w))])
 return "|".join(parts)+"#%d"%game.weapon_limit()
static func tomes_signature(game: Node) -> String:
 var parts=PackedStringArray()
 for id in game.tomes:parts.append("t%s:%d"%[id,int(game.tomes[id])])
 return "|".join(parts)+"#%d#%s"%[game.tome_limit(),str(game.tome_rarities)]
static func items_signature(game: Node) -> String:
 var parts=PackedStringArray()
 for e in game.items:parts.append("i%s:%d"%[e.id,int(e.stacks)])
 return "|".join(parts)
static func gems_signature(game: Node) -> String:
 var parts=PackedStringArray()
 for element in Elements.IDS:parts.append("g%d"%game.gems.count(element))
 parts.append("a%d"%game.amulets)
 return "|".join(parts)
static func build_signature(game: Node) -> String:
 return weapons_signature(game)+"@"+tomes_signature(game)+"@"+items_signature(game)+"@"+gems_signature(game)
# --- level up -----------------------------------------------------------------------------------------------------
# One Dictionary per offered card, from the real choice: {key,type,category,id,name,short_name,tier,tier_name,is_new,level_from,level_to,
# max_level,rows:[{label,from,to}] (change rows) or [{label,value}] (a new weapon's facts),preview:{stat,from,to} or {}}.
# Names read "Weapon — Stat" for a weapon upgrade; the numbers come from WeaponStats / Economy, never from card text.
static func level_cards(game: Node,choices: Array) -> Array:
 var out=[]
 for choice in choices:out.append(level_card(game,choice))
 return out
static func level_card(game: Node,choice: Dictionary) -> Dictionary:
 var tier_name=str(choice.get("tier","common"))
 var card={"key":str(choice.get("key","")),"type":str(choice.type),"category":"","id":str(choice.get("id","")),"name":"","short_name":"","tier":tier_index(tier_name),"is_new":false,"level_from":0,"level_to":0,"max_level":0,"rows":[],"preview":{}}
 card["tier_name"]=str(FogPalette.RARITY[card.tier]["name"])
 if choice.type=="supply":
  card.name="Field supplies";card.short_name=card.name;card.tier=0;card.tier_name="Common"
  card.rows=[{"label":"Health","from":"%d"%roundi(game.health),"to":"%d"%roundi(minf(float(game.stats.max_health),float(game.health)+25.0))}]
  return card
 if choice.type=="weapon":
  var id=int(choice.id);card.category="weapons";card.max_level=Economy.WEAPON_MAX_LEVEL;card.short_name=Catalog.weapon_name(id)
  if game.weapons.has(id):
   var state: Dictionary=game.weapons[id];card.level_from=int(state.level);card.level_to=mini(card.level_from+1,card.max_level)
   if choice.has("attribute"):
    var c=WeaponUpgrades.change(id,state,str(choice.attribute),game,float(choice.get("step",-1.0)))
    card.name="%s — %s"%[card.short_name,c.label];card.rows=[{"label":c.label,"from":c.from,"to":c.to}]
   else:card.name=card.short_name
  else:
   var def=Catalog.WEAPONS[id];card.is_new=true;card.name=card.short_name;card.level_to=1
   card.rows=[{"label":"Type","value":str(def[1])},{"label":"Base damage","value":"%.0f"%float(def[2])},{"label":"Cooldown","value":"%.2fs"%float(def[3])}]
  return card
 var tome=str(choice.id);card.category="tomes";card.max_level=Economy.TOME_MAX_LEVEL;card.short_name=Catalog.tome_name(tome);card.name=card.short_name
 card.level_from=int(game.tomes.get(tome,0));card.level_to=mini(card.level_from+1,card.max_level);card.is_new=card.level_from==0
 var stat=str(Catalog.TOMES[tome][0]);var now=float(game.stats[stat]);var later=now+Economy.scaled(float(Catalog.TOMES[tome][1]),tier_name,stat=="count")
 card.rows=[{"label":label(stat),"from":BuildStats.value(stat,shown(stat,now)),"to":BuildStats.value(stat,shown(stat,later))}];card.preview={"stat":stat,"from":now,"to":later}
 return card

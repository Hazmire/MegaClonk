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

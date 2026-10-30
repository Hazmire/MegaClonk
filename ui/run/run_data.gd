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
# --- shop -----------------------------------------------------------------------------------------------------------
# Stat rows an item would change when bought: [{stat, from, to}] from the live stats, using the item runtime's own maths.
static func item_preview(game: Node,id: String) -> Array:
 var out=[]
 if not Catalog.item_exists(id) or Catalog.item_consumable(id):return out
 var deltas: Dictionary=game.irt.preview(id)
 for key in ["max_health","regen","armor","evasion","lifesteal","thorns","damage","crit","crit_damage","haste","count","size","projectile_speed","duration","knockback","speed","air_jumps","jump","pickup","xp","gold_gain","luck","difficulty"]:
  if deltas.has(key) and game.stats.has(key):out.append({"stat":key,"from":float(game.stats[key]),"to":float(game.stats[key])+float(deltas[key])})
 for key in deltas:
  if not out.any(func(c):return c.stat==key) and game.stats.has(key):out.append({"stat":key,"from":float(game.stats[key]),"to":float(game.stats[key])+float(deltas[key])})
 return out
# One Dictionary per seller offer, in the seller's order: items and Socket Gems. Prices come from ShopSystem / Economy only.
# {kind item|gem, id, code, name, tier, tier_name, kind_label, description, owned, owned_after, price, gold, need, sold, closed, affordable, available, preview}
static func shop_rows(game: Node,object: Dictionary) -> Array:
 var rows=[];var used=bool(object.get("used",false));var sold_list=object.get("sold",[])
 for offer in object.get("offers",[]):
  if not offer is String:
   var code=int(offer)
   if not GemRewards.is_gem_offer(code):continue
   var element=GemRewards.offer_element(code);var price=ShopSystem.gem_price(game.stage);var owned=game.gems.count(element);var sold=GemRewards.has_code(sold_list,code)
   rows.append({"kind":"gem","id":element,"code":code,"name":Elements.display_name(element)+" Socket Gem","tier":FogPalette.Rarity.RARE,"tier_name":"Rare","kind_label":"Socket gem","description":Elements.summary(element)+" Socket it at an Imbue Station.","owned":owned,"owned_after":owned+1,"price":price,"sold":sold,"closed":used and not sold,"available":true,"preview":[]})
   continue
  var id=str(offer);var tier=tier_index(Catalog.item_tier(id));var price=ShopSystem.price(id,game.stage);var stacks=game.item_stacks(id)
  var maxed=Catalog.item_unique(id) and stacks>0
  rows.append({"kind":"item","id":id,"code":0,"name":str(Catalog.ITEMS[id].name) if Catalog.ITEMS.has(id) else id,"tier":tier,"tier_name":str(FogPalette.RARITY[tier]["name"]),"kind_label":"Item","description":Catalog.item_description(id,false),"owned":stacks,"owned_after":stacks if maxed else stacks+1,"price":price,"sold":id in sold_list,"closed":used and not (id in sold_list),"available":id in game.available_items(),"preview":item_preview(game,id)})
 for r in rows:
  r["gold"]=int(game.gold);r["need"]=maxi(0,int(r.price)-int(game.gold));r["affordable"]=int(game.gold)>=int(r.price)
 return rows
# --- shrine ---------------------------------------------------------------------------------------------------------
# One Dictionary per shrine choice: {index, stat, stat_name, bonus, description, tier, tier_name, before, after}; all from ShrineRewards.
static func shrine_cards(reward: Dictionary) -> Array:
 var out=[]
 for i in reward.get("choices",[]).size():
  var c: Dictionary=reward.choices[i];var tier=tier_index(str(c.rarity))
  out.append({"index":i,"stat":str(c.stat),"stat_name":ShrineRewards.stat_name(str(c.stat)),"bonus":ShrineRewards.bonus_text(c),"description":str(c.description),"tier":tier,"tier_name":str(FogPalette.RARITY[tier]["name"]),"before":float(c.before),"after":float(c.after)})
 return out
# --- treasure chest -------------------------------------------------------------------------------------------------
# What the chest screen shows. The item is already decided and granted by RewardDrops before the screen opens; this only builds the
# look of the reel around it: STRIP_LENGTH cards drawn from the items the run can still find (tier weights match the drop weights, for
# looks only), with the real item on WIN_INDEX. A private RNG seeded from the item and the chest count keeps game.rng untouched and
# makes the same chest always spin the same way.
const STRIP_LENGTH=40
const WIN_INDEX=34
const REEL_WEIGHTS=[50,28,15,5,2]
static func chest_data(game: Node,id: String) -> Dictionary:
 var rng=RandomNumberGenerator.new();rng.seed=hash(id)+int(game.chests_opened)*7919
 var pool={}
 for item in game.available_items():
  var t=tier_index(Catalog.item_tier(str(item)));if not pool.has(t):pool[t]=[]
  pool[t].append(str(item))
 var strip=[]
 for i in STRIP_LENGTH:
  var pick=id
  if i!=WIN_INDEX and not pool.is_empty():
   var total=0;for t in pool:total+=REEL_WEIGHTS[t]
   var roll=rng.randi_range(1,total);var tier=pool.keys()[0]
   for t in pool:
    roll-=REEL_WEIGHTS[t];if roll<=0:tier=t;break
   pick=str(pool[tier][rng.randi()%pool[tier].size()])
  strip.append({"id":pick,"name":Catalog.item_name(pick),"tier":tier_index(Catalog.item_tier(pick))})
 var tier=tier_index(Catalog.item_tier(id))
 return {"id":id,"name":Catalog.item_name(id),"tier":tier,"tier_name":str(FogPalette.RARITY[tier]["name"]),"description":Catalog.item_description(id,false),"consumable":Catalog.item_consumable(id),
  "strip":strip,"win_index":WIN_INDEX,"land_offset":rng.randf_range(-60.0,60.0),"chest_number":int(game.chests_opened),"stack":int(game.item_stacks(id))}
# --- imbue station ----------------------------------------------------------------------------------------------------
# Everything the Imbue Station shows, from the live game: gem tray, one entry per owned weapon with its sockets, and the price.
# Socket entry: {kind: "gem"|"empty"|"locked", element, name}. Whether a held element may go into a weapon is decided by ImbueRules.problem().
static func imbue(game: Node) -> Dictionary:
 var cost=ImbueRules.cost(game.stage,game.irt.imbue_discount())
 var tray=[]
 for element in Elements.IDS:tray.append({"element":element,"name":Elements.display_name(element),"count":int(game.gems.count(element)),"color":Elements.color(element)})
 var weapons=[]
 for id in game.weapons:
  var state: Dictionary=game.weapons[id];var gems=WeaponSockets.gems(state);var open=WeaponSockets.unlocked(state);var sockets=[]
  for i in WeaponSockets.MAX_SOCKETS:
   if i<gems.size():sockets.append({"kind":"gem","element":str(gems[i]),"name":Elements.display_name(str(gems[i]))})
   elif i<open:sockets.append({"kind":"empty","element":"","name":""})
   else:sockets.append({"kind":"locked","element":"","name":""})
  var combo=WeaponSockets.combo(state)
  weapons.append({"id":int(id),"name":str(Catalog.WEAPONS[id][0]),"level":int(state.level),"open":open,"used":gems.size(),"sockets":sockets,"combo":str(combo.get("name","")),"can_unlock_second":WeaponSockets.can_unlock_second(state)})
 return {"cost":cost,"gold":int(game.gold),"amulets":int(game.amulets),"tray":tray,"weapons":weapons}

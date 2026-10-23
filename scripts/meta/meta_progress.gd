class_name MetaProgress
extends RefCounted
# Profile v2 is additive; legacy character/currency/stat data is preserved.
static func migrate(data: Dictionary) -> void:
 var defaults={"credits":int(data.get("currency",0)),"quest_gold":0,"account_level":1,"weapon_slots":2,"tome_slots":2,"entries":[],"disabled":[],"claimed":[],"quest_metrics":{},"leaderboard":[],"loadout":{"weapon":0,"trait":"climber","ultimate":"nova"}}
 for key in defaults:
  if not data.has(key): data[key]=defaults[key]
 for category in ["weapons","traits","items","ultimates"]:
  for e in LoadoutCatalog.entries(category):
   var key=category+":"+e.id
   if e.goal==0 and not key in data.entries: data.entries.append(key)
 data.weapon_slots=clampi(int(data.weapon_slots),2,4)
 data.tome_slots=clampi(int(data.tome_slots),2,4)
 data.credits=maxi(0,int(data.credits)); data.quest_gold=maxi(0,int(data.quest_gold))
 data.version=2
static func unlocked(data: Dictionary, category: String, id: String) -> bool:
 return category+":"+id in data.entries
static func enabled(data: Dictionary, category: String, id: String) -> bool:
 return unlocked(data,category,id) and not category+":"+id in data.disabled
static func toggle(data: Dictionary, category: String, id: String) -> bool:
 if not unlocked(data,category,id): return false
 var key=category+":"+id
 if key in data.disabled: data.disabled.erase(key)
 else: data.disabled.append(key)
 return true
static func purchase(data: Dictionary, category: String, id: String) -> bool:
 var e=LoadoutCatalog.entry(category,id)
 if e.is_empty() or unlocked(data,category,id) or int(data.kills)<int(e.goal) or int(data.credits)<int(e.cost): return false
 data.credits-=int(e.cost)
 data.entries.append(category+":"+id)
 return true
static func slot_cost(data: Dictionary, kind: String) -> int:
 return 100 if int(data[kind+"_slots"])==2 else 200
static func buy_slot(data: Dictionary, kind: String) -> bool:
 if not kind in ["weapon","tome"] or int(data[kind+"_slots"])>=4: return false
 var cost=slot_cost(data,kind)
 var required_level=2 if int(data[kind+"_slots"])==2 else 4
 if data.quest_gold<cost or account_level(data)<required_level: return false
 data.quest_gold-=cost; data[kind+"_slots"]+=1
 return true
static func account_level(data: Dictionary) -> int:
 return 1+int(data.claimed.size()/2)
static func quest_value(data: Dictionary, metric: String) -> float:
 if metric=="kills": return float(data.kills)
 if metric=="survival": return float(data.best)
 return float(data.quest_metrics.get(metric,0))
static func claim(data: Dictionary, id: String) -> bool:
 for quest in LoadoutCatalog.QUESTS:
  if quest.id==id and not id in data.claimed and quest_value(data,quest.metric)>=quest.target:
   data.claimed.append(id); data.credits+=quest.credits; data.quest_gold+=quest.gold
   data.account_level=account_level(data)
   return true
 return false
static func record(data: Dictionary, record: Dictionary, sandbox: bool) -> void:
 if sandbox: return
 for key in record.get("metrics",{}): data.quest_metrics[key]=float(data.quest_metrics.get(key,0))+float(record.metrics[key])
 if record.get("victory",false) and record.time<=300: data.quest_metrics.fast_clear=float(data.quest_metrics.get("fast_clear",0))+1
 data.leaderboard.append(record.duplicate(true))
 data.leaderboard.sort_custom(func(a,b):
  if bool(a.victory)!=bool(b.victory): return bool(a.victory)
  return float(a.kills)>float(b.kills) if a.kills!=b.kills else float(a.time)>float(b.time))
 if data.leaderboard.size()>20: data.leaderboard.resize(20)

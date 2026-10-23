class_name Progress
extends RefCounted
const PATH = "user://progress.json"
var storage_path = PATH
var data: Dictionary = {"version":2,"currency":0,"kills":0,"runs":0,"wins":0,"best":0.0,"unlocked":[0,1],"completed":[],"settings":{}}
func _init() -> void:
 MetaProgress.migrate(data)
func load_save(path: String = "") -> bool:
 if path.is_empty(): path=storage_path
 if not FileAccess.file_exists(path):
  MetaProgress.migrate(data)
  return false
 var parser=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK:return false
 var parsed=parser.data
 if not parsed is Dictionary or int(parsed.get("version", 0)) > 2: return false
 if int(parsed.get("version",1))<2 and not FileAccess.file_exists(path+".v1.bak"):
  DirAccess.copy_absolute(path,path+".v1.bak")
 MetaProgress.migrate(data)
 for key in data:
  if parsed.has(key) and typeof(parsed[key]) == typeof(data[key]): data[key] = parsed[key]
 # JSON parses integers as floats. Normalize numerical fields explicitly.
 for key in ["currency","kills","runs","wins","credits","quest_gold","weapon_slots","tome_slots","account_level"]:
  if parsed.get(key) is float or parsed.get(key) is int: data[key] = maxi(0, int(parsed[key]))
 if int(parsed.get("version",1))<2: data.credits=maxi(0,int(parsed.get("currency",0)))
 data.unlocked = normalize_ids(data.unlocked, 21)
 for id in [0,1]:
  if not id in data.unlocked: data.unlocked.append(id)
 data.completed = normalize_ids(data.completed, 3)
 MetaProgress.migrate(data)
 return true
func save(path: String = "") -> bool:
 MetaProgress.migrate(data)
 if path.is_empty(): path=storage_path
 var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
 if not file: return false
 file.store_string(JSON.stringify(data, "  "))
 file.close()
 return DirAccess.rename_absolute(path + ".tmp", path) == OK
func finish(kills: int, time: float, victory: bool, biome: int, sandbox: bool) -> Array:
 if sandbox: return []
 MetaProgress.migrate(data)
 var previous_kills=int(data.kills)
 data.runs += 1
 data.kills += kills
 var reward=maxi(1,kills/8)+(25 if victory else 0)
 data.currency+=reward
 data.credits+=reward
 data.best = maxf(data.best, time)
 if victory:
  data.wins += 1
  if not biome in data.completed: data.completed.append(biome)
 var unlocked: Array = []
 for category in ["weapons","traits","items","ultimates"]:
  for entry in LoadoutCatalog.entries(category):
   if previous_kills<int(entry.goal) and data.kills>=int(entry.goal) and not MetaProgress.unlocked(data,category,entry.id):unlocked.append(entry.name)
 save()
 return unlocked

func normalize_ids(values: Array, limit: int) -> Array:
 var result: Array = []
 for value in values:
  if (value is int or value is float) and int(value)>=0 and int(value)<limit and not int(value) in result:
   result.append(int(value))
 return result

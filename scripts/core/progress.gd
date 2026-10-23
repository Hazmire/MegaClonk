class_name Progress
extends RefCounted
const PATH = "user://progress.json"
var storage_path = PATH
var data: Dictionary = {"version":1,"currency":0,"kills":0,"runs":0,"wins":0,"best":0.0,"unlocked":[0,1],"completed":[],"settings":{}}
func load_save(path: String = "") -> bool:
 if path.is_empty(): path=storage_path
 if not FileAccess.file_exists(path): return false
 var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
 if not parsed is Dictionary or int(parsed.get("version", 0)) > 1: return false
 for key in data:
  if parsed.has(key) and typeof(parsed[key]) == typeof(data[key]): data[key] = parsed[key]
 # JSON parses integers as floats. Normalize numerical fields explicitly.
 for key in ["currency","kills","runs","wins"]:
  if parsed.get(key) is float or parsed.get(key) is int: data[key] = maxi(0, int(parsed[key]))
 data.unlocked = normalize_ids(data.unlocked, 21)
 for id in [0,1]:
  if not id in data.unlocked: data.unlocked.append(id)
 data.completed = normalize_ids(data.completed, 3)
 data.version = 1
 return true
func save(path: String = "") -> bool:
 if path.is_empty(): path=storage_path
 var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
 if not file: return false
 file.store_string(JSON.stringify(data, "  "))
 file.close()
 return DirAccess.rename_absolute(path + ".tmp", path) == OK
func finish(kills: int, time: float, victory: bool, biome: int, sandbox: bool) -> Array:
 if sandbox: return []
 data.runs += 1
 data.kills += kills
 data.currency += maxi(1, kills / 8) + (25 if victory else 0)
 data.best = maxf(data.best, time)
 if victory:
  data.wins += 1
  if not biome in data.completed: data.completed.append(biome)
 var unlocked: Array = []
 for i in range(2, Catalog.CHARACTERS.size()):
  if not i in data.unlocked and data.kills >= (i - 1) * 80:
   data.unlocked.append(i)
   unlocked.append(Catalog.CHARACTERS[i][0])
 save()
 return unlocked

func normalize_ids(values: Array, limit: int) -> Array:
 var result: Array = []
 for value in values:
  if (value is int or value is float) and int(value)>=0 and int(value)<limit and not int(value) in result:
   result.append(int(value))
 return result

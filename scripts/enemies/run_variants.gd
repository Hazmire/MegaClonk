class_name RunEnemyVariants
extends RefCounted
var seed_value=0
var selections: Array[int]=[]
func initialize(run_seed: int) -> void:
 seed_value=run_seed
 var random=RandomNumberGenerator.new()
 random.seed=run_seed
 selections.clear()
 for kind in EnemyCatalog.ARCHETYPES.size(): selections.append(random.randi_range(0,1))
func lookup(kind: int) -> Dictionary:
 return EnemyCatalog.variant(kind,selections[kind])
func serialize() -> Dictionary:
 return {"version":1,"seed":str(seed_value),"selections":selections.duplicate()}
func restore(data: Dictionary) -> bool:
 if int(data.get("version",0))!=1 or not data.get("selections") is Array or data.selections.size()!=8: return false
 var selected: Array[int]=[]
 for value in data.selections:
  if not (value is float or value is int) or float(value) not in [0.0,1.0]: return false
  selected.append(int(value))
 seed_value=int(data.get("seed","0"))
 selections=selected
 return true

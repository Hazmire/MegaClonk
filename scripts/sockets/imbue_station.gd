class_name ImbueStation
extends RefCounted

# Exactly one Imbue Station per stage. It is an extra interactable appended after the normal
# points of interest, so existing placements, saves and the object layout cache are untouched.
# If no free spot exists, one ordinary Chest is converted instead, so a station always exists.
const KIND="Imbue Station"
const SETTINGS={"spacings":[10.0,8.0,6.0],"spawn_distance":14.0,"seed_offset":5557321}

static func count(game: Node) -> int:
 var total=0
 for obj in game.interactables:
  if obj.kind==KIND:total+=1
 return total
static func find(game: Node) -> Dictionary:
 for obj in game.interactables:
  if obj.kind==KIND:return obj
 return {}
# Deterministic position from the stage layout, or Vector3.INF when no free point exists.
static func choose_position(data: Dictionary,stage: int) -> Vector3:
 var rng=RandomNumberGenerator.new();rng.seed=int(data.seed)+int(SETTINGS.seed_offset)+stage*7919
 var pool=ForestPlacement.candidates(data);ForestPlacement.shuffle(pool,rng)
 var placed=[data.spawn,data.portal,data.elite]
 for p in data.pois:placed.append(p)
 for spacing in SETTINGS.spacings:
  var point=ForestPlacement.pick(pool,placed,float(spacing),data.spawn,float(SETTINGS.spawn_distance))
  if point.is_finite():return point
 return Vector3.INF
static func make(game: Node,pos: Vector3) -> Dictionary:
 var model=Node3D.new();game.world.add_child(model);model.position=pos
 GrimdarkObjects.populate(model,KIND,game.stage)
 return {"node":model,"kind":KIND,"used":false,"charge":0.0}
static func setup(game: Node) -> void:
 if game.world_content_version<2 or count(game)>0:return
 var pos=choose_position(game.map_layout,game.stage)
 if pos.is_finite():
  game.interactables.append(make(game,pos));return
 # Fallback: convert one Chest (the layout guarantees at least fifteen) in place.
 var chests=[]
 for i in game.interactables.size():
  if game.interactables[i].kind=="Chest":chests.append(i)
 if chests.is_empty():return
 var rng=RandomNumberGenerator.new();rng.seed=int(game.map_layout.seed)+int(SETTINGS.seed_offset)
 var index=chests[rng.randi_range(0,chests.size()-1)]
 var old: Dictionary=game.interactables[index]
 var where: Vector3=old.node.position
 old.node.queue_free()
 game.interactables[index]=make(game,where)

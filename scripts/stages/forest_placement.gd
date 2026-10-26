class_name ForestPlacement
extends RefCounted
const KINDS=["Chest","Heal","Charge Shrine","Shop","Risk Shrine","Stat Shrine"]
static func floor_height(data: Dictionary,p: Vector2) -> float:
 return ForestMap.plane_height(data.planes[ForestMap.index(p.x,p.y)],p.x,p.y)
static func candidates(data: Dictionary) -> Array:
 var result=[]
 for z in range(-87,89,8):
  for x in range(-87,89,8):
   var p=Vector2(x,z)
   if ForestMap.is_ramp(data,p,5):continue
   var plane: Vector3=data.planes[ForestMap.index(x,z)]
   if absf(plane.x)+absf(plane.z)>0.001:continue
   var clear=true
   for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
    if absf(floor_height(data,p+direction*6)-plane.y)>0.01:clear=false;break
   if clear:result.append(Vector3(x,plane.y,z))
 return result
static func shuffle(values: Array,rng: RandomNumberGenerator) -> void:
 for i in range(values.size()-1,0,-1):
  var j=rng.randi_range(0,i);var temp=values[i];values[i]=values[j];values[j]=temp
static func pick(pool: Array,placed: Array,spacing: float,spawn: Vector3=Vector3.INF,spawn_distance: float=0) -> Vector3:
 for point in pool:
  if spawn.is_finite() and Vector2(point.x-spawn.x,point.z-spawn.z).length()<spawn_distance:continue
  var clear=true
  for other in placed:
   if Vector2(point.x-other.x,point.z-other.z).length()<spacing:clear=false;break
  if clear:return point
 return Vector3.INF
static func populate(data: Dictionary,settings: ForestSettings) -> void:
 var rng=RandomNumberGenerator.new();rng.seed=data.seed+9154883
 var pool=candidates(data);shuffle(pool,rng)
 var peripheral=[]
 for p in pool:
  if maxf(absf(p.x),absf(p.z))>=63:peripheral.append(p)
 assert(not peripheral.is_empty(),"No safe peripheral spawn")
 data.spawn=peripheral[0]
 for region in data.regions:
  if region.rect.has_point(Vector2(data.spawn.x,data.spawn.z)):data.spawn_region=region.id;break
 var placed=[data.spawn]
 data.portal=pick(pool,placed,14,data.spawn,64);assert(data.portal.is_finite(),"No reachable portal location");placed.append(data.portal)
 data.elite=pick(pool,placed,18,data.spawn,20);assert(data.elite.is_finite(),"No elite statue location");placed.append(data.elite)
 var bands=[]
 for p in pool:
  if not p.y in bands:bands.append(p.y)
 shuffle(bands,rng)
 var pois=[];var count=rng.randi_range(settings.minimum_optional_objects,settings.maximum_optional_objects)
 for i in count:
  # Seeded band order spreads discovery vertically without a radial pattern.
  var preferred=[]
  for p in pool:
   if is_equal_approx(p.y,float(bands[i%bands.size()])):preferred.append(p)
  var point=pick(preferred,placed,10,data.spawn,14)
  if not point.is_finite():point=pick(pool,placed,10,data.spawn,14)
  assert(point.is_finite(),"Insufficient safe world-object locations")
  pois.append(point);placed.append(point)
 data.pois=pois
 var records=[{"kind":"Player","position":[data.spawn.x,data.spawn.y,data.spawn.z]},{"kind":"Boss Portal","position":[data.portal.x,data.portal.y,data.portal.z]},{"kind":"Elite Statue","position":[data.elite.x,data.elite.y,data.elite.z]}]
 for i in pois.size():records.append({"kind":KINDS[i%KINDS.size()],"position":[pois[i].x,pois[i].y,pois[i].z]})
 data.placements=records;data.placement_candidates=pool.size()

class_name Vases
extends RefCounted

# Breakable terracotta vases. plan() is a pure, deterministic function of the stage layout, so
# the same seed always produces the same vases, positions and rewards; build() turns a plan
# into nodes; break_vase() is the single, idempotent place a vase breaks and pays out.
const SETTINGS={
 "base_count":32,"min_count":25,"max_count":40,"count_jitter":5,
 "area_reference":36864.0,                       # a 192 x 192 map; count scales with area
 "grid_step":3.0,"jitter":1.2,
 "edge_margin":6.0,"ramp_margin":4.0,"cliff_clearance":2.5,
 "spawn_clearance":12.0,"objective_clearance":10.0,"poi_clearance":3.2,"prop_clearance":0.6,
 "min_spacing":2.6,"cluster_spacing":1.25,"cluster_radius":1.9,"cluster_chance":0.2,"cluster_min":2,"cluster_max":4,
 "weights":{"poi":0.40,"path":0.25,"scatter":0.35},
 "poi_ring":[4.5,8.5],"path_band":[10.5,14.5],
 "weapons_break":false,                          # vases are smashed by pressing E, not by weapon hits
 "interact_radius":2.4
}
const VARIANTS=[
 {"id":"terracotta_vase","height":1.05,"radius":0.40,"weight":3.0},
 {"id":"terracotta_vase_small","height":0.78,"radius":0.31,"weight":2.0},
 {"id":"terracotta_vase_open","height":0.92,"radius":0.40,"weight":2.0},
 {"id":"terracotta_vase_open_small","height":0.70,"radius":0.31,"weight":1.0}
]
const HIT_HEIGHT=0.5
# Weapon kinds that normally need an enemy in range before they fire. When none is in range
# they may aim at the nearest vase instead, so every weapon can break vases on its own.
const AIM_KINDS=["fireball","chain","bounce","pierce","bullet","return","rocket","lob","scatter","dice","wave","beam","rail","hitscan"]

# ---------------------------------------------------------------- placement (pure)
static func lane_distance(data: Dictionary,p: Vector2) -> float:
 var center=Vector2.ZERO
 for region in data.regions:
  if region.rect.has_point(p):center=region.rect.get_center();break
 return minf(absf(p.x-center.x),absf(p.y-center.y))
static func valid(data: Dictionary,p: Vector2,blocked: Callable) -> bool:
 var limit=ForestMap.HALF-float(SETTINGS.edge_margin)
 if absf(p.x)>limit or absf(p.y)>limit:return false
 var plane: Vector3=data.planes[ForestMap.index(p.x,p.y)]
 if absf(plane.x)+absf(plane.z)>0.001:return false
 if ForestMap.is_ramp(data,p,float(SETTINGS.ramp_margin)):return false
 for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
  if absf(ForestPlacement.floor_height(data,p+direction*float(SETTINGS.cliff_clearance))-plane.y)>0.01:return false
 if p.distance_to(Vector2(data.spawn.x,data.spawn.z))<float(SETTINGS.spawn_clearance):return false
 if p.distance_to(Vector2(data.elite.x,data.elite.z))<float(SETTINGS.objective_clearance):return false
 if p.distance_to(Vector2(data.portal.x,data.portal.z))<float(SETTINGS.objective_clearance):return false
 for poi in data.pois:
  if p.distance_to(Vector2(poi.x,poi.z))<float(SETTINGS.poi_clearance):return false
 if blocked.is_valid() and blocked.call(Vector3(p.x,plane.y,p.y)):return false
 return true
static func too_close(p: Vector2,placed: Array,spacing: float) -> bool:
 for other in placed:
  if p.distance_to(other)<spacing:return true
 return false
static func pick_variant(rng: RandomNumberGenerator) -> Dictionary:
 var total=0.0
 for variant in VARIANTS:total+=float(variant.weight)
 var roll=rng.randf()*total;var running=0.0
 for variant in VARIANTS:
  running+=float(variant.weight)
  if roll<running:return variant
 return VARIANTS[0]
static func target_count(data: Dictionary,rng: RandomNumberGenerator) -> int:
 var area=pow(ForestMap.HALF*2.0,2)
 var scaled=float(SETTINGS.base_count)*area/float(SETTINGS.area_reference)
 return clampi(roundi(scaled)+rng.randi_range(-int(SETTINGS.count_jitter),int(SETTINGS.count_jitter)),int(SETTINGS.min_count),int(SETTINGS.max_count))
# Returns [{id,pos,variant,height,radius,yaw,reward,category,cluster}], identical for a seed.
# `blocked` is an optional Callable(Vector3)->bool for obstacles that exist outside the layout.
static func plan(data: Dictionary,stage: int,blocked: Callable=Callable()) -> Array:
 var rng=RandomNumberGenerator.new();rng.seed=int(data.seed)*31+7740911
 var loot_rng=RandomNumberGenerator.new();loot_rng.seed=int(data.seed)+3330091
 var target=target_count(data,rng)
 var step=float(SETTINGS.grid_step);var cells=[];var path_cells=[]
 var band: Array=SETTINGS.path_band
 var x=-ForestMap.HALF+step*0.5
 while x<ForestMap.HALF:
  var z=-ForestMap.HALF+step*0.5
  while z<ForestMap.HALF:
   var p=Vector2(x,z)
   if valid(data,p,blocked):
    cells.append(p)
    var lane=lane_distance(data,p)
    if lane>=float(band[0]) and lane<=float(band[1]):path_cells.append(p)
   z+=step
  x+=step
 var result=[];var placed=[];var guard=0;var cluster_index=0
 var weights: Dictionary=SETTINGS.weights
 var ring: Array=SETTINGS.poi_ring;var jitter=float(SETTINGS.jitter)
 while result.size()<target and guard<target*60 and not cells.is_empty():
  guard+=1
  var roll=rng.randf()*(float(weights.poi)+float(weights.path)+float(weights.scatter))
  var category="poi" if roll<float(weights.poi) else ("path" if roll<float(weights.poi)+float(weights.path) else "scatter")
  var anchor=Vector2.INF
  if category=="poi" and not data.pois.is_empty():
   var poi: Vector3=data.pois[rng.randi_range(0,data.pois.size()-1)]
   anchor=Vector2(poi.x,poi.z)+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(float(ring[0]),float(ring[1]))
  elif category=="path" and not path_cells.is_empty():
   anchor=path_cells[rng.randi_range(0,path_cells.size()-1)]+Vector2(rng.randf_range(-jitter,jitter),rng.randf_range(-jitter,jitter))
  else:
   category="scatter"
   anchor=cells[rng.randi_range(0,cells.size()-1)]+Vector2(rng.randf_range(-jitter,jitter),rng.randf_range(-jitter,jitter))
  if not anchor.is_finite() or too_close(anchor,placed,float(SETTINGS.min_spacing)) or not valid(data,anchor,blocked):continue
  var size=1
  if rng.randf()<float(SETTINGS.cluster_chance):size=rng.randi_range(int(SETTINGS.cluster_min),int(SETTINGS.cluster_max))
  size=mini(size,target-result.size())
  var members=[anchor]
  for k in range(1,size):
   for attempt in 8:
    var candidate=anchor+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(float(SETTINGS.cluster_spacing),float(SETTINGS.cluster_radius))
    if valid(data,candidate,blocked) and not too_close(candidate,placed+members,float(SETTINGS.cluster_spacing)):members.append(candidate);break
  for member in members:
   var variant=pick_variant(rng);var size_scale=rng.randf_range(0.9,1.1)
   var plane: Vector3=data.planes[ForestMap.index(member.x,member.y)]
   result.append({"id":result.size(),"pos":Vector3(member.x,plane.y,member.y),"variant":variant.id,"height":float(variant.height)*size_scale,"radius":float(variant.radius)*size_scale,"yaw":rng.randf()*TAU,"reward":VaseLoot.roll(loot_rng,stage),"category":category,"cluster":cluster_index if members.size()>1 else -1})
   placed.append(member)
  cluster_index+=1
 return result

# ---------------------------------------------------------------- runtime nodes
static func prop_blocked(game: Node,pos: Vector3) -> bool:
 for obj in game.interactables:
  if obj.kind==ImbueStation.KIND and Vector2(pos.x-obj.node.position.x,pos.z-obj.node.position.z).length()<4.0:return true
 var cell=Vector2i(floori(pos.x/8),floori(pos.z/8))
 for cx in range(cell.x-1,cell.x+2):
  for cz in range(cell.y-1,cell.y+2):
   for obstacle in game.obstacles.get(Vector2i(cx,cz),[]):
    if Vector2(pos.x-obstacle.pos.x,pos.z-obstacle.pos.z).length()<float(obstacle.radius)+0.55+float(SETTINGS.prop_clearance):return true
 return false
static func clear(game: Node) -> void:
 game.vases=[]
static func build(game: Node) -> void:
 clear(game)
 if game.world_content_version<2:return
 var plan_result=plan(game.map_layout,game.stage,func(pos): return prop_blocked(game,pos))
 for v in plan_result:
  v["broken"]=false
  var root=Node3D.new();root.position=v.pos;root.rotation.y=v.yaw
  GrimdarkObjects.part(root,v.variant,v.height,Vector3.ZERO,game.stage)
  var body=StaticBody3D.new();body.set_meta("vase_id",v.id)
  var shape=CollisionShape3D.new();var cylinder=CylinderShape3D.new();cylinder.radius=v.radius;cylinder.height=v.height
  shape.shape=cylinder;shape.position.y=v.height*0.5;body.add_child(shape);root.add_child(body)
  game.world.add_child(root)
  v["root"]=root;v["body"]=body;v["shape"]=shape
  var key=Vector2i(floori(v.pos.x/8),floori(v.pos.z/8))
  if not game.obstacles.has(key):game.obstacles[key]=[]
  game.obstacles[key].append({"pos":v.pos,"radius":v.radius,"vase":v.id})
  game.vases.append(v)
static func remaining(game: Node) -> int:
 var count=0
 for v in game.vases:
  if not v.broken:count+=1
 return count
# Removes collision, the visual and the enemy-avoidance entry immediately.
static func disable(game: Node,v: Dictionary) -> void:
 if is_instance_valid(v.get("body")):
  v.body.collision_layer=0;v.body.collision_mask=0
 if is_instance_valid(v.get("shape")):v.shape.disabled=true
 if is_instance_valid(v.get("root")):v.root.hide();v.root.queue_free()
 var key=Vector2i(floori(v.pos.x/8),floori(v.pos.z/8))
 if game.obstacles.has(key):
  var list: Array=game.obstacles[key]
  for i in range(list.size()-1,-1,-1):
   if list[i].get("vase",-1)==v.id:list.remove_at(i)
# The only place a vase breaks. Idempotent: any number of simultaneous hits yields one reward.
static func break_vase(game: Node,id: int,_weapon: int=-1) -> bool:
 if id<0 or id>=game.vases.size():return false
 var v: Dictionary=game.vases[id]
 if v.broken:return false
 v.broken=true
 disable(game,v)
 var center: Vector3=v.pos+Vector3.UP*HIT_HEIGHT
 if is_instance_valid(game.combat_fx):
  game.combat_fx.burst("smoke_puff",center,0.7,0.35)
  game.combat_fx.supplied_burst("debris",center,1.1)
 game.play_sound("vase.break")
 WorldPickups.spawn_reward(game,v.pos+Vector3.UP*0.55,v.reward)
 game.run_metrics["vases"]=int(game.run_metrics.get("vases",0))+1
 return true

# ---------------------------------------------------------------- weapon strikes
# Every player weapon shape ends in one of these; each returns how many vases broke.
static func strike_sphere(game: Node,center: Vector3,radius: float,weapon: int=-1) -> int:
 if not SETTINGS.weapons_break:return 0
 var broken=0
 for v in game.vases:
  if v.broken:continue
  if center.distance_to(v.pos+Vector3.UP*HIT_HEIGHT)<=radius+float(v.radius) and break_vase(game,v.id,weapon):broken+=1
 return broken
static func strike_segment(game: Node,a: Vector3,b: Vector3,radius: float,weapon: int=-1) -> int:
 if not SETTINGS.weapons_break:return 0
 var broken=0
 for v in game.vases:
  if v.broken:continue
  if game.segment_distance(v.pos+Vector3.UP*HIT_HEIGHT,a,b)<=radius+float(v.radius) and break_vase(game,v.id,weapon):broken+=1
 return broken
# Forward-facing sweeps: same half-space test the weapons use for enemies.
static func strike_arc(game: Node,origin: Vector3,direction: Vector3,radius: float,full_circle: bool,weapon: int=-1) -> int:
 if not SETTINGS.weapons_break:return 0
 var broken=0
 for v in game.vases:
  if v.broken:continue
  var offset: Vector3=(v.pos+Vector3.UP*HIT_HEIGHT)-origin
  if offset.length()>radius+float(v.radius):continue
  if not full_circle and offset.length()>float(v.radius)+0.6 and direction.dot(offset.normalized())<=0.1:continue
  if break_vase(game,v.id,weapon):broken+=1
 return broken
# Nearest unbroken vase within range, shaped like an enemy so weapons can aim at it.
static func target(game: Node,origin: Vector3,max_range: float) -> Dictionary:
 if not SETTINGS.weapons_break:return {}
 var best={};var best_distance=max_range
 for v in game.vases:
  if v.broken:continue
  var distance=Vector2(v.pos.x-origin.x,v.pos.z-origin.z).length()
  if distance<=best_distance:best_distance=distance;best={"pos":v.pos+Vector3.UP*HIT_HEIGHT,"vase":int(v.id),"hp":1.0,"max_hp":1.0,"kind":0,"radius":float(v.radius)}
 return best

# ---------------------------------------------------------------- player interaction (E)
# Nearest unbroken vase within reach of the player, or {}.
static func nearest_in_reach(game: Node,pos: Vector3) -> Dictionary:
 var best={};var best_distance=float(SETTINGS.interact_radius)
 for v in game.vases:
  if v.broken:continue
  var d=Vector2(v.pos.x-pos.x,v.pos.z-pos.z).length()-float(v.radius)
  if d<=best_distance:best_distance=d;best=v
 return best
# Player-triggered smash (the E key). Returns true when a vase broke.
static func smash(game: Node,v: Dictionary) -> bool:
 if v.is_empty():return false
 return break_vase(game,int(v.id),-1)

# ---------------------------------------------------------------- saves
static func serialize(game: Node) -> Array:
 var ids=[]
 for v in game.vases:
  if v.broken:ids.append(int(v.id))
 return ids
# Quietly marks vases as already broken: no reward, no effects.
static func restore(game: Node,ids: Variant) -> void:
 if not ids is Array:return
 for id in ids:
  var index=int(id)
  if index<0 or index>=game.vases.size() or game.vases[index].broken:continue
  game.vases[index].broken=true;disable(game,game.vases[index])

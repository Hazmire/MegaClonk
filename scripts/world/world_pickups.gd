class_name WorldPickups
extends RefCounted

# World pickups that are not XP gems: gold coins, socket gems and the three power-ups. XP gems
# keep using the existing game.pickups list, so the Magnet can drive them through the
# normal collection path instead of a parallel one.
const TUNING={
 "heal_fraction":0.25,
 "collect_radius":1.5,"attract_radius":4.0,"gold_limit":160,"coin_speed_start":14.0,"coin_speed_ramp":30.0,"coin_speed_max":48.0,
 "magnet":{"batch":24,"batch_interval":0.0166,"start_speed":22.0,"acceleration":70.0,"max_speed":64.0}
}
const POWERUP_DISTANCE=2.4 # power-ups land this far from the player, outside the walk-over radius
const KINDS=["gold","gem","heart","magnet","stopwatch"]
const ATTRACTED=["gold","gem"] # drift to the player like XP; power-ups are walk-over only
static var meshes: Dictionary={}
static var materials: Dictionary={}

# ---------------------------------------------------------------- visuals
static func mesh(kind: String) -> Mesh:
 if meshes.has(kind):return meshes[kind]
 var parts=[]
 match kind:
  "heart":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.25,0.40,0.20),Vector3(-0.15,0.42,-0.05),"4a0a14",Vector3(0,0,0.45)),ModelBuilder.part(ModelBuilder.cone(0.25,0.40,0.20),Vector3(0.15,0.42,-0.05),"4a0a14",Vector3(0,0,-0.45)),ModelBuilder.part(ModelBuilder.cone(0.46,0.52,0.0),Vector3(0,0.2,-0.05),"4a0a14",Vector3(PI,0,0)),
    ModelBuilder.part(ModelBuilder.cone(0.22,0.38,0.17),Vector3(-0.15,0.42,0.02),"d3243a",Vector3(0,0,0.45)),ModelBuilder.part(ModelBuilder.cone(0.22,0.38,0.17),Vector3(0.15,0.42,0.02),"d3243a",Vector3(0,0,-0.45)),ModelBuilder.part(ModelBuilder.cone(0.42,0.50,0.0),Vector3(0,0.2,0.02),"d3243a",Vector3(PI,0,0)),
    ModelBuilder.part(ModelBuilder.cube(Vector3(0.08,0.08,0.04)),Vector3(-0.2,0.5,0.28),"ff9aa6")]
  "magnet":
   parts=[ModelBuilder.part(ModelBuilder.cube(Vector3(0.62,0.17,0.18)),Vector3(0,0.62,0),"3a56b0"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.18,0.50,0.18)),Vector3(-0.22,0.38,0),"3a56b0"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.18,0.50,0.18)),Vector3(0.22,0.38,0),"3a56b0"),
    ModelBuilder.part(ModelBuilder.cube(Vector3(0.20,0.20,0.20)),Vector3(-0.22,0.10,0),"e8ecf2"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.20,0.20,0.20)),Vector3(0.22,0.10,0),"e8ecf2"),
    ModelBuilder.part(ModelBuilder.cube(Vector3(0.20,0.08,0.20)),Vector3(-0.22,0.22,0),"d3243a"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.20,0.08,0.20)),Vector3(0.22,0.22,0),"d3243a")]
  "stopwatch":
   var face=Vector3(PI*0.5,0,0)
   parts=[ModelBuilder.part(ModelBuilder.cone(0.36,0.14,0.36),Vector3(0,0.42,0),"b88a2a",face),ModelBuilder.part(ModelBuilder.cone(0.29,0.06,0.29),Vector3(0,0.42,0.08),"ece6cf",face),ModelBuilder.part(ModelBuilder.cube(Vector3(0.10,0.12,0.10)),Vector3(0,0.82,0),"d6a93a"),
    ModelBuilder.part(ModelBuilder.cube(Vector3(0.04,0.22,0.03)),Vector3(0,0.52,0.12),"1c1c24"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.15,0.04,0.03)),Vector3(0.06,0.42,0.12),"1c1c24"),
    ModelBuilder.part(ModelBuilder.cube(Vector3(0.04,0.05,0.03)),Vector3(0,0.66,0.12),"a02a2a"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.05,0.04,0.03)),Vector3(0.25,0.42,0.12),"a02a2a"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.05,0.04,0.03)),Vector3(-0.25,0.42,0.12),"a02a2a")]
  "gold":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.20,0.05,0.20),Vector3(0,0.22,0),"f2c44c",Vector3(PI*0.5,0,0)),ModelBuilder.part(ModelBuilder.cone(0.13,0.07,0.13),Vector3(0,0.22,0),"c9962e",Vector3(PI*0.5,0,0))]
  _: # socket gem: a faceted bicone, tinted per element by its material
   parts=[ModelBuilder.part(ModelBuilder.cone(0.20,0.30),Vector3(0,0.42,0),"ffffff"),ModelBuilder.part(ModelBuilder.cone(0.20,0.24),Vector3(0,0.15,0),"d0d4dc",Vector3(PI,0,0))]
 meshes[kind]=ModelBuilder.bake(parts)
 return meshes[kind]
static func material(kind: String,element: String="") -> StandardMaterial3D:
 var key=kind+":"+element
 if materials.has(key):return materials[key]
 var result=StandardMaterial3D.new();result.vertex_color_use_as_albedo=true;result.roughness=0.55;result.emission_enabled=true
 var glow=Color("ffcf5a")
 match kind:
  "heart":glow=Color("ff3b52")
  "magnet":glow=Color("5d86ff")
  "stopwatch":glow=Color("ffd24a")
  "gem":
   glow=Elements.color(element);result.albedo_color=glow;result.metallic=0.2;result.roughness=0.2
 result.emission=glow;result.emission_energy_multiplier=0.7 if kind!="gold" else 0.45
 materials[key]=result;return result
static func scale_for(kind: String) -> float:
 return {"heart":1.6,"magnet":1.6,"stopwatch":1.5,"gem":1.7,"gold":1.5}.get(kind,1.5)

# ---------------------------------------------------------------- spawning
static func clear(game: Node) -> void:
 game.world_pickups=[]
static func spawn(game: Node,kind: String,pos: Vector3,value: int=0,element: String="") -> bool:
 if not kind in KINDS or (kind=="gem" and not Elements.valid(element)):return false
 if kind=="gold" and game.world_pickups.size()>=int(TUNING.gold_limit):
  game.gold+=value;return true # over the cap: pay out directly instead of spawning
 var key="wp_"+kind+("_"+element if kind=="gem" else "")
 var node=game.pool.acquire(key,mesh(kind),Color.WHITE,pos)
 node.material_override=material(kind,element);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 node.scale=Vector3.ONE*scale_for(kind);node.visibility_range_end=70;node.visibility_range_end_margin=5
 game.world_pickups.append({"kind":kind,"node":node,"age":randf()*3.0,"value":value,"element":element,"base_y":pos.y,"attracted":false})
 return true
# Where a power-up lands: a short step from the player towards the vase, clear of the pickup
# radius, so it is never collected by accident and the player decides whether to walk onto it.
static func near_player(game: Node,vase_pos: Vector3) -> Vector3:
 var from: Vector3=game.player.position
 var direction=Vector3(vase_pos.x-from.x,0.0,vase_pos.z-from.z)
 direction=Vector3.FORWARD if direction.length()<0.1 else direction.normalized()
 var spot=from+direction*POWERUP_DISTANCE
 spot.y=game.terrain_height(spot.x,spot.z)+0.8
 return spot
# A coin that always flies to the player (enemy kills, vases). `value` gold is paid on arrival.
static func spawn_gold(game: Node,pos: Vector3,value: int) -> void:
 if value<=0:return
 if spawn(game,"gold",pos,value) and not game.world_pickups.is_empty() and game.world_pickups.back().kind=="gold":
  game.world_pickups.back()["attracted"]=true
# Pays every coin still in flight (stage change, run end) so no gold is ever lost.
static func settle(game: Node) -> int:
 var paid=0
 for i in range(game.world_pickups.size()-1,-1,-1):
  var p: Dictionary=game.world_pickups[i]
  if p.kind!="gold":continue
  game.gold+=int(p.value);paid+=int(p.value)
  if is_instance_valid(p.node):game.pool.release(p.node)
  game.world_pickups.remove_at(i)
 return paid
# Turns a vase reward description into world objects at `pos`. XP, gold and gems fly straight
# to the player; Heart, Magnet and Stopwatch wait near the player until walked onto.
static func spawn_reward(game: Node,pos: Vector3,reward: Dictionary) -> void:
 var count=maxi(1,int(reward.get("count",1)))
 match str(reward.get("kind","")):
  "xp":
   for i in count:
    var offset=Vector3.RIGHT.rotated(Vector3.UP,TAU*float(i)/float(count))*0.9
    game.pickups.append({"node":XPGems.acquire(game,pos+offset),"value":float(reward.get("value",5.0)),"age":0.0,"attracted":true,"attraction_reason":"vase"})
  "gold":
   for i in count:
    var offset=Vector3.RIGHT.rotated(Vector3.UP,TAU*float(i)/float(count)+0.6)*0.7
    spawn_gold(game,pos+offset,int(reward.get("value",5)))
  "gem":
   if spawn(game,"gem",pos,0,str(reward.get("element",""))):game.world_pickups.back()["attracted"]=true
  "heart","magnet","stopwatch":spawn(game,str(reward.kind),near_player(game,pos))

# ---------------------------------------------------------------- per-frame update
static func update(game: Node,delta: float) -> void:
 var target: Vector3=game.player.position+Vector3.UP
 for i in range(game.world_pickups.size()-1,-1,-1):
  var p: Dictionary=game.world_pickups[i]
  p.age+=delta;p.node.rotation.y+=delta*1.7
  var distance=p.node.position.distance_to(target)
  if p.kind in ATTRACTED and not p.attracted and distance<float(TUNING.attract_radius)*game.stats.pickup:p.attracted=true
  if p.attracted and p.kind=="gold":
   # Coins home in on the player and accelerate, wherever they were dropped.
   p["homing"]=float(p.get("homing",0.0))+delta
   p.node.position=p.node.position.move_toward(target,delta*minf(float(TUNING.coin_speed_max),float(TUNING.coin_speed_start)+float(p.homing)*float(TUNING.coin_speed_ramp)))
  elif p.attracted:p.node.position=p.node.position.move_toward(target,delta*maxf(10.0,18.0-distance))
  else:p.node.position.y=float(p.base_y)+sin(p.age*2.4)*0.08
  if distance<float(TUNING.collect_radius):
   game.world_pickups.remove_at(i)
   game.pool.release(p.node)
   collect(game,p)

# ---------------------------------------------------------------- effects
static func collect(game: Node,p: Dictionary) -> void:
 match str(p.kind):
  "gold":
   game.gold+=int(p.value);game.play_sound("pickup.gold")
  "gem":
   game.gems.add(str(p.element));game.gem_discovered(str(p.element))
  "heart":heal(game)
  "magnet":magnet(game)
  "stopwatch":stopwatch(game)
# Heart Container: 25% of maximum HP at the moment of collection, never above maximum.
static func heal(game: Node) -> float:
 var amount: float=float(game.stats.max_health)*float(TUNING.heal_fraction)
 var before: float=game.health
 game.health=minf(game.stats.max_health,game.health+amount)
 var healed: float=game.health-before
 if healed>0.0 and game.settings.numbers and DisplayServer.get_name()!="headless" and is_instance_valid(game.numbers):
  game.numbers.show_damage(game.player.position+Vector3.UP*2.2,healed,false,Color("6fe06f"),game.elapsed)
 game.flash(game.player.position+Vector3.UP*0.2,Color("6fe06f"),1.8)
 game.play_sound("powerup.heart")
 return healed
# Magnet: flags every active XP gem as attracted. Release is staggered in batches (nearest
# first) so hundreds of gems stream in over a few frames instead of arriving on one frame.
# The existing update_pickups path collects them, so XP, events and pooling are unchanged.
static func magnet(game: Node) -> int:
 var origin: Vector3=game.player.position
 var queue=[]
 for p in game.pickups:
  if not p.get("magnet",false):queue.append(p)
 queue.sort_custom(func(a,b): return a.node.position.distance_squared_to(origin)<b.node.position.distance_squared_to(origin))
 var batch=maxi(1,int(TUNING.magnet.batch))
 for i in queue.size():
  var p: Dictionary=queue[i]
  p["magnet"]=true;p["attracted"]=true;p["attraction_reason"]="magnet"
  p["magnet_wait"]=float(int(i/batch))*float(TUNING.magnet.batch_interval)
  p["magnet_speed"]=float(TUNING.magnet.start_speed)
 game.play_sound("powerup.magnet")
 game.flash(origin+Vector3.UP*0.2,Color("6f9bff"),2.4)
 if queue.is_empty():game.toast("Magnet: no gems on the ground")
 return queue.size()
# Stopwatch: starts or refreshes the world slowdown (see WorldTime).
static func stopwatch(game: Node) -> void:
 game.world_time.activate()
 game.play_sound("powerup.stopwatch")
 game.flash(game.player.position+Vector3.UP*0.2,Color("ffe27a"),2.6)
# One step of a magnetised gem; returns the new position. Used by Game.update_pickups.
static func magnet_step(p: Dictionary,target: Vector3,delta: float) -> Vector3:
 p.magnet_wait=float(p.get("magnet_wait",0.0))-delta
 if p.magnet_wait>0.0:return p.node.position
 p.magnet_speed=minf(float(TUNING.magnet.max_speed),float(p.get("magnet_speed",TUNING.magnet.start_speed))+delta*float(TUNING.magnet.acceleration))
 return p.node.position.move_toward(target,delta*float(p.magnet_speed))

# ---------------------------------------------------------------- saves
static func serialize(game: Node) -> Array:
 var result=[]
 for p in game.world_pickups:
  var pos: Vector3=p.node.position;result.append({"kind":p.kind,"position":[pos.x,float(p.base_y),pos.z],"value":int(p.value),"element":str(p.element)})
 return result
static func restore(game: Node,records: Variant) -> void:
 if not records is Array:return
 for record in records:
  if not record is Dictionary or not record.get("position") is Array or record.position.size()!=3:continue
  var kind=str(record.get("kind",""))
  if kind=="gold":spawn_gold(game,Vector3(record.position[0],record.position[1],record.position[2]),int(record.get("value",0)))
  else:spawn(game,kind,Vector3(record.position[0],record.position[1],record.position[2]),int(record.get("value",0)),str(record.get("element","")))

class_name CrowdPhysics
extends RefCounted
# Actual vertical cylinder contacts, backed by compact arrays and a 3m hash.
# No per-enemy rigid body, scene search or global all-pairs collision pass.
const SETTINGS=preload("res://assets/config/stage_update.tres")
const CELL=3.0
const EMPTY: Dictionary={}
const EMPTY_MODULES: Array=[]
var buckets: Dictionary={}
var max_radius=1.0
var checks=0
var next_id=1
var solve_phase=0
var positions=PackedVector3Array()
var radii=PackedFloat32Array()
var heights=PackedFloat32Array()
var lifts=PackedFloat32Array()
var floors=PackedFloat32Array()
var ids=PackedInt64Array()
var traversing=PackedByteArray()
var alive=PackedByteArray()
func key(p: Vector3) -> Vector2i:return Vector2i(floori(p.x/CELL),floori(p.z/CELL))
func rebuild(enemies: Array) -> void:
 buckets.clear();max_radius=0.5;checks=0;solve_phase=1-solve_phase
 var count=enemies.size();positions.resize(count);radii.resize(count);heights.resize(count);lifts.resize(count);floors.resize(count);ids.resize(count);traversing.resize(count);alive.resize(count);alive.fill(0)
 for i in count:
  var e: Dictionary=enemies[i]
  if e.hp<=0:continue
  if not e.has("crowd_id"):e.crowd_id=next_id;next_id+=1
  next_id=maxi(next_id,int(e.crowd_id)+1);e["crowd_slot"]=i
  positions[i]=e.pos;radii[i]=float(e.get("radius",0.5));heights[i]=EnemyContact.height(e);lifts[i]=float(e.get("crowd_height",0));floors[i]=positions[i].y-0.65-lifts[i];ids[i]=int(e.crowd_id)
  traversing[i]=1 if not e.get("climb",EMPTY).is_empty() or not e.get("drop",EMPTY).is_empty() else 0;alive[i]=1
  max_radius=maxf(max_radius,radii[i]);var cell=key(e.pos)
  if not buckets.has(cell):buckets[cell]=[]
  buckets[cell].append(i)
func disable(e: Dictionary) -> void:
 var slot=int(e.get("crowd_slot",-1))
 if slot>=0 and slot<alive.size() and ids[slot]==int(e.get("crowd_id",0)):alive[slot]=0
func indices(p: Vector3,radius: float,budget: int=48) -> Array:
 var result=[];var center=key(p);var reach=ceili(radius/CELL);var inspected=0;var squared=radius*radius
 for x in range(center.x-reach,center.x+reach+1):
  for z in range(center.y-reach,center.y+reach+1):
   for i in buckets.get(Vector2i(x,z),[]):
    checks+=1;inspected+=1
    if inspected>budget*4:return result
    var position: Vector3=positions[i];var dx=position.x-p.x;var dz=position.z-p.z
    if alive[i] and dx*dx+dz*dz<=squared:
     result.append(i)
     if result.size()>=budget:return result
 return result
static func sweep(start: Vector2,motion: Vector2,center: Vector2,radius: float) -> float:
 var offset=start-center;var a=motion.length_squared();var c=offset.length_squared()-radius*radius
 if a<0.0000001:return 1.0
 if c<=0:return 0.0 if offset.dot(motion)<0 else 1.0
 var b=offset.dot(motion)
 if b>=0:return 1.0
 var discriminant=b*b-a*c
 if discriminant<0:return 1.0
 return clampf((-b-sqrt(discriminant))/a,0,1)
func player_velocity(game: Node,velocity: Vector3,delta: float) -> Vector3:
 if delta<=0 or game.loadout_runtime.immune():return velocity
 var p: Vector3=game.player.position;var motion=Vector2(velocity.x,velocity.z)*delta;var start=Vector2(p.x,p.z);var player_radius=game.player.collider.shape.radius;var player_height=game.player.collider.shape.height
 var nearby=indices(p,max_radius+player_radius+motion.length()+0.3,96)
 for iteration in 3:
  var earliest=1.0;var normal=Vector2.ZERO
  for i in nearby:
   var position: Vector3=positions[i];var bottom=position.y-0.65
   if p.y>=bottom+heights[i]+0.05 or p.y+player_height<=bottom:continue
   var center=Vector2(position.x,position.z);var t=sweep(start,motion,center,radii[i]+player_radius)
   if t<earliest:earliest=t;normal=(start+motion*t-center).normalized()
  if earliest>=1:break
  var remaining=motion*(1-earliest);motion=motion*maxf(0,earliest-0.001)+remaining.slide(normal)
 return Vector3(motion.x/delta,velocity.y,motion.y/delta)
func prepare(e: Dictionary) -> void:
 var slot=int(e.crowd_slot);e["crowd_was_traversing"]=traversing[slot]>0;e.pos.y-=lifts[slot]
func snapshot(e: Dictionary,slot: int) -> void:
 positions[slot]=e.pos;lifts[slot]=float(e.get("crowd_height",0));floors[slot]=positions[slot].y-0.65-lifts[slot]
func resolve(game: Node,e: Dictionary,delta: float) -> void:
 var slot=int(e.crowd_slot)
 if e.hp<=0:alive[slot]=0;return
 var radius=float(radii[slot]);var old_height=float(lifts[slot]);var on_terrain_path=not e.get("climb",EMPTY).is_empty() or not e.get("drop",EMPTY).is_empty();traversing[slot]=1 if on_terrain_path else 0
 # Two staggered groups solve at 30Hz against ALL actual body positions;
 # pursuit, damage, broadphase and the player's swept capsule remain at 60Hz.
 if int(ids[slot])%2!=solve_phase:
  if on_terrain_path:
   if not e.get("crowd_was_traversing",false):e.pos.y+=old_height
   e.crowd_height=0
  else:e.pos.y+=old_height
  snapshot(e,slot);return
 delta=minf(delta*2,0.08)
 var nearby=indices(e.pos,radius+max_radius+0.4,SETTINGS.crowd_neighbour_budget)
 var floor=float(e.pos.y)-0.65;var target=0.0
 if not on_terrain_path and e.kind<8 and not "flying" in e.variant.get("modules",EMPTY_MODULES) and e.speed>0 and e.state in ["move","charging"]:
  var direction: Vector3=e.get("move_direction",Vector3.ZERO)
  for other in nearby:
   if ids[other]>=ids[slot] or traversing[other] or absf(floor-floors[other])>0.35:continue
   var difference: Vector3=positions[other]-e.pos;difference.y=0;var reach=radius+radii[other]+0.15
   if difference.length_squared()>reach*reach or (old_height<0.1 and difference.dot(direction)<0.05):continue
   var top=lifts[other]+heights[other]
   if top<=SETTINGS.crowd_max_height and top>target:target=top
 var height=move_toward(old_height,target,(SETTINGS.crowd_climb_speed if target>old_height else SETTINGS.crowd_fall_speed)*delta)
 if on_terrain_path:
  if not e.get("crowd_was_traversing",false):e.pos.y+=old_height
  height=0
 e["crowd_height"]=height
 var position: Vector3=e.pos;position.y+=height
 var own_height=float(heights[slot]);var correction_total=Vector2.ZERO;var contacts=0
 for other in nearby:
  if other==slot:continue
  var other_position: Vector3=positions[other];var combined=radius+radii[other];var dx=position.x-other_position.x;var dz=position.z-other_position.z;var squared=dx*dx+dz*dz
  if squared>=combined*combined:continue
  var bottom=other_position.y-0.65
  if position.y-0.65>=bottom+heights[other]-0.04 or position.y-0.65+own_height<=bottom+0.04:continue
  var distance=sqrt(squared);var direction=Vector2(dx,dz)/distance if distance>0.001 else Vector2.from_angle(float(ids[slot])*2.39996)
  var correction=direction*minf(combined-distance,maxf(0.02,delta*4));var remaining=maxf(0,delta*8-correction_total.length());correction=correction.limit_length(remaining)
  if correction.length_squared()>0.000001:position=game.constrain_enemy_motion(position,position+Vector3(correction.x,0,correction.y));correction_total+=correction
  contacts+=1
  if contacts>=8 or remaining<=0:break
 # No impulses are applied to the player: enemies yield a bounded distance.
 var player: Vector3=game.player.position;var player_height=game.player.collider.shape.height
 if not game.loadout_runtime.immune() and player.y<position.y-0.65+own_height+0.1 and player.y+player_height>position.y-0.65:
  var difference=Vector2(position.x-player.x,position.z-player.z);var distance=difference.length();var required=radius+game.player.collider.shape.radius
  if distance<required:
   var n=difference.normalized() if distance>0.001 else Vector2.from_angle(float(ids[slot])*2.39996)
   position=game.constrain_enemy_motion(position,position+Vector3(n.x,0,n.y)*minf(required-distance,delta*2.5))
 if not on_terrain_path and not "flying" in e.variant.get("modules",EMPTY_MODULES) and e.get("encounter","")!="ghost":position.y=game.terrain_height(position.x,position.z)+0.65+height
 e.pos=position;snapshot(e,slot)

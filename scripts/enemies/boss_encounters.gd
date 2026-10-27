class_name BossEncounters
extends RefCounted
const MAIN=["chunkus","rock_golem"]
const MINI=["champion","hunter"]
static func start(game: Node,key: String,main: bool,origin: Vector3) -> Dictionary:
 if game.boss_encounters.has(key):return game.boss_encounters[key]
 var rng=RandomNumberGenerator.new();rng.seed=game.run_seed+game.stage*9109+hash(key)
 var count=1+game.additional_boss_count;var variants=[];var pool=MAIN if main else MINI
 for i in count:variants.append(pool[rng.randi_range(0,pool.size()-1)])
 var group={"id":key,"stage":game.stage,"main":main,"required":count,"remaining":count,"spawned":0,"pending":variants,"members":[],"origin":[origin.x,origin.y,origin.z],"retry_clock":0.0,"complete":false}
 game.boss_encounters[key]=group
 spawn_pending(game,group,2)
 return group
static func point(game: Node,origin: Vector3,index: int) -> Vector3:
 for attempt in 192:
  var angle=(attempt+index*7)*2.399963;var radius=6+sqrt(float(attempt))*1.7
  var p=origin+Vector3(cos(angle),0,sin(angle))*radius
  if maxf(absf(p.x),absf(p.z))>90:continue
  p.y=game.terrain_height(p.x,p.z)
  if game.forest_navigation.blocked.has(ForestMap.index(p.x,p.z)) or not game.forest_navigation.reachable(p):continue
  var valid=true
  for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
   var q=p+direction*2.5
   if absf(game.terrain_height(q.x,q.z)-p.y)>0.5:valid=false;break
  if not valid or game.avoid_props(p,2.2).distance_to(p)>0.1:continue
  for e in game.enemies:
   if e.hp<=0 or absf(e.pos.y-p.y)>6:continue
   if Vector2(p.x-e.pos.x,p.z-e.pos.z).length()<2.6+float(e.get("radius",0.5)):valid=false;break
  if valid:return p
 return Vector3.INF
static func spawn_pending(game: Node,group: Dictionary,budget: int) -> int:
 var spawned=0
 while not group.pending.is_empty() and spawned<budget and game.enemies.size()<game.ENEMY_LIMIT:
  var origin=Vector3(group.origin[0],group.origin[1],group.origin[2]);var p=point(game,origin,int(group.spawned))
  if not p.is_finite():group.retry_clock=0.5;break
  var variant=str(group.pending[0]);var kind=8 if group.main else 9 if variant=="champion" else 10
  var enemy=game.spawn_enemy(kind,p)
  if enemy.is_empty():group.retry_clock=0.5;break
  Encounters.initialize(game,enemy,variant);enemy.boss_group=group.id
  enemy.ability_clock+=float(int(group.spawned)%8)*0.35
  group.pending.pop_front();group.members.append(int(enemy.crowd_id));group.spawned+=1;spawned+=1
  if group.main and group.spawned==1:game.boss_variant=variant
 return spawned
static func tick(game: Node,delta: float) -> void:
 var budget=2
 for group in game.boss_encounters.values():
  if group.complete or group.pending.is_empty():continue
  group.retry_clock=maxf(0,float(group.get("retry_clock",0))-delta)
  if group.retry_clock<=0 and budget>0:budget-=spawn_pending(game,group,budget)
static func died(game: Node,e: Dictionary) -> bool:
 var key=str(e.get("boss_group",""))
 if game.boss_encounters.has(key) and not e.get("encounter_death_counted",false):
  e.encounter_death_counted=true
  var group=game.boss_encounters[key];var id=int(e.crowd_id)
  if id in group.members:
   group.members.erase(id);group.remaining=maxi(0,int(group.remaining)-1)
  group.complete=group.remaining==0 and group.pending.is_empty()
 if int(e.kind)!=8:return false
 for other in game.enemies:
  if other!=e and int(other.kind)==8 and other.hp>0:return false
 for group in game.boss_encounters.values():
  if group.main and int(group.remaining)>0:return false
 return true
static func restore(game: Node,data: Variant) -> void:
 game.boss_encounters.clear()
 if not data is Dictionary:return
 for key in data:
  var group=data[key]
  if not group is Dictionary or not group.get("pending") is Array or not group.get("members") is Array:continue
  var members=[]
  for id in group.members:members.append(int(id))
  group.members=members;group.required=int(group.get("required",members.size()+group.pending.size()));group.remaining=int(group.get("remaining",members.size()+group.pending.size()));group.spawned=int(group.get("spawned",members.size()));group.complete=group.remaining<=0
  game.boss_encounters[str(key)]=group

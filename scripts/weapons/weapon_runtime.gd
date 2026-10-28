class_name WeaponRuntime
extends RefCounted

# Runs all eight weapons (Weapon Overhaul 2.0). One shared hit interface (`strike`) feeds Game.hit, so
# every hit type (slash, fireball, strike/chain, arrow, bullet/ricochet, pulse, scythe out/back, pellet)
# passes through the same crit, elemental-socket (StatusManager.on_hit), combo and amulet code, and
# every attack instance owns a hit set so an enemy is never damaged twice by the same slash, arrow,
# strike, pass or pellet. Visuals go through PsxFx only: no nodes are created per effect.
const MAX_FIREBALLS=60
const MAX_ARROWS=120
const MAX_BULLETS=120
const MAX_SCYTHES=40
const MAX_TIMERS=400
var game: Node
var psx: PsxFx
var rng=RandomNumberGenerator.new() # gameplay jitter; never touches game.rng so seeded runs are unaffected
var timers: Array=[]
var fireballs: Array=[]
var arrows: Array=[]
var bullets: Array=[]
var scythes: Array=[]
var scythe_view: MultiMeshInstance3D
var aura_spin=0.0
var aura_glow=0.0
var aura_smoke=0.0
var aura_hum=0.0
var pulse_budget=0
var counters={"strike":{},"casts":{},"dropped_timers":0}
const SCYTHE_MODEL_PATH="res://assets/weapons/scythe.glb" # supplied model slot; PLACEHOLDER mesh is used until it exists

func _init(owner: Node,fx: PsxFx) -> void:
 game=owner;psx=fx;rng.seed=424242
 scythe_view=MultiMeshInstance3D.new();scythe_view.name="PLACEHOLDER_ScytheMeshes"
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=scythe_mesh();mm.instance_count=MAX_SCYTHES;mm.visible_instance_count=0
 scythe_view.multimesh=mm;scythe_view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;scythe_view.extra_cull_margin=200.0
 fx.add_child(scythe_view)
func clear() -> void:
 timers.clear();fireballs.clear();arrows.clear();bullets.clear();scythes.clear()
 if scythe_view!=null:scythe_view.multimesh.visible_instance_count=0
 psx.clear()
func uses_placeholder_scythe() -> bool:return not ResourceLoader.exists(SCYTHE_MODEL_PATH)
# Temporary low-poly scythe (handle + curved blade), flat-shaded through vertex colours.
# TEMPORARY / PLACEHOLDER: replace by dropping the supplied model at SCYTHE_MODEL_PATH.
func scythe_mesh() -> Mesh:
 if ResourceLoader.exists(SCYTHE_MODEL_PATH):
  var scene=load(SCYTHE_MODEL_PATH)
  if scene is PackedScene:
   var root=scene.instantiate();var found=_first_mesh(root);root.queue_free()
   if found!=null:return found
 var solid=ShaderMaterial.new();solid.shader=preload("res://shaders/psx_fx_solid.gdshader")
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 var wood=Color("6b4a2b");var steel=Color("a9b0bb");var edge=Color("eef2f6")
 _box(tool,Vector3.ZERO,Vector3(1.9,0.07,0.07),wood)
 var centre=Vector3(0.95,0,-0.85);var steps=7;var amax=1.45
 for k in steps:
  var a0=amax*float(k)/steps;var a1=amax*float(k+1)/steps
  var w0=0.26*(1.0-a0/amax*0.92);var w1=0.26*(1.0-a1/amax*0.92)
  var o0=centre+Vector3(sin(a0),0,cos(a0))*0.85;var o1=centre+Vector3(sin(a1),0,cos(a1))*0.85
  var i0=centre+Vector3(sin(a0),0,cos(a0))*(0.85-w0);var i1=centre+Vector3(sin(a1),0,cos(a1))*(0.85-w1)
  _quad(tool,o0,o1,i1,i0,edge,steel)
 var mesh=tool.commit();mesh.surface_set_material(0,solid);return mesh
func _first_mesh(node: Node) -> Mesh:
 if node is MeshInstance3D and node.mesh!=null:return node.mesh
 for child in node.get_children():
  var m=_first_mesh(child)
  if m!=null:return m
 return null
func _box(tool: SurfaceTool,center: Vector3,size: Vector3,color: Color) -> void:
 var h=size*0.5
 var corners=[Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(-h.x,h.y,-h.z),Vector3(-h.x,-h.y,h.z),Vector3(h.x,-h.y,h.z),Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z)]
 var faces=[[0,1,2,3],[5,4,7,6],[4,0,3,7],[1,5,6,2],[3,2,6,7],[4,5,1,0]]
 for f in faces:
  tool.set_color(color)
  for idx in [0,1,2,0,2,3]:tool.add_vertex(center+corners[f[idx]])
func _quad(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,outer: Color,inner: Color) -> void:
 # a,b = outer edge (lighter), c,d = inner edge; drawn on both faces so the spinning blade has no back-face gap
 var lift=Vector3(0,0.025,0)
 for side in [1.0,-1.0]:
  var o=lift*side
  var tri=[[a,b,c],[a,c,d]] if side>0.0 else [[c,b,a],[d,c,a]]
  for t in tri:
   for p in t:
    tool.set_color(outer if (p==a or p==b) else inner);tool.add_vertex(p+o)

func later(seconds: float,call: Callable) -> void:
 if timers.size()>=MAX_TIMERS:counters.dropped_timers+=1;return
 timers.append({"t":seconds,"call":call})
func origin_pos() -> Vector3:return game.player.position+Vector3.UP
func flat(v: Vector3) -> Vector3:
 var f=Vector3(v.x,0,v.z)
 return f.normalized() if f.length_squared()>0.0001 else Vector3.FORWARD.rotated(Vector3.UP,game.player.yaw)
func yaw_dir(dir: Vector3,angle: float) -> Vector3:return dir.rotated(Vector3.UP,angle)
func count_cast(id: int) -> void:counters.casts[id]=int(counters.casts.get(id,0))+1
# Shared hit interface ---------------------------------------------------------------------
func strike(e: Dictionary,damage: float,id: int,source: String,dir: Vector3=Vector3.ZERO,pos: Vector3=Vector3.INF) -> void:
 if e.is_empty() or e.hp<=0:return
 counters.strike[source]=int(counters.strike.get(source,0))+1
 game.hit(e,damage,id,{"source":source,"dir":dir,"pos":pos if pos.is_finite() else e.pos})
# Called by Game.hit once the crit roll is known (position/source come from the hit context).
func on_hit(e: Dictionary,id: int,ctx: Dictionary,critical: bool) -> void:
 var source=str(ctx.get("source",""))
 if not WeaponFeel.AUDIO.has(source):return
 e["flash_tint"]=1.0 if source=="pulse" else 0.0
 WeaponFeel.impact(self,id,source,ctx.get("pos",e.pos),ctx.get("dir",Vector3.ZERO),critical,e)
func hit_reach(e: Dictionary,scale: float=0.7) -> float:return float(e.get("radius",0.5))*scale

func update(delta: float) -> void:
 psx.intensity=0.5 if game.settings.reduced else clampf(float(game.settings.visual_intensity)/0.7,0.4,1.0)
 pulse_budget=14
 var i=0
 while i<timers.size():
  timers[i].t-=delta
  if timers[i].t<=0.0:
   var call: Callable=timers[i].call;timers.remove_at(i);call.call()
  else:i+=1
 for id in game.weapons.keys():
  var state=game.weapons[id]
  if id==10:update_aura(id,state,delta);continue
  state.clock-=delta
  if state.clock>0.0:continue
  var r=WeaponStats.resolve(game,id,state)
  var fired=false
  match id:
   0:fired=fire_sword(id,r)
   1:fired=fire_firestaff(id,r)
   2:fired=fire_lightning(id,r)
   6:fired=fire_bow(id,r)
   7:fired=fire_revolver(id,r)
   9:fired=fire_scythes(id,r)
   15:fired=fire_shotgun(id,r)
  state.clock=float(r.interval)+(float(r.count-1)*float(r.get("gap",0.0)) if id==0 else 0.0) if fired else 0.12
  if fired:count_cast(id)
 step_fireballs(delta);step_arrows(delta);step_bullets(delta);step_scythes(delta)
 psx.tick(delta)

# SWORD -------------------------------------------------------------------------------------
func fire_sword(id: int,r: Dictionary) -> bool:
 if game.nearest(game.player.position,float(r.reach)+0.8).is_empty():return false
 for k in int(r.count):
  if k==0:do_slash(id,0)
  else:later(float(k)*float(r.gap),do_slash.bind(id,k))
 return true
func do_slash(id: int,index: int) -> void:
 if not game.weapons.has(id):return
 var r=WeaponStats.resolve(game,id,game.weapons[id])
 var pos=game.player.position
 var target=game.nearest(pos,float(r.reach)+0.8)
 if target.is_empty():return
 var dir=flat(target.pos-pos)
 var half=deg_to_rad(float(r.arc_deg))*0.5
 var reach=float(r.reach)
 for e in game.nearby(pos,reach+2.0):
  var to=Vector3(e.pos.x-pos.x,0,e.pos.z-pos.z);var dist=to.length()
  if dist>reach+hit_reach(e):continue
  if dist>0.5:
   var allowed=half+atan(float(e.get("radius",0.5))/maxf(dist,0.6))
   if acos(clampf(dir.dot(to/dist),-1.0,1.0))>allowed:continue
  strike(e,float(r.damage),id,"slash",dir)
 WeaponFeel.sword_arc(self,origin_pos(),dir,reach,half,index,deg_to_rad(40.0 if index%2==0 else -40.0))
 game.audio.emit("weapon.sword.swing",origin_pos(),1.0,1.0+0.045*float(index))

# FIRESTAFF ---------------------------------------------------------------------------------
func fire_firestaff(id: int,r: Dictionary) -> bool:
 var target=game.nearest(game.player.position,float(r.range))
 if target.is_empty():return false
 var origin=origin_pos();var dir=(target.pos-origin).normalized()
 var n=int(r.count);var fan=deg_to_rad(WeaponStats.FIRESTAFF.fan_deg)
 for k in n:
  if fireballs.size()>=MAX_FIREBALLS:break
  var d=yaw_dir(dir,(float(k)-float(n-1)*0.5)*fan)
  fireballs.append({"pos":origin+d*0.9,"vel":d*float(r.speed),"dir":d,"damage":float(r.damage),"id":id,"scale":float(r.scale),"hit_r":float(r.hit_radius),"left":float(r.range)+3.0,"trail":0.0,"age":0.0})
 WeaponFeel.fire_muzzle(self,origin+dir*0.9,dir)
 game.audio.emit("weapon.firestaff.cast",origin,1.0,1.0)
 return true
func step_fireballs(delta: float) -> void:
 var cam=WeaponFeel.cam_pos(self)
 var i=fireballs.size()-1
 while i>=0:
  var b=fireballs[i]
  var prev: Vector3=b.pos;var step=b.vel*delta;var next=prev+step
  b.age+=delta;b.left-=step.length()
  var done=false
  var wall=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(prev,next,1))
  var ground=game.terrain_height(next.x,next.z)+0.1
  if not wall.is_empty():next=wall.position;done=true
  elif next.y<ground:next.y=ground;done=true
  if not done:
   for e in game.nearby(next,b.hit_r+3.0):
    if game.segment_distance(e.pos,prev,next)>b.hit_r+hit_reach(e):continue
    strike(e,b.damage,b.id,"fireball",b.dir,next)
    var flat_dir=flat(b.dir)
    e.knock+=flat_dir*float(WeaponStats.FIRESTAFF.shunt)
    next=prev.lerp(next,0.5);done=true;break
  b.pos=next
  if done or b.left<=0.0:
   if not done:WeaponFeel.fire_burst(self,next,Vector3.ZERO,0.6)
   else:
    WeaponFeel.fire_burst(self,next,-b.dir,1.0)
    game.audio.emit("weapon.firestaff.impact",next,0.8,1.0)
   fireballs.remove_at(i);i-=1;continue
  # body: three nested hard squares (red outer, orange, yellow core), nudged toward the camera to avoid z ties
  var s=float(b.scale)
  WeaponFeel.draw_fireball(self,next,s,float(b.age),cam)
  b.trail-=delta
  if b.trail<=0.0:
   b.trail=0.035
   psx.spark(next,Vector3(rng.randf_range(-1,1),rng.randf_range(0.2,1.6),rng.randf_range(-1,1)),WeaponFeel.FIRE_MID,WeaponFeel.EMBER_DEAD,0.26*s,0.08,0.36,3.0,0.5)
   if rng.randf()<0.5:psx.spark(next,Vector3(rng.randf_range(-1.4,1.4),rng.randf_range(0.0,1.0),rng.randf_range(-1.4,1.4)),WeaponFeel.FIRE_OUTER,WeaponFeel.EMBER_DEAD,0.14*s,0.05,0.7,9.0,0.4)
  i-=1

# LIGHTNING STAFF ---------------------------------------------------------------------------
func fire_lightning(id: int,r: Dictionary) -> bool:
 var pos=game.player.position
 var candidates=game.nearby(pos,float(WeaponStats.LIGHTNING.search_radius))
 if candidates.is_empty():return false
 candidates.sort_custom(func(a,b):return a.pos.distance_squared_to(pos)<b.pos.distance_squared_to(pos))
 var picked=[];var spacing=float(r.strike_radius)*1.3
 for e in candidates:
  if picked.size()>=int(r.count):break
  var apart=true
  for p in picked:
   if p.pos.distance_to(e.pos)<spacing:apart=false;break
  if apart:picked.append(e)
 for e in candidates: # not enough well-separated targets: top up with the nearest distinct ones
  if picked.size()>=int(r.count):break
  if not e in picked:picked.append(e)
 var cast={"hit":{}}
 for k in picked.size():
  if k==0:do_strike(id,picked[k],cast)
  else:later(float(k)*float(WeaponStats.LIGHTNING.strike_delay),do_strike.bind(id,picked[k],cast))
 later(0.14,func():game.audio.emit("weapon.lightning.thunder",origin_pos(),1.0,1.0))
 return true
func do_strike(id: int,target: Dictionary,cast: Dictionary) -> void:
 if not game.weapons.has(id):return
 var r=WeaponStats.resolve(game,id,game.weapons[id])
 if target.is_empty() or target.hp<=0:
  target=game.nearest(game.player.position,float(WeaponStats.LIGHTNING.search_radius))
  if target.is_empty() or cast.hit.has(target.crowd_id):return
 var p=target.pos
 WeaponFeel.bolt_strike(self,p,float(r.strike_radius))
 game.audio.emit("weapon.lightning.strike",p,1.0,1.0)
 for e in game.nearby(p,float(r.strike_radius)+1.0):
  if cast.hit.has(e.crowd_id):continue
  if e.pos.distance_to(p)>float(r.strike_radius)+hit_reach(e):continue
  cast.hit[e.crowd_id]=true
  strike(e,float(r.damage),id,"strike",Vector3.DOWN,e.pos)
 if int(r.bounces)>0:chain_from(id,p,cast,int(r.bounces),float(r.damage))
func chain_from(id: int,from_pos: Vector3,cast: Dictionary,remaining: int,damage: float) -> void:
 if remaining<=0:return
 var best: Dictionary={};var best_d=INF
 for e in game.nearby(from_pos,float(WeaponStats.LIGHTNING.chain_range)):
  if cast.hit.has(e.crowd_id):continue
  var d=e.pos.distance_squared_to(from_pos)
  if d<best_d:best_d=d;best=e
 if best.is_empty():return
 cast.hit[best.crowd_id]=true # claimed now so two chains can never take the same victim
 var next_damage=damage*float(WeaponStats.LIGHTNING.falloff)
 later(float(WeaponStats.LIGHTNING.chain_delay),func():
  if not game.weapons.has(id):return
  var to=best.pos if best.hp>0 else from_pos
  WeaponFeel.chain_link(self,from_pos+Vector3.UP*0.2,to)
  if best.hp>0:strike(best,next_damage,id,"chain",to-from_pos)
  chain_from(id,to,cast,remaining-1,next_damage))

# BOW ---------------------------------------------------------------------------------------
func fire_bow(id: int,r: Dictionary) -> bool:
 var target=game.nearest(game.player.position,float(Catalog.WEAPONS[id][4]))
 if target.is_empty():return false
 var origin=origin_pos();var dir=(target.pos-origin).normalized()
 var n=int(r.count);var fan=deg_to_rad(WeaponStats.BOW.fan_deg)
 for k in n:
  if arrows.size()>=MAX_ARROWS:break
  var d=yaw_dir(dir,(float(k)-float(n-1)*0.5)*fan)
  arrows.append({"pos":origin+d*0.8,"dir":d,"speed":float(r.speed),"left":float(r.range),"damage":float(r.damage),"id":id,"scale":float(r.scale),"hit_r":float(r.hit_radius),"hits":{},"trail":0.0})
 WeaponFeel.arrow_launch(self,origin+dir*0.8,dir)
 game.audio.emit("weapon.bow.fire",origin,1.0,1.0)
 return true
func step_arrows(delta: float) -> void:
 var cam=WeaponFeel.cam_pos(self)
 var i=arrows.size()-1
 while i>=0:
  var a=arrows[i]
  var prev: Vector3=a.pos;var travel=float(a.speed)*delta;var next=prev+a.dir*travel
  a.left-=travel
  var stopped=false
  var wall=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(prev,next,1))
  if not wall.is_empty():next=wall.position;stopped=true
  elif next.y<game.terrain_height(next.x,next.z)+0.05:stopped=true
  if not stopped:
   for e in game.nearby(next,a.hit_r+3.0):
    if a.hits.has(e.crowd_id):continue
    if game.segment_distance(e.pos,prev,next)>a.hit_r+hit_reach(e):continue
    a.hits[e.crowd_id]=true # piercing: one hit per enemy per arrow, the arrow flies on
    strike(e,a.damage,a.id,"arrow",a.dir,e.pos)
  a.pos=next
  if stopped or a.left<=0.0:
   psx.burst(next,5,[WeaponFeel.ARROW_DUST,WeaponFeel.ARROW_GLOW],3.5,0.15,0.3,6.0,1.5,Vector3.UP,1.2)
   arrows.remove_at(i);i-=1;continue
  var s=float(a.scale)
  psx.draw_segment(next-a.dir*1.5*s,next,0.12*s,WeaponFeel.ARROW_SHAFT)
  psx.draw_segment(next-a.dir*1.5*s,next-a.dir*1.15*s+Vector3(0,0.2,0)*s,0.08*s,WeaponFeel.ARROW_FIN)
  psx.draw_segment(next-a.dir*1.5*s,next-a.dir*1.15*s-Vector3(0,0.2,0)*s,0.08*s,WeaponFeel.ARROW_FIN)
  var toward=(cam-next).normalized()
  psx.draw_square(next+toward*0.0,0.5*s,WeaponFeel.ARROW_GLOW)
  psx.draw_square(next+toward*0.05,0.28*s,WeaponFeel.ARROW_TIP)
  a.trail-=delta
  if a.trail<=0.0:
   a.trail=0.06;psx.spark(next-a.dir*0.5,Vector3(rng.randf_range(-0.5,0.5),rng.randf_range(0.0,0.6),rng.randf_range(-0.5,0.5)),WeaponFeel.ARROW_DUST,WeaponFeel.ARROW_SHAFT,0.12,0.04,0.28)
  i-=1

# REVOLVER ----------------------------------------------------------------------------------
func fire_revolver(id: int,r: Dictionary) -> bool:
 var target=game.nearest(game.player.position,float(Catalog.WEAPONS[id][4]))
 if target.is_empty():return false
 var origin=origin_pos();var dir=(target.pos-origin).normalized()
 var right=dir.cross(Vector3.UP).normalized();var n=int(r.count)
 for k in n: # compact pattern: parallel lanes, a second row once there are five or more
  if bullets.size()>=MAX_BULLETS:break
  var lane=(float(k%4)-float(mini(n,4)-1)*0.5)*float(WeaponStats.REVOLVER.spacing)
  var row=0.0 if k<4 else 0.3
  bullets.append({"pos":origin+dir*0.9+right*lane+Vector3.UP*row,"dir":dir,"speed":float(r.speed),"left":float(r.range),"damage":float(r.damage),"id":id,"bounces":int(r.bounces),"hits":{},"smoke":0.0,"bounced":false})
 WeaponFeel.revolver_muzzle(self,origin+dir*0.9,dir)
 game.audio.emit("weapon.revolver.fire",origin,1.0,1.0)
 return true
func step_bullets(delta: float) -> void:
 var i=bullets.size()-1
 var cam=WeaponFeel.cam_pos(self)
 while i>=0:
  var b=bullets[i]
  var prev: Vector3=b.pos;var travel=float(b.speed)*delta;var next=prev+b.dir*travel
  b.left-=travel;b.smoke+=travel
  var dead=false
  var wall=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(prev,next,1))
  if not wall.is_empty():
   next=wall.position;dead=true
   psx.burst(next,6,[WeaponFeel.SPARK_GOLD,WeaponFeel.SMOKE_LIGHT],6.0,0.13,0.25,9.0,1.2,wall.normal,1.2)
  elif next.y<game.terrain_height(next.x,next.z)+0.05:
   dead=true;psx.burst(next,5,[WeaponFeel.DUST_MID,WeaponFeel.SMOKE_LIGHT],3.0,0.16,0.3,6.0,1.5,Vector3.UP,1.0)
  if not dead:
   for e in game.nearby(next,float(WeaponStats.REVOLVER.hit_radius)+3.0):
    if b.hits.has(e.crowd_id):continue
    if game.segment_distance(e.pos,prev,next)>float(WeaponStats.REVOLVER.hit_radius)+hit_reach(e):continue
    b.hits[e.crowd_id]=true
    strike(e,b.damage,b.id,"ricochet" if b.bounced else "bullet",b.dir,e.pos)
    if int(b.bounces)>0:
     var nxt: Dictionary={};var best=INF
     for c in game.nearby(e.pos,float(WeaponStats.REVOLVER.ricochet_range)):
      if b.hits.has(c.crowd_id) or c.hp<=0:continue
      var d=c.pos.distance_squared_to(e.pos)
      if d<best:best=d;nxt=c
     if not nxt.is_empty():
      b.bounces-=1;b.bounced=true;b.dir=(nxt.pos-e.pos).normalized();next=e.pos;b.left=minf(float(b.left)+8.0,float(WeaponStats.REVOLVER.range))
      WeaponFeel.ricochet_spark(self,e.pos,b.dir)
      game.audio.emit("weapon.revolver.ricochet",e.pos,1.0,1.0)
      break
    dead=true;break
  b.pos=next
  if dead or b.left<=0.0:bullets.remove_at(i);i-=1;continue
  # silver slug with a hard white head, discrete smoke squares every 1.2 m and the odd spark
  psx.draw_segment(next-b.dir*0.7,next,0.15,WeaponFeel.BULLET_BODY)
  psx.draw_square(next+(cam-next).normalized()*0.04,0.26,WeaponFeel.BULLET_HEAD)
  if b.smoke>=0.9:
   b.smoke-=0.9
   psx.spark(next-b.dir*0.4,Vector3(0,0.4,0),WeaponFeel.SMOKE_LIGHT,WeaponFeel.SMOKE_DARK,0.17,0.07,0.55,-0.4,0.8)
   if rng.randf()<0.28:psx.spark(next,Vector3(rng.randf_range(-2,2),rng.randf_range(0.5,2.5),rng.randf_range(-2,2)),WeaponFeel.SPARK_GOLD,WeaponFeel.SMOKE_DARK,0.12,0.05,0.22,9.0,0.5)
  i-=1

# AURA --------------------------------------------------------------------------------------
func update_aura(id: int,state: Dictionary,delta: float) -> void:
 var r=WeaponStats.resolve(game,id,state)
 var radius=float(r.radius)
 var pos=game.player.position
 var gy=game.terrain_height(pos.x,pos.z)+0.1
 var center=Vector3(pos.x,gy,pos.z)
 aura_spin+=delta*0.5 # slow, independent of Attack Speed (that only changes the pulse rate)
 aura_glow=maxf(0.0,aura_glow-delta)
 draw_aura_circle(center,radius,aura_spin,aura_glow>0.0)
 aura_smoke-=delta
 if aura_smoke<=0.0:
  aura_smoke=0.06
  for k in 2:
   var a=rng.randf()*TAU;var d=radius*sqrt(rng.randf())*0.95
   var p=center+Vector3(cos(a)*d,0.1,sin(a)*d)
   psx.spark(p,Vector3(rng.randf_range(-0.2,0.2),rng.randf_range(0.8,1.5),rng.randf_range(-0.2,0.2)),WeaponFeel.AURA_MID,WeaponFeel.AURA_SMOKE,0.3,0.1,1.1)
 aura_hum-=delta
 if aura_hum<=0.0:aura_hum=2.6;game.audio.emit("weapon.aura.hum",origin_pos(),1.0,1.0)
 state.clock-=delta
 if state.clock>0.0:return
 state.clock=float(r.interval);count_cast(id)
 aura_glow=0.16
 var hit_any=false
 for e in game.nearby(center,radius+1.5):
  if Vector2(e.pos.x-center.x,e.pos.z-center.z).length()>radius+hit_reach(e):continue
  hit_any=true;strike(e,float(r.damage),id,"pulse",Vector3.ZERO,e.pos)
 psx.ring(center,radius*0.96,int(radius*7.0),WeaponFeel.AURA_LIGHT,0.2,0.3,3.5)
 game.audio.emit("weapon.aura.pulse",origin_pos(),1.0 if hit_any else 0.6,1.0)
func draw_aura_circle(center: Vector3,radius: float,spin: float,flash: bool) -> void:
 var dark=WeaponFeel.AURA_FLASH if flash else WeaponFeel.AURA_MID
 var mid=WeaponFeel.AURA_LIGHT if flash else WeaponFeel.AURA_DARK
 var rings=[[1.0,28,0.16,dark],[0.84,24,0.1,mid],[0.52,16,0.1,mid],[0.2,8,0.08,dark]]
 for ring in rings:
  var sides=int(ring[1]);var rr=radius*float(ring[0])
  var prev=Vector3.ZERO
  for k in range(sides+1):
   var a=spin*(1.0 if float(ring[0])>0.6 else -1.4)+TAU*float(k)/sides
   var p=center+Vector3(cos(a)*rr,0,sin(a)*rr)
   if float(ring[0])>0.9:p.y=game.terrain_height(p.x,p.z)+0.1
   if k>0:psx.draw_segment(prev,p,float(ring[2]),ring[3])
   prev=p
 # runes between the two outer rings: small angular glyphs
 var runes=12
 for k in runes:
  var a=spin+TAU*float(k)/runes
  var radial=Vector3(cos(a),0,sin(a));var tangent=Vector3(-radial.z,0,radial.x)
  var base=center+radial*radius*0.92+Vector3.UP*0.02
  match k%3:
   0:
    psx.draw_segment(base-tangent*0.22,base+tangent*0.22,0.07,mid)
    psx.draw_segment(base-radial*0.18,base+radial*0.18,0.07,mid)
   1:
    psx.draw_segment(base-tangent*0.2,base+radial*0.24,0.07,mid)
    psx.draw_segment(base+tangent*0.2,base+radial*0.24,0.07,mid)
   2:
    psx.draw_segment(base-radial*0.2,base+radial*0.2,0.07,mid)
    psx.draw_segment(base-radial*0.2+tangent*0.15,base+radial*0.2-tangent*0.15,0.07,mid)
 # five-point star (occult) inside the inner ring
 for k in 5:
  var a0=-spin*1.4+TAU*float(k)/5.0;var a1=-spin*1.4+TAU*float((k+2)%5)/5.0
  var p0=center+Vector3(cos(a0),0,sin(a0))*radius*0.5;var p1=center+Vector3(cos(a1),0,sin(a1))*radius*0.5
  psx.draw_segment(p0,p1,0.07,mid)

# SCYTHES -----------------------------------------------------------------------------------
func fire_scythes(id: int,r: Dictionary) -> bool:
 var target=game.nearest(game.player.position,float(Catalog.WEAPONS[id][4]))
 if target.is_empty():return false
 var origin=origin_pos();var base=flat(target.pos-game.player.position)
 var n=int(r.count);var step=deg_to_rad(minf(40.0,360.0/float(maxi(n,1))))
 for k in n:
  if scythes.size()>=MAX_SCYTHES:break
  var d=yaw_dir(base,(float(k)-float(n-1)*0.5)*step)
  scythes.append({"pos":origin+d*0.8,"dir":d,"phase":0,"travel":0.0,"t":0.0,"life":0.0,"speed":float(r.speed),"return_speed":float(r.return_speed),"out_range":float(r.out_range),"damage":float(r.damage),"id":id,"scale":float(r.scale),"hit_r":float(r.hit_radius),"out_hits":{},"back_hits":{},"spin":rng.randf()*TAU,"curve":deg_to_rad(55.0)*(1.0 if k%2==0 else -1.0),"trail":0.0})
 game.audio.emit("weapon.scythes.throw",origin,1.0,1.0)
 return true
func step_scythes(delta: float) -> void:
 var mm=scythe_view.multimesh
 var shown=0
 var i=scythes.size()-1
 var target_pos=game.player.position+Vector3.UP
 while i>=0:
  var s=scythes[i]
  s.t+=delta;s.life+=delta;s.spin+=delta*17.0
  var prev: Vector3=s.pos
  if s.phase==0:
   var v=maxf(float(s.speed)*0.22,float(s.speed)*(1.0-float(s.travel)/float(s.out_range)))
   s.dir=yaw_dir(s.dir,s.curve*delta);s.pos=prev+s.dir*v*delta;s.travel+=v*delta
   if s.travel>=s.out_range or s.t>1.6:s.phase=1;s.t=0.0
  else:
   var to=target_pos-prev;var dist=to.length()
   var v=minf(float(s.return_speed)*1.3,7.0+float(s.t)*float(s.return_speed)*1.8)
   if dist<=v*delta+float(WeaponStats.SCYTHES.catch) or s.life>float(WeaponStats.SCYTHES.max_life):
    WeaponFeel.scythe_dust(self,prev,4);game.audio.emit("weapon.scythes.catch",prev,0.8,1.0);scythes.remove_at(i);i-=1;continue
   s.pos=prev+to/dist*v*delta
  var ground=game.terrain_height(s.pos.x,s.pos.z)+1.0
  s.pos.y=lerpf(s.pos.y,maxf(ground,target_pos.y if s.phase==1 else ground),minf(1.0,delta*8.0))
  var hits: Dictionary=s.out_hits if s.phase==0 else s.back_hits
  for e in game.nearby(s.pos,float(s.hit_r)+3.0):
   if hits.has(e.crowd_id):continue
   if game.segment_distance(e.pos,prev,s.pos)>float(s.hit_r)+hit_reach(e):continue
   hits[e.crowd_id]=true
   strike(e,s.damage,s.id,"scythe_out" if s.phase==0 else "scythe_back",s.dir,e.pos)
  s.trail-=delta
  if s.trail<=0.0:
   s.trail=0.045
   psx.spark(s.pos-s.dir*0.4,Vector3(rng.randf_range(-0.6,0.6),rng.randf_range(0.1,0.8),rng.randf_range(-0.6,0.6)),WeaponFeel.DUST_MID,WeaponFeel.DUST_DARK,0.2*float(s.scale),0.07,0.45,1.0,1.0)
   psx.segment(prev,s.pos,0.12*float(s.scale),WeaponFeel.DUST_LIGHT,WeaponFeel.DUST_MID,0.14,0.0,0.4) # angular stepped swish
  if shown<MAX_SCYTHES:
   var basis=Basis(Vector3.UP,s.spin).scaled(Vector3.ONE*float(s.scale)*1.7)*Basis(Vector3.RIGHT,0.2)
   mm.set_instance_transform(shown,Transform3D(basis,s.pos));mm.set_instance_color(shown,Color.WHITE);shown+=1
  i-=1
 mm.visible_instance_count=shown

# SHOTGUN -----------------------------------------------------------------------------------
func fire_shotgun(id: int,r: Dictionary) -> bool:
 var range_=float(r.range)
 var target=game.nearest(game.player.position,range_)
 if target.is_empty():return false
 var origin=origin_pos();var dir=(target.pos-origin).normalized()
 var right=dir.cross(Vector3.UP).normalized();var up=right.cross(dir).normalized()
 var half=deg_to_rad(float(r.cone_deg));var n=int(r.count)
 var candidates=game.nearby(game.player.position,range_+2.0)
 var space=game.get_world_3d().direct_space_state
 var hits_made=0
 for k in n:
  # one blast, n pellets: an even spiral through the cone so every added pellet is visible
  var spread=half*sqrt((float(k)+0.5)/float(n))*rng.randf_range(0.88,1.04)
  var az=float(k)*2.39996+rng.randf()*0.5
  var d=(dir*cos(spread)+(right*cos(az)+up*sin(az))*sin(spread)).normalized()
  var reach=range_
  var wall=space.intersect_ray(PhysicsRayQueryParameters3D.create(origin,origin+d*range_,1))
  if not wall.is_empty():reach=origin.distance_to(wall.position)
  var best_t=reach;var victim: Dictionary={}
  for e in candidates:
   if e.hp<=0:continue
   var v=e.pos-origin;var t=v.dot(d)
   if t<0.3 or t>=best_t:continue
   if (v-d*t).length()<=float(WeaponStats.SHOTGUN.hit_radius)+hit_reach(e):best_t=t;victim=e
  WeaponFeel.shotgun_tracer(self,origin,d,best_t,k)
  if not victim.is_empty():
   hits_made+=1;strike(victim,float(r.damage),id,"pellet",d,origin+d*best_t)
 WeaponFeel.shotgun_blast(self,origin+dir*0.7,dir,half,n)
 game.audio.emit("weapon.shotgun.fire",origin,1.0,1.0)
 return true

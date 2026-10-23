class_name EnemyView
extends Node3D
# Three instanced parts per active variant; no per-enemy scene/physics/skeleton.
var batches: Dictionary={}
var counts: Dictionary={}
var models: Dictionary={}
var distant_models: Dictionary={}
var material=ModelBuilder.material()
func batch(key: String, mesh: Mesh, capacity: int) -> MultiMesh:
 if batches.has(key): return batches[key].multimesh
 var node=MultiMeshInstance3D.new()
 node.multimesh=MultiMesh.new()
 node.multimesh.transform_format=MultiMesh.TRANSFORM_3D
 node.multimesh.use_colors=true
 node.multimesh.mesh=mesh
 node.multimesh.instance_count=capacity
 node.multimesh.visible_instance_count=0
 node.material_override=material
 add_child(node)
 batches[key]=node
 return node.multimesh
func begin_frame() -> void:
 counts.clear()
func put(key: String, mesh: Mesh, transform: Transform3D, color: Color, capacity: int = 500) -> void:
 var mm=batch(key,mesh,capacity)
 var index=int(counts.get(key,0))
 if index>=capacity: return
 mm.set_instance_transform(index,transform)
 mm.set_instance_color(index,color)
 counts[key]=index+1
func draw_enemy(e: Dictionary, viewer: Vector3) -> void:
 var key=e.variant.id
 if not models.has(key): models[key]=load(e.variant.model)
 var body: Mesh=models[key]
 var limb: Mesh=preload("res://assets/generated/limb.res")
 var direction=viewer-e.pos
 var facing=atan2(direction.x,direction.z)
 var phase=e.age*e.speed*2.8
 var walking=e.state=="move" and e.speed>0
 var far=e.pos.distance_squared_to(viewer)>324
 if far: phase=floorf(phase*3)/3
 var bob=absf(sin(phase))*0.06 if walking else sin(e.age*3)*0.02
 var tilt=-0.25 if e.state=="windup" else (0.4 if e.state=="charging" else 0.0)
 if e.hit_time>0: tilt=-0.25
 var swell=1+0.18*sin(e.age*24) if e.state=="windup" and e.action=="explode" else 1.0
 var color=Color.WHITE
 if e.hit_time>0: color=Color(2.5,2.2,2.0)
 elif e.frozen>0: color=Color("91dfff")
 elif e.poison>0: color=Color("bcff83")
 elif e.burn>0: color=Color("ffc086")
 elif e.state=="windup": color=Color("ffd59f")
 var base=Transform3D(Basis.from_euler(Vector3(tilt,facing,0)).scaled(Vector3.ONE*e.scale*swell),e.pos-Vector3.UP*0.65+Vector3.UP*bob)
 if far and not key in ["wolf","spider","scarab","beetle","bat","wisp","cactus","mushroom"]:
  if not distant_models.has(key):
   distant_models[key]=ModelBuilder.bake([{"mesh":body,"transform":Transform3D.IDENTITY,"color":Color.WHITE},{"mesh":limb,"transform":Transform3D(Basis.IDENTITY,Vector3(-0.24,0.6,0)),"color":Color.WHITE},{"mesh":limb,"transform":Transform3D(Basis.IDENTITY,Vector3(0.24,0.6,0)),"color":Color.WHITE}])
  put(key+"_distant",distant_models[key],base,color)
  return
 put(key,body,base,color)
 # Multi-legged bodies already include their legs; animate them by body sway.
 if key in ["wolf","spider","scarab","beetle","bat","wisp","cactus","mushroom"]: return
 for side in [-1,1]:
  var pivot=Transform3D(Basis(Vector3.RIGHT,sin(phase)*side*0.65 if walking else 0),Vector3(side*0.24,0.6,0))
  put(key+"_legs",limb,base*pivot,color,1000)
func end_frame() -> void:
 for key in batches: batches[key].multimesh.visible_instance_count=int(counts.get(key,0))

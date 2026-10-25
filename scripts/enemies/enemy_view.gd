class_name EnemyView
extends Node3D
# Shared textured animation-frame batches; no per-enemy scene/physics/skeleton.
var batches: Dictionary={}
var counts: Dictionary={}
var models: Dictionary={}
var distant_models: Dictionary={}
var material: ShaderMaterial
func _init() -> void:
 material=ShaderMaterial.new();material.shader=preload("res://shaders/enemy_feedback.gdshader")
func batch(key: String, mesh: Mesh, capacity: int) -> MultiMesh:
 if batches.has(key): return batches[key].multimesh
 var node=MultiMeshInstance3D.new()
 node.multimesh=MultiMesh.new()
 node.multimesh.transform_format=MultiMesh.TRANSFORM_3D
 node.multimesh.use_colors=true
 node.multimesh.use_custom_data=true
 node.multimesh.mesh=mesh
 node.multimesh.instance_count=capacity
 node.multimesh.visible_instance_count=0
 # Each baked surface keeps its supplied texture material and feedback shader.
 # No full-mesh override, which would erase the imported atlas.
 add_child(node)
 batches[key]=node
 return node.multimesh
func begin_frame() -> void:
 counts.clear()
func put(key: String, mesh: Mesh, transform: Transform3D, color: Color, capacity: int = 500, spectral: bool=false) -> void:
 var mm=batch(key,mesh,capacity)
 var index=int(counts.get(key,0))
 if index>=capacity: return
 mm.set_instance_transform(index,transform)
 mm.set_instance_color(index,color)
 mm.set_instance_custom_data(index,Color(1 if color==Color("ff0804") else 0,1 if spectral else 0,0,0))
 counts[key]=index+1
func draw_enemy(e: Dictionary, viewer: Vector3) -> void:
 var model=str(e.variant.get("visual_model","Puglin" if e.kind in [8,9] and e.get("encounter","")!="sovereign" else "Imp"))
 var walking=e.state in ["move","charging"] and e.speed>0 and not "flying" in e.variant.get("modules",[])
 var cycle=e.age*clampf(e.speed/2.5,0.4,3)
 var state="enemy_move" if walking else "enemy_idle"
 var frame=int(cycle*8)%8 if walking else int(e.age*2)%2
 if e.pos.distance_squared_to(viewer)>900:frame=(frame/4)*4 if walking else 0
 var mesh=BestiaryFrames.mesh(model,state,frame)
 var key=model+state+str(frame)
 models[e.variant.id]=mesh
 var direction=e.get("move_direction",viewer-e.pos) if walking else viewer-e.pos
 var facing=atan2(direction.x,direction.z)
 var tilt=-0.2 if e.state=="windup" else (0.35 if e.state=="charging" else 0.0)
 if e.hit_time>0:tilt=-0.15
 var scale_value=e.scale*float(e.variant.get("visual_scale",1))
 var color: Color=e.variant.get("visual_tint",Color.WHITE)
 if e.hit_time>0:color=Color("ff0804")
 elif e.frozen>0:color=Color("91dfff")
 elif e.poison>0:color=Color("bcff83")
 elif e.burn>0:color=Color("ffc086")
 if e.state=="windup" and e.action=="explode":scale_value*=1+0.12*sin(e.age*24)
 var base=Transform3D(Basis.from_euler(Vector3(tilt,facing,0)).scaled(Vector3.ONE*scale_value),e.pos-Vector3.UP*0.65)
 put(key,mesh,base,color,500,e.get("encounter","")=="ghost")
func end_frame() -> void:
 for key in batches: batches[key].multimesh.visible_instance_count=int(counts.get(key,0))

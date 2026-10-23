extends SceneTree
func _initialize() -> void:
 var folder="res://assets/generated/"
 DirAccess.make_dir_recursive_absolute(folder)
 var variants=["goblin","skeleton","wolf","spider","ogre","golem","archer","cactus","knight","brute","bat","wisp","scarab","mushroom","bulwark","beetle"]
 for id in variants:
  ResourceSaver.save(ModelBuilder.bake(ModelBuilder.enemy_parts(id)),folder+id+".res")
 ResourceSaver.save(ModelBuilder.bake([ModelBuilder.part(ModelBuilder.cube(Vector3(0.2,0.55,0.25)),Vector3(0,-0.22,0),"495660"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.25,0.16,0.4)),Vector3(0,-0.48,0.08),"2e3b4c")]),folder+"limb.res")
 var actor=Node3D.new()
 actor.name="FoxScout"
 actor.set_script(load("res://scripts/art/scout_visual.gd"))
 var hips=Node3D.new(); hips.name="Hips"; hips.position.y=0.92; actor.add_child(hips)
 var torso=Node3D.new(); torso.name="Torso"; hips.add_child(torso)
 ModelBuilder.node(torso,"Coat",[ModelBuilder.part(ModelBuilder.cone(0.38,0.65,0.29),Vector3.ZERO,"378e88"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.65,0.12,0.42)),Vector3(0,-0.2,0),"59483e"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.2,0.18,0.45)),Vector3(0,0.2,0.04),"e4c576")])
 var face=[ModelBuilder.part(ModelBuilder.cube(Vector3(0.48,0.42,0.4)),Vector3(0,0.54,0),"d9934f"),ModelBuilder.part(ModelBuilder.cone(0.25,0.4,0.1),Vector3(0,0.46,0.28),"f5dfb4",Vector3(PI/2,0,0)),ModelBuilder.part(ModelBuilder.cube(Vector3(0.12,0.1,0.12)),Vector3(0,0.45,0.5),"253144")]
 for side in [-1,1]:
  face.append(ModelBuilder.part(ModelBuilder.cone(0.16,0.4),Vector3(side*0.18,0.88,0),"d9934f"))
  face.append(ModelBuilder.part(ModelBuilder.cube(Vector3(0.08,0.08,0.04)),Vector3(side*0.14,0.58,0.22),"202e40"))
 ModelBuilder.node(torso,"Head",face)
 ModelBuilder.node(torso,"Scarf",[ModelBuilder.part(ModelBuilder.cube(Vector3(0.58,0.12,0.5)),Vector3(0,0.3,0),"e4c576"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.24,0.5,0.08)),Vector3(0.14,0.05,-0.3),"e4c576",Vector3(-0.25,0,0))])
 ModelBuilder.node(hips,"Tail",[ModelBuilder.part(ModelBuilder.cone(0.21,0.85,0.08),Vector3(0,-0.08,-0.5),"ce8648",Vector3(-0.9,0,0)),ModelBuilder.part(ModelBuilder.cone(0.13,0.32,0),Vector3(0,0.15,-0.85),"f8e6c2",Vector3(-0.9,0,0))])
 for side in [-1,1]:
  var leg=Node3D.new(); leg.name="LegL" if side<0 else "LegR"; leg.position=Vector3(side*0.19,-0.3,0); hips.add_child(leg)
  ModelBuilder.node(leg,"Boot",[ModelBuilder.part(ModelBuilder.cube(Vector3(0.22,0.42,0.23)),Vector3(0,-0.15,0),"415766"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.25,0.22,0.39)),Vector3(0,-0.42,0.07),"293b4d")])
  var arm=Node3D.new(); arm.name="ArmL" if side<0 else "ArmR"; arm.position=Vector3(side*0.4,0.2,0); torso.add_child(arm)
  ModelBuilder.node(arm,"Sleeve",[ModelBuilder.part(ModelBuilder.cube(Vector3(0.21,0.45,0.24)),Vector3(0,-0.2,0),"378e88"),ModelBuilder.part(ModelBuilder.cube(Vector3(0.19,0.2,0.2)),Vector3(0,-0.5,0),"e5a45d")])
 set_owners(actor,actor)
 var scene=PackedScene.new(); scene.pack(actor)
 ResourceSaver.save(scene,folder+"fox_scout.tscn")
 actor.free()
 print("Generated original Fox Scout scene and 16 distinct enemy meshes")
 quit()
func set_owners(node: Node, owner_node: Node) -> void:
 for child in node.get_children(): child.owner=owner_node; set_owners(child,owner_node)

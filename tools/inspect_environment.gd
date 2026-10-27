extends SceneTree
func _initialize():call_deferred("run")
func run():
 for name in ["Tree_1","Rock_1","Bush_1","Grass_1"]:
  var n=load("res://assets/vendor/environment/"+name+".fbx").instantiate();root.add_child(n);await process_frame
  for mesh in n.find_children("*","MeshInstance3D",true,false):print(name," ",mesh.global_transform*mesh.get_aabb()," ",mesh.mesh.surface_get_material(0))
  n.queue_free()
 quit()

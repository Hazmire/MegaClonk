extends SceneTree
func _initialize():call_deferred("run")
func run():
 var n=load("res://assets/vendor/jacob/Jacob.fbx").instantiate();root.add_child(n)
 await process_frame
 n.print_tree_pretty()
 for child in n.find_children("*","",true,false):
  if child is MeshInstance3D:print(child.name," bounds=",child.global_transform*child.get_aabb()," skin=",child.skin!=null)
  if child is Skeleton3D:print("SKELETON ",child.global_transform)
  if child is AnimationPlayer:print("ANIMATIONS ",child.get_animation_list())
 n.queue_free();await process_frame;quit()

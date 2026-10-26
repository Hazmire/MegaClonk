extends SceneTree
func _initialize():call_deferred("run")
func run():
 var model=load("res://assets/quaternius/ranger/Male_Ranger.gltf").instantiate();root.add_child(model);await process_frame
 var library=SimpleRangerClips.build_library(model.get_node("Armature/Skeleton3D"))
 print("Baked player core library: ",ResourceSaver.save(library,"res://assets/config/player_core.res",ResourceSaver.FLAG_COMPRESS))
 model.queue_free();SimpleRangerClips.cache=null;await process_frame;quit()

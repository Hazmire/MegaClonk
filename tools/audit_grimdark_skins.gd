extends SceneTree
func _initialize():call_deferred("run")
func run():
 for file in DirAccess.get_files_at("res://assets/grimdark/characters"):
  if not file.ends_with(".fbx"):continue
  var scene=load("res://assets/grimdark/characters/"+file).instantiate();root.add_child(scene);await process_frame
  var skins=0;var bones=0
  for node in scene.find_children("*","MeshInstance3D",true,false):
   if node.skin:skins+=1
  for node in scene.find_children("*","Skeleton3D",true,false):bones+=node.get_bone_count()
  print(file," skins=",skins," bones=",bones)
  scene.queue_free();await process_frame
 quit()

extends SceneTree
func _initialize():call_deferred("run")
func run():
 var paths=["res://assets/grimdark/knight/knight.glb","res://assets/grimdark/characters/Character_Monster.fbx","res://assets/grimdark/characters/Character_Monster_04.fbx","res://assets/grimdark/wrapper/MonsterPSX.fbx","res://assets/grimdark/horror/PS1_ForestAsset/PS1_NaturAssetCollection.fbx","res://assets/grimdark/horror/PS1_Palast_Assets/PS1_PalastAssetCollection.fbx","res://assets/grimdark/medieval/market_stall_round_red.glb","res://assets/grimdark/trees/dead_tree_rt_1.glb"]
 for path in paths:
  var scene=load(path).instantiate();root.add_child(scene);await process_frame;print("ASSET ",path)
  for node in scene.find_children("*","MeshInstance3D",true,false):
   if node.mesh==null:continue
   print("MESH ",node.name," bbox=",node.mesh.get_aabb()," transform=",node.global_transform," skin=",node.skin!=null)
   for surface in node.mesh.get_surface_count():
    var mat=node.mesh.surface_get_material(surface)
    if mat is BaseMaterial3D:print("MATERIAL ",surface," ",mat.resource_name," diffuse=",mat.albedo_texture," emission=",mat.emission_texture)
  for node in scene.find_children("*","Skeleton3D",true,false):
   var bones=[]
   for i in node.get_bone_count():bones.append({"name":node.get_bone_name(i),"pos":node.get_bone_global_rest(i).origin})
   print("BONES ",bones)
  for node in scene.find_children("*","AnimationPlayer",true,false):print("ANIMATIONS ",node.get_animation_list())
  scene.queue_free();await process_frame
 quit()

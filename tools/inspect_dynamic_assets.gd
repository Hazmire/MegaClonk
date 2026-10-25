extends SceneTree
func _initialize():call_deferred("run")
func run():
 for path in ["res://assets/quaternius/ranger/Male_Ranger.gltf","res://assets/kaykit/skeletons/Skeleton_Minion.glb","res://assets/kaykit/skeletons/Rig_Medium_MovementBasic.glb"]:
  var scene=load(path).instantiate();root.add_child(scene)
  print("ASSET ",path)
  for rig in scene.find_children("*","Skeleton3D",true,false):
   print("RIG ",rig.get_path()," transform ",rig.global_transform)
   for i in rig.get_bone_count():
    var name=rig.get_bone_name(i)
    if path.contains("kaykit") or name in ["pelvis","thigh_l","calf_l","foot_l","upperarm_l","lowerarm_l","hand_l"]:print(name," parent ",rig.get_bone_parent(i)," global ",rig.get_bone_global_rest(i))
  for player in scene.find_children("*","AnimationPlayer",true,false):print("ANIMS ",player.get_animation_list())
  scene.free()
 quit()

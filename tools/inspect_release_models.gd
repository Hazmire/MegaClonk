extends SceneTree
func _initialize():call_deferred("run")
func run():
 for path in ["res://assets/quaternius/ranger/Male_Ranger.gltf","res://assets/quaternius/animations/UAL2_Standard.glb","res://assets/quaternius/bestiary/Imp.glb","res://assets/quaternius/bestiary/Puglin.glb"]:
  var n=load(path).instantiate();root.add_child(n);await process_frame
  print("MODEL ",path);n.print_tree_pretty()
  var rig=n.find_child("Skeleton3D",true,false)
  if not rig:
   var rigs=n.find_children("*","Skeleton3D",true,false);rig=rigs[0] if rigs.size()>0 else null
  if rig:
   print("RIG ",rig.get_path()," bones=",rig.get_bone_count()," transform=",rig.global_transform)
   for bone in ["root","pelvis","Head","thigh_l","upperarm_l"]:
    var idx=rig.find_bone(bone)
    if idx>=0:print(bone," ",idx," rest=",rig.get_bone_rest(idx))
  for m in n.find_children("*","MeshInstance3D",true,false):print("MESH ",m.name," ",m.get_aabb()," surfaces=",m.mesh.get_surface_count()," vertices=",m.mesh.surface_get_array_len(0)," skin=",m.skin)
  for ap in n.find_children("*","AnimationPlayer",true,false):
   print("ANIMS ",ap.get_animation_list())
   var anim=ap.get_animation(ap.get_animation_list()[0]);print("TRACK0 ",anim.track_get_path(0)," ",anim.track_get_type(0)," ",anim.track_get_key_value(0,0))
  n.queue_free();await process_frame
 quit()

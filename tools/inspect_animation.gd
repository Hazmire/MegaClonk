extends SceneTree
func _initialize():call_deferred("run")
func run():
 var n=load("res://assets/quaternius/animations/UAL2_Standard.glb").instantiate();root.add_child(n);await process_frame
 var rig=n.get_node("Armature/Skeleton3D");var ap=n.get_node("AnimationPlayer")
 var a=ap.get_animation("A_TPose")
 for i in mini(8,a.get_track_count()):print(a.track_get_type(i)," ",a.track_get_path(i)," ",a.track_get_key_value(i,0))
 print("pelvis pose ",rig.get_bone_pose(1)," rest ",rig.get_bone_rest(1))
 ap.play("A_TPose");ap.advance(0);print("after ",rig.get_bone_pose(1))
 n.free();quit()

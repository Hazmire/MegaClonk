extends SceneTree
func _initialize():call_deferred("run")
func run():
 var actor=RangerVisual.new();root.add_child(actor);await process_frame
 for state in ["idle","run","jump","fall","crouch","slide"]:
  for i in 30:actor.animate(state,4,0.0167)
  actor.rig.force_update_all_bone_transforms()
  print(state," head=",actor.rig.get_bone_global_pose(actor.rig.find_bone("Head")).origin," foot=",actor.rig.get_bone_global_pose(actor.rig.find_bone("foot_l")).origin)
 actor.queue_free();await process_frame;RigClips.reset();quit()

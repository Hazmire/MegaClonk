extends SceneTree
func _initialize():call_deferred("run")
func run():
 var actor=KnightVisual.new();root.add_child(actor)
 assert(actor.rig!=null and actor.playback!=null)
 assert(actor.playback.has_animation("k_idle") and actor.playback.has_animation("k_walk"))
 for state in ["idle","run","jump","fall","crouch","slide","glide","death"]:
  actor.animate(state,6.0,0.16)
  assert(actor.animation_state==state)
  assert(actor.model.transform.is_finite())
 actor.set_damage_flash(true);assert(actor.flashing)
 actor.set_damage_flash(false);assert(not actor.flashing)
 assert(actor.surfaces.size()>0)
 print("GRIMDARK_KNIGHT_CHECK_OK: native clips, supplemental states, rig, materials and damage flash")
 actor.queue_free();await process_frame;quit()

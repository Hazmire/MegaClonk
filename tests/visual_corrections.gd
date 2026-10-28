extends SceneTree
var failures=[]
var checks=0
func verify(value: bool,message: String):
 checks+=1
 if not value:failures.append(message);push_error(message)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 var actor=game.player.avatar
 # Thousands of updates must not accumulate offsets on constant/absent clip tracks.
 for state in ["slide","crouch"]:
  for transition in 20:actor.animate(state,7,.016)
  actor.rig.force_update_all_bone_transforms()
  var frozen=[]
  for bone in actor.rig.get_bone_count():frozen.append(actor.rig.get_bone_global_pose(bone))
  for frame in 500:actor.animate(state,7,0)
  actor.rig.force_update_all_bone_transforms()
  for bone in actor.rig.get_bone_count():verify(actor.rig.get_bone_global_pose(bone).is_equal_approx(frozen[bone]),"Frozen animation does not accumulate procedural pose: "+state)
  for frame in 2000:actor.animate(state,7,.016)
  var root_bone=actor.rig.find_bone("Body")
  verify(absf(actor.rig.get_bone_pose_position(root_bone).y)<1.1,"Long-held "+state+" keeps visual root bounded")
  for bone in actor.rig.get_bone_count():verify(actor.rig.get_bone_global_pose(bone).is_finite(),"Finite pose after long "+state)
  actor.animate("idle",0,.2)
  verify(absf(actor.rig.get_bone_pose_position(root_bone).y)<.2,"Releasing "+state+" restores standing root")
  for tick in 30:actor.animate("idle",0,.016)
  var first=actor.rig.get_bone_pose_rotation(actor.rig.find_bone("LowerLeg.l"))
  actor.animate("idle",0,.016)
  verify(first.angle_to(actor.rig.get_bone_pose_rotation(actor.rig.find_bone("LowerLeg.l")))<.1,"Leg pose does not retain slide/crouch offset")
 for model in ["Goblin","Skeleton","Imp","BlightHusk","Behemoth","Knight","Puglin","Champion"]:
  var first=BestiaryFrames.mesh(model,"enemy_move",0);var opposite=BestiaryFrames.mesh(model,"enemy_move",4)
  verify(first.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]!=opposite.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],"Actual walking deformation for "+model)
 verify(BestiaryFrames.SOURCES.Goblin=="Autopsy" and BestiaryFrames.SOURCES.Skeleton=="Autopsy","Basic enemies use supplied Autopsy Zombie")
 verify(BestiaryFrames.SOURCES.BlightHusk=="Crab" and BestiaryFrames.mesh("BlightHusk","enemy_idle",0).get_aabb().size.y<.8,"Small exploding enemy uses crab silhouette")
 var source=StandardMaterial3D.new();source.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
 verify(GrimdarkMaterials.material(source).shader==preload("res://shaders/grimdark_opaque.gdshader"),"Solid objects ignore source texture alpha")
 verify(GrimdarkMaterials.material(source,1,true).shader==preload("res://shaders/grimdark_surface.gdshader"),"Only foliage uses intentional cutout shader")
 var terrain_shader=preload("res://shaders/grimdark_terrain.gdshader")
 verify(terrain_shader.code.contains("#define ALPHA_DISABLED") and terrain_shader.code.contains("cull_disabled"),"Terrain is opaque and renders its back faces")
 var shrine={}
 for object in game.interactables:
  if ShrineCharging.is_shrine(object):shrine=object;break
 var label=shrine.node.get_node("ChargeProgress")
 game.mode="run";ShrineCharging.tick(game,shrine,0,.1);verify(label.visible,"Charging progress appears inside active shrine")
 ShrineCharging.tick(game,shrine,10,.1);verify(not label.visible,"Progress disappears after leaving AOE")
 ShrineCharging.tick(game,shrine,0,.1);game.mode="pause";game.frontend._process(.01);verify(not label.visible,"Paused shrine progress is hidden")
 game.mode="run";shrine.used=true;ShrineCharging.visual(game,shrine,true);verify(not label.visible,"Completed shrine has no floating progress label")
 game.queue_free();await process_frame;await process_frame
 print("VISUAL CORRECTIONS: ",checks," checks, ",failures.size()," failures")
 quit(0 if failures.is_empty() else 1)

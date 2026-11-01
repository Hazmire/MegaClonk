extends SceneTree
var game: Node
var checks=0
var failures=[]
func check(value: bool,label: String) -> void:
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func ticks(count: int):
 for i in count:await physics_frame
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.map_seed_override=9;game.next_run_seed=123;game.settings.focus_pause=false
 game.progress.storage_path="user://investigator-test-profile.json"
 game.begin_run();game.mode="pause";game.player.active=false;game.weapons.clear();game.enemies.clear();game.spawn_clock=999
 var p=game.player;var actor=p.avatar
 check(actor is InvestigatorVisual,"Playable character is the Investigator")
 check(actor.rig.get_bone_count()==28,"Imported 28-bone Investigator skeleton is active")
 var mesh=actor.model.find_children("*","MeshInstance3D",true,false)[0]
 check(mesh.skin!=null and mesh.mesh.get_surface_count()==8,"Duster, hat and original material surfaces remain skinned")
 for clip in ["Idle","Walk","Run","Jump","Crouch","CrouchEnter","CrouchExit","Slide","CriticalWalk","Interact"]:
  check(actor.playback.has_animation(clip),"Gameplay imports clip "+clip)
 for clip in InvestigatorVisual.LOOPS:check(actor.playback.get_animation(clip).loop_mode==Animation.LOOP_LINEAR,"Loop configured for "+clip)
 check(actor.playback.get_animation("Jump").loop_mode==Animation.LOOP_NONE,"Jump is not an airborne loop that replays takeoff")
 check(is_equal_approx(p.collider.shape.height,1.8) and is_equal_approx(p.crouched_height,.95),"Original collision capsule heights are preserved")
 var position=p.position
 actor.animate("idle",0,.2);check(actor.animation_state=="Idle","Stopped player uses Idle")
 actor.animate("run",2,.2);check(actor.animation_state=="Walk","Slow movement selects Walk")
 actor.animate("run",8,.2);check(actor.animation_state=="Run","Normal controller speed selects Run")
 actor.set_health_fraction(.25);actor.animate("run",8,.1);check(actor.animation_state=="CriticalWalk","At 25 percent HP moving player uses injured walk")
 actor.set_health_fraction(.27);actor.animate("run",8,.1);check(actor.animation_state=="CriticalWalk","Health hysteresis avoids flickering between walks")
 actor.set_health_fraction(.31);actor.animate("run",8,.1);check(actor.animation_state=="Run","Recovery above 30 percent HP restores normal movement")
 actor.set_health_fraction(.2);actor.animate("idle",0,.1);check(actor.animation_state=="Idle","Low HP does not walk in place when stationary")
 actor.set_motion_context(0,true,1,10,true)
 actor.animate("crouch",0,.01);check(actor.animation_state=="CrouchEnter","Crouching plays the entry transition")
 for i in 20:actor.animate("crouch",0,.02)
 check(actor.animation_state=="Crouch" and actor.bone_world_position("Head").y-p.global_position.y<.95,"Crouch is held below the low capsule ceiling")
 actor.animate("slide",10,.3)
 for i in 50:actor.animate("slide",10,.05)
 check(actor.animation_state=="Slide" and is_equal_approx(actor.playback.current_animation_position,.625),"Long downhill slides hold the authored slide pose")
 for i in 25:actor.animate("crouch",0,.02)
 check(actor.animation_state=="Crouch","Slide recovery returns to crouch")
 for i in 20:actor.animate("idle",0,.02)
 check(actor.animation_state=="Idle","Crouch exit returns to idle")
 actor.set_motion_context(0,true,1,10,false);actor.animate("crouch",0,.01)
 check(actor.animation_state=="Crouch","Low ceilings force the fitted crouch pose immediately")
 actor.set_motion_context(5,false,1,10,true);actor.animate("jump",8,.02)
 check(actor.animation_state=="Jump" and actor.playback.current_animation_position>.37,"Physics jump skips the grounded anticipation")
 actor.set_motion_context(0,false,1,10,true);actor.animate("jump",8,.02)
 check(actor.bone_world_position("Hips").y-p.global_position.y<.94,"Airborne animation does not add a second positive hip arc")
 var apex=actor.playback.current_animation_position
 actor.set_motion_context(-8,false,1,10,true);actor.animate("fall",8,.02)
 check(actor.playback.current_animation_position>apex,"Falling advances to the descending jump pose")
 actor.set_motion_context(0,false,1,10,true);actor.animate("glide",8,.02)
 check(actor.animation_state=="Jump","Gliding has a held airborne pose")
 actor.set_motion_context(0,true,1,10,true);actor.animate("run",8,.02)
 check(actor.animation_state=="Jump" and actor.playback.current_animation_position>1.09,"Ground contact plays landing compression")
 for i in 20:actor.animate("run",8,.02)
 check(actor.animation_state=="Run" and p.position==position,"Landing returns to movement without moving the physics root")
 actor.set_damage_flash(true);check(actor.flashing and mesh.material_overlay!=null,"Damage flash works on the Investigator")
 actor.set_damage_flash(false);check(mesh.material_overlay==null,"Damage flash restores the original materials")
 game.ability_visual("ghost");check(mesh.material_override!=null,"Ability appearance still works")
 game.ability_visual("base");check(mesh.material_override==null and mesh.mesh.get_surface_count()==8,"Ability expiry restores the duster materials")
 # Real controller/health/input integration on an isolated flat platform.
 var floor=StaticBody3D.new();var collision=CollisionShape3D.new();var shape=BoxShape3D.new()
 shape.size=Vector3(40,.5,40);collision.shape=shape;floor.add_child(collision);game.world.add_child(floor);floor.position=Vector3(120,4,0)
 p.position=Vector3(120,4.3,0);p.velocity=Vector3.ZERO;p.active=true;game.health=game.stats.max_health
 await ticks(20)
 Input.action_press("forward");await ticks(25)
 check(actor.animation_state=="Run","Actual movement input drives the replacement model")
 game.health=game.stats.max_health*.2;await ticks(3)
 check(actor.animation_state=="CriticalWalk" and Vector2(p.velocity.x,p.velocity.z).length()>7.5,"Real game HP drives injured movement without changing movement balance")
 game.health=game.stats.max_health;await ticks(3);check(actor.animation_state=="Run","Actual healing clears the injured walk")
 Input.action_press("jump");await ticks(3);Input.action_release("jump")
 check(not p.is_on_floor() and actor.animation_state=="Jump","Space triggers physics and the Investigator jump together")
 check(absf(actor.bone_world_position("Root").y-p.global_position.y)<.001,"Physics body remains the sole jumping root")
 Input.action_release("forward");p.active=false
 actor.set_motion_context(0,true,1,10,true)
 for i in 20:actor.animate("idle",0,.02)
 var paused_time=actor.playback.current_animation_position
 await ticks(8)
 check(is_equal_approx(actor.playback.current_animation_position,paused_time),"Paused player animation does not advance automatically")
 game.queue_free();await process_frame;await process_frame
 print("INVESTIGATOR PLAYER RESULT: %d checks, %d failures"%[checks,failures.size()])
 quit(0 if failures.is_empty() else 1)

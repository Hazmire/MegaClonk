class_name InvestigatorVisual
extends Node3D

const MODEL=preload("res://assets/characters/investigator/Investigator_Gameplay.glb")
const MODEL_SCALE=1.8/2.020439863204956
const WALK_REFERENCE_SPEED=3.2
const RUN_REFERENCE_SPEED=8.0
const CRITICAL_ENTER=0.25
const CRITICAL_RECOVER=0.30
const LOOPS=["Idle","Walk","Run","Crouch","CriticalWalk"]
const AIR_STATES=["jump","jump_start","fall","glide","airborne"]
var model: Node3D
var rig: Skeleton3D
var playback: AnimationPlayer
var animation_state=""
var previous_input="idle"
var state_time=0.0
var flashing=false
var flash_material: StandardMaterial3D
var critical_health=false
var health_fraction=1.0
var vertical_speed=0.0
var launch_speed=10.0
var grounded=true
var standing_clearance=true
var _air_seen=false
var _landing_time=0.0
var _landing_started=false
var _recovering_slide=false

func _ready() -> void:
 model=MODEL.instantiate();model.name="InvestigatorModel";model.scale=Vector3.ONE*MODEL_SCALE;add_child(model)
 rig=model.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
 playback=model.find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
 playback.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 # Loop flags belong to each avatar's library; imported shared resources stay intact.
 var library=AnimationLibrary.new()
 for name in playback.get_animation_list():
  if name=="RESET":continue
  var clip=playback.get_animation(name).duplicate() as Animation
  clip.loop_mode=Animation.LOOP_LINEAR if name in LOOPS else Animation.LOOP_NONE
  library.add_animation(name,clip)
 for name in playback.get_animation_library_list():playback.remove_animation_library(name)
 playback.add_animation_library("",library)
 _play("Idle",0);playback.advance(0)

func set_health_fraction(value: float) -> void:
 health_fraction=clampf(value,0,1)
 if health_fraction<=CRITICAL_ENTER:critical_health=true
 elif health_fraction>=CRITICAL_RECOVER:critical_health=false

func set_motion_context(y_velocity: float,on_ground: bool,hp: float,jump_speed: float,can_stand: bool=true) -> void:
 vertical_speed=y_velocity;launch_speed=maxf(jump_speed,0.1);grounded=on_ground;standing_clearance=can_stand
 set_health_fraction(hp)
 if not grounded:_air_seen=true
 elif _air_seen:
  _landing_time=0.18;_landing_started=false;_air_seen=false

func _play(clip: String,blend: float=0.10) -> void:
 if animation_state==clip:return
 animation_state=clip;state_time=0
 playback.speed_scale=1
 playback.play(clip,blend)

func _finished() -> bool:
 return not playback.is_playing() or playback.current_animation_position>=playback.get_animation(animation_state).length-0.001

func animate(state: String,speed: float,delta: float) -> void:
 if not is_instance_valid(playback):return
 delta=maxf(0,delta)
 var previous=previous_input;previous_input=state
 if state=="death":
  _play("Crouch");playback.seek(0,true);playback.advance(0);return
 if state in AIR_STATES:
  _landing_time=0;_recovering_slide=false
  if not standing_clearance:
   _play("Crouch",0.06);playback.advance(delta);return
  _play("Jump",0.06)
  var phase=0.48
  if state=="glide":phase=0.56
  elif state in ["fall","airborne"]:phase=lerpf(0.48,0.71,clampf(-vertical_speed/launch_speed,0,1))
  else:phase=lerpf(0.25,0.48,1-clampf(vertical_speed/launch_speed,0,1))
  playback.seek(playback.get_animation("Jump").length*phase,true);playback.advance(0);return
 if state=="slide":
  _landing_time=0;_recovering_slide=false
  _play("Slide",0.06);state_time+=delta
  # Keep the low sliding pose for as long as physics continues the slide.
  var phase=0.5 if not standing_clearance else 0.5*clampf(state_time/0.25,0,1)
  playback.seek(playback.get_animation("Slide").length*phase,true);playback.advance(0);return
 if state=="crouch":
  _landing_time=0
  if previous=="slide" and standing_clearance:
   _recovering_slide=true;playback.play("Slide",0.06);animation_state="Slide"
   playback.seek(playback.get_animation("Slide").length*0.5,true)
  if not standing_clearance:
   _recovering_slide=false;_play("Crouch",0.04);playback.advance(delta);return
  if _recovering_slide:
   playback.speed_scale=2.5;playback.advance(delta)
   if _finished():_recovering_slide=false;_play("Crouch",0.05);playback.advance(0)
   return
  if animation_state not in ["CrouchEnter","Crouch"]:_play("CrouchEnter",0.06)
  playback.speed_scale=2.5 if animation_state=="CrouchEnter" else 1
  playback.advance(delta)
  if animation_state=="CrouchEnter" and _finished():_play("Crouch",0.05);playback.advance(0)
  return
 _recovering_slide=false
 if animation_state in ["Crouch","CrouchEnter","Slide"]:_play("CrouchExit",0.08)
 if animation_state=="CrouchExit":
  playback.speed_scale=2.5;playback.advance(delta)
  if not _finished():return
 if _landing_time>0:
  _play("Jump",0.06)
  if not _landing_started:playback.seek(playback.get_animation("Jump").length*0.73,true);_landing_started=true
  playback.speed_scale=1.5;playback.advance(delta);_landing_time=maxf(0,_landing_time-delta)
  return
 var moving=speed>0.5
 var wanted="Idle"
 if state in ["critical_walk","critical"] or (critical_health and moving):wanted="CriticalWalk"
 elif moving:wanted="Run" if speed>=4.5 else "Walk"
 _play(wanted)
 if wanted=="Run":playback.speed_scale=clampf(speed/RUN_REFERENCE_SPEED,0.65,2)
 elif wanted=="Walk":playback.speed_scale=clampf(speed/WALK_REFERENCE_SPEED,0.6,1.8)
 elif wanted=="CriticalWalk":playback.speed_scale=clampf(speed/4.0,0.7,1.6)
 else:playback.speed_scale=1
 playback.advance(delta)

func bone_world_position(name: String) -> Vector3:
 rig.force_update_all_bone_transforms()
 return rig.global_transform*rig.get_bone_global_pose(rig.find_bone(name)).origin

func set_damage_flash(value: bool) -> void:
 if flashing==value:return
 flashing=value
 if flash_material==null:
  flash_material=StandardMaterial3D.new();flash_material.albedo_color=Color(1,0.02,0.01,0.85)
  flash_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;flash_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.material_overlay=flash_material if value else null

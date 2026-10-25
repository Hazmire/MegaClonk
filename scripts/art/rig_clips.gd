class_name RigClips
extends RefCounted
static var source: Node3D
static var source_rig: Skeleton3D
static var libraries: Dictionary={}
static func initialize() -> void:
 if is_instance_valid(source):return
 source=load("res://assets/quaternius/animations/UAL2_Standard.glb").instantiate()
 source_rig=source.get_node("Armature/Skeleton3D")
static func library(rig: Skeleton3D,key: String) -> AnimationLibrary:
 if libraries.has(key):return libraries[key]
 initialize()
 var player=source.get_node("AnimationPlayer")
 var result=AnimationLibrary.new()
 var selected={"idle":"Idle_No","move":"Walk_Carry","jump_start":"NinjaJump_Start","airborne":"NinjaJump_Idle","fall":"NinjaJump_Idle","land":"NinjaJump_Land","slide":"Slide","hit":"Hit_Knockback","death":"LayToIdle","enemy_move":"Zombie_Walk_Fwd","enemy_idle":"Zombie_Idle"}
 for name in selected:
  var original: Animation=player.get_animation(selected[name]);var clip=original.duplicate(true)
  clip.loop_mode=Animation.LOOP_LINEAR if name in ["idle","move","airborne","fall","slide","enemy_move","enemy_idle"] else Animation.LOOP_NONE
  for track in range(clip.get_track_count()-1,-1,-1):
   var path=clip.track_get_path(track);var bone=String(path.get_subname(0)) if path.get_subname_count()>0 else ""
   var target=rig.find_bone(bone);var src=source_rig.find_bone(bone)
   if target<0 or src<0:clip.remove_track(track);continue
   var type=clip.track_get_type(track)
   if type==Animation.TYPE_POSITION_3D and bone!="pelvis":clip.remove_track(track);continue
   var old_rest=source_rig.get_bone_rest(src);var new_rest=rig.get_bone_rest(target)
   for frame in clip.track_get_key_count(track):
    var value=clip.track_get_key_value(track,frame)
    if type==Animation.TYPE_ROTATION_3D:value=(new_rest.basis.get_rotation_quaternion()*old_rest.basis.get_rotation_quaternion().inverse()*value).normalized()
    elif type==Animation.TYPE_POSITION_3D:
     var ratio=new_rest.origin.length()/maxf(0.01,old_rest.origin.length())
     value=new_rest.origin+(value-old_rest.origin)*ratio
    clip.track_set_key_value(track,frame,value)
  result.add_animation(name,clip)
 # Carry-walk legs are useful for an unarmed ranger; replace raised carry arms
 # with idle arm tracks so the character doesn't carry an invisible box.
 var walk: Animation=result.get_animation("move")
 for track in range(walk.get_track_count()-1,-1,-1):
  var name=String(walk.track_get_path(track))
  if "arm" in name or "hand" in name or "clavicle" in name:walk.remove_track(track)
 var idle: Animation=result.get_animation("idle")
 for track in idle.get_track_count():
  var name=String(idle.track_get_path(track))
  if "arm" in name or "hand" in name or "clavicle" in name:
   idle.copy_track(track,walk)
 # Original crouch authored on the actual rig, not a mesh scale/capsule trick.
 var crouch=Animation.new();crouch.length=1;crouch.loop_mode=Animation.LOOP_LINEAR
 for bone in ["pelvis","thigh_l","thigh_r","calf_l","calf_r","spine_02"]:
  var index=rig.find_bone(bone)
  if index<0:continue
  var rest=rig.get_bone_rest(index)
  var track=crouch.add_track(Animation.TYPE_ROTATION_3D);crouch.track_set_path(track,NodePath("Armature/Skeleton3D:"+bone))
  var angle=1.3 if bone.begins_with("thigh") else (-2.4 if bone.begins_with("calf") else (1.0 if bone=="spine_02" else 0))
  var rotation=rest.basis.get_rotation_quaternion()*Quaternion(Vector3.RIGHT,angle)
  crouch.rotation_track_insert_key(track,0,rotation);crouch.rotation_track_insert_key(track,1,rotation)
  if bone=="pelvis":
   var position=crouch.add_track(Animation.TYPE_POSITION_3D);crouch.track_set_path(position,NodePath("Armature/Skeleton3D:pelvis"))
   var low=rest.origin;low.z-=0.5
   crouch.position_track_insert_key(position,0,low);crouch.position_track_insert_key(position,1,low)
 for track in idle.get_track_count():
  var path=String(idle.track_get_path(track))
  if idle.track_get_type(track)!=Animation.TYPE_ROTATION_3D:continue
  if not ("arm" in path or "hand" in path or "clavicle" in path):continue
  var at=crouch.add_track(Animation.TYPE_ROTATION_3D);crouch.track_set_path(at,idle.track_get_path(track))
  var rotation=idle.track_get_key_value(track,0);crouch.rotation_track_insert_key(at,0,rotation);crouch.rotation_track_insert_key(at,1,rotation)
 if key=="ranger":
  result.remove_animation("move");result.add_animation("move",RangerStride.make(rig))
 result.add_animation("crouch",crouch)
 libraries[key]=result;return result
static func reset() -> void:
 if is_instance_valid(source):source.free()
 source=null;source_rig=null

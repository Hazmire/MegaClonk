class_name SimpleRangerClips
extends RefCounted
const SPEED=4.0
static var cache: AnimationLibrary
const MAP={"pelvis":"hips","spine_01":"spine","spine_02":"chest","Head":"head","thigh_l":"upperleg.l","calf_l":"lowerleg.l","foot_l":"foot.l","ball_l":"toes.l","thigh_r":"upperleg.r","calf_r":"lowerleg.r","foot_r":"foot.r","ball_r":"toes.r","upperarm_l":"upperarm.l","lowerarm_l":"lowerarm.l","hand_l":"wrist.l","upperarm_r":"upperarm.r","lowerarm_r":"lowerarm.r","hand_r":"wrist.r"}
static func library(target: Skeleton3D) -> AnimationLibrary:
 return preload("res://assets/config/player_core.res")
static func build_library(target: Skeleton3D) -> AnimationLibrary:
 if cache!=null:return cache
 cache=AnimationLibrary.new()
 for entry in [["idle","res://assets/kaykit/skeletons/Rig_Medium_General.glb","Idle_A"],["move","res://assets/kaykit/skeletons/Rig_Medium_MovementBasic.glb","Running_A"],["jump","res://assets/kaykit/skeletons/Rig_Medium_MovementBasic.glb","Jump_Idle"],["slide","res://assets/quaternius/animations/UAL2_Standard.glb","Slide"]]:
  var source=load(entry[1]).instantiate();target.add_child(source)
  var rig=source.find_children("*","Skeleton3D",true,false)[0] as Skeleton3D
  var player=source.get_node("AnimationPlayer");player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
  var original: Animation=player.get_animation(entry[2]);var result=Animation.new();result.length=original.length;result.loop_mode=Animation.LOOP_LINEAR
  var tracks=[]
  for bone in target.get_bone_count():
   var track=result.add_track(Animation.TYPE_ROTATION_3D);result.track_set_path(track,NodePath("Armature/Skeleton3D:"+target.get_bone_name(bone)));tracks.append(track)
  var pos_track=result.add_track(Animation.TYPE_POSITION_3D);result.track_set_path(pos_track,NodePath("Armature/Skeleton3D:pelvis"))
  player.play(entry[2])
  for frame in 33:
   var time=original.length*float(frame)/32;player.seek(time,true);player.advance(0);rig.force_update_all_bone_transforms()
   var globals=[]
   for bone in target.get_bone_count():
    var name=target.get_bone_name(bone);var source_name=name if entry[0]=="slide" else MAP.get(name,"")
    var src=rig.find_bone(source_name);var parent=target.get_bone_parent(bone)
    var parent_pose: Transform3D=Transform3D.IDENTITY if parent<0 else globals[parent]
    var local=target.get_bone_rest(bone)
    if src>=0:
     # Rest-space correction is GLOBAL, then converted through the CURRENT
     # target parent. Local-rest multiplication alone mixes incompatible axes.
     var delta=rig.get_bone_global_pose(src).basis*rig.get_bone_global_rest(src).basis.inverse()
     var desired=delta*target.get_bone_global_rest(bone).basis
     local.basis=parent_pose.basis.inverse()*desired
    if name=="pelvis":
     var vertical=0.0
     if src>=0:vertical=rig.get_bone_global_pose(src).origin.y-rig.get_bone_global_rest(src).origin.y
     vertical=clampf(vertical,-0.8,0.1) if entry[0]=="slide" else (clampf(vertical,-0.025,0.025) if entry[0] in ["idle","move"] else 0.0)
     local.origin+=parent_pose.basis.inverse()*Vector3.UP*vertical
     result.position_track_insert_key(pos_track,time,local.origin)
    result.rotation_track_insert_key(tracks[bone],time,local.basis.orthonormalized().get_rotation_quaternion())
    globals.append(parent_pose*local)
   # No animation translates the scene/root or physics body.
  cache.add_animation(entry[0],result);source.free()
 return cache

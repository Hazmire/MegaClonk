class_name RangerStride
extends RefCounted
# Original in-place, sagittal two-bone IK cycle fitted to the Ranger's real limb
# lengths. Stance feet stay on the ground and travel backwards at constant speed.
const LENGTH=0.66
const STANCE=0.42
const STRIDE=0.86
const METRES_PER_SECOND=STRIDE/(LENGTH*STANCE)
static func make(rig: Skeleton3D) -> Animation:
 var clip=Animation.new();clip.length=LENGTH;clip.loop_mode=Animation.LOOP_LINEAR
 var tracks={}
 for bone in ["pelvis","thigh_l","calf_l","foot_l","thigh_r","calf_r","foot_r","upperarm_l","upperarm_r"]:
  var track=clip.add_track(Animation.TYPE_ROTATION_3D);clip.track_set_path(track,NodePath("Armature/Skeleton3D:"+bone));tracks[bone]=track
 for index in rig.get_bone_count():
  var name=rig.get_bone_name(index)
  if tracks.has(name):continue
  var track=clip.add_track(Animation.TYPE_ROTATION_3D);clip.track_set_path(track,NodePath("Armature/Skeleton3D:"+name))
  var rotation=rig.get_bone_rest(index).basis.get_rotation_quaternion()
  clip.rotation_track_insert_key(track,0,rotation);clip.rotation_track_insert_key(track,LENGTH,rotation)
 var position=clip.add_track(Animation.TYPE_POSITION_3D);clip.track_set_path(position,NodePath("Armature/Skeleton3D:pelvis"))
 for frame in 49:
  var time=float(frame)/48;var offset=Vector3(0,-0.12+0.018*cos(time*TAU*2),0)
  var pelvis=rig.find_bone("pelvis");var parent=rig.get_bone_parent(pelvis)
  var local=rig.get_bone_global_rest(parent).affine_inverse()*(rig.get_bone_global_rest(pelvis).origin+offset)
  clip.position_track_insert_key(position,time*LENGTH,local)
  clip.rotation_track_insert_key(tracks.pelvis,time*LENGTH,rig.get_bone_rest(pelvis).basis.get_rotation_quaternion())
  for side in ["l","r"]:
   var phase=fposmod(time+(0.5 if side=="r" else 0),1)
   var thigh=rig.find_bone("thigh_"+side);var calf=rig.find_bone("calf_"+side);var foot=rig.find_bone("foot_"+side)
   var hip=rig.get_bone_global_rest(thigh).origin+offset
   var knee_rest=rig.get_bone_global_rest(calf).origin;var ankle_rest=rig.get_bone_global_rest(foot).origin
   var ankle=ankle_rest
   if phase<STANCE:ankle.z+=STRIDE*(0.5-phase/STANCE)
   else:
    var swing=(phase-STANCE)/(1-STANCE);ankle.z+=lerpf(-STRIDE/2,STRIDE/2,swing);ankle.y+=sin(swing*PI)*0.16
   var a=rig.get_bone_global_rest(thigh).origin.distance_to(knee_rest);var b=knee_rest.distance_to(ankle_rest)
   var delta=Vector2(ankle.y-hip.y,ankle.z-hip.z);var distance=minf(delta.length(),a+b-0.002);var unit=delta.normalized()
   var along=(a*a-b*b+distance*distance)/(2*distance)
   var knee=hip+Vector3(0,unit.x*along+unit.y*sqrt(maxf(0,a*a-along*along)),unit.y*along-unit.x*sqrt(maxf(0,a*a-along*along)))
   var thigh_basis=Basis(Quaternion((knee_rest-rig.get_bone_global_rest(thigh).origin).normalized(),(knee-hip).normalized()))*rig.get_bone_global_rest(thigh).basis
   var calf_basis=Basis(Quaternion((ankle_rest-knee_rest).normalized(),(ankle-knee).normalized()))*rig.get_bone_global_rest(calf).basis
   var parent_basis=rig.get_bone_global_rest(rig.get_bone_parent(thigh)).basis
   clip.rotation_track_insert_key(tracks["thigh_"+side],time*LENGTH,(parent_basis.inverse()*thigh_basis).get_rotation_quaternion())
   clip.rotation_track_insert_key(tracks["calf_"+side],time*LENGTH,(thigh_basis.inverse()*calf_basis).get_rotation_quaternion())
   clip.rotation_track_insert_key(tracks["foot_"+side],time*LENGTH,(calf_basis.inverse()*rig.get_bone_global_rest(foot).basis).get_rotation_quaternion())
   var arm=rig.find_bone("upperarm_"+side);var rest=rig.get_bone_global_rest(arm)
   var arm_basis=Basis(Vector3.RIGHT,sin(phase*TAU)*0.28)*Basis(Vector3.FORWARD,1.35 if side=="l" else -1.35)*rest.basis
   var arm_local=rig.get_bone_global_rest(rig.get_bone_parent(arm)).basis.inverse()*arm_basis
   clip.rotation_track_insert_key(tracks["upperarm_"+side],time*LENGTH,arm_local.get_rotation_quaternion())
 return clip

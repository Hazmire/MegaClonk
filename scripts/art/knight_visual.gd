class_name KnightVisual
extends Node3D
# Animation is visual only: movement/collision remains owned by the controller.
var model: Node3D
var rig: Skeleton3D
var playback: AnimationPlayer
var animation_state="idle"
var flashing=false
var state_time=0.0
var previous_input="idle"
var landing=0.0
var surfaces: Array[MeshInstance3D]=[]
static var damage_material: ShaderMaterial
func _ready() -> void:
 model=preload("res://assets/grimdark/knight/Knight_ready.glb").instantiate()
 add_child(model)
 for node in model.find_children("*","Skeleton3D",true,false):rig=node;break
 for node in model.find_children("*","AnimationPlayer",true,false):playback=node;break
 for node in model.find_children("*","MeshInstance3D",true,false):
  surfaces.append(node)
  for surface in node.mesh.get_surface_count():
   node.set_surface_override_material(surface,GrimdarkMaterials.material(node.mesh.surface_get_material(surface),1,false,true))
 playback.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 playback.get_animation("k_idle").loop_mode=Animation.LOOP_LINEAR
 playback.get_animation("k_walk").loop_mode=Animation.LOOP_LINEAR
 playback.play("k_idle");playback.advance(0)
func animate(state: String,speed: float,delta: float) -> void:
 if not is_instance_valid(playback):return
 if state!=previous_input:
  if previous_input in ["jump","fall","glide"] and state not in ["jump","fall","glide"]:landing=1.0
  state_time=0.0
 previous_input=state;animation_state=state;state_time+=delta
 var clip="k_walk" if speed>0.2 and state not in ["death","slide","jump","fall","glide"] else "k_idle"
 if playback.current_animation!=clip:playback.play(clip,0.1)
 playback.speed_scale=clampf(speed/4.5,0.2,2.5) if clip=="k_walk" else 1.0
 playback.advance(delta)
 var tilt=Vector3.ZERO
 var height=0.0
 if state=="crouch":height=-0.45;tilt.x=0.38
 if state=="slide":height=-0.72;tilt.x=-0.9
 if state=="jump":tilt.x=-0.12
 if state in ["fall","glide"]:tilt.x=0.16
 if state=="death":tilt.z=minf(state_time*2.5,PI/2);height=-minf(state_time,0.65)
 landing=move_toward(landing,0.0,delta*5.0)
 height-=sin(landing*PI)*0.12
 # Root bob belongs to the visual skeleton, never to the physics body.
 var body=rig.find_bone("Body")
 if body>=0:rig.set_bone_pose_position(body,rig.get_bone_pose_position(body)+Vector3.UP*height)
 if state in ["crouch","slide"]:
  for side in [".l",".r"]:
   for joint in ["UpperLeg","LowerLeg","Foot"]:
    var bone=rig.find_bone(joint+side)
    if bone>=0:
     var angle={"UpperLeg":-.65,"LowerLeg":1.15,"Foot":-.5}[joint] if state=="crouch" else {"UpperLeg":.7,"LowerLeg":.12,"Foot":-.3}[joint]
     rig.set_bone_pose_rotation(bone,rig.get_bone_pose_rotation(bone)*Quaternion(Vector3.RIGHT,angle))
 model.rotation=tilt;model.position.y=0.0
func set_damage_flash(value: bool) -> void:
 if flashing==value:return
 flashing=value
 if damage_material==null:
  damage_material=GrimdarkMaterials.material(null,1,false,true)
  damage_material.set_shader_parameter("hit_flash",1.0)
 for surface in surfaces:surface.material_overlay=damage_material if value else null

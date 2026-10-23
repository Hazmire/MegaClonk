class_name JacobVisual
extends Node3D
# Licensed supplied rig; imported Idle provides the base pose. Original additive
# movement poses remain separate from the collision/movement controller.
static var materials: Dictionary={}
var animation_state="idle"
var clock=0.0
var model: Node3D
var rig: Skeleton3D
var playback: AnimationPlayer
func _ready() -> void:
 model=preload("res://assets/vendor/jacob/Jacob.fbx").instantiate()
 add_child(model)
 for node in model.get_children():
  if node.name in ["Rocks","Ground","Grass"]:node.hide()
 # FBX material names survive import but its external image references do not.
 # Bind supplied atlases explicitly; retain the authored outline cull mode.
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  for surface in mesh.mesh.get_surface_count():
   var source=mesh.mesh.surface_get_material(surface)
   if not source is StandardMaterial3D:continue
   if materials.has(source.resource_name):
    mesh.set_surface_override_material(surface,materials[source.resource_name]);continue
   var material=source.duplicate() as StandardMaterial3D
   if source.resource_name=="Jacob_Body":material.albedo_texture=preload("res://assets/vendor/jacob/textures/T_JacobColor.png")
   elif source.resource_name=="Jacob_PropsAtlas":material.albedo_texture=preload("res://assets/vendor/jacob/textures/T_PropsAtlas.png")
   elif source.resource_name=="Outline":material.albedo_color=Color("20232a")
   material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
   materials[source.resource_name]=material
   mesh.set_surface_override_material(surface,material)
 rig=model.find_child("Skeleton3D",true,false)
 playback=model.get_node("AnimationPlayer")
 playback.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 playback.play("Idle");playback.advance(0)
 # Demonstration sword is not the equipped weapon; avoid a permanently drawn blade.
 rig.get_node("JacobMedieval-Claymore").hide()
func rotate_bone(label: String, axis: Vector3, angle: float) -> void:
 var bone=rig.find_bone(label)
 if bone>=0:rig.set_bone_pose_rotation(bone,rig.get_bone_pose_rotation(bone)*Quaternion(axis,angle))
func animate(state: String, speed: float, delta: float) -> void:
 animation_state=state;clock+=delta
 if not is_instance_valid(playback):return
 # Re-evaluate the authored base pose before applying offsets (no accumulation).
 playback.seek(fmod(clock,playback.get_animation("Idle").length),true)
 for prop in ["Rocks","Ground","Grass"]:model.get_node(prop).hide()
 rig.get_node("JacobMedieval-Claymore").hide()
 var stride=sin(clock*minf(16,speed*1.6))*minf(1,speed/8)*0.65 if state in ["run","crouch"] else 0.0
 var low=state in ["crouch","slide"]
 var lean=0.12 if state=="run" else 0.0
 if state=="crouch":lean=0.5
 if state=="slide":lean=-0.7
 if state=="hit":lean=-0.3
 if state=="death":lean=1.45
 model.position.y=lerpf(model.position.y,-0.55 if low else 0.0,clampf(delta*14,0,1))
 model.rotation.x=lerpf(model.rotation.x,lean,clampf(delta*14,0,1))
 for side in ["L","R"]:
  var sign_value=1.0 if side=="L" else -1.0
  var leg=stride*sign_value
  if state=="crouch":leg=-0.85+leg*0.25
  elif state=="slide":leg=-1.25
  elif state=="jump":leg=0.45*sign_value
  elif state=="fall":leg=0.2
  rotate_bone("DEF-ULEG."+side,Vector3.RIGHT,leg)
  rotate_bone("DEF-LLEG."+side,Vector3.RIGHT,0.95 if low else maxf(0,-leg)*0.5)
  rotate_bone("DEF-UARM_01."+side,Vector3.RIGHT,-stride*sign_value)
 rotate_bone("DEF-CHEST",Vector3.UP,sin(clock*6)*0.15 if state=="turn" else 0.0)

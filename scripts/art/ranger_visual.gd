class_name RangerVisual
extends Node3D
var model: Node3D
var rig: Skeleton3D
var playback: AnimationPlayer
var animation_state="idle"
var state_time=0.0
var air_clock=0.0
var previous_input="idle"
var flashing=false
var flash_material: StandardMaterial3D
static var head_mesh: ArrayMesh
static var head_skin: Skin
func _ready() -> void:
 model=preload("res://assets/quaternius/ranger/Male_Ranger.gltf").instantiate();add_child(model)
 rig=model.get_node("Armature/Skeleton3D")
 playback=AnimationPlayer.new();playback.name="AnimationPlayer";model.add_child(playback)
 playback.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
 playback.add_animation_library("",SimpleRangerClips.library(rig))
 attach_head()
 playback.play("idle");playback.advance(0)
func attach_head() -> void:
 # The outfit pack explicitly supplies clothing, not a base head. Reuse only
 # the supplied UAL mannequin's head geometry, retaining its matching 65-bone rig.
 if head_mesh==null:
  RigClips.initialize()
  var mesh_node=RigClips.source.get_node("Armature/Skeleton3D/Mannequin")
  var arrays=mesh_node.mesh.surface_get_arrays(0);var vertices=arrays[Mesh.ARRAY_VERTEX];var indices=arrays[Mesh.ARRAY_INDEX]
  var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
  for triangle in range(0,indices.size(),3):
   var keep=true
   for j in 3:
    if vertices[indices[triangle+j]].y<1.55:keep=false
   if not keep:continue
   for j in 3:
    var index=indices[triangle+j]
    tool.set_normal(arrays[Mesh.ARRAY_NORMAL][index])
    tool.set_bones(PackedInt32Array(arrays[Mesh.ARRAY_BONES].slice(index*4,index*4+4)))
    tool.set_weights(PackedFloat32Array(arrays[Mesh.ARRAY_WEIGHTS].slice(index*4,index*4+4)))
    tool.add_vertex(vertices[index])
  head_mesh=tool.commit();head_skin=mesh_node.skin.duplicate()
  for bind in head_skin.get_bind_count():
   var bone=rig.find_bone(head_skin.get_bind_name(bind))
   if bone>=0:head_skin.set_bind_pose(bind,rig.get_bone_global_rest(bone).affine_inverse())
  var skin=StandardMaterial3D.new();skin.albedo_color=Color("b87e58");skin.roughness=0.9;head_mesh.surface_set_material(0,skin)
 var head=MeshInstance3D.new();head.name="UAL_Head";head.mesh=head_mesh;head.skin=head_skin;rig.add_child(head);head.skeleton=NodePath("..")
func animate(state: String,speed: float,delta: float) -> void:
 if not is_instance_valid(playback):return
 var wanted="slide" if state in ["slide","crouch"] else ("jump" if state in ["jump","fall","glide","airborne","jump_start"] else ("move" if speed>0.2 else "idle"))
 if wanted!=animation_state:
  animation_state=wanted;playback.play(wanted,0.08)
 playback.speed_scale=clampf(speed/SimpleRangerClips.SPEED,0.15,3.5) if wanted=="move" else 1.0
 playback.advance(delta)
 if state=="crouch":playback.seek(playback.get_animation("slide").length*0.35,true);playback.advance(0)
func set_damage_flash(value: bool) -> void:
 if flashing==value:return
 flashing=value
 if flash_material==null:
  flash_material=StandardMaterial3D.new();flash_material.albedo_color=Color(1,0.02,0.01,0.85);flash_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;flash_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 for mesh in model.find_children("*","MeshInstance3D",true,false):mesh.material_overlay=flash_material if value else null

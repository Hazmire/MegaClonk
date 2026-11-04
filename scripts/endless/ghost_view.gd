class_name GhostView
extends Node3D
# Draws every endless ghost: one shared mesh (GhostMesh, built once), one shared material per tier, one MultiMesh per tier with a fixed capacity.
# Per-ghost fade (materialise in ~0.6 s, dissipate in ~0.25 s) rides in the instance custom data, so no ghost ever owns a material copy.
# Preallocated everywhere: nothing here allocates per frame.
const SHADER=preload("res://shaders/ghost.gdshader")
const DISSIPATE_SLOTS=96
# Tier look (from the ghost pack). Gameplay numbers are in assets/config/endless_rules.json.
const LOOK={
 "mourner":{"body":Color("6E7C78"),"rim":Color("C8D6D0"),"eye":Color("E8F4F0"),"opacity":0.75,"core":0.28,"rim_power":1.4,"wobble":1.0,"speed":1.0},
 "drowned":{"body":Color("3E5A2A"),"rim":Color("9AB86A"),"eye":Color("E8FF7A"),"opacity":0.7,"core":0.32,"rim_power":1.6,"wobble":1.1,"speed":1.15},
 "wrathful":{"body":Color("5A0A08"),"rim":Color("D8341E"),"eye":Color("FFB040"),"opacity":0.8,"core":0.48,"rim_power":2.2,"wobble":1.3,"speed":1.35},
 "hollow":{"body":Color("0A080C"),"rim":Color("B3363F"),"eye":Color("FFFFFF"),"opacity":1.0,"core":0.92,"rim_power":5.0,"wobble":0.8,"speed":0.8}}
static var mesh: ArrayMesh
static var materials: Dictionary={}
var nodes: Array=[]
var counts=PackedInt32Array()
var capacity=0
# Dissipating ghosts (killed or spent): a fixed ring of slots that keep drawing for the fade-out.
var d_tier=PackedInt32Array();var d_age=PackedFloat32Array();var d_xf: Array[Transform3D]=[];var d_next=0
func _init() -> void:
 name="GhostView";capacity=Endless.cap()
 if mesh==null:mesh=GhostMesh.build()
 for i in Endless.tiers().size():
  var node=MultiMeshInstance3D.new();node.name="Ghosts_"+str(Endless.tier(i).id)
  node.multimesh=MultiMesh.new();node.multimesh.transform_format=MultiMesh.TRANSFORM_3D;node.multimesh.use_custom_data=true;node.multimesh.mesh=mesh
  node.multimesh.instance_count=capacity+DISSIPATE_SLOTS;node.multimesh.visible_instance_count=0
  node.material_override=material(str(Endless.tier(i).id));node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  node.custom_aabb=AABB(Vector3(-400,-120,-400),Vector3(800,320,800)) # instances live in world space; never frustum-cull the batch
  add_child(node);nodes.append(node)
 counts.resize(nodes.size());d_tier.resize(DISSIPATE_SLOTS);d_age.resize(DISSIPATE_SLOTS);d_age.fill(99.0);d_xf.resize(DISSIPATE_SLOTS)
static func material(id: String) -> ShaderMaterial:
 if not materials.has(id):
  var look: Dictionary=LOOK[id];var m=ShaderMaterial.new();m.shader=SHADER
  m.set_shader_parameter("body_color",look.body);m.set_shader_parameter("rim_color",look.rim);m.set_shader_parameter("eye_color",look.eye)
  m.set_shader_parameter("opacity",look.opacity);m.set_shader_parameter("core",look.core);m.set_shader_parameter("rim_power",look.rim_power)
  m.set_shader_parameter("wobble",look.wobble);m.set_shader_parameter("speed",look.speed)
  materials[id]=m
 return materials[id]
func begin_frame() -> void:counts.fill(0)
func put(tier: int,transform: Transform3D,fade: float) -> void:
 var index=counts[tier]
 if index>=capacity:return
 var mm: MultiMesh=nodes[tier].multimesh
 mm.set_instance_transform(index,transform);mm.set_instance_custom_data(index,Color(fade,0,0,0));counts[tier]=index+1
# A ghost that just died or was spent keeps drawing, fading out, for Endless.data().fade.out_s.
func dissipate(tier: int,transform: Transform3D) -> void:
 d_tier[d_next]=tier;d_age[d_next]=0.0;d_xf[d_next]=transform;d_next=(d_next+1)%DISSIPATE_SLOTS
func end_frame(delta: float) -> void:
 var fade_out=float(Endless.data().fade.out_s)
 for i in DISSIPATE_SLOTS:
  if d_age[i]>=fade_out:continue
  d_age[i]+=delta
  var tier=d_tier[i];var index=counts[tier]
  if index>=capacity+DISSIPATE_SLOTS:continue
  var mm: MultiMesh=nodes[tier].multimesh
  mm.set_instance_transform(index,d_xf[i]);mm.set_instance_custom_data(index,Color(clampf(1.0-d_age[i]/fade_out,0.0,1.0),0,0,0));counts[tier]=index+1
 for i in nodes.size():nodes[i].multimesh.visible_instance_count=counts[i]
func visible_count() -> int:
 var total=0
 for i in counts.size():total+=counts[i]
 return total

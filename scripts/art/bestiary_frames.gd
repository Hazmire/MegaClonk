class_name BestiaryFrames
extends RefCounted
static var meshes: Dictionary={}
static var materials: Dictionary={}
static func mesh(model: String,state: String,frame: int) -> ArrayMesh:
 var key=model+state+str(frame)
 if meshes.has(key):return meshes[key]
 var result=load("res://assets/quaternius/baked/%s_%s_%d.res"%[model,state,frame]).duplicate() as ArrayMesh
 for surface in result.get_surface_count():
  var original=result.surface_get_material(surface) as StandardMaterial3D
  var material_key=original.resource_path if original else "white"
  if not materials.has(material_key):
   var material=ShaderMaterial.new();material.shader=preload("res://shaders/enemy_feedback.gdshader")
   if original:
    material.set_shader_parameter("albedo_map",original.albedo_texture);material.set_shader_parameter("base_tint",original.albedo_color)
   materials[material_key]=material
  result.surface_set_material(surface,materials[material_key])
 meshes[key]=result;return result

static func prewarm() -> void:
 for model in ["Imp","Puglin"]:
  for frame in 8:mesh(model,"enemy_move",frame)
  for frame in 2:mesh(model,"enemy_idle",frame)

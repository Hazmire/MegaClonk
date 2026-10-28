class_name GrimdarkMaterials
extends RefCounted
static var materials: Dictionary={}
static var meshes: Dictionary={}
static func material(original: Material,stage: int=1,foliage: bool=false,player: bool=false) -> ShaderMaterial:
 var key=(str(original.get_instance_id()) if original else "white")+":"+str(stage)+":"+str(foliage)+":"+str(player)
 if materials.has(key):return materials[key]
 var result=ShaderMaterial.new();result.shader=preload("res://shaders/grimdark_surface.gdshader")
 if original is BaseMaterial3D:
  result.set_shader_parameter("u_albedo_texture",original.albedo_texture if original.albedo_texture else original.emission_texture)
  result.set_shader_parameter("u_albedo_color",Color.WHITE if original.albedo_texture==null and original.emission_texture!=null else original.albedo_color)
  result.set_shader_parameter("u_vertex_color_use_as_albedo",true)
 result.set_shader_parameter("foliage",foliage);result.set_shader_parameter("season",StageThemes.index(stage));result.set_shader_parameter("flash_color",Color("d55951") if player else Color.WHITE)
 materials[key]=result;return result
static func mesh(base: Mesh,stage: int=1,foliage: bool=false) -> ArrayMesh:
 var key=str(base.get_instance_id())+":"+str(stage)+":"+str(foliage)
 if meshes.has(key):return meshes[key]
 var result=base.duplicate() as ArrayMesh
 for i in result.get_surface_count():result.surface_set_material(i,material(base.surface_get_material(i),stage,foliage))
 meshes[key]=result;return result

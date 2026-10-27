class_name StageThemes
extends RefCounted
# Explicit three-theme cycle for stages beyond three; no new gameplay biome.
const THEMES=[preload("res://assets/themes/green.tres"),preload("res://assets/themes/violet.tres"),preload("res://assets/themes/crimson.tres")]
static var mesh_cache: Dictionary={}
static var material_cache: Dictionary={}
static var gradients: Dictionary={}
static func index(stage: int) -> int:return posmod(maxi(1,stage)-1,THEMES.size())
static func config(stage: int) -> StageTheme:return THEMES[index(stage)]
static func gradient(stage: int) -> GradientTexture1D:
 var key=index(stage)
 if not gradients.has(key):
  var texture=GradientTexture1D.new();var colors=Gradient.new();colors.set_color(0,config(stage).grass_low);colors.set_color(1,config(stage).grass_high);texture.gradient=colors;gradients[key]=texture
 return gradients[key]
static func apply(game: Node) -> void:
 var t=config(game.stage);var env=game.world.get_child(0).environment
 ForestAtmosphere.apply(env)
 var material=env.sky.sky_material
 material.set_shader_parameter("zenith",t.zenith);material.set_shader_parameter("horizon",t.horizon);material.set_shader_parameter("cloud_tint",t.cloud)
 env.fog_light_color=t.fog;env.ambient_light_color=t.ambient
 for light in game.world.get_children():
  if light is DirectionalLight3D:light.light_color=t.sunlight;light.sky_mode=DirectionalLight3D.SKY_MODE_LIGHT_ONLY
 var floor=ForestAtmosphere.floor_material()
 for key in ["moss_low","moss_high","soil","stone_low","stone_high"]:floor.set_shader_parameter(key,t.get(key))
 ForestAtmosphere.grass_material().set_shader_parameter("color_gradient",gradient(game.stage))
static func decor(base: Mesh,stage: int,rock: bool=false) -> Mesh:
 if index(stage)==0:return base
 var key=str(base.get_instance_id())+":"+str(index(stage))+":"+str(rock)
 if mesh_cache.has(key):return mesh_cache[key]
 var mesh=base.duplicate() as ArrayMesh;var t=config(stage)
 for i in mesh.get_surface_count():
  var original=base.surface_get_material(i) as BaseMaterial3D
  if original==null:continue
  var material_key=str(original.get_instance_id())+":"+str(index(stage))+":"+str(rock)
  if not material_cache.has(material_key):
   var material=ShaderMaterial.new();material.shader=preload("res://shaders/stage_vegetation.gdshader")
   material.set_shader_parameter("base_texture",original.albedo_texture);material.set_shader_parameter("has_texture",original.albedo_texture!=null);material.set_shader_parameter("base_color",original.albedo_color)
   material.set_shader_parameter("foliage",t.foliage);material.set_shader_parameter("strength",t.foliage_strength);material.set_shader_parameter("rock",rock);material.set_shader_parameter("rock_tint",t.rock_tint)
   material_cache[material_key]=material
  mesh.surface_set_material(i,material_cache[material_key])
 mesh_cache[key]=mesh;return mesh
static func reset() -> void:
 mesh_cache.clear();material_cache.clear();gradients.clear()

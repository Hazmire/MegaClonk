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
 ForestAtmosphere.apply(env,false)
 GrimdarkWorld.apply_sky(game,env)
 env.fog_light_color=t.fog;env.ambient_light_color=t.ambient
 for light in game.world.get_children():
  if light is DirectionalLight3D:light.light_color=t.sunlight;light.sky_mode=DirectionalLight3D.SKY_MODE_LIGHT_ONLY
 var floor=ForestAtmosphere.floor_material()
 for key in ["moss_low","moss_high","soil","stone_low","stone_high"]:floor.set_shader_parameter(key,t.get(key))
 ForestAtmosphere.grass_material().set_shader_parameter("color_gradient",gradient(game.stage))
static func decor(base: Mesh,stage: int,rock: bool=false) -> Mesh:
 return GrimdarkMaterials.mesh(base,stage,not rock)
static func reset() -> void:
 mesh_cache.clear();material_cache.clear();gradients.clear();ArtResetWorld.reset()

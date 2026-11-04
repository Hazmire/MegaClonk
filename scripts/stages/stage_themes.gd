class_name StageThemes
extends RefCounted
# Explicit three-theme cycle for stages beyond three; no new gameplay biome.
const THEMES=[preload("res://assets/themes/green.tres"),preload("res://assets/themes/violet.tres"),preload("res://assets/themes/crimson.tres")]
static var mesh_cache: Dictionary={}
static var material_cache: Dictionary={}
static var gradients: Dictionary={}
# Prop style (tree/rock/grass variants, foliage tint) follows the stage dressing: Hollow living, Route 9 withering, Downtown and the Sinkhole dead.
static func index(stage: int) -> int:return clampi(StageDressing.for_stage(stage).prop_style,0,THEMES.size()-1)
static func title(stage: int) -> String:return StageDressing.for_stage(stage).title.to_upper()
static func config(stage: int) -> StageTheme:return THEMES[index(stage)]
static func gradient(stage: int) -> GradientTexture1D:
 var key=index(stage)
 if not gradients.has(key):
  var texture=GradientTexture1D.new();var colors=Gradient.new();colors.set_color(0,config(stage).grass_low);colors.set_color(1,config(stage).grass_high);texture.gradient=colors;gradients[key]=texture
 return gradients[key]
static func decor(base: Mesh,stage: int,rock: bool=false) -> Mesh:
 return GrimdarkMaterials.mesh(base,stage,not rock)
static func reset() -> void:
 mesh_cache.clear();material_cache.clear();gradients.clear();ArtResetWorld.reset()

class_name StageDressing
extends Resource
# One Calvary Run look per stage (sky, ground, fog, light, fog wall, weather, backdrop rings, footsteps).
# Values come from docs/stage_dressing/stage_dressing.json via tools/build_stage_dressings.gd; nothing here is hard-coded per stage.
const COUNT=4
const PATH="res://assets/stage_dressing/stage_%d.tres"
const RULES_PATH="res://assets/stage_dressing/rules.tres"
@export var stage_number=1
@export var title=""
@export var sky: Texture2D
@export var top: Texture2D
@export var side: Texture2D
@export var low: Texture2D
@export var torn_edge: Texture2D
@export var side_emission: Texture2D
@export var fog_color=Color.WHITE
@export var fog_density=0.005
@export var ambient_color=Color.WHITE
@export var ambient_energy=0.55
@export var sun_color=Color.WHITE
@export var sun_energy=0.7
@export var sun_rotation_deg=Vector3(-38,25,0)
@export var wall_color=Color.WHITE
@export var wall_glow_color=Color.BLACK
@export var wall_glow=0.0
@export var weather="rain"
@export var backdrop_far: Texture2D
@export var backdrop_mid: Texture2D
@export var backdrop_near: Texture2D
@export var footsteps="dirt"
# Prop look (tree/rock/grass variants) that goes with this dressing, until stage-specific props exist: 0 living, 1 withering, 2 dead.
@export var prop_style=0
static var cache: Dictionary={}
static var rules_cache: StageDressingRules
static func rules() -> StageDressingRules:
 if rules_cache==null:rules_cache=load(RULES_PATH)
 return rules_cache
# Stages 1-4 use dressings 1-4; later stages cycle 2 -> 3 -> 4 (stage 5 = Route 9, 6 = Downtown, 7 = Sinkhole, 8 = Route 9 ...).
static func index(stage: int) -> int:
 var s=maxi(1,stage)
 return s-1 if s<=COUNT else 1+posmod(s-2,COUNT-1)
static func for_stage(stage: int) -> StageDressing:
 var i=index(stage)
 if not cache.has(i):cache[i]=load(PATH%(i+1))
 return cache[i]
func backdrop(layer: int) -> Texture2D:return [backdrop_far,backdrop_mid,backdrop_near][layer]

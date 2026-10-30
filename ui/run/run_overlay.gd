class_name RunOverlay
extends ColorRect
# The one fog overlay for a run: scanlines and vignette always on, `low_hp` while HP <= 30% and `stopwatch` while hostile
# time is slowed or frozen (Stopwatch / Hourglass, both reported by WorldTime.active()). It sits above the HUD and below the
# pause / reward screens, so those never get a second overlay. Presentation only; nothing here touches gameplay.
const LOW_HP_FRACTION=0.30
const FADE_RATE=4.0
var shader_material: ShaderMaterial
var low_hp=0.0
var stopwatch=0.0
var hurt=0.0 # red flash after the player is hit; decays in ~0.4 s
var seen_hurts=0
func _init() -> void:
 name="RunFogOverlay";color=Color.WHITE;mouse_filter=Control.MOUSE_FILTER_IGNORE;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shader_material=MenuStyle.shader_material("res://ui/shaders/fog_overlay.gdshader",{"vignette_strength":0.42,"vignette_start":0.62});material=shader_material
static func wants_low_hp(health: float,max_health: float) -> bool:return max_health>0.0 and health>0.0 and health/max_health<=LOW_HP_FRACTION
# Called from the HUD refresh with real frame time.
func sync(game: Node,delta: float) -> void:
 low_hp=move_toward(low_hp,1.0 if wants_low_hp(game.health,float(game.stats.max_health)) else 0.0,delta*FADE_RATE)
 stopwatch=move_toward(stopwatch,1.0 if game.world_time.active() else 0.0,delta*FADE_RATE)
 if int(game.hurt_events)!=seen_hurts:seen_hurts=int(game.hurt_events);hurt=1.0
 hurt=move_toward(hurt,0.0,delta*2.5);shader_material.set_shader_parameter("hurt",hurt)
 shader_material.set_shader_parameter("low_hp",low_hp);shader_material.set_shader_parameter("stopwatch",stopwatch)
func reset() -> void:
 low_hp=0.0;stopwatch=0.0;hurt=0.0;shader_material.set_shader_parameter("hurt",0.0);shader_material.set_shader_parameter("low_hp",0.0);shader_material.set_shader_parameter("stopwatch",0.0)
func _exit_tree() -> void:
 material=null;shader_material=null

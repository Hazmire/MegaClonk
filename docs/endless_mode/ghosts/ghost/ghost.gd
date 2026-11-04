## Megaclonk — endless-mode ghost. Flies straight at its target and banks into turns.
## Drop ghost.tscn into the spawner, set `tier` and `target`. Movement here is a reference: if the game's
## enemy code already moves enemies, keep only the visuals (mesh + tier material) and `set_fade()`.
extends Node3D

const GhostMesh := preload("res://ghost/ghost_mesh.gd")
const SHADER := preload("res://ghost/ghost.gdshader")

## Tier look. Each tier is louder and more solid than the last.
const TIERS := {
	"mourner":  {"body": Color("6E7C78"), "rim": Color("C8D6D0"), "eye": Color("E8F4F0"), "opacity": 0.75, "core": 0.28, "rim_power": 1.4, "wobble": 1.0, "speed": 1.0, "scale": 1.0},
	"drowned":  {"body": Color("3E5A2A"), "rim": Color("9AB86A"), "eye": Color("E8FF7A"), "opacity": 0.7, "core": 0.32, "rim_power": 1.6, "wobble": 1.1, "speed": 1.15, "scale": 1.05},
	"wrathful": {"body": Color("5A0A08"), "rim": Color("D8341E"), "eye": Color("FFB040"), "opacity": 0.8, "core": 0.48, "rim_power": 2.2, "wobble": 1.3, "speed": 1.35, "scale": 1.12},
	"hollow":   {"body": Color("0A080C"), "rim": Color("B3363F"), "eye": Color("FFFFFF"), "opacity": 1.0, "core": 0.92, "rim_power": 5.0, "wobble": 0.8, "speed": 0.8, "scale": 1.3},
}

static var _mesh: ArrayMesh
static var _mats := {}

@export_enum("mourner", "drowned", "wrathful", "hollow") var tier := "mourner":
	set(v):
		tier = v
		if is_inside_tree(): _apply_tier()
@export var speed := 7.0
@export var turn_rate := 3.0
var target: Node3D
var velocity := Vector3.ZERO
var _mi: MeshInstance3D
var _fade := 0.0


static func material(t: String) -> ShaderMaterial:
	if not _mats.has(t):
		var d: Dictionary = TIERS[t]
		var m := ShaderMaterial.new(); m.shader = SHADER
		m.set_shader_parameter("body_color", d.body); m.set_shader_parameter("rim_color", d.rim)
		m.set_shader_parameter("eye_color", d.eye); m.set_shader_parameter("opacity", d.opacity); m.set_shader_parameter("core", d.core); m.set_shader_parameter("rim_power", d.rim_power)
		m.set_shader_parameter("wobble", d.wobble); m.set_shader_parameter("speed", d.speed)
		_mats[t] = m
	return _mats[t]


func _ready() -> void:
	if _mesh == null: _mesh = GhostMesh.build()
	_mi = MeshInstance3D.new(); _mi.mesh = _mesh
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mi)
	_apply_tier()


func _apply_tier() -> void:
	# per-ghost fade needs its own material copy only while fading; tiers otherwise share one material
	_mi.material_override = material(tier)
	_mi.scale = Vector3.ONE * TIERS[tier].scale


## 0 = invisible, 1 = fully there. Use it for a quick spawn fade-in and death fade-out. While fading the
## ghost holds its own material copy; at 1.0 it goes back to the shared tier material.
func set_fade(f: float) -> void:
	_fade = clampf(f, 0.0, 1.0)
	if _fade >= 1.0:
		_mi.material_override = material(tier)
		return
	if _mi.material_override == material(tier):
		_mi.material_override = material(tier).duplicate()
	(_mi.material_override as ShaderMaterial).set_shader_parameter("fade", _fade)


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target): return
	var to := (target.global_position + Vector3(0, 1.0, 0)) - global_position
	var want := to.normalized() * speed
	velocity = velocity.lerp(want, clampf(turn_rate * delta, 0.0, 1.0))
	global_position += velocity * delta
	if velocity.length() > 0.1:
		var fwd := velocity.normalized()
		var bank := clampf(-fwd.cross(want.normalized()).y * 2.0, -0.6, 0.6)
		look_at(global_position + fwd, Vector3.UP)
		rotate_object_local(Vector3.FORWARD, bank)

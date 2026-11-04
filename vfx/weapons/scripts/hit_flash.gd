## Megaclonk — flashes a mesh a solid colour for a moment (white on hit,
## green for Aura ticks, orange for burns).
##
## Usage:
##     const HitFlash := preload("res://vfx/weapons/scripts/hit_flash.gd")
##     HitFlash.flash($EnemyMesh)                       # white, 0.12 s
##     HitFlash.flash($EnemyMesh, Color(0.6, 1, 0.5))   # Aura green
extends RefCounted

const SHADER := preload("res://vfx/weapons/shaders/hit_flash.gdshader")


static func flash(target: GeometryInstance3D, color: Color = Color.WHITE, duration: float = 0.12) -> void:
	if target == null or not is_instance_valid(target):
		return
	var mat := target.material_overlay as ShaderMaterial
	if mat == null or mat.shader != SHADER:
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		target.material_overlay = mat
	mat.set_shader_parameter("flash_color", color)
	mat.set_shader_parameter("amount", 1.0)
	var tw := target.create_tween()
	tw.tween_interval(duration * 0.5)
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter("amount", v), 1.0, 0.0, duration * 0.5)

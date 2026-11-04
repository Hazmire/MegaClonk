## Megaclonk — Sword slash: a hard-edged white crescent swept in front of the
## player on stepped (PSX-style) frames, with speed streaks flying off.
##
## Parent it to the player at chest height, facing forward (-Z = forward).
##     $SwordSlash.look_at(closest_enemy.global_position)
##     await $SwordSlash.burst(projectile_count)   # then start the cooldown
## `slash_hit` fires on each slash at the moment the sweep completes —
## a good place to apply damage and flash the enemy.
extends Node3D

signal slash_hit

@export var radius := 2.0
@export var thickness := 0.55
@export var arc_degrees := 160.0
@export var segments := 18
@export var steps := 5
@export var step_time := 0.022
@export var hold_time := 0.05
@export var fade_steps := 3
@export var fade_time := 0.06
@export var burst_gap := 0.03
@export var blade_color := Color(0.96, 0.97, 0.95, 1.0)
@export var edge_color := Color(0.75, 0.88, 1.0, 1.0)
@export var rim_color := Color(0.05, 0.06, 0.05, 1.0)
@export var slash_material: Material

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	var arc := $Arc as MeshInstance3D
	arc.mesh = _mesh
	arc.material_override = slash_material


func slash(flip := false, tilt_degrees := 0.0) -> void:
	var arc := $Arc as Node3D
	arc.rotation = Vector3(0.0, 0.0, deg_to_rad(tilt_degrees))
	arc.scale = Vector3(-1.0 if flip else 1.0, 1.0, 1.0)
	for s in range(1, steps + 1):
		_build(float(s) / steps, 1.0)
		await get_tree().create_timer(step_time).timeout
	var p := get_node_or_null("Streaks") as GPUParticles3D
	if p:
		p.restart()
	slash_hit.emit()
	await get_tree().create_timer(hold_time).timeout
	for i in fade_steps:
		_build(1.0, 1.0 - float(i + 1) / (fade_steps + 1))
		await get_tree().create_timer(fade_time / fade_steps).timeout
	_mesh.clear_surfaces()


func burst(count: int) -> void:
	for i in maxi(count, 1):
		await slash(i % 2 == 1, (28.0 if i % 2 == 0 else -28.0) + randf_range(-6.0, 6.0))
		await get_tree().create_timer(burst_gap).timeout


func _build(frac: float, alpha: float) -> void:
	_mesh.clear_surfaces()
	var half := deg_to_rad(arc_degrees) * 0.5
	var n := maxi(int(segments * frac), 1)
	_band(n, frac, half, -0.09, -0.04, rim_color, alpha, false)
	_band(n, frac, half, -0.04, 0.0, edge_color, alpha, false)
	_band(n, frac, half, 0.0, 0.0, blade_color, alpha, true)


func _band(n: int, frac: float, half: float, off_out: float, off_in: float, col: Color, alpha: float, crescent: bool) -> void:
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var c := Color(col.r, col.g, col.b, col.a * alpha)
	for i in n + 1:
		var u := float(i) / n * frac
		var a := -half + u * half * 2.0
		var dir := Vector3(sin(a), 0.0, -cos(a))
		var r_out := radius - off_out
		var r_in := radius - off_in
		if crescent:
			r_in = radius - thickness * sin(PI * u)
		_mesh.surface_set_color(c)
		_mesh.surface_add_vertex(dir * r_out)
		_mesh.surface_set_color(c)
		_mesh.surface_add_vertex(dir * r_in)
	_mesh.surface_end()

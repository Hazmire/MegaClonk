## Megaclonk — Lightning Staff strike.
##
##     var s := preload("res://vfx/weapons/effects/lightning_strike.tscn").instantiate()
##     get_tree().current_scene.add_child(s)
##     s.strike(enemy_head_position)                 # bolt from the sky
##     s.strike_between(enemy_a_head, enemy_b_head)  # a bounce between enemies
##
## The bolt is a camera-facing jagged ribbon (blue outer, white core) that
## re-jitters every few frames and flickers out. Sparks, a ring and a blue
## light pop at the impact point. Flash the struck enemy white with hit_flash.gd.
extends Node3D

@export var height := 14.0
@export var segments := 10
@export var jitter := 0.6
@export var outer_width := 0.42
@export var inner_width := 0.14
@export var outer_color := Color(0.24, 0.5, 0.84, 1.0)
@export var inner_color := Color(0.87, 0.95, 1.0, 1.0)
@export var duration := 0.24
@export var rejitter_time := 0.05
@export var auto_free := true
@export var bolt_material: Material

var _a := Vector3.ZERO
var _b := Vector3.ZERO
var _t := 0.0
var _jt := 0.0
var _active := false
var _mesh := ImmediateMesh.new()
var _pts := PackedVector3Array()
var _fork := PackedVector3Array()


func strike(target: Vector3) -> void:
	strike_between(target + Vector3(0, height, 0), target)


func strike_between(from: Vector3, to: Vector3) -> void:
	global_position = to
	_a = from - to
	_b = Vector3.ZERO
	var bolt := $Bolt as MeshInstance3D
	bolt.mesh = _mesh
	bolt.material_override = bolt_material
	_t = 0.0
	_jt = 0.0
	_active = true
	_make_points()
	_draw(1.0)
	for c in get_children():
		if c is GPUParticles3D:
			c.restart()
	var light := get_node_or_null("Light") as OmniLight3D
	if light:
		light.light_energy = 8.0
		create_tween().tween_property(light, "light_energy", 0.0, duration * 1.6)
	var ring := get_node_or_null("Ring") as MeshInstance3D
	if ring:
		var src := ring.get_active_material(0) as StandardMaterial3D
		var mat := src.duplicate() as StandardMaterial3D
		ring.material_override = mat
		var base := mat.albedo_color
		ring.scale = Vector3.ONE * 0.2
		ring.visible = true
		var tw := create_tween().set_parallel(true)
		tw.tween_property(ring, "scale", Vector3.ONE * 2.4, 0.3)
		tw.tween_method(func(a: float) -> void: mat.albedo_color = Color(base.r, base.g, base.b, a), 1.0, 0.0, 0.3)
	if auto_free:
		get_tree().create_timer(maxf(duration, 0.6) + 0.4).timeout.connect(queue_free)


func _ready() -> void:
	var ring := get_node_or_null("Ring") as MeshInstance3D
	if ring:
		ring.visible = false


func _make_points() -> void:
	_pts = PackedVector3Array()
	var axis := _b - _a
	var ref := Vector3.FORWARD if absf(axis.normalized().dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var perp1 := axis.cross(ref).normalized()
	var perp2 := axis.cross(perp1).normalized()
	for i in segments + 1:
		var k := float(i) / segments
		var p := _a.lerp(_b, k)
		if i != 0 and i != segments:
			var j := jitter * sin(PI * k)
			p += perp1 * randf_range(-j, j) + perp2 * randf_range(-j, j)
		_pts.append(p)
	var fi := int(segments * randf_range(0.3, 0.6))
	_fork = PackedVector3Array([_pts[fi]])
	var fdir := (perp1 * randf_range(-1.0, 1.0) + axis.normalized() * 0.6).normalized()
	var fp := _pts[fi]
	for i in 3:
		fp += fdir * (axis.length() * 0.06) + perp2 * randf_range(-0.2, 0.2)
		_fork.append(fp)


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	_jt += delta
	if _jt >= rejitter_time:
		_jt = 0.0
		_make_points()
	var k := _t / duration
	if k >= 1.0:
		_active = false
		_mesh.clear_surfaces()
		return
	var a := 1.0 - k * k
	if k > 0.25 and k < 0.38:
		a *= 0.25
	_draw(a)


func _draw(alpha: float) -> void:
	_mesh.clear_surfaces()
	var cam := get_viewport().get_camera_3d()
	var cam_local := to_local(cam.global_position) if cam else Vector3(0, 0, 10)
	_strip(_pts, outer_width, outer_color, alpha, cam_local)
	_strip(_pts, inner_width, inner_color, alpha, cam_local)
	_strip(_fork, outer_width * 0.6, outer_color, alpha * 0.8, cam_local)
	_strip(_fork, inner_width * 0.6, inner_color, alpha * 0.8, cam_local)


func _strip(pts: PackedVector3Array, w: float, col: Color, alpha: float, cam_local: Vector3) -> void:
	if pts.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var c := Color(col.r, col.g, col.b, col.a * alpha)
	for i in pts.size():
		var p: Vector3 = pts[i]
		var d: Vector3 = (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var to_cam := (cam_local - p).normalized()
		var side := d.cross(to_cam).normalized() * w * 0.5
		_mesh.surface_set_color(c)
		_mesh.surface_add_vertex(p - side)
		_mesh.surface_set_color(c)
		_mesh.surface_add_vertex(p + side)
	_mesh.surface_end()

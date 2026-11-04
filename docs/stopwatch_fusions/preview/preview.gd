## Megaclonk — weapon VFX preview stage.
## Run the project and pass the weapon after `--`:
##     godot --path . -- weapon=firestaff
## Weapons: lightning, bow, revolver, aura, scythes, shotgun, sword, firestaff
extends Node3D

const FX := "res://vfx/weapons/effects/"
const HitFlash := preload("res://vfx/weapons/scripts/hit_flash.gd")

var weapon := "firestaff"
var element := ""
var layer
var player: MeshInstance3D
var cam: Camera3D


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("weapon="):
			weapon = a.substr(7)
		if a.begins_with("element="):
			element = a.substr(8)
	_stage()
	layer = load("res://vfx/weapons/scripts/element_layer.gd").new()
	add_child(layer)
	layer.setup(element)
	_run.call_deferred()


func _stage() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.47, 0.52, 0.49)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.6, 0.57)
	e.ambient_light_energy = 0.9
	e.fog_enabled = true
	e.fog_light_color = Color(0.47, 0.52, 0.49)
	e.fog_density = 0.022
	e.glow_enabled = true
	e.glow_intensity = 0.8
	e.glow_bloom = 0.1
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 0.5
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(80, 80)
	ground.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.13, 0.16, 0.13)
	gm.roughness = 1.0
	ground.material_override = gm
	add_child(ground)
	player = _dummy(Vector3.ZERO, Color(0.85, 0.83, 0.77), false)
	cam = Camera3D.new()
	cam.fov = 42.0
	add_child(cam)
	frame(Vector3(1.5, 4.5, 9.5), Vector3(3.6, 0.9, 0))


func frame(pos: Vector3, look: Vector3) -> void:
	cam.position = pos
	cam.look_at(look)


func _dummy(pos: Vector3, col: Color, is_enemy := true) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var c := CapsuleMesh.new()
	c.radius = 0.32
	c.height = 1.75
	m.mesh = c
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 1.0
	m.material_override = mat
	m.position = pos + Vector3(0, 0.875, 0)
	add_child(m)
	if is_enemy:
		for sz in [-0.1, 0.1]:
			var eye := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(0.07, 0.05, 0.05)
			eye.mesh = b
			var em := StandardMaterial3D.new()
			em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			em.albedo_color = Color(0.9, 0.2, 0.2)
			eye.material_override = em
			eye.position = Vector3(-0.29, 0.55, sz)
			m.add_child(eye)
	return m


func enemy(x: float, z: float) -> MeshInstance3D:
	return _dummy(Vector3(x, 0, z), Color(0.22, 0.25, 0.22))


func fx(fname: String):
	var n = load(FX + fname + ".tscn").instantiate()
	add_child(n)
	if element != "":
		layer.tint(n)
		if fname in ["bow_arrow", "revolver_bullet", "fireball", "scythe_projectile"]:
			layer.trail(n)
	return n


func wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func flash(m: MeshInstance3D, col := Color.WHITE, d := 0.14) -> void:
	if element == "":
		HitFlash.flash(m, col, d)
		return
	HitFlash.flash(m, Color.WHITE, 0.08)
	layer.impact(m.global_position + Vector3(0, 0.25, 0))
	get_tree().create_timer(0.08).timeout.connect(func() -> void: layer.status(m))


func knock(m: Node3D, dir: Vector3, dist := 0.5, t := 0.12) -> void:
	var home: Vector3 = m.get_meta("home", m.position)
	m.set_meta("home", home)
	var tw := create_tween()
	tw.tween_property(m, "position", home + dir * dist, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_property(m, "position", home, 0.4)


func head(m: Node3D) -> Vector3:
	return m.global_position + Vector3(0, 0.8, 0)


func chest(m: Node3D) -> Vector3:
	return m.global_position + Vector3(0, 0.25, 0)


func _run() -> void:
	match weapon:
		"lightning": await _lightning()
		"bow": await _bow()
		"revolver": await _revolver()
		"aura": await _aura()
		"scythes": await _scythes()
		"shotgun": await _shotgun()
		"sword": await _sword()
		_: await _firestaff()


func _lightning() -> void:
	frame(Vector3(2.2, 4.4, 11.5), Vector3(4.8, 2.4, 0))
	var es := [enemy(4.0, 0.0), enemy(5.6, -1.0), enemy(7.0, 0.8)]
	await wait(0.2)
	while true:
		for i in es.size():
			var s = fx("lightning_strike")
			s.strike(head(es[i]))
			flash(es[i], Color.WHITE, 0.16)
			if i == 1:
				await wait(0.12)
				var b = fx("lightning_strike")
				b.strike_between(head(es[1]), head(es[2]))
				flash(es[2], Color.WHITE, 0.16)
			await wait(0.5)
		await wait(0.5)


func _bow() -> void:
	frame(Vector3(1.6, 3.6, 7.5), Vector3(3.4, 1.0, 0))
	var es := [enemy(3.4, 0), enemy(4.9, 0), enemy(6.4, 0)]
	var origin := Vector3(0.5, 1.25, 0)
	await wait(0.2)
	while true:
		for ang in [-9.0, 0.0, 9.0]:
			var a = fx("bow_arrow")
			a.global_position = origin
			var dir := Vector3.RIGHT.rotated(Vector3.UP, deg_to_rad(ang))
			a.look_at(origin + dir)
		for e in es:
			var t: float = (e.global_position.x - origin.x) / 30.0
			get_tree().create_timer(t).timeout.connect(func() -> void:
				flash(e)
				knock(e, Vector3.RIGHT, 0.25))
		await wait(1.5)


func _revolver() -> void:
	frame(Vector3(2.6, 3.6, 8.5), Vector3(4.2, 1.0, 0.4))
	var e1 := enemy(6.0, 0.0)
	var e2 := enemy(7.4, 1.6)
	var muzzle := Vector3(0.55, 1.3, 0)
	await wait(0.2)
	while true:
		var m = fx("revolver_muzzle")
		m.global_position = muzzle
		m.look_at(muzzle + Vector3.RIGHT)
		var tgt := chest(e1) + Vector3(0, 0.15, 0)
		var b = fx("revolver_bullet")
		b.global_position = muzzle
		b.look_at(tgt)
		b.max_distance = muzzle.distance_to(tgt)
		await b.arrived
		var s = fx("impact_sparks")
		s.global_position = tgt
		flash(e1)
		knock(e1, Vector3.RIGHT, 0.25)
		var t2 := chest(e2) + Vector3(0, 0.15, 0)
		var b2 = fx("revolver_bullet")
		b2.global_position = tgt
		b2.look_at(t2)
		b2.max_distance = tgt.distance_to(t2)
		await b2.arrived
		var s2 = fx("impact_sparks")
		s2.global_position = t2
		flash(e2)
		knock(e2, Vector3(1, 0, 1).normalized(), 0.25)
		await wait(1.3)


func _aura() -> void:
	frame(Vector3(0.0, 6.0, 8.5), Vector3(0.4, 0.2, 0))
	var a = fx("aura")
	a.global_position = Vector3.ZERO
	a.radius = 3.0
	var inside := [enemy(2.0, 1.2), enemy(-1.8, -1.0), enemy(2.3, -1.4)]
	enemy(5.4, 0.4)
	a.pulsed.connect(func() -> void:
		for e in inside:
			flash(e, Color(0.6, 1.0, 0.5), 0.22))
	while true:
		await wait(10.0)


func _scythes() -> void:
	frame(Vector3(1.8, 5.5, 9.0), Vector3(3.4, 0.6, 0))
	var es := [enemy(3.4, 0.0), enemy(5.9, 0.4)]
	await wait(0.2)
	while true:
		var s = fx("scythe_projectile")
		s.global_position = Vector3(0.5, 1.1, 0)
		s.launch(player, Vector3.RIGHT)
		var near := {}
		while is_instance_valid(s):
			for e in es:
				var d := Vector2(s.global_position.x - e.global_position.x, s.global_position.z - e.global_position.z).length()
				if d < 0.7 and not near.get(e, false):
					near[e] = true
					flash(e)
					knock(e, Vector3.LEFT if s.returning else Vector3.RIGHT, 0.2)
				elif d > 1.3:
					near[e] = false
			await get_tree().process_frame
		await wait(0.45)


func _shotgun() -> void:
	frame(Vector3(1.6, 3.8, 8.5), Vector3(3.2, 0.9, 0))
	var close := [enemy(2.6, 0.4), enemy(3.3, -0.5)]
	enemy(8.0, 0.0)
	var muzzle := Vector3(0.55, 1.2, 0)
	await wait(0.2)
	while true:
		var b = fx("shotgun_blast")
		b.global_position = muzzle
		b.look_at(muzzle + Vector3.RIGHT)
		await wait(0.04)
		for e in close:
			flash(e)
			knock(e, Vector3.RIGHT, 0.7, 0.1)
		await wait(1.3)


func _sword() -> void:
	frame(Vector3(-2.6, 3.6, 3.8), Vector3(1.4, 1.0, 0))
	var e := enemy(2.0, 0.0)
	var s = fx("sword_slash")
	s.global_position = Vector3(0.2, 1.1, 0)
	s.look_at(Vector3(2.0, 1.1, 0))
	s.slash_hit.connect(func() -> void:
		flash(e)
		knock(e, Vector3.RIGHT, 0.3, 0.06))
	await wait(0.2)
	while true:
		await s.burst(3)
		await wait(1.0)


func _firestaff() -> void:
	frame(Vector3(3.2, 3.6, 8.5), Vector3(3.9, 1.0, 0))
	var e := enemy(7.0, 0.0)
	var start := Vector3(0.6, 1.5, 0)
	await wait(0.2)
	while true:
		var tgt := chest(e) + Vector3(0, 0.1, 0)
		var f = fx("fireball")
		f.global_position = start
		f.look_at(tgt)
		f.max_distance = start.distance_to(tgt) - 0.3
		await f.arrived
		var imp = fx("fire_impact")
		imp.global_position = tgt + Vector3(-0.3, 0, 0)
		flash(e, Color.WHITE, 0.1)
		knock(e, Vector3.RIGHT, 0.6, 0.1)
		await wait(0.1)
		flash(e, Color(1.0, 0.55, 0.2), 0.35)
		await wait(1.4)

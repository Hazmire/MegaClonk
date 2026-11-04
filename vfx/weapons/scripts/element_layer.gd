## Megaclonk — Elemental imbue layer for weapon VFX.
##
## One script adds a socketed gem's look on top of ANY weapon effect, so 8 weapons x 4 gems
## does not need 32 hand-made effects:
##   1. tint(effect)    recolours the weapon's own particles, meshes and lights toward the gem
##                      palette (65% by default), so the weapon keeps its shape but reads as
##                      "Fire Sword" / "Ice Bow" and so on.
##   2. trail(node)     adds a small element emitter to anything that moves (arrows, bullets,
##                      fireballs, scythes, slashes): embers, frost motes, acid drips or sparks.
##   3. impact(pos)     plays the element's hit burst: flame puff, ice shards + frost ring,
##                      acid splash + puddle, or forked arcs.
##   4. status(enemy)   the matching status look on the enemy: burning, chilled, poisoned, shocked.
##
## Everything is pooled-friendly: emitters are GPUParticles3D with shared materials, impacts are
## one-shots that free themselves, and no per-hit materials are created except the enemy tint.
extends Node3D

const PAL := {
	"fire":      {"core": Color("FFE08A"), "mid": Color("FF8A3D"), "deep": Color("C9461A")},
	"ice":       {"core": Color("EAF7FF"), "mid": Color("9FD8F0"), "deep": Color("3D7FA6")},
	"corrosive": {"core": Color("D8FFB0"), "mid": Color("79B35F"), "deep": Color("2F6B2A")},
	"electric":  {"core": Color("F2E8FF"), "mid": Color("A487DA"), "deep": Color("5A2F8A")},
}

var element := ""
var tint_amount := 0.65
var _quad_cache := {}


func setup(e: String) -> void:
	element = e


func pal(key: String) -> Color:
	return PAL[element][key]


# ------------------------------------------------------------------ 1. tint
func tint(n: Node) -> void:
	if element == "":
		return
	for c in _walk(n):
		if c is GPUParticles3D:
			var pm := (c as GPUParticles3D).process_material as ParticleProcessMaterial
			if pm:
				pm = pm.duplicate()
				pm.color = (pm.color as Color).lerp(pal("mid"), tint_amount)
				if pm.color_ramp:
					pm.color_ramp = _ramp(pm.color_ramp.gradient if pm.color_ramp is GradientTexture1D else null)
				c.process_material = pm
			_tint_mesh_material(c.draw_pass_1)
		elif c is MeshInstance3D:
			var m := (c as MeshInstance3D).get_active_material(0)
			if m is StandardMaterial3D:
				var d: StandardMaterial3D = m.duplicate()
				d.albedo_color = Color((d.albedo_color as Color).lerp(pal("core") if d.albedo_color.v > 0.7 else pal("mid"), tint_amount), d.albedo_color.a)
				if d.emission_enabled:
					d.emission = (d.emission as Color).lerp(pal("mid"), tint_amount)
				c.material_override = d
		elif c is OmniLight3D:
			c.light_color = (c.light_color as Color).lerp(pal("mid"), 0.8)


func _tint_mesh_material(mesh: Mesh) -> void:
	if mesh == null:
		return
	for i in mesh.get_surface_count():
		var m := mesh.surface_get_material(i)
		if m is StandardMaterial3D and not m.vertex_color_use_as_albedo:
			var d: StandardMaterial3D = m.duplicate()
			d.albedo_color = Color((d.albedo_color as Color).lerp(pal("mid"), tint_amount), d.albedo_color.a)
			mesh.surface_set_material(i, d)


func _ramp(_src: Gradient) -> GradientTexture1D:
	var g := Gradient.new()
	g.set_color(0, pal("core"))
	g.set_color(1, Color(pal("deep"), 0.0))
	g.add_point(0.45, pal("mid"))
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _walk(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_walk(c))
	return out


# ------------------------------------------------------------------ helpers
func _quad(size: float, stretch := 1.0, fixed_y := false) -> QuadMesh:
	var key := "%s_%s_%s" % [size, stretch, fixed_y]
	if _quad_cache.has(key):
		return _quad_cache[key]
	var q := QuadMesh.new()
	q.size = Vector2(size, size * stretch)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y if fixed_y else BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	q.material = m
	_quad_cache[key] = q
	return q


func _emitter(amount: int, life: float, size: float, one_shot: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.one_shot = one_shot
	p.explosiveness = 1.0 if one_shot else 0.0
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-6, -6, -6), Vector3(12, 12, 12))
	var pm := ParticleProcessMaterial.new()
	pm.color_ramp = _ramp(null)
	pm.scale_min = 0.7
	pm.scale_max = 1.3
	p.process_material = pm
	p.draw_pass_1 = _quad(size)
	return p


func _light(pos: Vector3, energy: float, rng: float, fade: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = pal("mid")
	l.light_energy = energy
	l.omni_range = rng
	add_child(l)
	l.global_position = pos
	var tw := l.create_tween()
	tw.tween_property(l, "light_energy", 0.0, fade)
	tw.tween_callback(l.queue_free)


func _free_later(n: Node, t: float) -> void:
	get_tree().create_timer(t).timeout.connect(func() -> void:
		if is_instance_valid(n): n.queue_free())


# ------------------------------------------------------------------ 2. trail
func trail(n: Node3D, strength := 1.0) -> void:
	if element == "":
		return
	var p: GPUParticles3D
	var pm: ParticleProcessMaterial
	match element:
		"fire":
			p = _emitter(int(46 * strength), 0.55, 0.09, false)
			pm = p.process_material; pm.gravity = Vector3(0, 2.2, 0); pm.spread = 180; pm.initial_velocity_min = 0.3; pm.initial_velocity_max = 1.2
		"ice":
			p = _emitter(int(36 * strength), 0.8, 0.07, false)
			pm = p.process_material; pm.gravity = Vector3(0, -1.2, 0); pm.spread = 180; pm.initial_velocity_min = 0.1; pm.initial_velocity_max = 0.5
			pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE; pm.emission_sphere_radius = 0.15
		"corrosive":
			p = _emitter(int(28 * strength), 0.6, 0.11, false)
			pm = p.process_material; pm.gravity = Vector3(0, -9.0, 0); pm.spread = 30; pm.direction = Vector3(0, -1, 0); pm.initial_velocity_min = 0.0; pm.initial_velocity_max = 0.6
		"electric":
			p = _emitter(int(50 * strength), 0.18, 0.06, false)
			pm = p.process_material; pm.gravity = Vector3.ZERO; pm.spread = 180; pm.initial_velocity_min = 2.5; pm.initial_velocity_max = 5.0
	n.add_child(p)
	p.emitting = true


# ------------------------------------------------------------------ 3. impact
func impact(pos: Vector3) -> void:
	if element == "":
		return
	match element:
		"fire": _impact_fire(pos)
		"ice": _impact_ice(pos)
		"corrosive": _impact_corrosive(pos)
		"electric": _impact_electric(pos)


func _burst(pos: Vector3, amount: int, life: float, size: float, vmin: float, vmax: float, grav: Vector3, spread := 180.0, dir := Vector3.UP) -> void:
	var p := _emitter(amount, life, size, true)
	var pm: ParticleProcessMaterial = p.process_material
	pm.direction = dir; pm.spread = spread; pm.initial_velocity_min = vmin; pm.initial_velocity_max = vmax; pm.gravity = grav
	add_child(p)
	p.global_position = pos
	p.emitting = true
	_free_later(p, life + 0.3)


func _impact_fire(pos: Vector3) -> void:
	_burst(pos, 26, 0.5, 0.32, 0.6, 2.0, Vector3(0, 4.0, 0), 50.0)      # flame puff
	_burst(pos, 22, 0.9, 0.07, 2.0, 4.5, Vector3(0, -3.0, 0), 80.0)     # embers
	_light(pos, 5.0, 4.0, 0.35)


func _impact_ice(pos: Vector3) -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = pal("core")
	var r := RandomNumberGenerator.new()
	for i in 9:                                                        # shards flung outward
		var s := MeshInstance3D.new()
		var pr := PrismMesh.new(); pr.size = Vector3(0.08, 0.42, 0.06); s.mesh = pr
		s.material_override = m
		add_child(s)
		s.global_position = pos
		var d := Vector3(r.randf_range(-1, 1), r.randf_range(-0.1, 1), r.randf_range(-1, 1)).normalized()
		s.look_at(pos + d, Vector3.UP if abs(d.y) < 0.95 else Vector3.RIGHT)
		s.rotate_object_local(Vector3.RIGHT, -PI / 2)
		var tw := s.create_tween().set_parallel(true)
		tw.tween_property(s, "global_position", pos + d * r.randf_range(0.8, 1.4), 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(s, "scale", Vector3.ONE * 0.2, 0.5).set_delay(0.2)
		_free_later(s, 0.75)
	var ring := MeshInstance3D.new()                                    # frost ring on the ground
	var cy := CylinderMesh.new(); cy.top_radius = 0.6; cy.bottom_radius = 0.6; cy.height = 0.02; cy.radial_segments = 10
	ring.mesh = cy
	var rm := StandardMaterial3D.new(); rm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; rm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rm.albedo_color = Color(pal("mid"), 0.55); ring.material_override = rm
	add_child(ring); ring.global_position = Vector3(pos.x, 0.02, pos.z)
	ring.scale = Vector3(0.3, 1, 0.3)
	var t2 := ring.create_tween()
	t2.tween_property(ring, "scale", Vector3(2.0, 1, 2.0), 0.25).set_ease(Tween.EASE_OUT)
	t2.tween_interval(0.5)
	t2.tween_method(func(a: float) -> void: rm.albedo_color = Color(pal("mid"), a), 0.55, 0.0, 0.5)
	_free_later(ring, 1.4)
	_burst(pos, 18, 0.9, 0.06, 0.4, 1.6, Vector3(0, -1.5, 0))
	_light(pos, 3.0, 3.5, 0.3)


func _impact_corrosive(pos: Vector3) -> void:
	_burst(pos, 26, 0.7, 0.12, 2.0, 4.0, Vector3(0, -9.0, 0), 60.0)     # splash droplets
	var pud := MeshInstance3D.new()                                     # lingering puddle
	var cy := CylinderMesh.new(); cy.top_radius = 0.7; cy.bottom_radius = 0.7; cy.height = 0.02; cy.radial_segments = 9
	pud.mesh = cy
	var pm := StandardMaterial3D.new(); pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.albedo_color = Color(pal("deep"), 0.85); pud.material_override = pm
	add_child(pud); pud.global_position = Vector3(pos.x + 0.2, 0.02, pos.z)
	pud.scale = Vector3(0.1, 1, 0.1)
	var tw := pud.create_tween()
	tw.tween_property(pud, "scale", Vector3(1.6, 1, 1.2), 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.2)
	tw.tween_method(func(a: float) -> void: pm.albedo_color = Color(pal("deep"), a), 0.85, 0.0, 0.6)
	_free_later(pud, 2.4)
	_burst(Vector3(pos.x + 0.2, 0.1, pos.z), 12, 1.4, 0.09, 0.3, 0.8, Vector3(0, 0.6, 0), 25.0)   # bubbles
	_light(pos, 2.5, 3.0, 0.3)


func _impact_electric(pos: Vector3) -> void:
	var r := RandomNumberGenerator.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = pal("core")
	for i in 4:                                                       # forked arcs
		var im := ImmediateMesh.new()
		var mi := MeshInstance3D.new(); mi.mesh = im; mi.material_override = mat
		add_child(mi)
		var a := pos
		var b := pos + Vector3(r.randf_range(-1.6, 1.6), r.randf_range(-0.9, 0.8), r.randf_range(-1.6, 1.6))
		im.surface_begin(Mesh.PRIMITIVE_LINES)
		var prev := a
		for k in range(1, 7):
			var t := k / 6.0
			var p := a.lerp(b, t) + (Vector3(r.randf_range(-0.2, 0.2), r.randf_range(-0.2, 0.2), r.randf_range(-0.2, 0.2)) if k < 6 else Vector3.ZERO)
			for o in [Vector3.ZERO, Vector3(0, 0.02, 0), Vector3(0.02, 0, 0)]:
				im.surface_add_vertex(prev + o); im.surface_add_vertex(p + o)
			prev = p
		im.surface_end()
		var tw := mi.create_tween()
		for f in 3:
			tw.tween_callback(func() -> void: mi.visible = true)
			tw.tween_interval(0.05)
			tw.tween_callback(func() -> void: mi.visible = false)
			tw.tween_interval(0.04)
		tw.tween_callback(mi.queue_free)
	_burst(pos, 30, 0.22, 0.05, 4.0, 7.0, Vector3.ZERO)
	_light(pos, 6.0, 4.5, 0.25)


# ------------------------------------------------------------------ 4. status on the enemy
func status(enemy: GeometryInstance3D) -> void:
	if element == "" or not is_instance_valid(enemy):
		return
	var tint := StandardMaterial3D.new()
	tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tint.albedo_color = Color(pal("mid"), 0.0)
	tint.grow = true; tint.grow_amount = 0.01
	enemy.material_overlay = tint
	var tw := enemy.create_tween()
	match element:
		"fire":       # burning: orange flicker + embers rising off the body
			for f in 6:
				tw.tween_method(func(a: float) -> void: tint.albedo_color = Color(pal("mid"), a), 0.5, 0.15, 0.12)
			var p := _emitter(18, 0.8, 0.07, false); var pm: ParticleProcessMaterial = p.process_material
			pm.gravity = Vector3(0, 2.5, 0); pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pm.emission_box_extents = Vector3(0.25, 0.7, 0.25)
			enemy.add_child(p); p.emitting = true; _free_later(p, 1.6)
		"ice":        # chilled: holds a pale blue coat, then thaws
			tw.tween_method(func(a: float) -> void: tint.albedo_color = Color(pal("mid"), a), 0.0, 0.55, 0.1)
			tw.tween_interval(0.6)
			tw.tween_method(func(a: float) -> void: tint.albedo_color = Color(pal("mid"), a), 0.55, 0.0, 0.4)
		"corrosive":  # poisoned: sickly green pulse + bubbles
			for f in 3:
				tw.tween_method(func(a: float) -> void: tint.albedo_color = Color(pal("mid"), a), 0.45, 0.1, 0.25)
			var p := _emitter(10, 1.0, 0.08, false); var pm: ParticleProcessMaterial = p.process_material
			pm.gravity = Vector3(0, 0.8, 0); pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pm.emission_box_extents = Vector3(0.25, 0.6, 0.25)
			enemy.add_child(p); p.emitting = true; _free_later(p, 1.4)
		"electric":   # shocked: hard purple strobe
			for f in 4:
				tw.tween_callback(func() -> void: tint.albedo_color = Color(pal("core"), 0.75))
				tw.tween_interval(0.05)
				tw.tween_callback(func() -> void: tint.albedo_color = Color(pal("mid"), 0.0))
				tw.tween_interval(0.07)

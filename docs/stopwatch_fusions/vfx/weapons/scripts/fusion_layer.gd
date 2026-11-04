## Megaclonk — Fusion layer: what a weapon looks like with TWO different gems (Imbued Amulet).
##
## Two gems fuse into one of six named Fusions. A Fusion is not the two element looks stacked:
## it has its own palette, materials and shapes, and it adds new pieces of geometry the single
## gems never use (hanging crystals, steam clouds, plasma lines, black-ice spikes, tethers).
##
##   Steamforged  fire + ice            flash-freeze, then the ice cracks into scalding steam
##   Plasma       fire + electric       white-hot core, violet corona, a crackle line that detonates
##   Aurora       ice + electric        crystals hang in the air and zap each other into a net
##   Livewire     corrosive + electric  green lightning that drips, poison tethers between enemies
##   Pyrebile     corrosive + fire      sticky fire globs, black smoke column, puddle that ignites
##   Rimerot      corrosive + ice       black ice spikes grow out of the ground, frost-rot spreads
##
## API (same shape as element_layer.gd, so weapon code can hold either):
##   setup_fusion(gem_a, gem_b)    picks the Fusion (order does not matter)
##   tint(effect) / trail(node)    recolour a weapon effect / add a fused trail to a projectile
##   impact(pos)                   the Fusion's signature hit
##   status(enemy)                 the fused status look on an enemy mesh
##   tether(a, b, time)            Livewire-style arc between two nodes (any Fusion can call it)
##   plasma_line(a, b)             crackle line that detonates along its length after 0.5 s
##   crystals(pos, n, time)        Aurora-style hanging crystals that net-zap each other
##   spikes(ground_pos, n, r)      Rimerot-style black ice spike cluster
##   steam(pos, scale)             Steamforged steam cloud with embers
##   motes(player)                 two gem motes that orbit the player while a Fusion is held
##
## Budget: every impact is a handful of one-shot emitters and <= 10 meshes that free themselves.
## In game, route impacts through the same 24/s combo budget as the element combos.
extends "res://vfx/weapons/scripts/element_layer.gd"

const FUSIONS := {
	"fire+ice": "steamforged", "electric+fire": "plasma", "electric+ice": "aurora",
	"corrosive+electric": "livewire", "corrosive+fire": "pyrebile", "corrosive+ice": "rimerot",
}
const NAMES := {
	"steamforged": "Steamforged", "plasma": "Plasma", "aurora": "Aurora",
	"livewire": "Livewire", "pyrebile": "Pyrebile", "rimerot": "Rimerot",
}
const COMBO := {
	"steamforged": "Thermal Shock", "plasma": "Overcharge", "aurora": "Cryoshock",
	"livewire": "Toxic Conduction", "pyrebile": "Caustic Combustion", "rimerot": "Blightfrost",
}
const FPAL := {
	"steamforged": {"core": Color("F4F1EA"), "mid": Color("FF8A3D"), "deep": Color("3D7FA6"), "acc": Color("A8E0F5"), "smoke": Color("E2DED6")},
	"plasma":      {"core": Color("FFFFFF"), "mid": Color("C77DFF"), "deep": Color("4A1F7A"), "acc": Color("FF9A4A"), "smoke": Color("2A1438")},
	"aurora":      {"core": Color("F0FFFF"), "mid": Color("6FE3D6"), "deep": Color("3E2A86"), "acc": Color("B89BFF"), "smoke": Color("8FD0E0")},
	"livewire":    {"core": Color("F0FFC8"), "mid": Color("9BE04A"), "deep": Color("1F4A1A"), "acc": Color("B08AF0"), "smoke": Color("2E4A22")},
	"pyrebile":    {"core": Color("FFF2A0"), "mid": Color("C8D23A"), "deep": Color("3A2A10"), "acc": Color("FF7A2A"), "smoke": Color("121010")},
	"rimerot":     {"core": Color("DDF5E4"), "mid": Color("4F8A6C"), "deep": Color("070C0A"), "acc": Color("A6E070"), "smoke": Color("18221C")},
}

var fusion := ""
var gems: Array = []
var _octa_mesh: ArrayMesh
var _puff_cache := {}


static func fusion_of(a: String, b: String) -> String:
	var k := [a, b]
	k.sort()
	return FUSIONS.get("%s+%s" % k, "")


func setup_fusion(a: String, b: String) -> void:
	gems = [a, b]
	fusion = fusion_of(a, b)
	element = fusion
	tint_amount = 0.8


func display_name(weapon_name: String) -> String:
	return "%s %s" % [NAMES[fusion], weapon_name]


func pal(key: String) -> Color:
	return FPAL[fusion].get(key, FPAL[fusion]["mid"])


func gem_color(i: int) -> Color:
	return PAL[gems[i]]["mid"]


# ------------------------------------------------------------------ shared building blocks
func _grad(cols: Array, offs: Array) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	var t := GradientTexture1D.new()
	t.gradient = g
	return t


func _ramp_of(c0: Color, c1: Color, c2: Color) -> GradientTexture1D:
	return _grad([c0, c1, Color(c2, 0.0)], [0.0, 0.45, 1.0])


func _smoke_ramp(c: Color, a := 0.75) -> GradientTexture1D:
	var t := _grad([Color(c, 0.0), Color(c, a), Color(c, a * 0.6), Color(c, 0.0)], [0.0, 0.15, 0.6, 1.0])
	t.set_meta("puff", true)   # _em draws smoke ramps with the dithered puff sprite
	return t


## A round, ordered-dithered puff (16x16, nearest) so smoke reads as PSX clouds, not squares.
func _puff_quad(size: float) -> QuadMesh:
	if _puff_cache.has(size):
		return _puff_cache[size]
	var bayer := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length() / 7.5
			var keep: bool = (1.0 - d) * 1.6 > (bayer[(y % 4) * 4 + x % 4] + 0.5) / 16.0
			img.set_pixel(x, y, Color(1, 1, 1, 1.0 if keep and d < 1.0 else 0.0))
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.billboard_keep_scale = true
	q.material = m
	_puff_cache[size] = q
	return q


func _unlit(c: Color, alpha := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


## One emitter with explicit colours. `ramp` overrides the colour ramp (e.g. a smoke ramp).
func _em(amount: int, life: float, size: float, one_shot: bool, ramp: GradientTexture1D, grav: Vector3,
		vmin: float, vmax: float, spread := 180.0, dir := Vector3.UP, sphere := 0.0) -> GPUParticles3D:
	var p := _emitter(maxi(amount, 1), life, size, one_shot)
	var pm: ParticleProcessMaterial = p.process_material
	pm.color_ramp = ramp
	pm.gravity = grav
	pm.initial_velocity_min = vmin
	pm.initial_velocity_max = vmax
	pm.spread = spread
	pm.direction = dir
	if ramp.has_meta("puff"):
		p.draw_pass_1 = _puff_quad(size)
		pm.angle_min = -180.0; pm.angle_max = 180.0
	if sphere > 0.0:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
		pm.emission_sphere_radius = sphere
	return p


func _shot(pos: Vector3, p: GPUParticles3D) -> GPUParticles3D:
	add_child(p)
	p.global_position = pos
	p.emitting = true
	_free_later(p, p.lifetime + 0.4)
	return p


func _mesh_at(mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_position = pos
	return mi


func _later(t: float, f: Callable) -> void:
	get_tree().create_timer(t).timeout.connect(f)


func _octa() -> ArrayMesh:
	if _octa_mesh:
		return _octa_mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0, 1.6, 0); var bot := Vector3(0, -1.0, 0)
	var ring := [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]
	for i in 4:
		var a: Vector3 = ring[i]; var b: Vector3 = ring[(i + 1) % 4]
		for v in [top, b, a, bot, a, b]:
			st.add_vertex(v)
	st.generate_normals()
	_octa_mesh = st.commit()
	return _octa_mesh


## Jagged line strips (3 parallel offsets so it reads at PSX resolution).
func _draw_jag(im: ImmediateMesh, a: Vector3, b: Vector3, jag: float, segs: int, r: RandomNumberGenerator) -> void:
	var prev := a
	for k in range(1, segs + 1):
		var t := float(k) / segs
		var p := a.lerp(b, t)
		if k < segs:
			p += Vector3(r.randf_range(-jag, jag), r.randf_range(-jag, jag), r.randf_range(-jag, jag))
		for o in [Vector3.ZERO, Vector3(0, 0.025, 0), Vector3(0.025, 0, 0)]:
			im.surface_add_vertex(prev + o)
			im.surface_add_vertex(p + o)
		prev = p


func _arc(a: Vector3, b: Vector3, col: Color, flickers := 3, jag := 0.22, segs := 7) -> void:
	var im := ImmediateMesh.new()
	var r := RandomNumberGenerator.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	_draw_jag(im, a, b, jag, segs, r)
	im.surface_end()
	var mi := _mesh_at(im, _unlit(col), Vector3.ZERO)
	mi.global_position = Vector3.ZERO
	var tw := mi.create_tween()
	for f in flickers:
		tw.tween_callback(func() -> void: mi.visible = true)
		tw.tween_interval(0.05)
		tw.tween_callback(func() -> void: mi.visible = false)
		tw.tween_interval(0.035)
	tw.tween_callback(mi.queue_free)


## A live, re-jagged arc redrawn every few frames. `ends` returns [a, b] each redraw.
func _live_arc(ends: Callable, time: float, col: Color, jag := 0.25, drip := false) -> void:
	var im := ImmediateMesh.new()
	var mi := _mesh_at(im, _unlit(col), Vector3.ZERO)
	mi.global_position = Vector3.ZERO
	var r := RandomNumberGenerator.new()
	var steps := int(time / 0.06)
	var tw := mi.create_tween()
	for s in steps:
		tw.tween_callback(func() -> void:
			var e: Array = ends.call()
			im.clear_surfaces()
			if e.is_empty():
				return
			im.surface_begin(Mesh.PRIMITIVE_LINES)
			_draw_jag(im, e[0], e[1], jag, 8, r)
			im.surface_end()
			if drip and s % 3 == 0:
				_drip((e[0] as Vector3).lerp(e[1], r.randf_range(0.25, 0.75))))
		tw.tween_interval(0.06)
	tw.tween_callback(mi.queue_free)


func _drip(pos: Vector3) -> void:
	_shot(pos, _em(4, 0.55, 0.07, true, _ramp_of(pal("core"), pal("mid"), pal("deep")), Vector3(0, -9.0, 0), 0.0, 0.4, 20.0, Vector3.DOWN))


# ------------------------------------------------------------------ 1. tint (two-tone, not a mix)
func tint(n: Node) -> void:
	if fusion == "":
		return
	var i := 0
	for c in _walk(n):
		if c is GPUParticles3D:
			var pm := (c as GPUParticles3D).process_material as ParticleProcessMaterial
			if pm:
				pm = pm.duplicate()
				# alternate emitters between the Fusion's two hues so it reads as two-tone
				var hue := pal("acc") if i % 2 == 1 else pal("mid")
				pm.color = (pm.color as Color).lerp(hue, tint_amount)
				if pm.color_ramp:
					pm.color_ramp = _ramp_of(pal("core"), hue, pal("deep"))
				c.process_material = pm
				i += 1
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
			c.light_color = (c.light_color as Color).lerp(pal("mid"), 0.85)


# ------------------------------------------------------------------ 2. trail
func trail(n: Node3D, strength := 1.0) -> void:
	if fusion == "":
		return
	var core_mid := _ramp_of(pal("core"), pal("mid"), pal("deep"))
	var core_acc := _ramp_of(pal("core"), pal("acc"), pal("deep"))
	var list: Array = []
	match fusion:
		"steamforged":
			list = [_em(24, 0.9, 0.24, false, _smoke_ramp(pal("smoke"), 0.55), Vector3(0, 1.2, 0), 0.1, 0.5, 180, Vector3.UP, 0.08),
					_em(30, 0.7, 0.07, false, core_acc, Vector3(0, -1.5, 0), 0.1, 0.5, 180, Vector3.UP, 0.12),
					_em(26, 0.45, 0.06, false, core_mid, Vector3(0, 3.0, 0), 0.4, 1.4)]
		"plasma":
			list = [_em(40, 0.14, 0.16, false, _grad([pal("core"), Color(pal("core"), 0.0)], [0.0, 1.0]), Vector3.ZERO, 0.0, 0.1),
					_em(50, 0.2, 0.06, false, core_mid, Vector3.ZERO, 3.0, 6.0),
					_em(18, 0.5, 0.05, false, core_acc, Vector3(0, -3.0, 0), 0.5, 1.5)]
		"aurora":
			list = [_em(30, 1.3, 0.07, false, core_mid, Vector3.ZERO, 0.05, 0.3, 180, Vector3.UP, 0.15),
					_em(30, 1.0, 0.05, false, core_acc, Vector3(0, 0.4, 0), 0.05, 0.25, 180, Vector3.UP, 0.2),
					_em(30, 0.16, 0.05, false, _ramp_of(pal("core"), pal("acc"), pal("deep")), Vector3.ZERO, 2.5, 4.5)]
		"livewire":
			list = [_em(26, 0.6, 0.08, false, core_mid, Vector3(0, -9.0, 0), 0.0, 0.5, 30, Vector3.DOWN),
					_em(46, 0.16, 0.05, false, core_acc, Vector3.ZERO, 2.5, 5.5),
					_em(30, 0.2, 0.05, false, core_mid, Vector3.ZERO, 2.0, 4.5)]
		"pyrebile":
			list = [_em(36, 0.55, 0.14, false, _ramp_of(pal("core"), pal("mid"), pal("acc")), Vector3(0, 2.4, 0), 0.2, 0.9, 180, Vector3.UP, 0.06),
					_em(20, 1.1, 0.26, false, _smoke_ramp(pal("smoke"), 0.7), Vector3(0, 1.4, 0), 0.1, 0.4, 180, Vector3.UP, 0.05),
					_em(18, 0.7, 0.05, false, core_acc, Vector3(0, -5.0, 0), 0.6, 1.8)]
		"rimerot":
			list = [_em(22, 1.2, 0.2, false, _smoke_ramp(pal("smoke"), 0.65), Vector3(0, 0.3, 0), 0.05, 0.3, 180, Vector3.UP, 0.08),
					_em(26, 1.4, 0.05, false, _ramp_of(pal("core"), pal("acc"), pal("mid")), Vector3(0, 0.5, 0), 0.05, 0.3, 180, Vector3.UP, 0.18),
					_em(22, 0.8, 0.07, false, _ramp_of(pal("mid"), pal("deep"), pal("deep")), Vector3(0, -6.0, 0), 0.0, 0.5)]
	for p in list:
		var gp := p as GPUParticles3D
		gp.amount = maxi(int(gp.amount * strength), 1)
		n.add_child(gp)
		gp.emitting = true


# ------------------------------------------------------------------ 3. impact
func impact(pos: Vector3) -> void:
	match fusion:
		"steamforged": _impact_steamforged(pos)
		"plasma": _impact_plasma(pos)
		"aurora": _impact_aurora(pos)
		"livewire": _impact_livewire(pos)
		"pyrebile": _impact_pyrebile(pos)
		"rimerot": _impact_rimerot(pos)


## Steamforged: ice shell snaps shut over the hit, holds, then cracks into a steam cloud.
func _impact_steamforged(pos: Vector3) -> void:
	var r := RandomNumberGenerator.new()
	var ice := _unlit(pal("acc"))
	var shards: Array = []
	for i in 7:
		var pr := PrismMesh.new(); pr.size = Vector3(0.16, r.randf_range(0.45, 0.8), 0.12)
		var s := _mesh_at(pr, ice, pos)
		var d := Vector3(r.randf_range(-1, 1), r.randf_range(0.2, 1.2), r.randf_range(-1, 1)).normalized()
		s.global_transform = Transform3D(Basis(), pos).looking_at(pos + d, Vector3.UP if absf(d.y) < 0.95 else Vector3.RIGHT)
		s.rotate_object_local(Vector3.RIGHT, -PI / 2)
		s.scale = Vector3.ONE * 0.05
		s.create_tween().tween_property(s, "scale", Vector3.ONE, 0.07).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		shards.append([s, d])
	_light(pos, 3.0, 3.0, 0.25)
	_later(0.34, func() -> void:
		for sd in shards:
			var s: MeshInstance3D = sd[0]
			if not is_instance_valid(s): continue
			var tw := s.create_tween().set_parallel(true)
			tw.tween_property(s, "global_position", pos + (sd[1] as Vector3) * r.randf_range(0.7, 1.3), 0.22).set_ease(Tween.EASE_OUT)
			tw.tween_property(s, "scale", Vector3.ONE * 0.1, 0.3).set_delay(0.06)
			_free_later(s, 0.4)
		steam(pos, 1.0)
		_light(pos, 6.0, 4.5, 0.4))


func steam(pos: Vector3, scale := 1.0) -> void:
	_shot(pos, _em(int(12 * scale), 1.7, 0.7 * scale, true, _smoke_ramp(pal("smoke"), 0.55), Vector3(0, 0.9, 0), 0.6, 1.8 * scale, 180, Vector3.UP, 0.25 * scale))
	_shot(pos, _em(int(20 * scale), 1.1, 0.07, true, _ramp_of(pal("core"), pal("mid"), pal("deep")), Vector3(0, 1.6, 0), 1.2, 3.2, 70, Vector3.UP))
	_shot(pos, _em(10, 0.6, 0.05, true, _ramp_of(pal("core"), pal("acc"), pal("deep")), Vector3(0, -6, 0), 1.0, 2.5))


## Plasma: white-hot sphere, violet corona ring, and a crackle line that detonates.
func _impact_plasma(pos: Vector3) -> void:
	_plasma_pop(pos, 1.0)
	var r := RandomNumberGenerator.new()
	var d := Vector3(r.randf_range(-1, 1), 0.0, r.randf_range(-1, 1)).normalized()
	plasma_line(pos, pos + d * 2.2 + Vector3(0, r.randf_range(-0.3, 0.3), 0))


func _plasma_pop(pos: Vector3, k: float) -> void:
	var core := _unlit(Color(pal("core"), 1.0), true)
	var sm := SphereMesh.new(); sm.radius = 0.3 * k; sm.height = 0.6 * k; sm.radial_segments = 8; sm.rings = 4
	var s := _mesh_at(sm, core, pos)
	s.scale = Vector3.ONE * 0.2
	var tw := s.create_tween()
	tw.tween_property(s, "scale", Vector3.ONE * 1.3, 0.08)
	tw.tween_method(func(a: float) -> void: core.albedo_color = Color(pal("core"), a), 1.0, 0.0, 0.22)
	tw.tween_callback(s.queue_free)
	var shell := _unlit(Color(pal("mid"), 0.55), true)
	var sm2 := SphereMesh.new(); sm2.radius = 0.5 * k; sm2.height = 1.0 * k; sm2.radial_segments = 8; sm2.rings = 4
	var s2 := _mesh_at(sm2, shell, pos)
	var t2 := s2.create_tween()
	t2.tween_property(s2, "scale", Vector3.ONE * 1.8, 0.2).set_ease(Tween.EASE_OUT)
	t2.parallel().tween_method(func(a: float) -> void: shell.albedo_color = Color(pal("mid"), a), 0.55, 0.0, 0.3)
	t2.tween_callback(s2.queue_free)
	var rm := _unlit(Color(pal("mid"), 0.9), true)
	var tm := TorusMesh.new(); tm.inner_radius = 0.42 * k; tm.outer_radius = 0.52 * k; tm.rings = 14; tm.ring_segments = 4
	var ring := _mesh_at(tm, rm, pos)
	ring.rotation = Vector3(deg_to_rad(70), 0, 0)
	var t3 := ring.create_tween()
	t3.tween_property(ring, "scale", Vector3.ONE * 3.0, 0.3).set_ease(Tween.EASE_OUT)
	t3.parallel().tween_method(func(a: float) -> void: rm.albedo_color = Color(pal("mid"), a), 0.9, 0.0, 0.32)
	t3.tween_callback(ring.queue_free)
	_shot(pos, _em(int(28 * k), 0.3, 0.06, true, _ramp_of(pal("core"), pal("mid"), pal("deep")), Vector3.ZERO, 4.0, 8.0))
	_shot(pos, _em(int(12 * k), 0.6, 0.05, true, _ramp_of(pal("core"), pal("acc"), pal("deep")), Vector3(0, -6, 0), 1.0, 3.0))
	_light(pos, 7.0 * k, 4.5 * k, 0.3)


func plasma_line(a: Vector3, b: Vector3, fuse := 0.5, k := 0.55) -> void:
	_live_arc(func() -> Array: return [a, b], fuse, pal("mid"), 0.12)
	_live_arc(func() -> Array: return [a, b], fuse, pal("core"), 0.06)
	var n := maxi(int(a.distance_to(b) / 0.7), 2)
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		_later(fuse + i * 0.045, func() -> void: _plasma_pop(p, k))


## Aurora: crystals hang where the hit landed and zap each other into a net.
func _impact_aurora(pos: Vector3) -> void:
	crystals(pos, 4, 1.2)
	_shot(pos, _em(24, 0.25, 0.05, true, _ramp_of(pal("core"), pal("acc"), pal("deep")), Vector3.ZERO, 3.0, 6.0))
	_light(pos, 4.0, 4.0, 0.3)


func crystals(pos: Vector3, n := 4, life := 1.2) -> Array:
	var r := RandomNumberGenerator.new()
	var list: Array = []
	for i in n:
		var col := pal("mid") if i % 2 == 0 else pal("acc")
		var c := _mesh_at(_octa(), _unlit(col), pos)
		var ang := TAU * i / n + r.randf_range(-0.3, 0.3)
		var home := pos + Vector3(cos(ang) * r.randf_range(0.55, 1.0), r.randf_range(0.25, 0.9), sin(ang) * r.randf_range(0.55, 1.0))
		c.scale = Vector3.ONE * 0.01
		var tw := c.create_tween()
		tw.tween_property(c, "global_position", home, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.parallel().tween_property(c, "scale", Vector3.ONE * 0.18, 0.18)
		tw.tween_method(func(t: float) -> void:
			c.global_position = home + Vector3(0, sin(t * 6.0 + i) * 0.05, 0)
			c.rotation.y = t * 3.0, 0.0, life, life)
		tw.tween_callback(func() -> void:
			_shot(c.global_position, _em(10, 0.4, 0.05, true, _ramp_of(pal("core"), col, pal("deep")), Vector3(0, -4, 0), 0.8, 2.2))
			c.queue_free())
		list.append(c)
	_live_arc(func() -> Array:
		var alive := list.filter(func(x) -> bool: return is_instance_valid(x))
		if alive.size() < 2: return []
		var k := randi() % alive.size()
		return [alive[k].global_position, alive[(k + 1) % alive.size()].global_position], life + 0.18, pal("core"), 0.12)
	_live_arc(func() -> Array:
		var alive := list.filter(func(x) -> bool: return is_instance_valid(x))
		if alive.size() < 2: return []
		var k := randi() % alive.size()
		return [alive[k].global_position, alive[(k + 2) % alive.size()].global_position], life + 0.18, pal("acc"), 0.16)
	return list


## Livewire: green lightning forks into the ground and drips; the ground fizzes.
func _impact_livewire(pos: Vector3) -> void:
	var r := RandomNumberGenerator.new()
	for i in 3:
		var g := Vector3(pos.x + r.randf_range(-1.2, 1.2), 0.03, pos.z + r.randf_range(-1.2, 1.2))
		_arc(pos, g, pal("mid") if i != 1 else pal("acc"), 3, 0.2)
		_drip(pos.lerp(g, 0.5))
	var cy := CylinderMesh.new(); cy.top_radius = 0.75; cy.bottom_radius = 0.75; cy.height = 0.02; cy.radial_segments = 9
	var pm := _unlit(Color(pal("mid"), 0.6), true)
	var pud := _mesh_at(cy, pm, Vector3(pos.x, 0.02, pos.z))
	pud.scale = Vector3(0.1, 1, 0.1)
	var tw := pud.create_tween()
	tw.tween_property(pud, "scale", Vector3(1.5, 1, 1.3), 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.9)
	tw.tween_method(func(a: float) -> void: pm.albedo_color = Color(pal("mid"), a), 0.6, 0.0, 0.5)
	tw.tween_callback(pud.queue_free)
	var fizz := _em(30, 0.14, 0.05, false, _ramp_of(pal("core"), pal("acc"), pal("deep")), Vector3.ZERO, 1.5, 3.0, 60, Vector3.UP)
	(fizz.process_material as ParticleProcessMaterial).emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	(fizz.process_material as ParticleProcessMaterial).emission_ring_radius = 0.8
	(fizz.process_material as ParticleProcessMaterial).emission_ring_inner_radius = 0.2
	(fizz.process_material as ParticleProcessMaterial).emission_ring_height = 0.02
	(fizz.process_material as ParticleProcessMaterial).emission_ring_axis = Vector3.UP
	add_child(fizz); fizz.global_position = Vector3(pos.x, 0.05, pos.z); fizz.emitting = true
	_later(1.2, func() -> void: if is_instance_valid(fizz): fizz.emitting = false)
	_free_later(fizz, 1.6)
	_light(pos, 5.0, 4.0, 0.3)


func tether(a: Node3D, b: Node3D, time := 1.0) -> void:
	var ends := func() -> Array:
		if not (is_instance_valid(a) and is_instance_valid(b)): return []
		return [a.global_position + Vector3(0, 0.2, 0), b.global_position + Vector3(0, 0.2, 0)]
	_live_arc(ends, time, pal("mid"), 0.22, true)
	_live_arc(ends, time, pal("core"), 0.1)


## Pyrebile: sticky globs stay burning, black smoke climbs, the puddle ignites.
func _impact_pyrebile(pos: Vector3) -> void:
	var r := RandomNumberGenerator.new()
	var glob := _unlit(pal("mid"))
	var sm := SphereMesh.new(); sm.radius = 0.07; sm.height = 0.14; sm.radial_segments = 6; sm.rings = 3
	for i in 5:
		var g := _mesh_at(sm, glob, pos)
		var land := pos + Vector3(r.randf_range(-0.5, 0.5), r.randf_range(-0.4, 0.4), r.randf_range(-0.5, 0.5))
		g.create_tween().tween_property(g, "global_position", land, 0.12)
		var f := _em(14, 0.45, 0.13, false, _ramp_of(pal("core"), pal("mid"), pal("acc")), Vector3(0, 2.6, 0), 0.1, 0.5, 30, Vector3.UP)
		g.add_child(f); f.emitting = true
		_later(1.5, func() -> void: if is_instance_valid(f): f.emitting = false)
		_free_later(g, 2.1)
	_shot(pos, _em(22, 1.9, 0.6, true, _smoke_ramp(pal("smoke"), 0.85), Vector3(0, 1.6, 0), 0.5, 1.4, 18, Vector3.UP, 0.3))
	var pm := _unlit(Color(pal("mid"), 0.8), true)
	var cy := CylinderMesh.new(); cy.top_radius = 0.8; cy.bottom_radius = 0.8; cy.height = 0.02; cy.radial_segments = 9
	var pud := _mesh_at(cy, pm, Vector3(pos.x + 0.2, 0.02, pos.z))
	pud.scale = Vector3(0.1, 1, 0.1)
	var tw := pud.create_tween()
	tw.tween_property(pud, "scale", Vector3(1.4, 1, 1.1), 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.4)
	tw.tween_method(func(a: float) -> void: pm.albedo_color = Color(pal("deep"), a), 0.8, 0.0, 0.5)
	tw.tween_callback(pud.queue_free)
	_later(0.42, func() -> void:
		pm.albedo_color = Color(pal("acc"), 0.85)
		var ring := _em(60, 0.6, 0.17, false, _ramp_of(pal("core"), pal("acc"), pal("mid")), Vector3(0, 3.2, 0), 0.2, 0.8, 20, Vector3.UP)
		var rp := ring.process_material as ParticleProcessMaterial
		rp.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		rp.emission_ring_radius = 0.95; rp.emission_ring_inner_radius = 0.1; rp.emission_ring_height = 0.02; rp.emission_ring_axis = Vector3.UP
		add_child(ring); ring.global_position = Vector3(pos.x + 0.2, 0.05, pos.z); ring.emitting = true
		_later(1.1, func() -> void: if is_instance_valid(ring): ring.emitting = false)
		_free_later(ring, 1.8)
		_light(Vector3(pos.x, 0.5, pos.z), 6.0, 4.0, 0.6))
	_light(pos, 3.0, 3.0, 0.3)


## Rimerot: black ice grows up out of the ground like fungus and frost-rot spreads.
func _impact_rimerot(pos: Vector3) -> void:
	var g := Vector3(pos.x, 0.0, pos.z)
	spikes(g, 8, 0.8)
	_shot(pos, _em(14, 0.5, 0.08, true, _ramp_of(pal("core"), pal("mid"), pal("deep")), Vector3(0, -6, 0), 1.0, 2.6))
	_light(pos, 2.5, 3.0, 0.3)


func spikes(g: Vector3, n := 8, radius := 0.8, hold := 1.3) -> void:
	var r := RandomNumberGenerator.new()
	var dark := _unlit(pal("deep"))
	var mid := _unlit(pal("mid"))
	var tip := _unlit(pal("core"))
	for i in n:
		var h := r.randf_range(0.5, 1.25)
		var pr := PrismMesh.new(); pr.size = Vector3(0.16, h, 0.14)
		var base := g + Vector3(r.randf_range(-radius, radius), 0, r.randf_range(-radius, radius))
		var s := _mesh_at(pr, dark if i % 3 else mid, base)
		var lean := Vector3(r.randf_range(-0.4, 0.4), 1.0, r.randf_range(-0.4, 0.4)).normalized()
		s.global_transform = Transform3D(Basis(), base).looking_at(base + lean, Vector3.RIGHT)
		s.rotate_object_local(Vector3.RIGHT, -PI / 2)
		s.translate_object_local(Vector3(0, h * 0.5, 0))
		var t := MeshInstance3D.new()                     # pale frost tip
		var tp := PrismMesh.new(); tp.size = Vector3(0.07, h * 0.28, 0.06); t.mesh = tp; t.material_override = tip
		s.add_child(t); t.position = Vector3(0, h * 0.42, 0)
		s.scale = Vector3(1, 0.01, 1)
		var tw := s.create_tween()
		tw.tween_interval(i * 0.035)
		tw.tween_property(s, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(hold)
		tw.tween_property(s, "scale", Vector3(1, 0.01, 1), 0.35)
		tw.tween_callback(s.queue_free)
	var rot := _unlit(Color(pal("deep"), 0.8), true)
	var cy := CylinderMesh.new(); cy.top_radius = 1.0; cy.bottom_radius = 1.0; cy.height = 0.02; cy.radial_segments = 11
	var ring := _mesh_at(cy, rot, g + Vector3(0, 0.025, 0))
	ring.scale = Vector3(0.2, 1, 0.2)
	var tr := ring.create_tween()
	tr.tween_property(ring, "scale", Vector3(radius * 2.4, 1, radius * 2.2), 1.0).set_ease(Tween.EASE_OUT)
	tr.tween_interval(hold - 0.4)
	tr.tween_method(func(a: float) -> void: rot.albedo_color = Color(pal("deep"), a), 0.8, 0.0, 0.6)
	tr.tween_callback(ring.queue_free)
	var spores := _em(18, 1.8, 0.05, true, _ramp_of(pal("core"), pal("acc"), pal("mid")), Vector3(0, 0.5, 0), 0.1, 0.5, 60, Vector3.UP, radius)
	spores.explosiveness = 0.3
	_shot(g + Vector3(0, 0.3, 0), spores)


# ------------------------------------------------------------------ 4. status
func status(enemy: GeometryInstance3D) -> void:
	if fusion == "" or not is_instance_valid(enemy):
		return
	var ov := _unlit(Color(pal("mid"), 0.0), true)
	ov.grow = true; ov.grow_amount = 0.012
	enemy.material_overlay = ov
	var tw := enemy.create_tween()
	var set_c := func(c: Color, a: float) -> void: ov.albedo_color = Color(c, a)
	var body := func(amount: int, life: float, size: float, ramp: GradientTexture1D, grav: Vector3) -> void:
		var p := _em(amount, life, size, false, ramp, grav, 0.05, 0.3)
		var pm := p.process_material as ParticleProcessMaterial
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pm.emission_box_extents = Vector3(0.25, 0.7, 0.25)
		enemy.add_child(p); p.emitting = true
		_later(1.2, func() -> void: if is_instance_valid(p): p.emitting = false)
		_free_later(p, 1.2 + life + 0.2)
	match fusion:
		"steamforged":   # frozen solid for a beat, then scalded orange with steam lifting off
			tw.tween_callback(set_c.bind(pal("acc"), 0.65)); tw.tween_interval(0.32)
			for f in 4:
				tw.tween_method(func(a: float) -> void: set_c.call(pal("mid"), a), 0.55, 0.12, 0.12)
			tw.tween_callback(set_c.bind(pal("mid"), 0.0))
			_later(0.32, func() -> void: if is_instance_valid(enemy): body.call(10, 1.0, 0.26, _smoke_ramp(pal("smoke"), 0.5), Vector3(0, 1.4, 0)))
		"plasma":        # white-violet strobe, too bright to look at
			for f in 5:
				tw.tween_callback(set_c.bind(pal("core"), 0.85)); tw.tween_interval(0.04)
				tw.tween_callback(set_c.bind(pal("mid"), 0.5)); tw.tween_interval(0.06)
			tw.tween_callback(set_c.bind(pal("mid"), 0.0))
		"aurora":        # teal coat with violet sparks running over it
			tw.tween_callback(set_c.bind(pal("mid"), 0.55))
			for f in 4:
				tw.tween_interval(0.12); tw.tween_callback(set_c.bind(pal("acc"), 0.7))
				tw.tween_interval(0.05); tw.tween_callback(set_c.bind(pal("mid"), 0.5))
			tw.tween_method(func(a: float) -> void: set_c.call(pal("mid"), a), 0.5, 0.0, 0.3)
			body.call(10, 1.0, 0.05, _ramp_of(pal("core"), pal("acc"), pal("deep")), Vector3.ZERO)
		"livewire":      # sick green pulse, violet strobes, drips off the body
			for f in 3:
				tw.tween_method(func(a: float) -> void: set_c.call(pal("mid"), a), 0.55, 0.15, 0.18)
				tw.tween_callback(set_c.bind(pal("acc"), 0.8)); tw.tween_interval(0.05)
			tw.tween_callback(set_c.bind(pal("mid"), 0.0))
			body.call(10, 0.6, 0.07, _ramp_of(pal("core"), pal("mid"), pal("deep")), Vector3(0, -9, 0))
		"pyrebile":      # yellow-green burning that will not go out, black smoke
			for f in 7:
				tw.tween_method(func(a: float) -> void: set_c.call(pal("mid") if f % 2 else pal("acc"), a), 0.6, 0.2, 0.12)
			tw.tween_callback(set_c.bind(pal("mid"), 0.0))
			body.call(12, 0.6, 0.12, _ramp_of(pal("core"), pal("mid"), pal("acc")), Vector3(0, 2.6, 0))
			body.call(6, 1.2, 0.3, _smoke_ramp(pal("smoke"), 0.7), Vector3(0, 1.6, 0))
		"rimerot":       # darkens from the feet up, spores drift off
			tw.tween_method(func(a: float) -> void: set_c.call(pal("deep"), a), 0.0, 0.75, 0.35)
			tw.tween_interval(0.5)
			tw.tween_callback(set_c.bind(pal("acc"), 0.5)); tw.tween_interval(0.05)
			tw.tween_method(func(a: float) -> void: set_c.call(pal("deep"), a), 0.75, 0.0, 0.5)
			body.call(8, 1.4, 0.05, _ramp_of(pal("core"), pal("acc"), pal("mid")), Vector3(0, 0.6, 0))


# ------------------------------------------------------------------ 5. the player carries it
## Two gem motes orbiting the player at chest height, each leaving a short streak.
func motes(player: Node3D) -> Node3D:
	var pivot := Node3D.new()
	player.add_child(pivot)
	pivot.position = Vector3(0, 0.15, 0)
	for i in 2:
		var col := gem_color(i)
		var m := MeshInstance3D.new()
		m.mesh = _octa(); m.material_override = _unlit(col)
		m.scale = Vector3.ONE * 0.075
		pivot.add_child(m)
		m.position = Vector3(cos(PI * i) * 0.75, 0.0, sin(PI * i) * 0.75)
		var t := _em(26, 0.35, 0.05, false, _ramp_of(PAL[gems[i]]["core"], col, PAL[gems[i]]["deep"]), Vector3.ZERO, 0.0, 0.05)
		m.add_child(t); t.emitting = true
	var tw := pivot.create_tween().set_loops()
	tw.tween_method(func(a: float) -> void:
		pivot.rotation.y = a
		for k in pivot.get_child_count():
			var c := pivot.get_child(k) as Node3D
			c.position.y = sin(a * 2.0 + k * PI) * 0.18
			c.rotation.y = a * 3.0, 0.0, TAU, 2.4)
	return pivot

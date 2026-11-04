## Megaclonk — Fusion preview: a weapon with TWO gems (Imbued Amulet).
##
##     godot --path . res://preview/fusion_preview.tscn -- weapon=bow gems=fire,ice
##     godot --path . res://preview/fusion_preview.tscn -- mode=forge weapon=bow gems=fire,ice
##     godot --path . res://preview/fusion_preview.tscn -- mode=impacts
##
## Each weapon has one fused attack form; the Fusion (from the gem pair) supplies the look:
##   lightning  a storm cloud rides above you and strikes on its own, enemies get tethered
##   bow        the arrow splits into three fused shards on its first pierce
##   revolver   every 6th shot is a judgement round that leaves a detonating line
##   aura       twin counter-rotating rings; every 3rd pulse erupts
##   scythes    the blade leaves a fused vortex where it turns back
##   shotgun    the blast leaves a short-lived wall of the Fusion in the cone
##   sword      every 3rd slash throws a crescent wave
##   firestaff  the fireball is a comet that splits into a meteor shower
extends "res://preview/preview.gd"

const FusionLayer := preload("res://vfx/weapons/scripts/fusion_layer.gd")
const DEFAULT_GEMS := {
	"lightning": ["corrosive", "electric"], "bow": ["fire", "ice"], "revolver": ["fire", "electric"],
	"aura": ["ice", "electric"], "scythes": ["corrosive", "ice"], "shotgun": ["corrosive", "fire"],
	"sword": ["fire", "electric"], "firestaff": ["fire", "ice"],
}
const WEAPON_NAMES := {
	"lightning": "Lightning Staff", "bow": "Bow", "revolver": "Revolver", "aura": "Aura",
	"scythes": "Scythes", "shotgun": "Shotgun", "sword": "Sword", "firestaff": "Firestaff",
}

var mode := "attack"
var gems: Array = []
var fl: FusionLayer


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("weapon="): weapon = a.substr(7)
		if a.begins_with("gems="): gems = Array(a.substr(5).split(","))
		if a.begins_with("mode="): mode = a.substr(5)
	if gems.size() != 2:
		gems = DEFAULT_GEMS.get(weapon, ["fire", "ice"])
	_stage()
	fl = FusionLayer.new()
	add_child(fl)
	fl.setup_fusion(gems[0], gems[1])
	layer = fl
	element = fl.fusion
	if mode == "attack":
		fl.motes(player)
	match mode:
		"forge": _forge.call_deferred()
		"impacts": _impacts.call_deferred()
		_: _run.call_deferred()


func fx(fname: String):
	var n = load(FX + fname + ".tscn").instantiate()
	add_child(n)
	fl.tint(n)
	if "outer_color" in n:
		n.outer_color = fl.pal("mid"); n.inner_color = fl.pal("core")
	if "edge_color" in n:
		n.edge_color = fl.pal("mid"); n.blade_color = fl.pal("core")
	if fname in ["bow_arrow", "revolver_bullet", "fireball", "scythe_projectile"]:
		fl.trail(n)
	return n


## Normal fused hit: white pop, the Fusion's impact and status.
func flash(m: MeshInstance3D, _col := Color.WHITE, _d := 0.14) -> void:
	HitFlash.flash(m, Color.WHITE, 0.08)
	fl.impact(m.global_position + Vector3(0, 0.25, 0))
	get_tree().create_timer(0.08).timeout.connect(func() -> void: fl.status(m))


## Light hit for rapid-fire shots: no full impact, just the status.
func tick(m: MeshInstance3D) -> void:
	HitFlash.flash(m, Color.WHITE, 0.06)
	fl.status(m)


func shake(t: float, amt: float) -> void:
	var tw := create_tween()
	for i in int(t / 0.03):
		tw.tween_property(cam, "h_offset", randf_range(-amt, amt), 0.03)
		tw.parallel().tween_property(cam, "v_offset", randf_range(-amt, amt), 0.03)
	tw.tween_property(cam, "h_offset", 0.0, 0.03)
	tw.parallel().tween_property(cam, "v_offset", 0.0, 0.03)


func _unlit(c: Color, alpha := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	if alpha: m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


# ------------------------------------------------------------------ fused forms
func _lightning() -> void:
	frame(Vector3(2.2, 4.8, 12.0), Vector3(4.4, 2.2, 0))
	var es := [enemy(4.0, 0.0), enemy(5.6, -1.0), enemy(7.0, 0.8)]
	# the storm cloud that rides above the player
	var cloud := Node3D.new(); add_child(cloud)
	var cm := _unlit(Color(0.16, 0.2, 0.15))
	var r := RandomNumberGenerator.new(); r.seed = 7
	for i in 9:
		var s := MeshInstance3D.new(); var sm := SphereMesh.new()
		sm.radius = r.randf_range(0.45, 0.8); sm.height = sm.radius * 1.3; sm.radial_segments = 7; sm.rings = 4
		s.mesh = sm; s.material_override = cm
		s.position = Vector3(r.randf_range(-1.4, 1.4), r.randf_range(-0.15, 0.3), r.randf_range(-0.8, 0.8))
		cloud.add_child(s)
	var under := OmniLight3D.new(); under.light_color = fl.pal("mid"); under.light_energy = 1.5; under.omni_range = 4.0
	cloud.add_child(under); under.position = Vector3(0, -0.6, 0)
	var rain := fl._em(60, 0.5, 0.05, false, fl._ramp_of(fl.pal("core"), fl.pal("mid"), fl.pal("deep")), Vector3(0, -12, 0), 0.0, 0.2, 10, Vector3.DOWN)
	(rain.process_material as ParticleProcessMaterial).emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	(rain.process_material as ParticleProcessMaterial).emission_box_extents = Vector3(1.3, 0.1, 0.7)
	cloud.add_child(rain); rain.position = Vector3(0, -0.4, 0); rain.emitting = true
	cloud.position = Vector3(1.6, 4.2, 0)
	var ct := cloud.create_tween().set_loops()
	ct.tween_property(cloud, "position:y", 4.4, 1.2).set_trans(Tween.TRANS_SINE)
	ct.tween_property(cloud, "position:y", 4.2, 1.2).set_trans(Tween.TRANS_SINE)
	await wait(0.2)
	while true:
		# the staff's own cast, then the cloud strikes on its own and tethers the pack
		var s0 = fx("lightning_strike"); s0.strike_between(player.global_position + Vector3(0.4, 0.6, 0), head(es[0])); flash(es[0])
		await wait(0.35)
		for i in [1, 2]:
			under.light_energy = 6.0
			create_tween().tween_property(under, "light_energy", 1.5, 0.3)
			var s = fx("lightning_strike"); s.strike_between(cloud.global_position + Vector3(0, -0.5, 0), head(es[i])); flash(es[i])
			await wait(0.3)
		fl.tether(es[0], es[1], 1.0)
		fl.tether(es[1], es[2], 1.0)
		for e in es: get_tree().create_timer(0.3).timeout.connect(tick.bind(e))
		await wait(1.3)


func _bow() -> void:
	frame(Vector3(1.6, 4.4, 9.0), Vector3(4.2, 0.9, 0))
	var first := enemy(3.0, 0)
	var fan := [enemy(6.4, -1.9), enemy(6.9, 0.0), enemy(6.4, 1.9)]
	var origin := Vector3(0.5, 1.25, 0)
	await wait(0.2)
	while true:
		var tgt := chest(first) + Vector3(0, 0.15, 0)
		var a = fx("bow_arrow")
		a.global_position = origin; a.look_at(tgt); a.max_distance = origin.distance_to(tgt)
		await a.arrived
		flash(first); knock(first, Vector3.RIGHT, 0.25)
		for e in fan:   # split into three shards on the first pierce
			var t2: Vector3 = chest(e) + Vector3(0, 0.15, 0)
			var s = fx("bow_arrow")
			s.scale = Vector3.ONE * 0.75
			s.global_position = tgt; s.look_at(t2); s.max_distance = tgt.distance_to(t2)
			s.arrived.connect(func(_p) -> void: flash(e); knock(e, (t2 - tgt).normalized(), 0.25))
		await wait(1.9)


func _revolver() -> void:
	frame(Vector3(2.6, 4.0, 9.5), Vector3(4.6, 1.0, 0.4))
	var e1 := enemy(6.0, 0.0)
	var e2 := enemy(8.4, 0.9)
	var muzzle := Vector3(0.55, 1.3, 0)
	await wait(0.2)
	while true:
		for shot in 6:
			var big := shot == 5
			var m = fx("revolver_muzzle"); m.global_position = muzzle; m.look_at(muzzle + Vector3.RIGHT)
			var tgt := chest(e1) + Vector3(0, 0.15, 0)
			var b = fx("revolver_bullet"); b.global_position = muzzle; b.look_at(tgt)
			if big:   # the judgement round: huge, slower, and it carries straight through
				m.scale = Vector3.ONE * 2.2
				b.scale = Vector3.ONE * 2.6; b.speed *= 0.55
				var far := chest(e2) + Vector3(0, 0.15, 0)
				b.look_at(far); b.max_distance = muzzle.distance_to(far)
				fl._plasma_pop(muzzle + Vector3(0.2, 0, 0), 0.8)
				get_tree().create_timer(muzzle.distance_to(tgt) / b.speed).timeout.connect(func() -> void:
					flash(e1); knock(e1, Vector3.RIGHT, 0.6, 0.1))
				await b.arrived
				fl._plasma_pop(far, 1.6); flash(e2); knock(e2, Vector3.RIGHT, 0.6, 0.1)
				fl.plasma_line(muzzle + Vector3(0.3, 0, 0), far, 0.35, 0.95)
				shake(0.25, 0.12)
				await wait(1.6)
			else:
				b.max_distance = muzzle.distance_to(tgt)
				await b.arrived
				var s = fx("impact_sparks"); s.global_position = tgt
				tick(e1); knock(e1, Vector3.RIGHT, 0.15, 0.06)
				await wait(0.24)


func _aura() -> void:
	frame(Vector3(0.0, 6.4, 9.0), Vector3(0.4, 0.2, 0))
	var a = fx("aura"); a.global_position = Vector3.ZERO; a.radius = 3.0
	var b = fx("aura"); b.global_position = Vector3(0, 0.03, 0); b.radius = 2.1
	b.spin_degrees_per_second = -a.spin_degrees_per_second * 2.2   # counter-rotating inner ring
	a.spin_degrees_per_second *= 1.6
	b.pulse_interval = 0.0
	var sig := b.get_node("Sigil") as MeshInstance3D
	var sm := sig.material_override as StandardMaterial3D
	if sm == null: sm = (sig.get_active_material(0) as StandardMaterial3D).duplicate(); sig.material_override = sm
	sm.albedo_color = Color(fl.pal("acc"), sm.albedo_color.a)
	var inside := [enemy(2.0, 1.2), enemy(-1.8, -1.0), enemy(2.3, -1.4)]
	enemy(5.4, 0.4)
	var n := [0]
	a.pulsed.connect(func() -> void:
		b.pulse()
		n[0] += 1
		if n[0] % 3 == 0:   # eruption: crystals burst up around the rings and net-zap everyone inside
			for k in 6:
				var ang := TAU * k / 6.0
				fl.crystals(Vector3(cos(ang) * 2.5, 0.2, sin(ang) * 2.5), 2, 1.0)
			for e in inside: flash(e)
			fl._light(Vector3(0, 1, 0), 6.0, 6.0, 0.5)
		else:
			for e in inside: tick(e))
	while true:
		await wait(10.0)


func _scythes() -> void:
	frame(Vector3(2.8, 5.0, 8.6), Vector3(4.6, 0.6, 0))
	var es := [enemy(3.2, 0.0), enemy(7.2, 1.1), enemy(7.9, -0.9)]
	await wait(0.2)
	while true:
		var s = fx("scythe_projectile")
		s.global_position = Vector3(0.5, 1.1, 0)
		s.launch(player, Vector3.RIGHT)
		var near := {}
		var turned := false
		while is_instance_valid(s):
			if s.returning and not turned:
				turned = true
				_vortex(Vector3(s.global_position.x, 0.0, s.global_position.z), es)
			for e in es:
				var d := Vector2(s.global_position.x - e.global_position.x, s.global_position.z - e.global_position.z).length()
				if d < 0.9 and not near.get(e, false):
					near[e] = true; tick(e)
				elif d > 1.4:
					near[e] = false
			await get_tree().process_frame
		await wait(0.9)


func _vortex(g: Vector3, es: Array) -> void:
	var pivot := Node3D.new(); add_child(pivot); pivot.global_position = g + Vector3(0, 0.25, 0)
	var vl := OmniLight3D.new(); vl.light_color = fl.pal("acc"); vl.light_energy = 3.0; vl.omni_range = 3.5; pivot.add_child(vl); vl.position = Vector3(0, 0.6, 0)
	for spec in [[fl._smoke_ramp(fl.pal("mid"), 0.7), 0.34, 46], [fl._smoke_ramp(fl.pal("deep"), 0.85), 0.3, 30], [fl._ramp_of(fl.pal("core"), fl.pal("acc"), fl.pal("mid")), 0.07, 50]]:
		var p = fl._em(spec[2], 0.9, spec[1], false, spec[0], Vector3(0, 1.2, 0), 0.0, 0.2)
		p.local_coords = true
		var pm := p.process_material as ParticleProcessMaterial
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		pm.emission_ring_radius = 1.1; pm.emission_ring_inner_radius = 0.5; pm.emission_ring_height = 0.1; pm.emission_ring_axis = Vector3.UP
		pivot.add_child(p); p.emitting = true
	var tw := pivot.create_tween()
	tw.tween_method(func(t: float) -> void: pivot.rotation.y = t * TAU * 1.6; pivot.scale = Vector3.ONE * (1.0 - maxf(t - 0.75, 0.0) * 3.5), 0.0, 1.0, 1.6)
	tw.tween_callback(pivot.queue_free)
	fl.spikes(g, 10, 1.0, 1.1)
	for e in es:
		if Vector2(e.global_position.x - g.x, e.global_position.z - g.z).length() < 2.2:
			flash(e)
			get_tree().create_timer(0.7).timeout.connect(tick.bind(e))


func _shotgun() -> void:
	frame(Vector3(1.6, 4.6, 9.5), Vector3(3.4, 0.8, 0))
	var close := [enemy(2.6, 0.5), enemy(3.4, -0.6)]
	var walker := enemy(6.5, 0.2)
	var muzzle := Vector3(0.55, 1.2, 0)
	await wait(0.2)
	while true:
		walker.position.x = 6.5
		var b = fx("shotgun_blast"); b.global_position = muzzle; b.look_at(muzzle + Vector3.RIGHT)
		await wait(0.04)
		for e in close: flash(e); knock(e, Vector3.RIGHT, 0.7, 0.1)
		_wall(Vector3(3.6, 0, 0), 1.7)
		var wt := create_tween()   # an enemy walks into the wall and keeps burning
		wt.tween_property(walker, "position:x", 3.9, 1.0)
		wt.tween_callback(func() -> void: tick(walker))
		wt.tween_interval(0.35); wt.tween_callback(func() -> void: tick(walker))
		await wait(2.2)


func _wall(c: Vector3, life: float) -> void:
	var strip := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.9, 0.02, 3.8)
	var mm := _unlit(Color(fl.pal("mid"), 0.75), true)
	strip.mesh = bm; strip.material_override = mm; add_child(strip); strip.global_position = c + Vector3(0, 0.02, 0)
	strip.scale = Vector3(1, 1, 0.05)
	var tw := strip.create_tween()
	tw.tween_property(strip, "scale", Vector3.ONE, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_interval(life)
	tw.tween_method(func(a: float) -> void: mm.albedo_color = Color(fl.pal("deep"), a), 0.75, 0.0, 0.4)
	tw.tween_callback(strip.queue_free)
	for spec in [[fl._ramp_of(fl.pal("core"), fl.pal("mid"), fl.pal("acc")), 0.2, 90, 0.6, Vector3(0, 3.0, 0)],
				[fl._smoke_ramp(fl.pal("smoke"), 0.8), 0.5, 30, 1.4, Vector3(0, 1.8, 0)]]:
		var p = fl._em(spec[2], spec[3], spec[1], false, spec[0], spec[4], 0.2, 0.6, 15, Vector3.UP)
		var pm := p.process_material as ParticleProcessMaterial
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX; pm.emission_box_extents = Vector3(0.35, 0.05, 1.8)
		add_child(p); p.global_position = c + Vector3(0, 0.1, 0); p.emitting = true
		get_tree().create_timer(life).timeout.connect(func() -> void: if is_instance_valid(p): p.emitting = false)
		fl._free_later(p, life + spec[3] + 0.3)
	fl._light(c + Vector3(0, 0.8, 0), 5.0, 5.0, life)


func _sword() -> void:
	frame(Vector3(-1.4, 4.6, 7.4), Vector3(2.8, 0.9, 0))
	var e := enemy(2.0, 0.0)
	var far := [enemy(4.8, -0.8), enemy(5.6, 0.7)]
	var s = fx("sword_slash")
	s.global_position = Vector3(0.2, 1.1, 0)
	s.look_at(Vector3(2.0, 1.1, 0))
	var n := [0]
	s.slash_hit.connect(func() -> void:
		n[0] += 1
		tick(e); knock(e, Vector3.RIGHT, 0.3, 0.06)
		if n[0] % 3 == 0:
			_crescent(Vector3(0.6, 1.0, 0), far + [e]))
	await wait(0.2)
	while true:
		await s.burst(3)
		await wait(1.3)


func _crescent(from: Vector3, hits: Array) -> void:
	var node := Node3D.new(); add_child(node); node.global_position = from
	shake(0.15, 0.06)
	for layer_i in 2:   # violet outer band, white-hot inner band
		var im := ImmediateMesh.new()
		var mi := MeshInstance3D.new(); mi.mesh = im
		mi.material_override = _unlit(Color(fl.pal("mid"), 0.85) if layer_i == 0 else fl.pal("core"), layer_i == 0)
		(mi.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
		node.add_child(mi)
		var r0 := 1.2 if layer_i == 0 else 1.05
		var w := 0.5 if layer_i == 0 else 0.12
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var segs := 14
		for k in segs:
			var a0 := lerpf(-1.2, 1.2, float(k) / segs); var a1 := lerpf(-1.2, 1.2, float(k + 1) / segs)
			var t0 := 1.0 - absf(a0) / 1.2; var t1 := 1.0 - absf(a1) / 1.2
			var y := 0.01 * layer_i
			var o0 := Vector3(cos(a0) * r0, y, sin(a0) * r0); var o1 := Vector3(cos(a1) * r0, y, sin(a1) * r0)
			var i0 := Vector3(cos(a0) * (r0 - w * t0), y, sin(a0) * (r0 - w * t0)); var i1 := Vector3(cos(a1) * (r0 - w * t1), y, sin(a1) * (r0 - w * t1))
			for v in [o0, o1, i1, o0, i1, i0]: im.surface_add_vertex(v)
		im.surface_end()
	var tr = fl._em(60, 0.4, 0.07, false, fl._ramp_of(fl.pal("core"), fl.pal("mid"), fl.pal("deep")), Vector3.ZERO, 0.0, 0.4)
	(tr.process_material as ParticleProcessMaterial).emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	(tr.process_material as ParticleProcessMaterial).emission_box_extents = Vector3(0.1, 0.05, 1.0)
	node.add_child(tr); tr.position = Vector3(1.0, 0, 0); tr.emitting = true
	var light := OmniLight3D.new(); light.light_color = fl.pal("mid"); light.light_energy = 3.0; light.omni_range = 3.5; node.add_child(light)
	var dist := 6.5
	var tw := node.create_tween()
	tw.tween_property(node, "global_position", from + Vector3(dist, 0, 0), 0.5)
	tw.parallel().tween_property(node, "scale", Vector3(1.4, 1, 1.6), 0.5)
	tw.tween_callback(func() -> void: tr.emitting = false; node.visible = false)
	tw.tween_interval(0.5); tw.tween_callback(node.queue_free)
	for e in hits:
		var t: float = maxf((e.global_position.x - from.x - 1.0) / dist * 0.5, 0.0)
		get_tree().create_timer(t).timeout.connect(func() -> void: flash(e); knock(e, Vector3.RIGHT, 0.4, 0.08))


func _firestaff() -> void:
	frame(Vector3(3.6, 4.8, 11.0), Vector3(4.4, 0.8, 0))
	var e := enemy(7.0, 0.0)
	var ring := [enemy(6.0, 1.6), enemy(8.3, -1.2), enemy(8.0, 1.5), enemy(5.9, -1.4)]
	var start := Vector3(0.6, 1.5, 0)
	await wait(0.2)
	while true:
		var tgt := chest(e) + Vector3(0, 0.1, 0)
		var f = fx("fireball")
		f.scale = Vector3.ONE * 1.5
		fl.trail(f, 1.4)
		f.global_position = start; f.look_at(tgt); f.max_distance = start.distance_to(tgt) - 0.3
		await f.arrived
		flash(e); knock(e, Vector3.RIGHT, 0.6, 0.1)
		fl.steam(tgt, 1.4)
		for i in ring.size():   # the comet splits; meteors rain down on the pack
			var m: MeshInstance3D = ring[i]
			var land := chest(m)
			var sky := land + Vector3(-1.0, 3.4, 0.4)
			get_tree().create_timer(0.18 + i * 0.12).timeout.connect(func() -> void:
				var mt = fx("fireball")
				mt.scale = Vector3.ONE * 0.6
				mt.speed = 16.0
				mt.global_position = sky; mt.look_at(land); mt.max_distance = sky.distance_to(land)
				mt.arrived.connect(func(_p) -> void: flash(m); fl.steam(land, 0.6)))
		await wait(2.4)


# ------------------------------------------------------------------ the forging moment
func _forge() -> void:
	var wname: String = fl.display_name(WEAPON_NAMES.get(weapon, "Weapon"))
	frame(Vector3(0.0, 2.0, 4.2), Vector3(0.0, 1.5, 0))
	player.visible = false
	for p in [Vector3(-2.6, 0, -2.0), Vector3(2.8, 0, -1.6), Vector3(-1.4, 0, -3.6), Vector3(1.6, 0, -3.8)]:
		enemy(p.x, p.z)
	var env := (get_children().filter(func(c) -> bool: return c is WorldEnvironment)[0] as WorldEnvironment).environment
	# the weapon: a simple bone-coloured blade standing in for the real model
	var wpn := Node3D.new(); add_child(wpn); wpn.position = Vector3(0, 1.5, 0)
	var wm := StandardMaterial3D.new(); wm.albedo_color = Color("E8E2D0"); wm.roughness = 1.0
	var parts := []
	var specs := [[Vector3(0.12, 1.1, 0.04), Vector3(0, 0.25, 0), 0.0], [Vector3(0.5, 0.08, 0.08), Vector3(0, -0.32, 0), 0.0], [Vector3(0.07, 0.32, 0.07), Vector3(0, -0.52, 0), 0.0]]
	if weapon == "bow":   # a bow: curved limb out of 7 segments plus a string
		specs = []
		for k in 7:
			var a := lerpf(-1.05, 1.05, k / 6.0)
			specs.append([Vector3(0.08, 0.26, 0.06), Vector3(-cos(a) * 0.55 + 0.35, sin(a) * 0.62, 0), -a * 0.9])
		specs.append([Vector3(0.015, 1.12, 0.015), Vector3(0.12, 0.0, 0), 0.0])
	for spec in specs:
		var b := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = spec[0]; b.mesh = bm; b.material_override = wm
		wpn.add_child(b); b.position = spec[1]; b.rotation.z = spec[2]; parts.append(b)
	var spin := wpn.create_tween().set_loops()
	spin.tween_property(wpn, "rotation:y", TAU, 3.0).from(0.0)
	var ui := CanvasLayer.new(); add_child(ui)
	var white := ColorRect.new(); white.color = Color(1, 1, 1, 0); white.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(white)
	var vig := ColorRect.new(); vig.color = Color(0.03, 0.03, 0.03, 0); vig.set_anchors_preset(Control.PRESET_FULL_RECT); ui.add_child(vig)
	await wait(0.4)
	# 1. time slows, the world darkens
	var tw := create_tween().set_parallel(true)
	tw.tween_property(env, "background_color", Color(0.07, 0.07, 0.08), 0.5)
	tw.tween_property(env, "ambient_light_energy", 0.25, 0.5)
	tw.tween_property(env, "fog_light_color", Color(0.07, 0.07, 0.08), 0.5)
	tw.tween_property(vig, "color:a", 0.35, 0.5)
	await wait(0.4)
	# 2. the two gems orbit the weapon and spiral in
	var g := []
	for i in 2:
		var m := MeshInstance3D.new(); m.mesh = fl._octa(); m.material_override = _unlit(fl.gem_color(i)); m.scale = Vector3.ONE * 0.14
		add_child(m)
		var t = fl._em(40, 0.5, 0.06, false, fl._ramp_of(FusionLayer.PAL[gems[i]]["core"], fl.gem_color(i), FusionLayer.PAL[gems[i]]["deep"]), Vector3.ZERO, 0.0, 0.1)
		m.add_child(t); t.emitting = true
		var l := OmniLight3D.new(); l.light_color = fl.gem_color(i); l.light_energy = 2.0; l.omni_range = 2.5; m.add_child(l)
		g.append(m)
	var orbit := create_tween()
	orbit.tween_method(func(t: float) -> void:
		var rad := lerpf(1.3, 0.0, pow(t, 1.6))
		for i in 2:
			var a := t * TAU * 2.6 + PI * i
			g[i].global_position = Vector3(0, 1.55 + sin(t * 9.0 + i) * 0.1 * (1.0 - t), 0) + Vector3(cos(a) * rad, 0, sin(a) * rad * 0.6)
			g[i].rotation.y = t * 20.0, 0.0, 1.0, 1.5).set_ease(Tween.EASE_IN)
	await orbit.finished
	# 3. they collide: flash, the weapon shatters into shards and re-forms in the Fusion's colours
	for m in g: m.queue_free()
	white.color.a = 0.9
	create_tween().tween_property(white, "color:a", 0.0, 0.35)
	fl._plasma_pop(Vector3(0, 1.55, 0), 1.6)
	for p in parts: p.visible = false
	var r := RandomNumberGenerator.new(); r.seed = 3
	var shards := []
	for i in 16:
		var s := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3.ONE * r.randf_range(0.05, 0.11)
		s.mesh = bm; s.material_override = _unlit(fl.pal("core") if i % 3 == 0 else (fl.pal("mid") if i % 2 else fl.pal("acc")))
		add_child(s)
		var home := Vector3(r.randf_range(-0.06, 0.06), 1.5 + r.randf_range(-0.55, 0.8), 0)
		s.global_position = home
		var out := home + Vector3(r.randf_range(-1.6, 1.6), r.randf_range(-0.6, 1.0), r.randf_range(-0.6, 0.6))
		var st := s.create_tween()
		st.tween_property(s, "global_position", out, 0.22).set_ease(Tween.EASE_OUT)
		st.parallel().tween_property(s, "rotation", Vector3(r.randf() * 6, r.randf() * 6, 0), 0.22)
		st.tween_interval(0.12)
		st.tween_property(s, "global_position", home, 0.28).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		st.tween_callback(s.queue_free)
		shards.append(s)
	await wait(0.64)
	# re-formed: fused material, trail and orbiting motes
	wm.albedo_color = fl.pal("core")
	for k in parts.size():   # the re-formed weapon alternates the Fusion's two hues
		parts[k].material_override = _unlit(fl.pal("mid") if k % 2 == 0 else fl.pal("acc"))
	if weapon == "bow": parts[-1].material_override = _unlit(fl.pal("core"))
	for p in parts: p.visible = true
	fl.trail(wpn, 1.0)
	fl.motes(wpn)
	white.color.a = 0.6
	create_tween().tween_property(white, "color:a", 0.0, 0.3)
	fl._light(Vector3(0, 1.5, 0.6), 8.0, 5.0, 0.6)
	# 4. the name card slams down
	_name_card(ui, wname)
	await wait(3.5)


func _name_card(ui: CanvasLayer, wname: String) -> void:
	var serif := FontFile.new(); serif.load_dynamic_font("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf")
	var sans := FontFile.new(); sans.load_dynamic_font("/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf")
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new(); sb.bg_color = Color("E8E2D0"); sb.border_color = Color("7E1820"); sb.set_border_width_all(3)
	sb.border_width_top = 6; sb.border_color = Color("7E1820"); sb.content_margin_left = 22; sb.content_margin_right = 22; sb.content_margin_top = 8; sb.content_margin_bottom = 10
	sb.shadow_color = Color(fl.pal("mid"), 0.6); sb.shadow_size = 12
	card.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 0); card.add_child(v)
	var top := Label.new(); top.text = "FUSION FORGED  ·  %s" % FusionLayer.COMBO[fl.fusion].to_upper()
	top.add_theme_font_override("font", sans); top.add_theme_font_size_override("font_size", 10); top.add_theme_color_override("font_color", Color("7E1820"))
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(top)
	var nm := Label.new(); nm.text = wname
	nm.add_theme_font_override("font", serif); nm.add_theme_font_size_override("font_size", 30); nm.add_theme_color_override("font_color", Color("0E0F0E"))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(nm)
	var sub := Label.new(); sub.text = "%s  +  %s" % [str(gems[0]).capitalize(), str(gems[1]).capitalize()]
	sub.add_theme_font_override("font", sans); sub.add_theme_font_size_override("font_size", 11); sub.add_theme_color_override("font_color", fl.pal("deep"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; v.add_child(sub)
	ui.add_child(card)
	await get_tree().process_frame
	card.position = Vector2((640 - card.size.x) / 2.0, 262)
	card.pivot_offset = card.size / 2.0
	card.rotation = deg_to_rad(-1.5)
	card.scale = Vector2.ONE * 1.8; card.modulate.a = 0.0
	var tw := card.create_tween().set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_IN)
	tw.tween_property(card, "modulate:a", 1.0, 0.1)


# ------------------------------------------------------------------ overview: all six impacts
func _impacts() -> void:
	frame(Vector3(0, 4.0, 10.8), Vector3(0, 1.0, 0))
	player.visible = false
	var order := [["fire", "ice"], ["electric", "fire"], ["electric", "ice"], ["corrosive", "electric"], ["corrosive", "fire"], ["corrosive", "ice"]]
	var layers := []
	var dummies := []
	for i in order.size():
		var x := -5.5 + i * 2.2
		var L = FusionLayer.new(); add_child(L); L.setup_fusion(order[i][0], order[i][1]); layers.append(L)
		dummies.append(enemy(x, 0))
		var lab := Label3D.new(); lab.text = FusionLayer.NAMES[L.fusion].to_upper()
		lab.font = FontFile.new(); (lab.font as FontFile).load_dynamic_font("/usr/share/fonts/truetype/dejavu/DejaVuSansCondensed-Bold.ttf")
		lab.font_size = 40; lab.pixel_size = 0.006; lab.modulate = L.pal("acc") if L.fusion == "rimerot" else L.pal("mid"); lab.outline_size = 10; lab.outline_modulate = Color(0.05, 0.05, 0.05)
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED; lab.position = Vector3(x, 2.35, 0); add_child(lab)
	await wait(0.3)
	while true:
		for i in order.size():
			var m: MeshInstance3D = dummies[i]; var L = layers[i]
			HitFlash.flash(m, Color.WHITE, 0.08)
			L.impact(m.global_position + Vector3(0, 0.25, 0))
			get_tree().create_timer(0.08).timeout.connect(L.status.bind(m))
			await wait(0.22)
		await wait(1.6)

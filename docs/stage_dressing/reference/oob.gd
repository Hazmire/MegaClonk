## Megaclonk — Calvary Run: one farmland arena, four stage dressings.
## The playable terrain is identical every stage (same generator, same seed here). Only the ground textures,
## the fog, the skybox and the out-of-bounds backdrop rings change.
##   godot --path . --script res://oob.gd -- stage=1 shot=edge out=res://oob_1.png
extends SceneTree

const HALF := 48.0
const CELL := 2.0
var world: Node3D
var noise := FastNoiseLite.new()
var _tex := {}

const STAGES := {
	"1": {"sky": "alt1_calvary_run_hollow_skyonly_pano_2048", "top": "s1_grass", "side": "s1_soil_wall", "low": "a1_brown_creek",
		"fog": Color("9AA093"), "amb": Color("8C978F"), "sun": Color("C9CEC8"), "dens": 0.005, "veil": Color("A7B0A6"), "fx": "rain", "strip": "s1"},
	"2": {"sky": "alt2_route9_tipple_skyonly_pano_2048", "top": "s2_dead_grass", "side": "s2_clay_wall", "low": "a2_coal_slag",
		"fog": Color("A8713C"), "amb": Color("9A7A5A"), "sun": Color("F0B070"), "dens": 0.005, "veil": Color("B8844C"), "fx": "dust", "strip": "s2"},
	"3": {"sky": "alt3_downtown_skyonly_pano_2048", "top": "s3_scorched", "side": "s3_charred_wall", "low": "a3_wet_street",
		"fog": Color("6A2014"), "amb": Color("A04020"), "sun": Color("FF8A4A"), "dens": 0.0055, "veil": Color("7A2414"), "fx": "ash", "strip": "s3"},
	"4": {"sky": "alt4_no9_sinkhole_skyonly_pano_2048", "top": "s1_mud", "side": "a4_coal_rock", "low": "a1_brown_creek",
		"fog": Color("1E1414"), "amb": Color("5A4040"), "sun": Color("8A6A6A"), "dens": 0.006, "veil": Color("2A1A18"), "fx": "blood", "strip": "s4"},
}


func arg(k: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(k + "="): return a.split("=")[1]
	return d


func tex(n: String) -> ImageTexture:
	if not _tex.has(n): _tex[n] = ImageTexture.create_from_image(Image.load_from_file("res://" + n + ".png"))
	return _tex[n]


func tmat(n: String, scale := 0.25, tint := Color.WHITE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_texture = tex(n); m.albedo_color = tint; m.roughness = 1.0
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.uv1_triplanar = true; m.uv1_world_triplanar = true; m.uv1_scale = Vector3.ONE * scale
	return m


# ------------------------------------------------------------------ the arena (same for every stage)
func height(x: float, z: float) -> float:
	var n := noise.get_noise_2d(x, z) * 0.5 + 0.5
	return floor(n * 5.0) * 3.0


func terrain(c: Dictionary) -> void:
	var tops := SurfaceTool.new(); tops.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lows := SurfaceTool.new(); lows.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := SurfaceTool.new(); sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := int(HALF * 2 / CELL)
	for i in n:
		for j in n:
			var x0 := -HALF + i * CELL; var z0 := -HALF + j * CELL
			var h := height(x0 + CELL / 2, z0 + CELL / 2)
			_q(lows if h == 0.0 else tops, Vector3(x0, h, z0), Vector3(x0 + CELL, h, z0), Vector3(x0 + CELL, h, z0 + CELL), Vector3(x0, h, z0 + CELL))
			if i < n - 1:
				var h2 := height(x0 + CELL * 1.5, z0 + CELL / 2)
				if h2 != h: _q(sides, Vector3(x0 + CELL, h, z0), Vector3(x0 + CELL, h2, z0), Vector3(x0 + CELL, h2, z0 + CELL), Vector3(x0 + CELL, h, z0 + CELL))
			if j < n - 1:
				var h3 := height(x0 + CELL / 2, z0 + CELL * 1.5)
				if h3 != h: _q(sides, Vector3(x0, h, z0 + CELL), Vector3(x0 + CELL, h, z0 + CELL), Vector3(x0 + CELL, h3, z0 + CELL), Vector3(x0, h3, z0 + CELL))
	# torn edge where the arena ends
	for side in 4:
		for k in n:
			var t0 := -HALF + k * CELL; var t1 := t0 + CELL
			var p0: Vector3; var p1: Vector3
			match side:
				0: p0 = Vector3(t0, 0, -HALF); p1 = Vector3(t1, 0, -HALF)
				1: p0 = Vector3(t1, 0, HALF); p1 = Vector3(t0, 0, HALF)
				2: p0 = Vector3(-HALF, 0, t1); p1 = Vector3(-HALF, 0, t0)
				3: p0 = Vector3(HALF, 0, t0); p1 = Vector3(HALF, 0, t1)
			var mid := (p0 + p1) / 2.0
			var hh := height(clampf(mid.x, -HALF + 0.5, HALF - 0.5), clampf(mid.z, -HALF + 0.5, HALF - 0.5))
			_q(sides, Vector3(p1.x, hh, p1.z), Vector3(p0.x, hh, p0.z), Vector3(p0.x, hh - 30, p0.z), Vector3(p1.x, hh - 26, p1.z))
	for pair in [[tops, tmat(c.top)], [lows, tmat(c.low, 0.18)], [sides, tmat(c.side)]]:
		var st: SurfaceTool = pair[0]; st.generate_normals()
		var mi := MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = pair[1]; world.add_child(mi)


func _q(st: SurfaceTool, a: Vector3, b: Vector3, cc: Vector3, d: Vector3) -> void:
	for v in [a, b, cc, a, cc, d]: st.add_vertex(v)


func veil(c: Dictionary) -> void:
	var sh := load("res://veil.gdshader")
	for layer in 2:
		var off := HALF + 9.0 + layer * 6.0
		for s in 4:
			var mi := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(off * 2.0, 360.0); mi.mesh = q
			var sm := ShaderMaterial.new(); sm.shader = sh
			sm.set_shader_parameter("fog_color", c.veil); sm.set_shader_parameter("density", 0.2 + layer * 0.08)
			mi.material_override = sm; mi.position.y = 150.0
			match s:
				0: mi.position.z = -off
				1: mi.position.z = off; mi.rotation.y = PI
				2: mi.position.x = -off; mi.rotation.y = PI / 2
				3: mi.position.x = off; mi.rotation.y = -PI / 2
			world.add_child(mi)


# ------------------------------------------------------------------ the out-of-bounds backdrop
## One open cylinder per layer, textured with a seamless RGBA strip (8:1). Unshaded with a hard alpha
## cut-out (PSX look); the scene fog still tints it, so further rings fade more. Three rings at different
## radii give real parallax as the player runs around. Cost: 3 draw calls, no lighting, no shadows.
func backdrop_ring(strip: String, radius: float, repeats: int, base_y: float, haze: float, haze_col: Color) -> MeshInstance3D:
	var circ := TAU * radius
	var h := circ / (repeats * 16.0)                 # strip (8:1) + its mirror per lap = 16:1
	# our own open cylinder so the strip maps exactly: u runs around the ring, v from top (0) to bottom (1)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 128
	for i in segs:
		var a0 := TAU * i / segs; var a1 := TAU * (i + 1) / segs
		var u0 := float(i) / segs; var u1 := float(i + 1) / segs
		var p0t := Vector3(cos(a0) * radius, h / 2.0, sin(a0) * radius); var p1t := Vector3(cos(a1) * radius, h / 2.0, sin(a1) * radius)
		var p0b := Vector3(p0t.x, -h / 2.0, p0t.z); var p1b := Vector3(p1t.x, -h / 2.0, p1t.z)
		for v in [[p0t, Vector2(u0, 0)], [p1t, Vector2(u1, 0)], [p1b, Vector2(u1, 1)], [p0t, Vector2(u0, 0)], [p1b, Vector2(u1, 1)], [p0b, Vector2(u0, 1)]]:
			st.set_uv(v[1]); st.add_vertex(v[0])
	var cm := st.commit()
	var m := ShaderMaterial.new(); m.shader = load("res://backdrop.gdshader")
	m.set_shader_parameter("strip", tex(strip)); m.set_shader_parameter("repeats", Vector2(repeats, 1))
	m.set_shader_parameter("haze", haze); m.set_shader_parameter("haze_color", haze_col)
	var mi := MeshInstance3D.new(); mi.mesh = cm; mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi); mi.position = Vector3(0, base_y + h / 2.0, 0)
	return mi


func backdrop(c: Dictionary) -> void:
	backdrop_ring(c.strip + "_far", 240.0, 1, -12.0, 0.55, c.fog)
	backdrop_ring(c.strip + "_mid", 150.0, 1, -4.0, 0.3, c.fog)
	backdrop_ring(c.strip + "_near", 90.0, 1, 0.0, 0.1, c.fog)


func particles(kind: String, at: Vector3) -> void:
	var ps := GPUParticles3D.new(); ps.preprocess = 6.0
	var pm := ParticleProcessMaterial.new(); pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	var q := QuadMesh.new(); var qm := StandardMaterial3D.new(); qm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	qm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; qm.vertex_color_use_as_albedo = true; q.material = qm
	if kind in ["rain", "blood"]:
		ps.amount = 3000; ps.lifetime = 2.0; qm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		pm.direction = Vector3(-0.15, -1, 0); pm.spread = 2; pm.initial_velocity_min = 22; pm.initial_velocity_max = 26; pm.gravity = Vector3(0, -9.8, 0)
		pm.color = Color(0.85, 0.9, 0.86, 0.3) if kind == "rain" else Color(0.6, 0.05, 0.04, 0.55)
		q.size = Vector2(0.025, 0.7); pm.emission_box_extents = Vector3(30, 1, 30); ps.position = at + Vector3(0, 18, -18)
	else:
		ps.amount = 900; ps.lifetime = 10.0; qm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		pm.emission_box_extents = Vector3(26, 8, 26); pm.direction = Vector3(0.4, 1, 0) if kind == "dust" else Vector3(0.3, -1, 0); pm.spread = 40
		pm.initial_velocity_min = 0.2; pm.initial_velocity_max = 0.7; pm.gravity = Vector3(0.1, 0.02, 0) if kind == "dust" else Vector3(0.2, -0.3, 0)
		pm.color = Color(0.85, 0.7, 0.5, 0.6) if kind == "dust" else Color(0.75, 0.68, 0.64, 0.9)
		q.size = Vector2(0.08, 0.08); ps.position = at + Vector3(0, 3, -14)
	ps.process_material = pm; ps.draw_pass_1 = q; ps.visibility_aabb = AABB(Vector3(-80, -40, -80), Vector3(160, 80, 160))
	world.add_child(ps)


func _initialize() -> void:
	var stage := arg("stage", "1"); var c: Dictionary = STAGES[stage]
	noise.seed = 1337; noise.frequency = 0.022; noise.fractal_octaves = 3
	world = Node3D.new(); get_root().add_child(world)
	var sky_mat := PanoramaSkyMaterial.new(); sky_mat.panorama = tex(c.sky); sky_mat.filter = false
	var sky := Sky.new(); sky.sky_material = sky_mat
	var env := Environment.new(); env.background_mode = Environment.BG_SKY; env.sky = sky; env.sky_rotation = Vector3(0, PI, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = c.amb; env.ambient_light_energy = 0.55
	env.fog_enabled = true; env.fog_light_color = c.fog; env.fog_density = c.dens; env.fog_sky_affect = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new(); we.environment = env; world.add_child(we)
	var sun := DirectionalLight3D.new(); sun.light_color = c.sun; sun.light_energy = 0.7; sun.rotation_degrees = Vector3(-38, 25, 0); world.add_child(sun)
	terrain(c); if arg("veil", "1") == "1": veil(c)
	backdrop(c)
	var shot := arg("shot", "edge")
	var cam := Camera3D.new(); cam.fov = 70; world.add_child(cam)
	if shot == "edge" or shot == "pan":   # standing near the north edge, looking out past the boundary
		var p := Vector3(6, 0, -22); p.y = (12.0 if shot == "pan" else height(p.x, p.z)) + 5.5
		cam.transform = Transform3D(Basis(), p).looking_at(Vector3(-10, p.y + 3.0, -200), Vector3.UP)
	elif shot == "debug":
		var yaw := float(arg("yaw", "0")); cam.transform = Transform3D(Basis(), Vector3(0, 20, 0)).looking_at(Vector3(sin(yaw) * -100, 20, cos(yaw) * -100), Vector3.UP); cam.fov = 90; env.fog_enabled = false
	else:                 # high overview: the arena, the fog wall and the rings around it
		cam.transform = Transform3D(Basis(), Vector3(30, 46, 70)).looking_at(Vector3(-10, 8, -60), Vector3.UP); cam.fov = 72
	cam.current = true
	particles(c.fx, cam.position)
	if shot == "pan":   # recorded with --write-movie: strafe along the edge to show the parallax
		_cam = cam; _p0 = cam.position
		return
	for i in 40: await process_frame
	get_root().get_texture().get_image().save_png(arg("out", "res://oob.png"))
	quit()


var _cam: Camera3D
var _p0 := Vector3.ZERO
var _t := 0.0


func _process(delta: float) -> bool:
	if _cam == null: return false
	_t += 1.0 / 30.0
	var k := sin(_t / 6.0 * TAU) * 0.5 + 0.5
	_cam.position = _p0 + Vector3(lerpf(-34.0, 30.0, k), 0, 0)
	_cam.look_at(_cam.position + Vector3(-0.05, 0.02, -1.0), Vector3.UP)
	return false

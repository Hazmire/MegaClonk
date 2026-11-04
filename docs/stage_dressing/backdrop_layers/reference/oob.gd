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


const APRON_R := 86.0   # the visual apron: terrain continues out to this radius, beyond the wall

## Apron height: the same generator continued past the edge, so there is no seam at the wall. With distance
## the terraces relax toward one low level (3 m), so the far apron never walls off the backdrop.
func apron_height(x: float, z: float) -> float:
	var d := maxf(absf(x), absf(z)) - HALF
	var k := smoothstep(4.0, APRON_R - HALF, d) * 0.85
	return round(lerpf(height(x, z), 3.0, k) / 3.0) * 3.0


func terrain(c: Dictionary) -> void:
	var tops := SurfaceTool.new(); tops.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lows := SurfaceTool.new(); lows.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := SurfaceTool.new(); sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	var apron := arg("apron", "1") == "1"
	var ext := APRON_R if apron else HALF
	var n := int(ext * 2 / CELL)
	var hf := func(x: float, z: float) -> float:
		if maxf(absf(x), absf(z)) < HALF: return height(x, z)
		return apron_height(x, z)
	var inside := func(x: float, z: float) -> bool:
		if maxf(absf(x), absf(z)) < HALF: return true
		return apron and Vector2(x, z).length() < APRON_R
	for i in n:
		for j in n:
			var x0 := -ext + i * CELL; var z0 := -ext + j * CELL
			var cx := x0 + CELL / 2; var cz := z0 + CELL / 2
			if not inside.call(cx, cz): continue
			var h: float = hf.call(cx, cz)
			_q(lows if h == 0.0 else tops, Vector3(x0, h, z0), Vector3(x0 + CELL, h, z0), Vector3(x0 + CELL, h, z0 + CELL), Vector3(x0, h, z0 + CELL))
			if inside.call(cx + CELL, cz):
				var h2: float = hf.call(cx + CELL, cz)
				if h2 != h: _q(sides, Vector3(x0 + CELL, h, z0), Vector3(x0 + CELL, h2, z0), Vector3(x0 + CELL, h2, z0 + CELL), Vector3(x0 + CELL, h, z0 + CELL))
			if inside.call(cx, cz + CELL):
				var h3: float = hf.call(cx, cz + CELL)
				if h3 != h: _q(sides, Vector3(x0, h, z0 + CELL), Vector3(x0 + CELL, h, z0 + CELL), Vector3(x0 + CELL, h3, z0 + CELL), Vector3(x0, h3, z0 + CELL))
	# torn edge where the arena ends (only without the apron)
	for side in (4 if not apron else 0):
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
		var off := (HALF + 9.0 + layer * 6.0) if arg("apron", "1") != "1" else (HALF + 18.0 + layer * 14.0)
		for s in 4:
			var mi := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(off * 2.0, 360.0); mi.mesh = q
			var sm := ShaderMaterial.new(); sm.shader = sh
			sm.set_shader_parameter("fog_color", c.veil); sm.set_shader_parameter("density", 0.2 + layer * 0.08); veil_mats.append(sm)
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
func backdrop_ring(strip: String, radius: float, repeats: int, ground_y: float, haze: float, haze_col: Color, fog_floor: float, fog_band: float) -> MeshInstance3D:
	var circ := TAU * radius
	var t := tex(strip)
	var h := circ * float(t.get_height()) / (repeats * 2.0 * t.get_width())   # strip + its mirror per lap
	# place the ring so the strip's ground line (measured by the generator) sits at ground_y
	var gpx: float = STRIPS.ground_px_from_bottom[strip]
	var base_y := ground_y - gpx * h / float(t.get_height())
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
	m.set_shader_parameter("fog_floor", fog_floor); m.set_shader_parameter("fog_band", fog_band)
	var mi := MeshInstance3D.new(); mi.mesh = cm; mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi); mi.position = Vector3(0, base_y + h / 2.0, 0)
	print(strip, ": r ", radius, "  h ", snappedf(h, 0.1), "  bottom y ", snappedf(base_y, 0.1), "  ground line y ", ground_y)
	return mi


const OUTER_DROP := 4.0   # outer ground sits this far below the lowest terrain

## Render-only flat ring of ground from just outside the torn edge to past the far backdrop ring.
func outer_ground(c: Dictionary) -> void:
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r0 := HALF * 1.5; var r1 := 240.0 * 1.1; var y := -OUTER_DROP; var segs := 96
	# a square hole the size of the arena (+ a margin) so it never shows through the playable ground
	for i in segs:
		var a0 := TAU * i / segs; var a1 := TAU * (i + 1) / segs
		var i0 := Vector3(cos(a0), 0, sin(a0)); var i1 := Vector3(cos(a1), 0, sin(a1))
		var in0 := i0 * (HALF + 2.0) / maxf(absf(i0.x), absf(i0.z)); var in1 := i1 * (HALF + 2.0) / maxf(absf(i1.x), absf(i1.z))
		in0.y = y; in1.y = y
		var o0 := i0 * r1 + Vector3(0, y, 0); var o1 := i1 * r1 + Vector3(0, y, 0)
		for v in [in0, o0, o1, in0, o1, in1]: st.add_vertex(v)
	st.generate_normals()
	var m := tmat(c.low, 0.12, Color(0.6, 0.6, 0.6))
	var mi := MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; world.add_child(mi)


## The boundary fence: posts snapped to the terrain along the perimeter wall, styled per stage.
func boundary_fence(c: Dictionary) -> void:
	var style: Dictionary = {
		"s1": {"post": Color("3A2E24"), "wire": Color("1A1612"), "h": 1.3, "gap": 3.0, "wires": 3, "panel": false, "stripes": false},
		"s2": {"post": Color("5A5A56"), "wire": Color("3A3A38"), "h": 2.0, "gap": 3.0, "wires": 2, "panel": true, "stripes": false},
		"s3": {"post": Color("6A5A48"), "wire": Color("C8401F"), "h": 1.1, "gap": 2.6, "wires": 1, "panel": false, "stripes": true},
		"s4": {"post": Color("2A2018"), "wire": Color("8A1E1A"), "h": 1.5, "gap": 3.4, "wires": 1, "panel": false, "stripes": false},
	}[c.strip]
	var pm := StandardMaterial3D.new(); pm.albedo_color = style.post; pm.roughness = 1.0
	var wm := StandardMaterial3D.new(); wm.albedo_color = style.wire; wm.roughness = 1.0
	var inset := 1.0
	var sides := [[Vector3(-HALF, 0, -HALF + inset), Vector3(HALF, 0, -HALF + inset)], [Vector3(-HALF, 0, HALF - inset), Vector3(HALF, 0, HALF - inset)],
		[Vector3(-HALF + inset, 0, -HALF), Vector3(-HALF + inset, 0, HALF)], [Vector3(HALF - inset, 0, -HALF), Vector3(HALF - inset, 0, HALF)]]
	var link: ImageTexture
	if style.panel:   # chain-link panel texture, cut-out
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for y in 16:
			for x in 16:
				var on := (x + y) % 8 == 0 or (x - y + 16) % 8 == 0
				img.set_pixel(x, y, Color(0.35, 0.35, 0.33, 1.0 if on else 0.0))
		link = ImageTexture.create_from_image(img)
	for sd in sides:
		var a: Vector3 = sd[0]; var b: Vector3 = sd[1]; var L := a.distance_to(b); var dir := (b - a).normalized()
		var d := 0.5; var prev := Vector3.INF; var k := 0
		while d < L:
			var p := a + dir * d
			var y := height(clampf(p.x, -HALF + 0.5, HALF - 0.5), clampf(p.z, -HALF + 0.5, HALF - 0.5))
			var top := Vector3(p.x, y + style.h, p.z)
			var post := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(0.14, style.h, 0.14); post.mesh = bm; post.material_override = pm
			world.add_child(post); post.position = Vector3(p.x, y + style.h / 2, p.z); post.rotation.z = (sin(k * 1.7) * 0.06)
			if prev != Vector3.INF and absf(prev.y - top.y) < 0.2:
				for w in style.wires:
					var off := Vector3(0, -style.h * (0.15 + 0.3 * w), 0)
					var wa := prev + off; var wb := top + off
					var seg := MeshInstance3D.new(); var sm := BoxMesh.new()
					sm.size = Vector3(0.03, 0.03 if not style.stripes else 0.22, wa.distance_to(wb)); seg.mesh = sm; seg.material_override = wm
					world.add_child(seg); seg.transform = Transform3D(Basis(), (wa + wb) / 2).looking_at(wb, Vector3.UP)
					if style.stripes and k % 2 == 0: seg.material_override = pm
				if style.panel:
					var q := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = Vector2(prev.distance_to(top), style.h * 0.9); q.mesh = qm
					var lm := StandardMaterial3D.new(); lm.albedo_texture = link; lm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
					lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR; lm.cull_mode = BaseMaterial3D.CULL_DISABLED
					lm.uv1_scale = Vector3(qm.size.x / 0.5, qm.size.y / 0.5, 1); q.material_override = lm
					world.add_child(q); var mid := (prev + top) / 2 - Vector3(0, style.h * 0.47, 0)
					q.transform = Transform3D(Basis(), mid).looking_at(mid + dir.cross(Vector3.UP), Vector3.UP)
			prev = top; d += style.gap; k += 1
			if c.strip == "s4" and k % 3 == 0:   # candles at the foot of every third timber
				var cd := MeshInstance3D.new(); var cm := BoxMesh.new(); cm.size = Vector3(0.06, 0.2, 0.06); cd.mesh = cm
				var cmat := StandardMaterial3D.new(); cmat.albedo_color = Color("FFC060"); cmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; cd.material_override = cmat
				world.add_child(cd); cd.position = Vector3(p.x, y + 0.1, p.z) - Vector3(dir.z, 0, -dir.x) * 0.3


## A rolling fog sea filling the void around the arena, just below the lowest terrain, plus a second, higher
## and thinner layer that the backdrop ring silhouettes rise out of.
func fog_sea(c: Dictionary) -> void:
	var sh := load("res://fogsea.gdshader")
	for layer in [[-0.6, 1.0, 1.0], [2.5, 0.55, 0.82]]:
		var pm := PlaneMesh.new(); pm.size = Vector2(560, 560); pm.subdivide_width = 0; pm.subdivide_depth = 0
		var m := ShaderMaterial.new(); m.shader = sh
		var fc: Color = c.fog
		m.set_shader_parameter("fog_color", fc.lightened(0.06)); m.set_shader_parameter("deep_color", fc.darkened(0.18))
		m.set_shader_parameter("arena_half", Vector2(HALF, HALF)); m.set_shader_parameter("density", layer[1])
		m.set_shader_parameter("edge_soft", 6.0 if layer[0] < 0 else 26.0)
		fog_mats.append(m)
		var mi := MeshInstance3D.new(); mi.mesh = pm; mi.material_override = m; mi.position.y = layer[0]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; world.add_child(mi)


var fog_mats := []
var veil_mats := []
var stage_c: Dictionary
var env: Environment


## The layers rise away from the arena like the sides of a valley: each ground line is higher than the one in
## front, and every one is above the top plateau (12 m), so from anywhere in the arena each ridge shows over the
## nearer one and you never look down onto a strip's foot. Values: radius, ground line y, haze, fog floor, fog band.
const LAYERS := [["far", 240.0, 52.0, 0.55, 26.0, 26.0], ["mid", 150.0, 30.0, 0.35, 13.0, 17.0], ["near", 90.0, 15.0, 0.3, 4.0, 11.0]]
var STRIPS: Dictionary


func backdrop(c: Dictionary) -> void:
	STRIPS = JSON.parse_string(FileAccess.get_file_as_string("res://strips.json"))
	for l in LAYERS: backdrop_ring(c.strip + "_" + l[0], l[1], 1, l[2], l[3], c.fog, l[4], l[5])


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
	env = Environment.new(); env.background_mode = Environment.BG_SKY; env.sky = sky; env.sky_rotation = Vector3(0, PI, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = c.amb; env.ambient_light_energy = 0.55
	env.fog_enabled = true; env.fog_light_color = c.fog; env.fog_density = c.dens; env.fog_sky_affect = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new(); we.environment = env; world.add_child(we)
	var sun := DirectionalLight3D.new(); sun.light_color = c.sun; sun.light_energy = 0.7; sun.rotation_degrees = Vector3(-38, 25, 0); world.add_child(sun)
	terrain(c); if arg("veil", "1") == "1": veil(c)
	if arg("fix", "1") == "1":
		outer_ground(c); boundary_fence(c)
	stage_c = c
	if arg("fogsea", "1") == "1":
		fog_sea(c)
		# height fog: anything below the arena's lowest level thickens fast
		env.fog_height = 0.0; env.fog_height_density = 0.35
	backdrop(c)
	var shot := arg("shot", "edge")
	var cam := Camera3D.new(); cam.fov = 70; world.add_child(cam)
	if shot == "low":   # the lowest ground near the north edge, eye height, looking out
		var lp := Vector3.INF
		var lowest := 99.0
		for xi in range(-45, 46, 2):
			for zi in range(-47, -20, 2): lowest = minf(lowest, height(xi, zi))
		for zi in range(-47, -20, 2):   # nearest cell to the north edge on the lowest level, clear for 6 m behind
			for xi in range(-41, 42, 2):
				if lp != Vector3.INF: break
				var ok := true
				for dz in range(0, 8, 2):
					for dx in [-2, 0, 2]: ok = ok and height(xi + dx, zi + dz) == lowest
				if ok: lp = Vector3(xi, lowest, zi)
		if lp == Vector3.INF: lp = Vector3(0, 0, -47)
		print("low cam at ", lp)
		cam.transform = Transform3D(Basis(), lp + Vector3(0, 1.9, 6.0)).looking_at(Vector3(lp.x, lp.y + 0.5, -160), Vector3.UP)
	elif shot == "plateau":   # standing on the highest terrace nearest the north edge, looking out (worst case)
		var best := Vector3(0, -1, 0)
		for zi in range(-46, -10, 2):
			for xi in range(-44, 45, 2):
				var hh := height(xi, zi)
				if hh > best.y or (hh == best.y and zi < best.z): best = Vector3(xi, hh, zi)
		print("plateau cam at ", best)
		var pp := best + Vector3(0, 5.5, 6.0)
		cam.transform = Transform3D(Basis(), pp).looking_at(Vector3(pp.x - 8, pp.y - 2.0, -200), Vector3.UP)
	elif shot == "edge" or shot == "pan":   # standing near the north edge, looking out past the boundary
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

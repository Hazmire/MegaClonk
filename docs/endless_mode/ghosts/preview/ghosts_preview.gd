## Preview for the endless-mode ghosts.
##   godot --path . --script res://ghosts_preview.gd -- mode=lineup|swarm stage=1 out=res://ghosts.png
extends SceneTree

const GhostScript := preload("res://ghost/ghost.gd")
const HeroScript := preload("res://hero.gd")
const SKIES := {"1": ["alt1_calvary_run_hollow_skyonly_pano_2048", Color("9AA093"), Color("8C978F"), "s1_grass", "s1"],
	"3": ["alt3_downtown_skyonly_pano_2048", Color("6A2014"), Color("A04020"), "s3_scorched", "s3"],
	"4": ["alt4_no9_sinkhole_skyonly_pano_2048", Color("1E1414"), Color("5A4040"), "s1_mud", "s4"]}
var world: Node3D
var player: Node3D
var cam: Camera3D
var mode := "lineup"
var t := 0.0
var spawn_acc := 0.0
var rng := RandomNumberGenerator.new()
var ghosts := []
var _tex := {}


func arg(k: String, d: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(k + "="): return a.split("=")[1]
	return d


func tex(n: String) -> ImageTexture:
	if not _tex.has(n): _tex[n] = ImageTexture.create_from_image(Image.load_from_file("res://" + n + ".png"))
	return _tex[n]


func ring(strip: String, radius: float, base_y: float, haze: float, col: Color) -> void:
	var h := TAU * radius / 16.0
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 128:
		var a0 := TAU * i / 128; var a1 := TAU * (i + 1) / 128
		var p0 := Vector3(cos(a0) * radius, h / 2, sin(a0) * radius); var p1 := Vector3(cos(a1) * radius, h / 2, sin(a1) * radius)
		var q0 := Vector3(p0.x, -h / 2, p0.z); var q1 := Vector3(p1.x, -h / 2, p1.z)
		for v in [[p0, Vector2(i / 128.0, 0)], [p1, Vector2((i + 1) / 128.0, 0)], [q1, Vector2((i + 1) / 128.0, 1)], [p0, Vector2(i / 128.0, 0)], [q1, Vector2((i + 1) / 128.0, 1)], [q0, Vector2(i / 128.0, 1)]]:
			st.set_uv(v[1]); st.add_vertex(v[0])
	var m := ShaderMaterial.new(); m.shader = load("res://backdrop.gdshader")
	m.set_shader_parameter("strip", tex(strip)); m.set_shader_parameter("haze", haze); m.set_shader_parameter("haze_color", col)
	var mi := MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = m; world.add_child(mi); mi.position.y = base_y + h / 2


func _initialize() -> void:
	mode = arg("mode", "lineup"); var s: Array = SKIES[arg("stage", "1")]
	rng.seed = 9
	world = Node3D.new(); get_root().add_child(world)
	var sky_mat := PanoramaSkyMaterial.new(); sky_mat.panorama = tex(s[0]); sky_mat.filter = false
	var sky := Sky.new(); sky.sky_material = sky_mat
	var env := Environment.new(); env.background_mode = Environment.BG_SKY; env.sky = sky; env.sky_rotation = Vector3(0, PI, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = s[2]; env.ambient_light_energy = 0.5
	env.fog_enabled = true; env.fog_light_color = s[1]; env.fog_density = 0.012; env.fog_sky_affect = 0.0; env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new(); we.environment = env; world.add_child(we)
	var sun := DirectionalLight3D.new(); sun.light_energy = 0.7; sun.rotation_degrees = Vector3(-38, 25, 0); world.add_child(sun)
	var g := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(300, 300); g.mesh = pm
	var gm := StandardMaterial3D.new(); gm.albedo_texture = tex(s[3]); gm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	gm.uv1_triplanar = true; gm.uv1_world_triplanar = true; gm.uv1_scale = Vector3.ONE * 0.25; g.material_override = gm; world.add_child(g)
	ring(s[4] + "_far", 240.0, -12.0, 0.55, s[1]); ring(s[4] + "_mid", 150.0, -4.0, 0.3, s[1]); ring(s[4] + "_near", 90.0, 0.0, 0.1, s[1])
	cam = Camera3D.new(); world.add_child(cam); cam.current = true
	if mode == "lineup":
		var tiers := ["mourner", "drowned", "wrathful", "hollow"]
		var font := FontFile.new(); font.load_dynamic_font("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf")
		for i in 4:
			var gh := Node3D.new(); gh.set_script(GhostScript); gh.tier = tiers[i]; world.add_child(gh)
			gh.position = Vector3(-4.2 + i * 2.8, 0.25, 0); gh.rotation.y = PI - 0.55
			var l := Label3D.new(); l.text = tiers[i].to_upper(); l.font = font; l.font_size = 28; l.pixel_size = 0.008
			l.modulate = GhostScript.TIERS[tiers[i]].rim; l.outline_size = 8; l.outline_modulate = Color(0, 0, 0, 0.8)
			l.position = Vector3(-4.2 + i * 2.8, 0.45, 1.2); world.add_child(l)
		cam.fov = 55; cam.transform = Transform3D(Basis(), Vector3(0, 1.45, 5.6)).looking_at(Vector3(0, 1.25, 0), Vector3.UP)
		for i in 50: await process_frame
		get_root().get_texture().get_image().save_png(arg("out", "res://ghosts_lineup.png"))
		quit()
	elif mode == "portrait":   # one ghost, close, three-quarter from the front
		var gh := Node3D.new(); gh.set_script(GhostScript); gh.tier = arg("tier", "mourner"); world.add_child(gh)
		gh.position = Vector3(0, 0.3, 0); gh.rotation.y = PI - 0.5
		cam.fov = 50; cam.transform = Transform3D(Basis(), Vector3(-0.9, 1.75, 2.5)).looking_at(Vector3(0.1, 1.45, 0.1), Vector3.UP)
		for i in 50: await process_frame
		get_root().get_texture().get_image().save_png(arg("out", "res://ghost_portrait.png"))
		quit()
	else:
		player = HeroScript.Investigator.new(); world.add_child(player); player.rotation.y = PI   # faces -Z
		player.wind = 0.6
		cam.fov = 62


func _process(delta: float) -> bool:
	if mode != "swarm" or player == null: return false
	var dt := 1.0 / 30.0
	t += dt
	player.step(dt)
	player.rotation.y = PI + sin(t * 0.5) * 0.4
	cam.transform = Transform3D(Basis(), Vector3(0, 4.2, 7.5)).looking_at(Vector3(0, 1.6, -5), Vector3.UP)
	# endless escalation, compressed: mourners, then drowned, wrathful and finally the hollow
	spawn_acc += dt * (6.0 + t * 1.2)
	while spawn_acc >= 1.0:
		spawn_acc -= 1.0
		var r := rng.randf()
		var tier := "mourner"
		if t > 1.5 and r < 0.6: tier = "drowned"
		if t > 3.5 and r < 0.45: tier = "wrathful"
		if t > 5.5 and r < 0.3: tier = "hollow"
		var gh := Node3D.new(); gh.set_script(GhostScript); gh.tier = tier; gh.speed = rng.randf_range(6.0, 9.0) * (1.25 if tier == "wrathful" else 1.0) * (0.8 if tier == "hollow" else 1.0)
		world.add_child(gh)
		var a := rng.randf_range(-PI * 0.95, PI * 0.15) - PI / 2   # mostly from in front and the sides
		gh.position = Vector3(cos(a) * 24.0, rng.randf_range(1.5, 7.0), sin(a) * 34.0)
		gh.target = player
		gh.set_fade(0.0)
		ghosts.append([gh, 0.0, false])
	for e in ghosts:
		if not is_instance_valid(e[0]): continue
		var gh: Node3D = e[0]
		e[1] += dt
		if not e[2]:
			gh.set_fade(minf(e[1] / 0.6, 1.0))   # materialise over 0.6 s
			if gh.global_position.distance_to(player.global_position + Vector3(0, 1.0, 0)) < 1.4:
				e[2] = true; e[1] = 0.0
		else:
			gh.set_fade(maxf(1.0 - e[1] / 0.25, 0.0))   # dissipate on contact
			gh.speed = 1.0
			if e[1] > 0.25: gh.queue_free()
	return false

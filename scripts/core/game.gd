extends Node3D

const STAGE_SECONDS = 180.0
const ENEMY_LIMIT = 500
var rng = RandomNumberGenerator.new()
var progress = Progress.new()
var stats = Catalog.base_stats()
var player: BonkPlayer
var world: Node3D
var ui: CanvasLayer
var panel: PanelContainer
var hud: Label
var notice: Label
var health_bar: ProgressBar
var xp_bar: ProgressBar
var enemies: Array[Dictionary] = []
var projectiles: Array[Dictionary] = []
var fields: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var interactables: Array[Dictionary] = []
var weapons: Dictionary = {}
var tomes: Dictionary = {}
var items: Array = []
var effects: Array[Dictionary] = []
var grid: Dictionary = {}
var prop_batches: Dictionary = {}
var mode = "menu"
var sandbox = false
var character = 0
var biome = 0
var tier = 1
var stage = 1
var elapsed = 0.0
var stage_time = 0.0
var health = 100.0
var xp = 0.0
var level = 1
var kills = 0
var gold = 0
var gold_fraction = 0.0
var damage_total = 0.0
var damage_by_weapon: Dictionary = {}
var spawn_clock = 0.0
var invulnerability = 0.0
var boss_spawned = false
var boss_dead = false
var portal: Node3D
var terrain_noise = FastNoiseLite.new()
var selected_character = 0
var selected_biome = 0
var selected_tier = 1
var message_time = 0.0
var passive_clock = 0.0
var moving_time = 0.0
var banished: Array = []
var rerolls = 3
var choices: Array = []
var settings = {"render_scale":1.0,"quality":1,"master":0.7,"effects":0.7,"music":0.3,"sensitivity":0.0025,"invert":false,"reduced":false,"fps":false,"focus_pause":true,"shake":true,"numbers":true,"invincible":false}
var pending_binding = ""
var bindings = {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"jump":KEY_SPACE,"sprint":KEY_SHIFT,"interact":KEY_E,"inspect":KEY_TAB}
var music: AudioStreamPlayer
var sfx: Array[AudioStreamPlayer] = []
var sfx_cursor = 0
var pool: MeshPool
var enemy_mesh: MultiMeshInstance3D
var enemy_material: StandardMaterial3D
var smoke_mode = false
var smoke_step = 0
var smoke_frames = 0
var smoke_failures: Array = []

func _ready() -> void:
 rng.seed = 7371
 progress.load_save()
 settings.merge(progress.data.settings, true)
 if settings.has("bindings"):
  for key in bindings:
   if settings.bindings.has(key): bindings[key] = int(settings.bindings[key])
 for action in bindings:
  InputMap.add_action(action)
  var event = InputEventKey.new()
  event.physical_keycode = int(bindings[action])
  InputMap.action_add_event(action, event)
 setup_audio()
 ui = CanvasLayer.new()
 add_child(ui)
 var theme = Theme.new()
 theme.default_font_size = 19
 var style = StyleBoxFlat.new()
 style.bg_color = Color("182637")
 style.border_color = Color("5ed6c0")
 style.set_border_width_all(2)
 style.set_corner_radius_all(9)
 style.content_margin_left = 22
 style.content_margin_right = 22
 style.content_margin_top = 16
 style.content_margin_bottom = 16
 theme.set_stylebox("panel", "PanelContainer", style)
 var root = Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 root.theme = theme
 ui.add_child(root)
 panel = PanelContainer.new()
 panel.position = Vector2(60, 38)
 panel.custom_minimum_size = Vector2(650, 0)
 root.add_child(panel)
 hud = Label.new()
 hud.position = Vector2(24, 15)
 hud.add_theme_color_override("font_shadow_color", Color.BLACK)
 hud.add_theme_constant_override("shadow_offset_x", 2)
 hud.add_theme_constant_override("shadow_offset_y", 2)
 root.add_child(hud)
 health_bar = ProgressBar.new()
 health_bar.position = Vector2(24, 110)
 health_bar.size = Vector2(330, 20)
 var fill = StyleBoxFlat.new()
 fill.bg_color = Color("e56d80")
 fill.set_corner_radius_all(4)
 health_bar.add_theme_stylebox_override("fill", fill)
 health_bar.show_percentage = false
 root.add_child(health_bar)
 xp_bar = ProgressBar.new()
 xp_bar.position = Vector2(24, 136)
 xp_bar.size = Vector2(330, 12)
 var xp_fill = StyleBoxFlat.new()
 xp_fill.bg_color = Color("62d9c1")
 xp_fill.set_corner_radius_all(3)
 xp_bar.add_theme_stylebox_override("fill", xp_fill)
 xp_bar.show_percentage = false
 root.add_child(xp_bar)
 notice = Label.new()
 notice.position = Vector2(400, 610)
 notice.add_theme_color_override("font_color", Color("ffe09b"))
 root.add_child(notice)
 build_menu_world()
 main_menu()
 smoke_mode = "--smoke" in OS.get_cmdline_user_args()
 if smoke_mode:
  sandbox = true
  begin_run()

func mesh_node(mesh: Mesh, color: Color, parent: Node3D, pos: Vector3 = Vector3.ZERO, emissive: bool = false) -> MeshInstance3D:
 var node = MeshInstance3D.new()
 node.mesh = mesh
 var material = StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.9
 if emissive:
  material.emission_enabled = true
  material.emission = color
  material.emission_energy_multiplier = 1.4
 node.material_override = material
 parent.add_child(node)
 node.position = pos
 return node
func sphere(radius: float = 0.5) -> SphereMesh:
 var mesh = SphereMesh.new()
 mesh.radius = radius
 mesh.height = radius * 2
 mesh.radial_segments = 8
 mesh.rings = 4
 return mesh
func box(size: Vector3) -> BoxMesh:
 var mesh = BoxMesh.new()
 mesh.size = size
 return mesh
func cylinder(radius: float, height: float, top: float = -1.0) -> CylinderMesh:
 var mesh = CylinderMesh.new()
 mesh.bottom_radius = radius
 mesh.top_radius = radius if top < 0 else top
 mesh.height = height
 mesh.radial_segments = 7
 return mesh
func title(text: String, parent: Node, size: int = 28) -> Label:
 var label = Label.new()
 label.text = text
 label.add_theme_font_size_override("font_size", size)
 parent.add_child(label)
 return label
func button(text: String, parent: Node, callback: Callable) -> Button:
 var node = Button.new()
 node.text = text
 node.custom_minimum_size.y = 40
 parent.add_child(node)
 node.pressed.connect(func(): tone(660, 0.06); callback.call())
 return node
func clear_panel(heading: String) -> VBoxContainer:
 hud.hide()
 health_bar.hide()
 xp_bar.hide()
 for child in panel.get_children():
  panel.remove_child(child)
  child.queue_free()
 panel.show()
 var column = VBoxContainer.new()
 column.add_theme_constant_override("separation", 8)
 var scroll=ScrollContainer.new()
 scroll.custom_minimum_size=Vector2(650,570)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 scroll.follow_focus=true
 panel.add_child(scroll)
 scroll.add_child(column)
 column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 title(heading, column)
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 if is_instance_valid(player): player.active = false
 return column
func main_menu() -> void:
 mode = "menu"
 hud.hide()
 health_bar.hide()
 xp_bar.hide()
 var col = clear_panel("BONK  /  INFINITY")
 title("SURVIVE • EVOLVE • BREAK THE HORDE", col, 16)
 title("Original playable foundation · reference balance unverified", col, 14)
 var select = OptionButton.new()
 for i in Catalog.CHARACTERS.size():
  select.add_item(Catalog.CHARACTERS[i][0] + ("" if i in progress.data.unlocked or sandbox else "  [LOCKED · %d lifetime kills]" % ((i - 1) * 80)))
 select.selected = selected_character
 select.item_selected.connect(func(i): selected_character = i; build_menu_world(); main_menu())
 col.add_child(select)
 var char_data = Catalog.CHARACTERS[selected_character]
 title("%s  •  %s\n%s" % [char_data[0], Catalog.WEAPONS[char_data[1]][0], char_data[2]], col, 18)
 var maps = OptionButton.new()
 for name in ["Verdant Reach / Forest", "Sunken Sun / Desert", "Hollow Vigil / Graveyard"]: maps.add_item(name)
 maps.selected = selected_biome
 maps.item_selected.connect(func(i): selected_biome = i)
 col.add_child(maps)
 var tiers = OptionButton.new()
 for name in ["Tier I · Wanderer", "Tier II · Challenger", "Tier III · Cataclysm"]: tiers.add_item(name)
 tiers.selected = selected_tier - 1
 tiers.item_selected.connect(func(i): selected_tier = i + 1)
 col.add_child(tiers)
 var play = button("ENTER THE WILD", col, begin_run)
 play.disabled = not sandbox and not selected_character in progress.data.unlocked
 button("Sandbox: " + ("ON · progression disabled" if sandbox else "OFF"), col, func(): sandbox = not sandbox; main_menu())
 var row = HBoxContainer.new()
 col.add_child(row)
 button("Progress & unlocks", row, show_progress)
 button("Settings", row, func(): settings_menu(main_menu))
 button("Quit", row, func(): get_tree().quit())
 title("WASD move   •   Mouse look   •   Space jump   •   Shift sprint\nE interact   •   Tab build   •   Esc pause   •   F11 fullscreen", col, 15)
 play.grab_focus()
func build_menu_world() -> void:
 if is_instance_valid(world):
  remove_child(world)
  world.queue_free()
 world = Node3D.new()
 add_child(world)
 var environment = WorldEnvironment.new()
 var env = Environment.new()
 env.background_mode = Environment.BG_COLOR
 env.background_color = Color("101c2a")
 env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.ambient_light_color = Color("bbd2e5")
 env.ambient_light_energy = 0.45
 env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 environment.environment = env
 world.add_child(environment)
 var sun = DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-48, -35, 0)
 sun.light_color = Color("ffe9ba")
 sun.light_energy = 0.9
 sun.shadow_enabled = true
 world.add_child(sun)
 var camera = Camera3D.new()
 world.add_child(camera)
 camera.position = Vector3(16, 13, 20)
 camera.look_at(Vector3.ZERO)
 camera.current = true
 mesh_node(cylinder(8, 1), Color("31575a"), world, Vector3(10, -1, -10))
 create_avatar(world, selected_character, Vector3(10,0,-10)).scale = Vector3.ONE * 3
func create_avatar(parent: Node3D, index: int, pos: Vector3) -> Node3D:
 var node = Node3D.new()
 parent.add_child(node)
 node.position = pos
 var palette=["df8c4c","728ca8","e0ddc9","ce9e78","7c9b54","8ba8aa","c7b58e","7c9b5e","9b7257","70cbde","3f6a42","ecce75","b1e5ef","a6c74d","9ba9db","ae8362","514b71","a35169","694c9a","e5e0d2","72a193"]
 var color = Color(palette[index])
 mesh_node(cylinder(0.37, 0.8, 0.27), color, node, Vector3(0, 0.85, 0))
 mesh_node(sphere(0.28), Color("f4d3b0") if index % 3 else color.lightened(0.2), node, Vector3(0, 1.45, 0))
 for side in [-1, 1]:
  var leg = mesh_node(box(Vector3(0.18, 0.5, 0.22)), color.darkened(0.4), node, Vector3(side * 0.2, 0.3, 0))
  leg.set_meta("side",side)
  mesh_node(box(Vector3(0.16, 0.55, 0.2)), color, node, Vector3(side * 0.46, 0.85, 0))
  mesh_node(sphere(0.055), Color("17202b"), node, Vector3(side * 0.1, 1.49, 0.24))
 # Combinatorial original silhouettes: horns, crowns, hats, shoulder pieces.
 var hat = mesh_node(cylinder(0.38, 0.18 + (index % 4) * 0.1, 0.05 if index % 2 else 0.3), color.darkened(0.3), node, Vector3(0, 1.8, 0))
 hat.rotation.z = (index % 3 - 1) * 0.12
 if index==0:
  mesh_node(cylinder(0.18,0.9,0.03),color,node,Vector3(0,0.7,-0.5)).rotation.x=-0.8
 if index % 3 == 0:
  for side in [-1, 1]:
   mesh_node(cylinder(0.12, 0.35, 0), color, node, Vector3(side * 0.24, 1.9, 0))
 return node
func begin_run() -> void:
 character = selected_character
 biome = selected_biome
 tier = selected_tier
 stage = 1
 stats = Catalog.base_stats()
 match character:
  2, 9: stats.speed += 0.15
  4: stats.max_health += 30
  6: stats.thorns += 5
  10: stats.crit_damage += 0.75
  14: stats.xp += 0.3
  16: stats.evasion += 0.15
  17: stats.lifesteal += 0.03
  18: stats.damage += tier * 0.2
 health = stats.max_health
 xp = 0
 level = 1
 kills = 0
 gold = 0
 gold_fraction = 0
 elapsed = 0
 damage_total = 0
 damage_by_weapon.clear()
 weapons.clear()
 tomes.clear()
 items.clear()
 banished.clear()
 rerolls = 3
 passive_clock = 0
 moving_time = 0
 equip(Catalog.CHARACTERS[character][1])
 build_stage()
 resume()
func equip(id: int) -> void:
 if weapons.has(id): weapons[id].level = mini(10, weapons[id].level + 1)
 elif weapons.size() < 4: weapons[id] = {"level":1,"clock":0.1,"visuals":[],"summons":[]}
func terrain_height(x: float, z: float) -> float:
 var radial = Vector2(x, z).length()
 var h = terrain_noise.get_noise_2d(x, z) * 8.0 + sin(x * 0.045) * cos(z * 0.055) * 3.0
 return lerpf(0, h, smoothstep(5, 22, radial))
func build_stage() -> void:
 enemies.clear()
 projectiles.clear()
 fields.clear()
 pickups.clear()
 effects.clear()
 interactables.clear()
 grid.clear()
 prop_batches.clear()
 for id in weapons:
  weapons[id]["visuals"] = []
  weapons[id]["summons"] = []
 stage_time = 0
 spawn_clock = 0
 boss_spawned = false
 boss_dead = false
 portal = null
 build_menu_world()
 for child in world.get_children():
  if child is Camera3D or child is MeshInstance3D or (child is Node3D and not child is Light3D and not child is WorldEnvironment): child.queue_free()
 terrain_noise.seed = 8127 + biome * 101 + stage * 73
 terrain_noise.frequency = 0.018
 var colors = [Color("304f3d"),Color("9b7e51"),Color("353947")]
 var env = world.get_child(0).environment
 env.background_color = [Color("668e9b"),Color("b8a07c"),Color("343a58")][biome]
 env.fog_enabled = true
 env.fog_light_color = env.background_color
 env.fog_density = 0.003 if biome < 2 else 0.009
 var surface = SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for x in range(-90, 90, 3):
  for z in range(-90, 90, 3):
   for offset in [Vector2(0,0),Vector2(3,0),Vector2(0,3),Vector2(3,0),Vector2(3,3),Vector2(0,3)]:
    var px = x + offset.x
    var pz = z + offset.y
    surface.set_color(colors[biome].lightened(rng.randf_range(-0.07, 0.08)))
    surface.add_vertex(Vector3(px, terrain_height(px,pz), pz))
 surface.generate_normals()
 var terrain = mesh_node(surface.commit(), Color.WHITE, world)
 var terrain_mat = terrain.material_override as StandardMaterial3D
 terrain_mat.vertex_color_use_as_albedo = true
 terrain.create_trimesh_collision()
 # Repeated biome props are instanced, with collision only for large rocks/ruins.
 for i in range(150):
  var p = Vector3(rng.randf_range(-84,84),0,rng.randf_range(-84,84))
  if Vector2(p.x,p.z).length() < 10: continue
  p.y = terrain_height(p.x,p.z)
  if biome == 0:
   prop_instance("trunks",cylinder(0.25,3),Color("755841"),p+Vector3.UP*1.5)
   prop_instance("leaves",cylinder(1.7,4,0),Color("254b40").lightened(rng.randf()*0.15),p+Vector3.UP*4)
  elif biome == 1:
   prop_instance("rocks",box(Vector3(2,2,2)),Color("997448"),p+Vector3.UP,Vector3(1,rng.randf_range(1,3),1))
  else:
   prop_instance("stones",box(Vector3(1,1.6,0.4)),Color("72798a"),p+Vector3.UP*0.8)
   if i % 5 == 0:
    prop_instance("dead_trees",box(Vector3(0.25,3,0.25)),Color("343743"),p+Vector3.UP*1.5)
 for i in range(12):
  var angle = i * TAU / 12
  var p = Vector3(cos(angle),0,sin(angle)) * (20 + (i%3)*14)
  p.y = terrain_height(p.x,p.z)
  var kind = ["Chest","Heal","Charge Shrine","Shop","Risk Shrine","Stat Shrine"][i % 6]
  var model = Node3D.new()
  world.add_child(model)
  model.position = p
  var color = [Color("efba5d"),Color("7fffd2"),Color("85baff"),Color("f4d3ff"),Color("ff7082"),Color("a8e47c")][i%6]
  mesh_node(cylinder(0.9,0.4),Color("626e7b"),model,Vector3.UP*0.2)
  mesh_node(box(Vector3(1,1,1)) if kind in ["Chest","Shop"] else cylinder(0.35,2,0.05),color,model,Vector3.UP, true)
  interactables.append({"node":model,"kind":kind,"used":false,"charge":0.0})
 pool = MeshPool.new()
 world.add_child(pool)
 player = BonkPlayer.new()
 player.stats = stats
 world.add_child(player)
 player.position = Vector3(0,3,0)
 player.avatar = create_avatar(player,character,Vector3.ZERO)
 player.can_climb = character == 8
 player.air_control = 22 if character == 11 else 13
 player.max_jumps = 3 if character == 11 else (2 if character == 8 else 1)
 player.sensitivity = settings.sensitivity
 player.inverted = settings.invert
 player.camera.current = true
 enemy_mesh = MultiMeshInstance3D.new()
 enemy_mesh.multimesh = MultiMesh.new()
 enemy_mesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
 enemy_mesh.multimesh.use_colors = true
 enemy_mesh.multimesh.mesh = build_enemy_mesh()
 enemy_mesh.multimesh.instance_count = ENEMY_LIMIT
 enemy_mesh.multimesh.visible_instance_count = 0
 enemy_material = StandardMaterial3D.new()
 enemy_material.vertex_color_use_as_albedo = true
 enemy_material.roughness = 0.8
 enemy_mesh.material_override = enemy_material
 world.add_child(enemy_mesh)
 toast("Stage %d / 3 • boss arrives in 3 minutes" % stage)
func resume() -> void:
 mode = "run"
 panel.hide()
 hud.show()
 health_bar.show()
 xp_bar.show()
 player.active = true
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
func toast(text: String) -> void:
 notice.text = text
 message_time = 4
func _unhandled_input(event: InputEvent) -> void:
 if pending_binding != "" and event is InputEventKey and event.pressed:
  InputMap.action_erase_events(pending_binding)
  var binding = InputEventKey.new()
  binding.physical_keycode = event.physical_keycode
  InputMap.action_add_event(pending_binding,binding)
  bindings[pending_binding] = int(event.physical_keycode)
  pending_binding = ""
  settings_menu(func(): pause_menu())
  return
 if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F11:
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
 if event.is_action_pressed("ui_cancel"):
  if mode == "run": pause_menu()
  elif mode in ["pause","build","settings","sandbox"]: resume()
 if event.is_action_pressed("inspect") and mode == "run": show_build()
func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and settings.focus_pause and mode == "run" and not smoke_mode: pause_menu()
func _physics_process(delta: float) -> void:
 if mode != "run": return
 if health <= 0:
  finish_run(false)
  return
 elapsed += delta
 stage_time += delta
 passive_clock += delta
 message_time -= delta
 if message_time <= 0: notice.text = ""
 player.camera.h_offset=lerpf(player.camera.h_offset,0,delta*12)
 invulnerability = maxf(0,invulnerability-delta)
 health = minf(stats.max_health,health+stats.regen*delta)
 if player.fall_hit > 0:
  hurt(player.fall_hit)
  player.fall_hit = 0
 if player.position.y < -30 or absf(player.position.x)>89 or absf(player.position.z)>89:
  hurt(12)
  player.position = Vector3(0,4,0)
 if player.velocity.length() > 3: moving_time += delta
 else: moving_time = maxf(0,moving_time-delta*2)
 if passive_clock >= 1:
  tick_passive()
  passive_clock -= 1
 spawn_clock -= delta
 if spawn_clock <= 0 and enemies.size() < ENEMY_LIMIT - 8:
  spawn_clock = maxf(0.12, 0.9 / (1+elapsed/90))
  for i in range(mini(1+stage+tier,ENEMY_LIMIT-enemies.size())): spawn_enemy()
 if stage_time > STAGE_SECONDS and not boss_spawned:
  boss_spawned = true
  spawn_enemy(8)
  tone(90,0.6)
  toast("WARDEN AWAKENED • defeat it to open the exit")
 update_enemies(delta)
 rebuild_grid()
 update_special_visuals(delta)
 update_weapons(delta)
 update_projectiles(delta)
 update_fields(delta)
 update_pickups(delta)
 update_effects(delta)
 update_interactions(delta)
 for i in range(enemies.size()-1,-1,-1):
  if enemies[i].hp <= 0: kill_enemy(i)
 update_hud()
 if health <= 0: finish_run(false)
func tick_passive() -> void:
 match character:
  3:
   if int(elapsed) % 12 == 0: invulnerability = 2; flash(player.position,Color("fff3ab"),3)
  9:
   if moving_time > 2:
    var target = nearest(player.position,12)
    if not target.is_empty(): hit(target,8+level,17); flash(target.pos,Color.CYAN,0.6)
  19:
   if int(elapsed) % 15 == 0:
    var names = ["damage","haste","speed","luck"]
    stats[names[rng.randi_range(0,3)]] += 0.04
  20:
   if int(elapsed) % 60 == 0: award_item()
func spawn_enemy(kind: int = -1, at: Vector3 = Vector3.INF) -> Dictionary:
 if enemies.size() >= ENEMY_LIMIT: return {}
 if kind < 0: kind = rng.randi_range(0, mini(7,2+int(elapsed/35)))
 var angle = rng.randf()*TAU
 var pos = player.position + Vector3(cos(angle),0,sin(angle))*rng.randf_range(25,38) if at == Vector3.INF else at
 pos.x = clampf(pos.x,-84,84)
 pos.z = clampf(pos.z,-84,84)
 pos.y = terrain_height(pos.x,pos.z)+0.7
 var scale_factor = (1+elapsed/140.0) * (1+(tier-1)*0.5) * (1+(stage-1)*0.5) * stats.difficulty
 var hp = (35 + kind*8) * scale_factor * (18 if kind==8 else 1)
 var enemy = {"pos":pos,"hp":hp,"max_hp":hp,"kind":kind,"speed":(4.5 if kind==1 else (1.8 if kind in [2,7] else 3.0)),"cooldown":rng.randf()*2,"slow":0.0,"frozen":0.0,"spore":false,"poison":0.0,"poison_clock":0.0,"knock":Vector3.ZERO,"age":0.0,"phase":0,"biome":biome,"target":Vector3.ZERO,"telegraph":0.0,"scale":2.8 if kind==8 else (1.4 if kind in [2,7] else 1.0)}
 enemies.append(enemy)
 return enemy
func update_enemies(delta: float) -> void:
 var colors = [Color("ee7d70"),Color("ffc05f"),Color("a28cae"),Color("e0d3a0"),Color("f55e67"),Color("b0dafa"),Color("aeef7a"),Color("80b9cb"),Color("cf7aff")]
 var mm = enemy_mesh.multimesh
 mm.visible_instance_count = enemies.size()
 for i in enemies.size():
  var e = enemies[i]
  if e.hp <= 0: continue
  e.age += delta
  e.cooldown -= delta
  e.slow = maxf(0,e.slow-delta)
  e.frozen = maxf(0,e.frozen-delta)
  e.poison = maxf(0,e.poison-delta)
  if e.poison > 0:
   e.poison_clock -= delta
   if e.poison_clock <= 0: hit(e,5+level,23); e.poison_clock = 0.5
  var direction = player.position-e.pos
  direction.y = 0
  var distance = direction.length()
  direction = direction.normalized()
  var speed = e.speed * (0.2 if e.slow>0 else 1.0)
  if e.kind == 3 and distance < 18:
   speed = -1 if distance<10 else 0
   if e.cooldown <= 0:
    hostile_bolt(e.pos,player.position)
    e.cooldown = 2.4
  if e.kind == 4:
   if e.cooldown <= 0:
    e.telegraph = 0.8
    e.cooldown = 3.8
    flash(e.pos,Color("ff4444"),2)
   if e.telegraph > 0:
    e.telegraph -= delta
    speed = 0 if e.telegraph>0.3 else 18
  if e.kind == 8:
   speed = 2.0
   if e.cooldown<=0:
    e.phase = (e.phase+1)%3
    e.telegraph = 1.4
    e.target = player.position
    e.cooldown = 4.0 if e.hp/e.max_hp > 0.5 else 2.8
    flash(e.target,Color("ff5a82"),4)
    effects.back().life=1.4
   if e.telegraph>0:
    speed = 0
    e.telegraph -= delta
    if e.telegraph <= 0:
     if e.phase == 0:
      for j in 12:
       var angle = j*TAU/12
       hostile_bolt(e.pos,e.pos+Vector3(cos(angle),0,sin(angle))*10)
     elif e.phase == 1:
      for j in 5: spawn_enemy(1,e.pos+Vector3(rng.randf_range(-3,3),0,rng.randf_range(-3,3)))
     else:
      var impact = e.target
      flash(impact,Color("ff718d"),5)
      if player.position.distance_to(impact)<5: hurt(22*tier); player.velocity += direction*12+Vector3.UP*5
     if e.biome==1:
      for j in 6:
       var angle=j*TAU/6+e.age
       hostile_bolt(e.pos,e.pos+Vector3(cos(angle),0,sin(angle))*10)
     if e.biome==2 and e.pos.distance_to(player.position)<18:
      hurt(4*tier)
      e.hp=minf(e.max_hp,e.hp+e.max_hp*0.015)
     flash(e.pos,Color("ff718d"),8)
  if e.frozen > 0: speed = 0
  e.pos += (direction*speed+e.knock)*delta
  e.knock = e.knock.move_toward(Vector3.ZERO,delta*15)
  e.pos.y = terrain_height(e.pos.x,e.pos.z)+0.65*e.scale+(2+sin(e.age*3) if e.kind==5 else 0)
  if distance < 1.1*e.scale+0.5 and e.cooldown<=0:
   hurt((8+stage*2+tier*2)*(2 if e.kind==8 else 1))
   if stats.thorns>0: hit(e,stats.thorns,0)
   e.cooldown = 1
   if e.kind==6: area(e.pos,4,25,-1); e.hp = 0
  var facing = atan2(direction.x,direction.z)
  var transform = Transform3D(Basis(Vector3.UP,facing).scaled(Vector3(0.8,1.2,0.8)*e.scale),e.pos)
  mm.set_instance_transform(i,transform)
  mm.set_instance_color(i,Color("91ddff") if e.slow>0 else (Color("b0ed72") if e.poison>0 else colors[e.kind]))
func rebuild_grid() -> void:
 grid.clear()
 for e in enemies:
  if e.hp<=0: continue
  var cell = Vector2i(floori(e.pos.x/8),floori(e.pos.z/8))
  if not grid.has(cell): grid[cell] = []
  grid[cell].append(e)
func nearby(pos: Vector3, radius: float) -> Array:
 var result: Array = []
 for x in range(floori((pos.x-radius)/8),floori((pos.x+radius)/8)+1):
  for z in range(floori((pos.z-radius)/8),floori((pos.z+radius)/8)+1):
   for e in grid.get(Vector2i(x,z),[]):
    if e.hp>0 and e.pos.distance_squared_to(pos)<radius*radius: result.append(e)
 return result
func nearest(pos: Vector3, radius: float, farthest: bool = false) -> Dictionary:
 var result: Dictionary = {}
 var best = 0.0 if farthest else radius*radius
 for e in nearby(pos,radius):
  var d = e.pos.distance_squared_to(pos)
  if (farthest and d>best) or (not farthest and d<best): best=d; result=e
 return result
func hurt(amount: float) -> void:
 if invulnerability>0 or (sandbox and settings.invincible): return
 if rng.randf()<minf(0.75,stats.evasion): toast("DODGED"); return
 health -= maxf(1,amount*100/(100+stats.armor*5))
 invulnerability = 0.5
 if settings.shake: player.camera.h_offset=rng.randf_range(-0.15,0.15)
 tone(130,0.1)
func hit(e: Dictionary, base: float, weapon: int) -> void:
 if e.is_empty() or e.hp<=0: return
 var critical = rng.randf()<stats.crit
 var amount = Catalog.damage(base,stats,critical)
 if character == 6: amount *= 1+(1-health/stats.max_health)*1.5
 if character == 7: amount *= 1+gold*0.001
 if character == 10 and e.hp/e.max_hp>0.9: amount*=1.5
 if character == 16 and e.hp/e.max_hp<0.1: amount = e.hp+1
 if e.kind == 7 and e.hp/e.max_hp > 0.5: amount *= 0.5
 e.hp -= amount
 e.knock += (e.pos-player.position).normalized()*stats.knockback*2
 if settings.numbers and effects.size()<60 and DisplayServer.get_name()!="headless":
  var number=Label3D.new()
  number.text=str(int(amount))+("!" if critical else "")
  number.font_size=42 if critical else 32
  number.modulate=Color("ffe6a0") if critical else Color.WHITE
  number.billboard=BaseMaterial3D.BILLBOARD_ENABLED
  number.no_depth_test=true
  world.add_child(number)
  number.position=e.pos+Vector3.UP
  effects.append({"node":number,"life":0.55})
 damage_total += amount
 damage_by_weapon[weapon] = damage_by_weapon.get(weapon,0.0)+amount
 health = minf(stats.max_health,health+amount*stats.lifesteal)
 if critical and not settings.reduced: flash(e.pos,Color("fff3aa"),0.4)
func area(pos: Vector3, radius: float, damage: float, weapon: int, status: String = "") -> void:
 for e in nearby(pos,radius):
  hit(e,damage,weapon)
  if status == "slow": e.slow = 2.0*stats.duration
  if status == "poison": e.poison = 4.0*stats.duration
func kill_enemy(index: int) -> void:
 var e = enemies[index]
 if character == 13 and e.poison>0: area(e.pos,4,12,23,"poison")
 if character == 12 and (e.slow>0 or e.frozen>0): health = minf(stats.max_health,health+2)
 if e.spore:
  area(e.pos,4*stats.size,12,33,"poison")
  flash(e.pos,Color("acff6a"),4)
 kills += 1
 if e.kind == 8:
  boss_dead = true
  make_portal()
  gold += 50
  award_item()
 for i in (6 if e.kind==8 else 1):
  var model = pool.acquire("xp",sphere(0.17),Color("6dffd8"),e.pos+Vector3(rng.randf()-0.5,0,rng.randf()-0.5))
  pickups.append({"node":model,"value":(5 if e.kind>=7 else 2),"age":0.0})
 if rng.randf()<0.3:
  gold_fraction+=stats.gold_gain
  var gained=int(gold_fraction)
  gold+=gained
  gold_fraction-=gained
 enemies.remove_at(index)
func make_portal() -> void:
 portal = Node3D.new()
 world.add_child(portal)
 var p = player.position + Vector3(7,0,0)
 p.y = terrain_height(p.x,p.z)
 portal.position = p
 var torus = TorusMesh.new()
 torus.inner_radius = 1.5
 torus.outer_radius = 2
 var ring = mesh_node(torus,Color("77ffe1"),portal,Vector3.UP*2,true)
 ring.rotation.x = PI/2
 toast("EXIT OPEN • approach the portal and press E")
func update_weapons(delta: float) -> void:
 for id in weapons:
  var state = weapons[id]
  state.clock -= delta
  if state.clock>0: continue
  var w = Catalog.WEAPONS[id]
  var rank = state.level
  var haste = stats.haste + (minf(moving_time,20)*0.02 if character==2 else 0)
  state.clock = float(w[3])/haste/(1+rank*0.045)
  var target = nearest(player.position,w[4]*stats.size,w[1] in ["beam","rail"])
  var power = float(w[2])*(1+(rank-1)*0.23)
  var radius = stats.size*(1+(rank-1)*0.07)
  var count = mini(12,int(stats.count)+(rank/3))
  var color = Color(w[5])
  var origin = player.position+Vector3.UP
  var direction = (target.pos-origin).normalized() if not target.is_empty() else Vector3.FORWARD.rotated(Vector3.UP,player.yaw)
  match w[1]:
   "aura","sweep","corrupt","reap","dash_slash","cone":
    var r = float(w[4])*radius
    for e in nearby(origin,r):
     if w[1] in ["aura","reap","corrupt"] or direction.dot((e.pos-origin).normalized())>0.1:
      hit(e,power,id)
      if w[1]=="corrupt": e.poison=3
    flash(origin,color,r)
    if w[1]=="reap": health = minf(stats.max_health,health+1)
   "orbit","chrono":
    for i in range(2+count):
     var angle = elapsed*3+i*TAU/(2+count)
     var p = origin+Vector3(cos(angle),0,sin(angle))*float(w[4])*radius
     area(p,2*radius,power,id,"slow" if w[1]=="chrono" else "")
     flash(p,color,0.7)
    if w[1]=="chrono" and rank>=6:
     for e in nearby(origin,7*radius): e.frozen=0.6*stats.duration
   "trail","frost_trail","mine":
    make_field(player.position,float(w[4])*radius,power,id,color,"slow" if w[1]=="frost_trail" else "",4*stats.duration,w[1]=="mine")
   "chain","drain","execute","freeze":
    if target.is_empty(): continue
    var list = nearby(target.pos,8*radius)
    list.sort_custom(func(a,b): return a.pos.distance_squared_to(target.pos)<b.pos.distance_squared_to(target.pos))
    for i in mini(list.size(),count+2):
     var e = list[i]
     hit(e,power*(2 if w[1]=="execute" and e.hp/e.max_hp<0.3 else 1),id)
     if w[1]=="freeze": e.frozen=1.5*stats.duration
     beam(origin,e.pos,color)
    if w[1]=="drain": health=minf(stats.max_health,health+3)
   "hitscan","beam","rail":
    if target.is_empty(): continue
    var length = float(w[4])
    var end = origin+direction*length
    beam(origin,end,color)
    var hits = 0
    for e in nearby(origin,length):
     var along = clampf((e.pos-origin).dot(direction),0,length)
     if e.pos.distance_to(origin+direction*along)<1.2*radius:
      hit(e,power,id)
      hits+=1
      if w[1]=="rail":
       for arc in nearby(e.pos,5+rank):
        if arc!=e: hit(arc,power*0.25,id); beam(e.pos,arc.pos,color)
      if w[1]=="hitscan" and hits>=count: break
   "poison","spore":
    if target.is_empty(): continue
    launch(origin,direction,power,id,color,w[1],rank)
   "gravity","hammer","vortex":
    if target.is_empty(): continue
    var status = "poison" if w[1] in ["poison","spore"] else "pull"
    var r = (6 if w[1] in ["gravity","hammer"] else 4)*radius
    make_field(target.pos,r,power*0.4,id,color,status,(3+rank*0.15)*stats.duration)
    if w[1]=="hammer":
     var hammer=Node3D.new()
     world.add_child(hammer)
     hammer.position=target.pos+Vector3.UP*1.5
     mesh_node(box(Vector3(2.8,1.5,1.5)),color,hammer,Vector3.UP,true)
     mesh_node(box(Vector3(0.25,3,0.25)),Color("e6dbff"),hammer,Vector3.ZERO,true)
     effects.append({"node":hammer,"life":0.5})
     if rank>=7:
      for side in [-1,1]:
       make_field(target.pos+Vector3(side*5,0,0),3*radius,power*0.3,id,color,"",3)
     area(target.pos,r,power,id)
     flash(target.pos,color,r)
     for e in nearby(target.pos,r): e.knock+=(e.pos-target.pos).normalized()*15
   "summon":
    for i in range(1+count/2):
     var angle = elapsed+i*TAU/(1+count/2)
     var p = origin+Vector3(cos(angle),0,sin(angle))*3
     var e = nearest(p,float(w[4]))
     flash(p,color,1)
     if not e.is_empty():
      beam(p,e.pos,color)
      hit(e,power*(1.7 if rank>=7 and i==0 else 1),id)
   _:
    if target.is_empty(): continue
    for i in (count+4 if w[1]=="scatter" else count):
     var spread = (i-(count-1)*0.5)*0.13
     if w[1]=="scatter": spread = rng.randf_range(-0.4,0.4)
     launch(origin,direction.rotated(Vector3.UP,spread),power,id,color,w[1],rank)
  if not target.is_empty(): tone(180+id*19,0.035,0.12)
func launch(pos: Vector3, direction: Vector3, damage: float, id: int, color: Color, kind: String, rank: int) -> void:
 if projectiles.size()>=220: return
 var node = pool.acquire("shot%d"%id,sphere(0.18),color,pos)
 node.scale = Vector3.ONE * stats.size
 var speed = (35 if kind in ["pierce","scatter"] else 20)*stats.projectile_speed
 projectiles.append({"node":node,"velocity":direction*speed,"damage":damage,"weapon":id,"kind":kind,"life":2.5*stats.duration,"age":0.0,"pierce":rank+1 if kind in ["pierce","wave"] else 1,"hits":[],"hostile":false,"rank":rank})
func hostile_bolt(pos: Vector3, target: Vector3) -> void:
 if projectiles.size()>=240: return
 var node = pool.acquire("hostile",sphere(0.3),Color("ff4f75"),pos)
 projectiles.append({"node":node,"velocity":(target-pos).normalized()*13,"damage":10.0*tier,"weapon":-1,"kind":"hostile","life":4.0,"age":0.0,"pierce":1,"hits":[],"hostile":true,"rank":1})
func segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
 var segment = b-a
 var t = clampf((p-a).dot(segment)/maxf(segment.length_squared(),0.001),0,1)
 return p.distance_to(a+segment*t)
func update_projectiles(delta: float) -> void:
 for i in range(projectiles.size()-1,-1,-1):
  var p = projectiles[i]
  p.life -= delta
  p.age += delta
  var previous = p.node.position
  if p.kind=="rocket":
   var target = nearest(previous,25)
   if not target.is_empty(): p.velocity=p.velocity.lerp((target.pos-previous).normalized()*24*stats.projectile_speed,delta*6)
  if p.kind=="return" and p.age>0.6: p.velocity=(player.position+Vector3.UP-previous).normalized()*26*stats.projectile_speed
  if p.kind=="lob": p.velocity.y-=15*delta
  p.node.position+=p.velocity*delta
  if p.hostile:
   if segment_distance(player.position+Vector3.UP,previous,p.node.position)<0.8: hurt(p.damage); p.life=0
  else:
   for e in nearby(p.node.position,4+ p.velocity.length()*delta):
    if e in p.hits or segment_distance(e.pos,previous,p.node.position)>1.0*stats.size: continue
    hit(e,p.damage,p.weapon)
    p.hits.append(e)
    if p.kind in ["poison","spore"]:
     make_field(p.node.position,4*stats.size,p.damage*0.4,p.weapon,Color(Catalog.WEAPONS[p.weapon][5]),"poison",(3+p.rank*0.15)*stats.duration)
    if p.kind in ["fireball","rocket","lob","dice"]:
     area(p.node.position,3.5*stats.size,p.damage*0.7,p.weapon)
     flash(p.node.position,Color(Catalog.WEAPONS[p.weapon][5]),3)
    if p.kind=="bounce" and p.hits.size()<3+p.rank:
     for target in nearby(p.node.position,14):
      if not target in p.hits:
       p.velocity=(target.pos-p.node.position).normalized()*22
       p.pierce+=1
       break
    p.pierce-=1
    if p.pierce<=0: p.life=0; break
  if p.life<=0:
   pool.release(p.node)
   projectiles.remove_at(i)
func make_field(pos: Vector3, radius: float, damage: float, id: int, color: Color, status: String, duration: float, mine: bool = false) -> void:
 if fields.size()>=55: return
 var node = mesh_node(cylinder(radius,0.08),color.darkened(0.2),world,Vector3(pos.x,terrain_height(pos.x,pos.z)+0.12,pos.z),true)
 fields.append({"node":node,"radius":radius,"damage":damage,"weapon":id,"status":status,"life":duration,"clock":0.3,"mine":mine})
func update_fields(delta: float) -> void:
 for i in range(fields.size()-1,-1,-1):
  var f = fields[i]
  f.life-=delta
  f.clock-=delta
  if f.clock<=0:
   var targets=nearby(f.node.position,f.radius)
   if not f.mine or targets.size()>0:
    for e in targets:
     hit(e,f.damage,f.weapon)
     if f.status=="poison":
      e.poison=4*stats.duration
      if f.weapon==33: e.spore=true
     if f.status=="slow": e.slow=2*stats.duration
     if f.status=="pull": e.knock+=(f.node.position-e.pos).normalized()*8
    f.clock=0.5
    if f.mine and targets.size()>0: flash(f.node.position,Color("ffc56a"),f.radius); f.life=0
  if f.life<=0: f.node.queue_free(); fields.remove_at(i)
func flash(pos: Vector3, color: Color, radius: float) -> void:
 if effects.size() >= (35 if settings.reduced else 90): return
 var ring = TorusMesh.new()
 ring.inner_radius = radius*0.85
 ring.outer_radius = radius
 ring.rings = 12
 ring.ring_segments = 8
 var node = mesh_node(ring,color,world,pos,true)
 effects.append({"node":node,"life":0.3})
func beam(a: Vector3, b: Vector3, color: Color) -> void:
 if a.distance_squared_to(b)<0.01 or effects.size()>90: return
 var node = mesh_node(box(Vector3(0.1,0.1,a.distance_to(b))),color,world,(a+b)*0.5,true)
 node.look_at(b)
 effects.append({"node":node,"life":0.13})
func update_effects(delta: float) -> void:
 for i in range(effects.size()-1,-1,-1):
  effects[i].life-=delta
  effects[i].node.scale*=1+delta*2
  if effects[i].node is Label3D: effects[i].node.position.y+=delta*2
  if effects[i].life<=0: effects[i].node.queue_free(); effects.remove_at(i)
func update_pickups(delta: float) -> void:
 for i in range(pickups.size()-1,-1,-1):
  var p = pickups[i]
  p.age+=delta
  var distance = p.node.position.distance_to(player.position+Vector3.UP)
  if distance<5*stats.pickup or p.age>25:
   p.node.position=p.node.position.move_toward(player.position+Vector3.UP,delta*maxf(10,18-distance))
  if distance<1.2:
   xp+=p.value*stats.xp
   pool.release(p.node)
   pickups.remove_at(i)
 if xp>=Catalog.threshold(level):
  xp-=Catalog.threshold(level)
  level+=1
  on_level()
  show_upgrades()
func on_level() -> void:
 match character:
  0: stats.luck+=0.03
  1: stats.armor+=1.5
  4: stats.damage+=0.04
  5: stats.crit+=0.01
  8: stats.max_health+=4; health+=4
  15: stats.haste+=0.025
func upgrade_pool() -> Array:
 var pool: Array = []
 for id in Catalog.WEAPONS.size():
  if (weapons.has(id) and weapons[id].level<10) or (not weapons.has(id) and weapons.size()<4):
   if not "w%d"%id in banished: pool.append({"type":"weapon","id":id,"key":"w%d"%id})
 for name in Catalog.TOMES:
  if (tomes.has(name) and tomes[name]<10) or (not tomes.has(name) and tomes.size()<4):
   if not name in banished: pool.append({"type":"tome","id":name,"key":name})
 return pool
func show_upgrades() -> void:
 mode="upgrade"
 var col=clear_panel("LEVEL %d  /  CHOOSE YOUR POWER"%level)
 choices.clear()
 var pool=upgrade_pool()
 for i in mini(3,pool.size()):
  var index=rng.randi_range(0,pool.size()-1)
  var choice=pool.pop_at(index)
  choices.append(choice)
  var description=""
  if choice.type=="weapon":
   var id=int(choice.id)
   var rank=weapons[id].level if weapons.has(id) else 0
   description="%s  ·  level %d → %d\n%s · damage %.0f · cooldown %.2fs"%[Catalog.WEAPONS[id][0],rank,rank+1,Catalog.WEAPONS[id][1],Catalog.WEAPONS[id][2]*(1+rank*0.23),Catalog.WEAPONS[id][3]]
  else:
   description="%s Tome  ·  level %d → %d\n+%s %s"%[choice.id,tomes.get(choice.id,0),tomes.get(choice.id,0)+1,Catalog.TOMES[choice.id][1],Catalog.TOMES[choice.id][0]]
  var row=HBoxContainer.new()
  col.add_child(row)
  button(description,row,func(): apply_upgrade(choice); resume())
  button("Banish",row,func(): banished.append(choice.key); resume())
 button("Reroll (%d left)"%rerolls,col,func(): if rerolls>0: rerolls-=1; show_upgrades()).disabled=rerolls<=0
 button("Skip · heal 10",col,func(): health=minf(stats.max_health,health+10); resume())
 tone(900,0.2)
func apply_upgrade(choice: Dictionary) -> void:
 if choice.type=="weapon": equip(int(choice.id))
 else:
  var name=choice.id
  tomes[name]=tomes.get(name,0)+1
  var stat=Catalog.TOMES[name][0]
  stats[stat]+=Catalog.TOMES[name][1]
  if stat=="max_health": health+=Catalog.TOMES[name][1]
func award_item() -> void:
 var roll=rng.randf()+minf(stats.luck*0.2,0.4)
 var rarity="epic" if roll>0.92 else ("rare" if roll>0.58 else "common")
 var candidates: Array=[]
 for definition in Catalog.ITEMS:
  if definition[1]==rarity: candidates.append(definition)
 var item=candidates[rng.randi_range(0,candidates.size()-1)]
 items.append(item[0])
 stats[item[2]]+=item[3]
 if item[2]=="max_health": health+=item[3]
 toast("%s [%s] · +%s %s"%[item[0],item[1],item[3],item[2]])
 tone(720,0.15)
func update_interactions(delta: float) -> void:
 var closest: Dictionary={}
 var distance=4.0
 for obj in interactables:
  if obj.used: continue
  var d=obj.node.position.distance_to(player.position)
  if d<distance: distance=d; closest=obj
  if obj.kind=="Charge Shrine" and obj.charge>0:
   if d<8: obj.charge+=delta
   if obj.charge>=12: obj.used=true; award_item(); gold+=15
   elif d<8: notice.text="Charge Shrine: %d%% · stay nearby"%int(obj.charge/12*100)
 if is_instance_valid(portal) and portal.position.distance_to(player.position)<4:
  notice.text="E  /  Enter exit portal"
  if Input.is_action_just_pressed("interact"):
   if stage==3: finish_run(true)
   else: stage+=1; biome=(biome+1)%3; build_stage(); resume()
  return
 if closest.is_empty(): return
 notice.text="E  /  %s%s"%[closest.kind," · 15 gold" if closest.kind in ["Chest","Shop"] else ""]
 if not Input.is_action_just_pressed("interact"): return
 match closest.kind:
  "Chest","Shop":
   if gold<15: toast("Need 15 gold"); return
   gold-=15
   award_item()
  "Heal": health=minf(stats.max_health,health+40); toast("Restored 40 health")
  "Stat Shrine": stats.damage+=0.15; toast("Blessing · +15% damage")
  "Risk Shrine": stats.difficulty+=0.25; stats.damage+=0.3; gold+=20; toast("Curse accepted · stronger enemies, +30% damage")
  "Charge Shrine": closest.charge=0.1; toast("Stay within the blue shrine circle"); return
 closest.used=true
 closest.node.scale=Vector3.ONE*0.5
 tone(600,0.15)
func update_hud() -> void:
 var weapon_names: Array[String]=[]
 for id in weapons: weapon_names.append("%s %d"%[Catalog.WEAPONS[id][0],weapons[id].level])
 var boss_text=""
 for e in enemies:
  if e.kind==8: boss_text="\nWARDEN  %d / %d"%[maxf(0,e.hp),e.max_hp]
 hud.text="%s  /  STAGE %d · TIER %d    %02d:%02d\nHP %d / %d   LV %d   KILLS %d   GOLD %d\n%s%s%s"%[Catalog.CHARACTERS[character][0],stage,tier,int(elapsed)/60,int(elapsed)%60,maxf(0,health),stats.max_health,level,kills,gold,"  |  ".join(weapon_names),boss_text,"\nFPS %d · enemies %d · projectiles %d"%[Engine.get_frames_per_second(),enemies.size(),projectiles.size()] if settings.fps else ""]
 health_bar.max_value=stats.max_health
 health_bar.value=health
 xp_bar.max_value=Catalog.threshold(level)
 xp_bar.value=xp
func pause_menu() -> void:
 mode="pause"
 var col=clear_panel("RUN PAUSED")
 button("Resume",col,resume).grab_focus()
 button("Inspect build",col,show_build)
 button("Settings",col,func(): settings_menu(pause_menu))
 if sandbox: button("Sandbox tools",col,sandbox_menu)
 button("Restart run",col,begin_run)
 button("Abandon run",col,func(): finish_run(false))
func show_build() -> void:
 mode="build"
 var col=clear_panel("CURRENT BUILD")
 for id in weapons: title("%s · level %d"%[Catalog.WEAPONS[id][0],weapons[id].level],col,18)
 title("Tomes: %s\nItems: %s"%[str(tomes),", ".join(items)],col,16)
 var text=""
 for key in stats: text+="%s %.2f   "%[key,stats[key]]
 var label=title(text,col,15)
 label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 label.custom_minimum_size.x=600
 button("Resume",col,resume)
func finish_run(victory: bool) -> void:
 mode="results"
 var unlocked=progress.finish(kills,elapsed,victory,selected_biome,sandbox)
 var col=clear_panel("VICTORY / INFINITY BROKEN" if victory else "THE WILD CLAIMS ANOTHER")
 var best=-1
 for id in damage_by_weapon:
  if best==-1 or damage_by_weapon[id]>damage_by_weapon[best]: best=id
 title("Survived %02d:%02d · Stage %d · Level %d\n%d kills · %.0f damage · %d gold\nHighest damage: %s\n%s"%[int(elapsed)/60,int(elapsed)%60,stage,level,kills,damage_total,gold,Catalog.WEAPONS[best][0] if best>=0 else "None","Sandbox: no progression written" if sandbox else "Banked %d permanent currency"%(maxi(1,kills/8)+(25 if victory else 0))],col,20)
 if unlocked.size()>0: title("Unlocked: "+", ".join(unlocked),col,18)
 button("Run again",col,begin_run)
 button("Main menu",col,func(): build_menu_world(); main_menu())
 tone(520 if victory else 110,0.5)
func show_progress() -> void:
 var col=clear_panel("PROGRESS / LOCAL PROFILE")
 title("Currency %d · Runs %d · Victories %d\nLifetime kills %d · Best survival %.0fs\nCharacters %d / 21 · Biomes completed %s"%[progress.data.currency,progress.data.runs,progress.data.wins,progress.data.kills,progress.data.best,progress.data.unlocked.size(),str(progress.data.completed)],col,19)
 title("Quests: defeat 80 more foes to work toward each next character.\nAchievements: First Hunt (80 kills), Survivor (300s), Warden Breaker (victory).",col,16)
 button("Export save to user://bonk-profile-export.json",col,func(): toast("Exported" if progress.save("user://bonk-profile-export.json") else "Export failed"))
 button("Import user://bonk-profile-export.json",col,func(): if progress.load_save("user://bonk-profile-export.json"): progress.save(); show_progress())
 button("Back",col,main_menu)
func sandbox_menu() -> void:
 mode="sandbox"
 var col=clear_panel("SANDBOX / PROGRESSION ISOLATED")
 var select=OptionButton.new()
 for w in Catalog.WEAPONS: select.add_item(w[0])
 col.add_child(select)
 button("Equip / upgrade selected weapon",col,func(): equip(select.selected); toast("Equipped or upgraded"))
 button("Set selected weapon to level 10",col,func():
  equip(select.selected)
  if weapons.has(select.selected): weapons[select.selected].level=10)
 button("Clear weapons",col,func():
  for id in weapons:
   for node in weapons[id].visuals: node.queue_free()
   for ally in weapons[id].summons: ally.node.queue_free()
  weapons.clear())
 button("Add random tome",col,func(): var names=Catalog.TOMES.keys(); var name=names[rng.randi_range(0,names.size()-1)]; apply_upgrade({"type":"tome","id":name}))
 button("Add item",col,award_item)
 button("Spawn 100 enemies",col,func(): for i in 100: spawn_enemy())
 button("Spawn Warden",col,func(): spawn_enemy(8))
 button("Add XP +100 / gold +100",col,func(): xp+=100; gold+=100)
 button("Invincibility: "+str(settings.invincible),col,func(): settings.invincible=not settings.invincible; sandbox_menu())
 button("Time scale: "+str(Engine.time_scale),col,func(): Engine.time_scale=2 if Engine.time_scale==1 else 1; sandbox_menu())
 button("Teleport to spawn",col,func(): player.position=Vector3(0,4,0))
 button("Resume",col,resume)
func settings_menu(back: Callable) -> void:
 mode="settings" if is_instance_valid(player) else "menu"
 var col=clear_panel("SETTINGS")
 for key in ["master","effects","music","sensitivity","render_scale"]:
  var row=HBoxContainer.new()
  col.add_child(row)
  title(key.capitalize(),row,16).custom_minimum_size.x=140
  var slider=HSlider.new()
  slider.min_value=0.0005 if key=="sensitivity" else (0.5 if key=="render_scale" else 0)
  slider.max_value=0.008 if key=="sensitivity" else 1
  slider.step=0.0001 if key=="sensitivity" else 0.05
  slider.value=settings[key]
  slider.custom_minimum_size.x=300
  row.add_child(slider)
  slider.value_changed.connect(func(value): settings[key]=value; apply_settings())
 var resolution=OptionButton.new()
 for name in ["1280 × 720","1600 × 900","1920 × 1080"]: resolution.add_item(name)
 col.add_child(resolution)
 resolution.item_selected.connect(func(i): DisplayServer.window_set_size([Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)][i]))
 var quality=OptionButton.new()
 for name in ["Low · no shadows","Medium · shadows","High · shadows and 4× MSAA"]: quality.add_item(name)
 quality.selected=int(settings.quality)
 col.add_child(quality)
 quality.item_selected.connect(func(i): settings.quality=i; apply_settings())
 for key in ["invert","reduced","numbers","shake","fps","focus_pause"]:
  var check=CheckButton.new()
  check.text=key.capitalize().replace("_"," ")
  check.button_pressed=settings[key]
  col.add_child(check)
  check.toggled.connect(func(value): settings[key]=value; apply_settings())
 var row=GridContainer.new()
 row.columns=4
 col.add_child(row)
 for action in bindings:
  button("%s: %s"%[action,OS.get_keycode_string(bindings[action])],row,func(): pending_binding=action; toast("Press a key for "+action))
 title("F11 toggles fullscreen. Compatibility renderer selected for broad support.",col,14)
 button("Save & back",col,func(): progress.data.settings=settings; progress.data.settings["bindings"]=bindings; progress.save(); back.call())
func apply_settings() -> void:
 AudioServer.set_bus_volume_db(0,linear_to_db(maxf(0.001,settings.master)))
 get_viewport().scaling_3d_scale=float(settings.render_scale)
 get_viewport().msaa_3d=Viewport.MSAA_4X if int(settings.quality)==2 else Viewport.MSAA_DISABLED
 if is_instance_valid(world):
  for child in world.get_children():
   if child is DirectionalLight3D: child.shadow_enabled=int(settings.quality)>0
 music.volume_db=linear_to_db(maxf(0.001,settings.music))
 if is_instance_valid(player): player.sensitivity=settings.sensitivity; player.inverted=settings.invert
func setup_audio() -> void:
 for i in 10:
  var audio=AudioStreamPlayer.new()
  add_child(audio)
  sfx.append(audio)
 music=AudioStreamPlayer.new()
 add_child(music)
 var stream=AudioStreamWAV.new()
 stream.mix_rate=22050
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
 stream.loop_end=22050*8
 var bytes=PackedByteArray()
 bytes.resize(22050*8*2)
 var notes=[130.81,164.81,196.0,146.83]
 for i in 22050*8:
  var t=float(i)/22050
  var f=notes[int(t/2)%4]
  var sample=(sin(t*f*TAU)*0.07+sin(t*f*1.5*TAU)*0.035)*minf(1,fmod(t,2)*5)
  bytes.encode_s16(i*2,int(sample*32767))
 stream.data=bytes
 music.stream=stream
 if AudioServer.get_driver_name()!="Dummy": music.play()
 apply_settings()
func tone(frequency: float, duration: float, loudness: float = 0.3) -> void:
 if AudioServer.get_driver_name()=="Dummy": return
 var stream=AudioStreamWAV.new()
 stream.mix_rate=22050
 stream.format=AudioStreamWAV.FORMAT_16_BITS
 var bytes=PackedByteArray()
 var length=int(duration*22050)
 bytes.resize(length*2)
 for i in length:
  var t=float(i)/22050
  var value=sin(t*frequency*TAU)*(1-float(i)/length)*loudness*settings.effects
  bytes.encode_s16(i*2,int(value*32767))
 stream.data=bytes
 var audio=sfx[sfx_cursor%sfx.size()]
 sfx_cursor+=1
 audio.stream=stream
 audio.play()

func update_special_visuals(delta: float) -> void:
 for id in weapons:
  var w = Catalog.WEAPONS[id]
  var state = weapons[id]
  var rank = state.level
  if w[1] in ["orbit","chrono"]:
   var count = mini(12,2+int(stats.count)+rank/3)
   while state.visuals.size()<count:
    var node=Node3D.new()
    world.add_child(node)
    mesh_node(box(Vector3(0.16,0.35,1.5)),Color(w[5]),node,Vector3.ZERO,true)
    mesh_node(box(Vector3(0.6,0.12,0.12)),Color("edf7ff"),node,Vector3(0,0,-0.5))
    state.visuals.append(node)
   for i in state.visuals.size():
    var angle=elapsed*3+i*TAU/count
    var radius=w[4]*stats.size*(1+(rank-1)*0.07)
    state.visuals[i].position=player.position+Vector3(cos(angle)*radius,1.1,sin(angle)*radius)
    state.visuals[i].rotation.y=-angle
  if w[1]=="summon":
   var count=mini(8,1+int(stats.count)/2+rank/3)
   while state.summons.size()<count:
    var node=create_avatar(world,14,player.position+Vector3(rng.randf_range(-2,2),1,rng.randf_range(-2,2)))
    state.summons.append({"node":node,"clock":0.0})
   for i in state.summons.size():
    var summon=state.summons[i]
    summon.clock-=delta
    var node=summon.node
    var target=nearest(node.position,18)
    var destination=player.position+Vector3(cos(elapsed+i)*3,0,sin(elapsed+i)*3) if target.is_empty() else target.pos
    node.position=node.position.move_toward(destination,delta*11*stats.speed)
    node.position.y=terrain_height(node.position.x,node.position.z)+0.3+sin(elapsed*3+i)*0.2
    if node.position.distance_to(destination)>0.2: node.look_at(Vector3(destination.x,node.position.y,destination.z))
    if not target.is_empty() and target.pos.distance_to(node.position)<3 and summon.clock<=0:
     hit(target,w[2]*(1+(rank-1)*0.23)*(1.8 if rank>=7 and i==0 else 1),id)
     flash(target.pos,Color(w[5]),0.8)
     summon.clock=0.9/stats.haste

func _exit_tree() -> void:
 if is_instance_valid(music):
  music.stop()
  music.stream=null
 for audio in sfx:
  if is_instance_valid(audio):
   audio.stop()
   audio.stream=null

func prop_instance(key: String, mesh: Mesh, color: Color, pos: Vector3, size: Vector3 = Vector3.ONE) -> void:
 if not prop_batches.has(key):
  var batch=MultiMeshInstance3D.new()
  batch.multimesh=MultiMesh.new()
  batch.multimesh.transform_format=MultiMesh.TRANSFORM_3D
  batch.multimesh.use_colors=true
  batch.multimesh.mesh=mesh
  batch.multimesh.instance_count=512
  batch.multimesh.visible_instance_count=0
  var material=StandardMaterial3D.new()
  material.vertex_color_use_as_albedo=true
  material.roughness=0.9
  batch.material_override=material
  world.add_child(batch)
  prop_batches[key]=batch
 var mm=prop_batches[key].multimesh
 var index=mm.visible_instance_count
 mm.set_instance_transform(index,Transform3D(Basis.IDENTITY.scaled(size),pos))
 mm.set_instance_color(index,color)
 mm.visible_instance_count+=1
func build_enemy_mesh() -> ArrayMesh:
 var surface=SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 surface.append_from(sphere(0.65),0,Transform3D.IDENTITY)
 for side in [-1,1]:
  surface.append_from(cylinder(0.16,0.6,0),0,Transform3D(Basis.IDENTITY,Vector3(side*0.4,0.55,0)))
  surface.append_from(sphere(0.13),0,Transform3D(Basis.IDENTITY,Vector3(side*0.25,0.18,0.57)))
 surface.generate_normals()
 return surface.commit()

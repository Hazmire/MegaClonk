extends Node3D

const RUN_RULES=preload("res://assets/config/run_rules.tres")
const STAGE_SECONDS = StageClock.DURATION
const ENEMY_LIMIT = 500
# Bumped when new procedural world content (vases, Imbue Stations) is added. Saves keep the
# version they were made with so their object layout never changes underneath them; runs adopt
# the latest version on their next stage.
const WORLD_CONTENT_VERSION = 2
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
var pending_blasts: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var interactables: Array[Dictionary] = []
var landmarks: Array[Vector3]=[]
var weapons: Dictionary = {}
var gems=GemInventory.new()
var chest_gem="" # element found by the chest being revealed, shown once by the reward screen
var world_time=WorldTime.new()
var vases: Array=[]
var world_pickups: Array=[]
var tomes: Dictionary = {}
var tome_rarities: Dictionary={}
var items: Array = []
var effects: Array[Dictionary] = []
var grid: Dictionary = {}
var crowd=CrowdPhysics.new()
var prop_batches: Dictionary = {}
var decoration_checksum=0
var projectile_meshes: Dictionary = {}
var effect_meshes: Dictionary={}
var numbers: CombatNumbers
var combat_counters={"hits":0,"deaths":0,"xp_drops":0,"xp_merged":0}
var debug_combat=false
var combat_debug_label: Label
var combat_pool_start=0
var combat_burst_start=0
var obstacles: Dictionary = {}
var mode = "menu"
var sandbox = false
var character = 0
var biome = 0
var tier = 1
var stage = 1
var elapsed = 0.0
var stage_time = 0.0
var stage_clock=StageClock.new()
var spawn_budget=0.0
var portal_state="dormant"
var health = 100.0
var xp = 0.0
var level = 1
var kills = 0
var gold = 0
var gold_fraction = 0.0
var damage_total = 0.0
var damage_by_weapon: Dictionary = {}
var weapon_damage_windows: Dictionary={}
var spawn_clock = 0.0
var invulnerability = 0.0
var boss_variant="chunkus"
var spawn_rng=RandomNumberGenerator.new()
var elite_active=false
var elite_rewarded=false
var ghost_budget=0.0
var boss_spawned = false
var boss_dead = false
var portal: Node3D
var terrain_noise = FastNoiseLite.new()
var map_layout: Dictionary={}
var map_seed_override=-1
var terrain_version=4
var world_content_version=1
var additional_boss_count=0
var boss_encounters: Dictionary={}
var gem_rng=RandomNumberGenerator.new()
var pending_upgrades=0
var announced_stages: Array=[]
var drop_chests: Array=[]
var reward_queue: Array=[]
var active_reward=-1
var shrine_reward_queue: Array=[]
var active_shrine_reward: Dictionary={}
var portal_wind: PortalWind
var shrine_orbs: MultiMeshInstance3D
var map_debug=false
var map_debug_node: MeshInstance3D
var forest_navigation: ForestNavigation
var selected_character = 0
var selected_biome = 0
var selected_tier = 1
var message_time = 0.0
var announcement=""
var announcement_time=0.0
var passive_clock = 0.0
var moving_time = 0.0
var banished: Array = []
var rerolls = 3
var choices: Array = []
var frontend: FrontEnd
var loadout_runtime=LoadoutRuntime.new()
var selected_weapon=1
var selected_trait="climber"
var selected_ultimate="nova"
var run_metrics: Dictionary={}
var chests_opened=0
var legacy_weapon_slots=0
var legacy_tome_slots=0
var grimdark_renderer: GrimdarkRenderer
var settings = {"retro_scale":0.5,"psx_warp":0.25,"psx_snap":0.35,"psx_dither":true,"visual_intensity":0.7,"render_scale":1.0,"quality":1,"master":0.7,"effects":0.7,"ui_volume":0.65,"ambience":0.35,"music":0.3,"sensitivity":0.0025,"invert":false,"reduced":false,"fps":false,"focus_pause":true,"shake":true,"numbers":true,"invincible":false}
var pending_binding = ""
var bindings = {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"jump":KEY_SPACE,"crouch":KEY_CTRL,"interact":KEY_E,"inspect":KEY_TAB,"ultimate":KEY_Q,"map":KEY_M}
var music: AudioStreamPlayer
var sfx: Array[AudioStreamPlayer] = []
var sound_bank: Dictionary={}
var audio: RetroAudio
var movement_audio=MovementAudio.new()
var sound_last: Dictionary={}
var sfx_cursor = 0
var combat_fx: CombatFX
var pool: MeshPool
var variants=RunEnemyVariants.new()
var next_run_seed=-1
var run_seed=0
var enemy_view: EnemyView
var enemy_mesh: MultiMeshInstance3D
var enemy_material: StandardMaterial3D
var smoke_mode = false
var smoke_step = 0
var smoke_frames = 0
var smoke_failures: Array = []

func _ready() -> void:
 DisplayServer.window_set_title("MEGACLONK")
 rng.randomize()
 progress.load_save()
 settings.merge(progress.data.settings, true)
 if settings.has("bindings"): settings.bindings.erase("sprint")
 if InputMap.has_action("sprint"): InputMap.erase_action("sprint")
 if settings.has("bindings"):
  for key in bindings:
   if settings.bindings.has(key): bindings[key] = int(settings.bindings[key])
 for action in bindings:
  InputMap.add_action(action)
  var event = InputEventKey.new()
  event.physical_keycode = int(bindings[action])
  InputMap.action_add_event(action, event)
 setup_audio()
 selected_weapon=int(progress.data.loadout.weapon)
 if not selected_weapon in Catalog.ACTIVE_WEAPONS:selected_weapon=Catalog.ACTIVE_WEAPONS[0]
 selected_trait=str(progress.data.loadout.trait)
 selected_ultimate=str(progress.data.loadout.ultimate)
 if not MetaProgress.unlocked(progress.data,"weapons",str(selected_weapon)):selected_weapon=1
 if not MetaProgress.unlocked(progress.data,"traits",selected_trait):selected_trait="climber"
 if not MetaProgress.unlocked(progress.data,"ultimates",selected_ultimate):selected_ultimate="nova"
 frontend=FrontEnd.new();add_child(frontend);frontend.setup(self)
 build_menu_world()
 grimdark_renderer=GrimdarkRenderer.new();add_child(grimdark_renderer);grimdark_renderer.setup(self)
 main_menu()
 smoke_mode = "--smoke" in OS.get_cmdline_user_args()
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--map-seed="):map_seed_override=int(argument.get_slice("=",1))
 if "--showcase" in OS.get_cmdline_user_args() and not Engine.has_meta("showcase_started"):
  Engine.set_meta("showcase_started",true);get_tree().call_deferred("change_scene_to_file","res://scenes/showcase/assets.tscn")
 if smoke_mode or "--practice" in OS.get_cmdline_user_args():
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
 node.mouse_entered.connect(func():play_sound("ui.hover"))
 node.pressed.connect(func(): play_sound("ui.confirm"); callback.call())
 return node
func clear_panel(heading: String) -> VBoxContainer:
 return frontend.page(heading)

func main_menu() -> void:
 frontend.home()

func build_menu_world() -> void:
 if is_instance_valid(world):
  if is_instance_valid(forest_navigation) and is_instance_valid(forest_navigation.region):
   NavigationServer3D.region_set_map(forest_navigation.region.get_rid(),RID())
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
 if debug_combat:combat_counters["scenes"]=int(combat_counters.get("scenes",0))+1
 var node=KnightVisual.new()
 parent.add_child(node)
 node.position=pos
 node.set_meta("character_index",index)
 return node
func begin_run() -> void:
 if not selected_weapon in Catalog.ACTIVE_WEAPONS:selected_weapon=Catalog.ACTIVE_WEAPONS[0]
 tome_rarities.clear()
 terrain_version=4
 MetaProgress.migrate(progress.data)
 character = -1
 selected_character=0
 selected_biome=0
 biome = 0
 tier = selected_tier
 stage = 1
 run_seed=next_run_seed if next_run_seed>=0 else rng.randi()
 variants.initialize(run_seed)
 world_content_version=WORLD_CONTENT_VERSION;additional_boss_count=0
 gem_rng.seed=run_seed+719477;pending_upgrades=0;announced_stages.clear();reward_queue.clear();active_reward=-1;shrine_reward_queue.clear();active_shrine_reward={};crowd.next_id=1
 rng.seed=run_seed
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
 damage_by_weapon.clear();weapon_damage_windows.clear()
 weapons.clear();gems.reset()
 tomes.clear()
 items.clear()
 banished.clear()
 rerolls = 3
 passive_clock = 0
 moving_time = 0
 run_metrics.clear();chests_opened=0;legacy_weapon_slots=0;legacy_tome_slots=0
 loadout_runtime.reset(selected_trait,selected_ultimate)
 frontend.minimap.reset(selected_trait=="seer")
 equip(selected_weapon)
 build_stage()
 resume();show_stage_intro()
func equip(id: int) -> void:
 if weapons.has(id): weapons[id].level = mini(10, weapons[id].level + 1)
 elif weapons.size() < weapon_limit():
  weapons[id] = {"level":1,"rarity":"common","clock":0.1,"visuals":[],"summons":[],"upgrades":{},"legacy_damage":1.0}
  WeaponSockets.ensure(weapons[id])
func terrain_height(x: float, z: float) -> float:
 # Query the collision mesh's already-built planes, never regenerate or format
 # a layout-cache key for each agent probe during a horde tick.
 if not map_layout.is_empty() and int(map_layout.seed)==stage_map_seed() and int(map_layout.terrain_version)==terrain_version and int(map_layout.get("object_version",0))==world_content_version:
  var plane: Vector3=map_layout.planes[ForestMap.index(x,z)]
  return plane.x*x+plane.y+plane.z*z+maxf(0,maxf(absf(x),absf(z))-96)*3.0
 return ForestMap.height(stage_map_seed(),x,z)
func build_stage() -> void:
 ForestMap.generation_version=terrain_version;ForestMap.object_version=world_content_version
 var previous_seed=rng.seed
 var previous_state=rng.state
 rng.seed=run_seed+stage*65537+biome*101
 enemies.clear();crowd.buckets.clear();drop_chests.clear();boss_encounters.clear()
 projectiles.clear()
 fields.clear()
 pending_blasts.clear()
 pickups.clear()
 world_pickups=[];vases=[];world_time.reset()
 effects.clear()
 interactables.clear();landmarks.clear()
 grid.clear()
 prop_batches.clear();decoration_checksum=0
 obstacles.clear()
 for id in weapons:
  weapons[id].erase("debris")
  weapons[id]["visuals"] = []
  weapons[id]["summons"] = []
 stage_time = 0
 announcement="";announcement_time=0
 stage_clock.reset()
 ghost_budget=0
 boss_variant="chunkus" if posmod(hash(str(run_seed)+":"+str(stage)),2)==0 else "rock_golem"
 spawn_rng.seed=run_seed+stage*104729
 elite_active=false;elite_rewarded=false
 spawn_budget=0
 portal_state="dormant"
 frontend.minimap.reset(loadout_runtime.trait_id=="seer")
 spawn_clock = 0
 boss_spawned = false
 boss_dead = false
 portal = null
 build_menu_world()
 for child in world.get_children():
  if child is Camera3D or child is MeshInstance3D or (child is Node3D and not child is Light3D and not child is WorldEnvironment): child.queue_free()
 terrain_noise.seed = posmod(run_seed+8127+biome*101+stage*73,2147483647)
 terrain_noise.frequency = 0.018
 var colors = [Color("304f3d"),Color("9b7e51"),Color("353947")]
 var env = world.get_child(0).environment
 env.background_color = [Color("668e9b"),Color("b8a07c"),Color("343a58")][biome]
 env.fog_enabled = true
 env.fog_light_color = env.background_color
 env.fog_density = 0.003 if biome < 2 else 0.009
 StageThemes.apply(self)
 ForestWorld.build(self)
 if world_content_version>=1 or OrdinaryRoster.SETTINGS.elite_statues>0:create_elite_statue()
 for i in range(map_layout.pois.size()):
  var p: Vector3=map_layout.pois[i]
  var kind = map_layout.poi_kinds[i] if map_layout.has("poi_kinds") else ["Chest","Heal","Charge Shrine","Shop","Risk Shrine","Stat Shrine"][i % 6]
  if kind=="Elite Statue":create_elite_statue(p);continue
  if kind=="Boss Statue":create_boss_statue(p);continue
  var model = Node3D.new()
  world.add_child(model)
  model.position = p
  GrimdarkObjects.populate(model,kind,stage)
  var object={"node":model,"kind":kind,"used":false,"charge":0.0}
  if kind=="Shop":object.tier=ShopSystem.tier(rng)
  interactables.append(object)
 ShrineCharging.setup(self)
 ImbueStation.setup(self)
 Vases.build(self)
 combat_fx=CombatFX.new();world.add_child(combat_fx)
 pool = MeshPool.new()
 world.add_child(pool)
 numbers=CombatNumbers.new();world.add_child(numbers);numbers.prewarm()
 prewarm_combat()
 player = BonkPlayer.new()
 player.crowd_world=self
 player.stats = stats
 world.add_child(player)
 player.position = map_layout.spawn+Vector3.UP*0.1
 player.avatar = create_avatar(player,0,Vector3.ZERO)
 player.can_climb = loadout_runtime.trait_id=="climber"
 player.can_glide=loadout_runtime.trait_id=="glider"
 player.air_control = 18 if character == 11 else 9
 player.max_jumps = 3 if character == 11 else (2 if character == 8 else 1)
 player.sensitivity = settings.sensitivity
 player.inverted = settings.invert
 player.camera.current = true
 enemy_view=EnemyView.new()
 world.add_child(enemy_view)
 enemy_mesh = MultiMeshInstance3D.new()
 enemy_mesh.multimesh = MultiMesh.new()
 enemy_mesh.multimesh.transform_format = MultiMesh.TRANSFORM_3D
 enemy_mesh.multimesh.use_colors = true
 enemy_mesh.multimesh.mesh = preload("res://assets/generated/brute.res")
 enemy_mesh.multimesh.instance_count = ENEMY_LIMIT
 enemy_mesh.multimesh.visible_instance_count = 0
 enemy_material = StandardMaterial3D.new()
 enemy_material.vertex_color_use_as_albedo = true
 enemy_material.roughness = 0.8
 enemy_mesh.material_override = enemy_material
 world.add_child(enemy_mesh)
 rng.seed=previous_seed
 rng.state=previous_state
 make_portal()
 portal_wind=PortalWind.new();world.add_child(portal_wind);portal_wind.setup(self)
 if is_instance_valid(audio):audio.music_stage(stage)
 if map_debug:map_debug=false;toggle_map_debug()
 toast("Stage %d • Explore the forest. Activate the portal to challenge the stage guardian."%stage)
func resume() -> void:
 if is_instance_valid(audio):audio.emit("ui.close")
 if mode=="shrine" and not active_shrine_reward.is_empty():return
 if mode=="reward" and active_reward>=0:active_reward=-1
 if ShrineRewards.present_next(self):return
 if RewardDrops.present_next(self):return
 if pending_upgrades>0:
  pending_upgrades-=1;show_upgrades();return
 mode = "run"
 if is_instance_valid(panel):panel.hide()
 frontend.enter_run()
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
  settings_menu(frontend.settings_back if frontend.settings_back.is_valid() else main_menu)
  return
 if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F11:
  DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
 if event.is_action_pressed("ui_cancel"):
  if mode == "run": pause_menu()
  elif mode=="reward" and frontend.chest_skip.is_valid():frontend.chest_skip.call()
  elif mode in ["pause","build","sandbox","shop","reward","imbue"]: resume()
  elif mode=="map":
   if frontend.map_return_to_pause:pause_menu()
   else:resume()
  elif mode=="settings":frontend.leave_settings()
  elif mode in ["play","unlocks","quests"]: main_menu()
 if event.is_action_pressed("map"):
  if mode in ["run","pause"]:frontend.world_map(mode=="pause")
  elif mode=="map":
   if frontend.map_return_to_pause:pause_menu()
   else:resume()
 if event.is_action_pressed("inspect") and mode == "run": show_build()
 if event is InputEventKey and event.pressed and event.keycode==KEY_F8 and sandbox:
  map_seed_override=stage_map_seed()+1;build_stage();resume()
 if event is InputEventKey and event.pressed and sandbox and event.keycode==KEY_F7:build_stage();resume()
 if event is InputEventKey and event.pressed and sandbox and event.keycode==KEY_F6:toggle_map_debug()
func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT and settings.focus_pause and mode == "run" and not smoke_mode: pause_menu()
func _physics_process(delta: float) -> void:
 if is_instance_valid(combat_fx):
  combat_fx.intensity=settings.visual_intensity;combat_fx.reduced=settings.reduced;combat_fx.tick(delta,mode=="run")
 if mode != "run":
  if is_instance_valid(audio):audio.stop_event("player.slide")
  movement_audio.reset();return
 movement_audio.tick(self,delta)
 if health<=0 and stats.get("revives",0)>0:
  stats.revives-=1;health=stats.max_health;invulnerability=3;combat_fx.burst("explosion_small",player.position,3);toast("PHOENIX REBIRTH")
 if health <= 0:
  finish_run(false)
  return
 loadout_runtime.tick(self,delta)
 loadout_runtime.cooldown=maxf(0,loadout_runtime.cooldown-delta*stats.get("ultimate_haste",0))
 elapsed += delta
 world_time.tick(delta)
 var hostile_delta=world_time.hostile(delta)
 for event_id in stage_clock.advance(delta):
  stage_event(event_id)
 stage_time = stage_clock.elapsed
 passive_clock += delta
 message_time -= delta
 announcement_time=maxf(0,announcement_time-delta)
 frontend.event_label.text=announcement if announcement_time>0 else ""
 if message_time <= 0: notice.text = ""
 player.camera.h_offset=lerpf(player.camera.h_offset,0,delta*12)
 invulnerability = maxf(0,invulnerability-delta)
 health = minf(stats.max_health,health+stats.regen*delta)
 if player.fall_hit > 0:
  hurt(player.fall_hit)
  player.fall_hit = 0
 if player.position.y < -30 or absf(player.position.x)>102 or absf(player.position.z)>102:
  hurt(12)
  player.position = map_layout.spawn+Vector3.UP
 if player.velocity.length() > 3: moving_time += delta
 else: moving_time = maxf(0,moving_time-delta*2)
 if passive_clock >= 1:
  if stats.get("storm",0)>0:
   var storm_target=nearest(player.position,20)
   if not storm_target.is_empty():hit(storm_target,45*stats.storm,-3);lightning_arc(player.position+Vector3.UP,storm_target.pos,Color.CYAN)
  tick_passive()
  passive_clock -= 1
 spawn_clock -= hostile_delta
 # Budgeted spawning: no catch-up burst after a long frame; bounded ordinary counts.
 spawn_budget=minf(6,spawn_budget+hostile_delta*RUN_RULES.base_spawn_rate*stage_clock.pressure()*(1+(stage-1)*RUN_RULES.stage_spawn_growth))
 if spawn_clock<=0 and spawn_budget>=1 and enemies.size()<ENEMY_LIMIT-8:
  var count=mini(3,int(spawn_budget))
  for i in count:spawn_enemy()
  spawn_budget-=count
  spawn_clock=0.25
 if stage_clock.endless():
  ghost_budget=minf(3,ghost_budget+hostile_delta*(RUN_RULES.ghost_base_rate+maxf(0,stage_time-STAGE_SECONDS)/RUN_RULES.ghost_growth_seconds))
  if ghost_budget>=1 and enemies.size()<ENEMY_LIMIT-8:spawn_enemy(11);ghost_budget-=1
 BossEncounters.tick(self,hostile_delta)
 update_enemies(delta)
 rebuild_grid()
 update_special_visuals(delta)
 update_weapons(delta)
 update_projectiles(delta)
 update_fields(delta)
 update_blasts(delta)
 update_pickups(delta)
 WorldPickups.update(self,delta)
 update_effects(delta)
 if mode=="run":update_interactions(delta)
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
 if is_instance_valid(forest_navigation) and not forest_navigation.ready_for_spawning:return {}
 if kind < 0:kind=OrdinaryRoster.choose(spawn_rng)
 var angle = rng.randf()*TAU
 var pos = player.position + Vector3(cos(angle),0,sin(angle))*rng.randf_range(25,38) if at == Vector3.INF else at
 pos.x = clampf(pos.x,-92,92)
 pos.z = clampf(pos.z,-92,92)
 if at==Vector3.INF and pos.distance_to(player.position)<18:
  var inward=-Vector3(player.position.x,0,player.position.z).normalized()
  pos=player.position+inward*28;pos.x=clampf(pos.x,-92,92);pos.z=clampf(pos.z,-92,92)
 pos.y = terrain_height(pos.x,pos.z)+0.7
 var overtime=maxf(0,stage_time-STAGE_SECONDS)
 var scale_factor = (1+elapsed/140.0)*(1+overtime/60.0) * (1+(tier-1)*0.5) * (1+(stage-1)*0.5) * stats.difficulty
 var hp = (35 + kind*8) * scale_factor * (18 if kind==8 else 1)
 var enemy = {"pos":pos,"hp":hp,"max_hp":hp,"kind":kind,"speed":(4.5 if kind==1 else (1.8 if kind in [2,7] else 3.0)),"cooldown":rng.randf()*2,"slow":0.0,"frozen":0.0,"spore":false,"burn":0.0,"burn_clock":0.0,"poison":0.0,"poison_clock":0.0,"knock":Vector3.ZERO,"age":0.0,"phase":0,"biome":biome,"target":Vector3.ZERO,"telegraph":0.0,"scale":2.8 if kind==8 else (1.4 if kind in [2,7] else 1.0)}
 if kind<8:
  var config=OrdinaryRoster.variant(kind,spawn_rng.randi_range(0,1)) if kind<3 else variants.lookup(kind)
  enemy["ordinary"]=kind<3
  enemy["roster_choice"]=config.id
  enemy["radius"]=config.get("radius",0.5)
  enemy["variant"]=config
  enemy["hp"]=config.health*scale_factor
  enemy["max_hp"]=enemy.hp
  enemy["speed"]=config.speed
  enemy["damage"]=config.damage*(1+(tier-1)*0.3+(stage-1)*0.2)*(1+overtime/180)
  enemy["scale"]=1.0
  enemy["state"]="move"
  enemy["windup"]=0.0
  enemy["recovery"]=0.0
  enemy["action"]=""
  enemy["charge_time"]=0.0
  enemy["charge_direction"]=Vector3.ZERO
  enemy["charge_hit"]=false
  enemy["detonated"]=false
  enemy["hit_time"]=0.0
 if kind>=8:
  Encounters.initialize(self,enemy,boss_variant if kind==8 else ("champion" if kind==9 else ("hunter" if kind==10 else ("lesser_golem" if kind==12 else ("statue_elite" if kind==13 else "ghost")))))
 if is_instance_valid(forest_navigation):
  enemy.pos=avoid_props(enemy.pos,float(enemy.get("radius",0.5)))
  if not forest_navigation.reachable(enemy.pos):return {}
 enemy["crowd_id"]=crowd.next_id;crowd.next_id+=1
 enemies.append(enemy)
 if effects.size()<70:combat_fx.burst("smoke_puff",enemy.pos-Vector3.UP*0.5,0.5)
 return enemy
func update_enemies(real_delta: float) -> void:
 # Everything below is hostile simulation, so it runs on Stopwatch-scaled time. The player,
 # weapons, camera, UI and audio never go through here.
 var delta=world_time.hostile(real_delta)
 if debug_combat:
  combat_pool_start=pool.created;combat_burst_start=combat_fx.bursts_created
  combat_counters={"hits":0,"deaths":0,"xp_drops":0,"xp_merged":0,"scenes":0,"freed_nodes":0}
 if is_instance_valid(forest_navigation):forest_navigation.tick(real_delta,player.position)
 crowd.rebuild(enemies)
 var colors = [Color("ee7d70"),Color("ffc05f"),Color("a28cae"),Color("e0d3a0"),Color("f55e67"),Color("b0dafa"),Color("aeef7a"),Color("80b9cb"),Color("cf7aff")]
 var mm = enemy_mesh.multimesh
 var boss_count=0
 enemy_view.begin_frame()
 for i in enemies.size():
  var e = enemies[i]
  if e.hp <= 0: continue
  e.age += delta
  EnemyContact.step(self,e,delta)
  if e.hp<=0:crowd.disable(e);continue
  if e.kind>=8:e["hit_time"]=maxf(0,float(e.get("hit_time",0))-delta)
  e.cooldown -= delta
  if e.has("fx"):StatusManager.tick(self,e,delta)
  e.slow = maxf(0,e.slow-delta)
  e.frozen = maxf(0,e.frozen-delta)
  e.poison = maxf(0,e.poison-delta)
  e.burn=maxf(0,e.burn-delta)
  if e.burn>0:
   if rng.randf()<delta:combat_fx.burst("fire_torch",e.pos,1,0.7)
   e.burn_clock-=delta
   if e.burn_clock<=0: hit(e,3+level*0.5,int(e.get("burn_source",1))); e.burn_clock=0.5
   if not settings.reduced and rng.randf()<0.07: impact(e.pos,Color("ffb45a"),1)
  if e.poison > 0:
   e.poison_clock -= delta
   if e.poison_clock <= 0: hit(e,5+level,int(e.get("poison_source",23))); e.poison_clock = 0.5
  if e.kind<8:
   crowd.prepare(e);EnemySimulation.step(self,e,delta)
   crowd.resolve(self,e,delta)
   if e.hp>0: enemy_view.draw_enemy(e,player.position)
   continue
  if e.has("encounter"):
   crowd.prepare(e);Encounters.step(self,e,delta);crowd.resolve(self,e,delta);enemy_view.draw_enemy(e,player.position);continue
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
  var transform = Transform3D(Basis(Vector3.UP,facing).scaled(Vector3.ONE*e.scale),e.pos-Vector3.UP*0.65*e.scale)
  mm.set_instance_transform(boss_count,transform)
  mm.set_instance_color(boss_count,Color.WHITE if e.get("hit_time",0)>0 else Color("91ddff") if e.slow>0 else (Color("b0ed72") if e.poison>0 else colors[e.kind]))
  boss_count+=1
 mm.visible_instance_count=boss_count
 enemy_view.end_frame()
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
 if invulnerability>0 or loadout_runtime.immune() or (sandbox and settings.invincible): return
 amount*=loadout_runtime.incoming_multiplier()
 if rng.randf()<minf(0.75,stats.evasion): toast("DODGED"); return
 health -= maxf(1,amount*100/(100+stats.armor*5))
 invulnerability = 0.5
 if settings.shake: player.camera.h_offset=rng.randf_range(-0.15,0.15)
 player.hurt_time=0.22
 player.avatar.set_damage_flash(true)
 combat_fx.burst("blood_burst",player.position+Vector3.UP)
 play_sound("hit")
func hit(e: Dictionary, base: float, weapon: int) -> void:
 if e.is_empty() or e.hp<=0: return
 if debug_combat:combat_counters.hits+=1
 var critical = rng.randf()<minf(1,stats.crit+(WeaponUpgrades.value(weapons[weapon],"crit") if weapons.has(weapon) else 0))
 var amount = Catalog.damage(base,stats,critical)*loadout_runtime.damage_multiplier()
 e["last_weapon"]=weapon
 if character == 6: amount *= 1+(1-health/stats.max_health)*1.5
 if character == 7: amount *= 1+gold*0.001
 if character == 10 and e.hp/e.max_hp>0.9: amount*=1.5
 if character == 16 and e.hp/e.max_hp<0.1: amount = e.hp+1
 if e.kind<8 and "shield" in e.variant.modules and e.hp/e.max_hp>0.5: amount*=0.5
 amount=StatusManager.modify_damage(self,e,amount,critical,weapon)
 e["hit_time"]=0.10
 if is_instance_valid(combat_fx):
  combat_fx.burst("impact_concrete",e.pos,0.35,0.12)
  if weapon>=0:WeaponVFX.contact(self,weapon,e.pos)
  else:combat_fx.burst("impact_concrete",e.pos,0.5)
 var actual=minf(amount,maxf(0,e.hp))
 e.hp -= amount
 if weapon>=0:
  if not weapon_damage_windows.has(weapon):weapon_damage_windows[weapon]=[]
  var samples: Array=weapon_damage_windows[weapon]
  var bucket=floorf(elapsed*2)/2
  if not samples.is_empty() and samples.back().time==bucket:samples.back().damage+=actual
  else:samples.append({"time":bucket,"damage":actual})
  while samples.size()>21:samples.pop_front()
 e.knock += (e.pos-player.position).normalized()*stats.knockback*2*(e.variant.knockback if e.kind<8 else 0.2)
 if settings.numbers and DisplayServer.get_name()!="headless":
  var color=Color("ffe6a0") if critical else (Color("acdf76") if weapon in [23,33] else (Color("ffb370") if weapon in [1,3,25] else Color.WHITE))
  numbers.show_damage(e.pos+Vector3.UP,amount,critical,color,elapsed)
 damage_total += actual
 damage_by_weapon[weapon] = damage_by_weapon.get(weapon,0.0)+actual
 health = minf(stats.max_health,health+actual*stats.lifesteal)
 if critical and not settings.reduced: flash(e.pos,Color("fff3aa"),0.4)
 StatusManager.on_hit(self,e,weapon,critical,actual)
func area(pos: Vector3, radius: float, damage: float, weapon: int, status: String = "") -> void:
 if weapon>=0:Vases.strike_sphere(self,pos,radius,weapon)
 for e in nearby(pos,radius):
  hit(e,damage,weapon)
  if status == "slow": e.slow = 2.0*stats.duration
  if status == "poison": e.poison = 4.0*stats.duration;e["poison_source"]=weapon
func kill_enemy(index: int) -> void:
 if index<0 or index>=enemies.size():return
 var e = enemies[index]
 if e.get("death_handled",false):return
 e.death_handled=true;crowd.disable(e)
 StatusManager.on_death(self,e)
 var stage_encounter_complete=BossEncounters.died(self,e)
 RewardDrops.from_enemy(self,e)
 if debug_combat:combat_counters.deaths+=1
 if e.kind<8:
  if "death_blast" in e.variant.modules and not e.detonated:
   e.detonated=true
   schedule_blast(e.pos,e.variant.blast_radius,e.damage,0.4)
  if effects.size()<48:
   var model=e.variant.get("visual_model","Puglin")
   var corpse=pool.acquire("corpse_"+model,BestiaryFrames.mesh(model,"enemy_idle",0),Color.WHITE,e.pos-Vector3.UP*0.65,true)
   corpse.scale=Vector3.ONE*float(e.variant.get("visual_scale",1))*e.scale
   effects.append({"node":corpse,"life":0.4,"death":true})
  combat_fx.burst("smoke_puff",e.pos,0.5,0.25)
 if character == 13 and e.poison>0: area(e.pos,4,12,23,"poison")
 if character == 12 and (e.slow>0 or e.frozen>0): health = minf(stats.max_health,health+2)
 if e.spore:
  area(e.pos,4*stats.size,12,33,"poison")
  flash(e.pos,Color("acff6a"),4)
 kills += 1
 var source=int(e.get("last_weapon",-1))
 if source>=0:run_metrics["weapon:"+str(source)]=int(run_metrics.get("weapon:"+str(source),0))+1
 if e.kind in [9,10]:
  run_metrics["minibosses"]=int(run_metrics.get("minibosses",0))+1;gold+=25
 if e.kind>=8:
  if effects.size()<48:
   var model=e.variant.get("visual_model","Puglin" if e.get("encounter","") in ["colossus","champion"] else "Imp")
   var corpse=pool.acquire("corpse_"+model,e.variant.mesh,Color.WHITE,e.pos,true);corpse.scale=Vector3.ONE*e.scale
   effects.append({"node":corpse,"life":0.6,"death":true})
  combat_fx.burst("smoke_puff",e.pos,2)
 if e.kind == 8:
  for summoned in enemies:
   if summoned.get("summon_owner","")==e.get("owner_key","none"):summoned.hp=0;crowd.disable(summoned)
  run_metrics["bosses"]=int(run_metrics.get("bosses",0))+1
  if stage_encounter_complete:
   boss_dead = true
   portal_state="exit"
   refresh_portal()
   toast("ALL STAGE BOSSES DEFEATED • The portal is open.")
  gold += 50
 for i in (6 if e.kind==8 else 1):
  add_xp_drop(e.pos+Vector3(rng.randf()-0.5,0,rng.randf()-0.5),float(e.variant.reward if e.has("variant") else 5))
 if XPGems.eligible(e) and gem_rng.randf()<XPGems.RED_CHANCE:add_red_gem(e.pos)
 # Gold is automatically collected on every kill; no per-coin physics objects.
 gold_fraction+=stats.gold_gain
 var gained=int(gold_fraction)
 gold+=gained
 gold_fraction-=gained
 enemies.remove_at(index)
 if e.get("elite",false) and elite_active and not elite_rewarded:
  var remaining=false
  for enemy in enemies:
   if enemy.hp>0 and enemy.get("elite",false):remaining=true;break
  if not remaining:
   elite_rewarded=true;elite_active=false;gold+=OrdinaryRoster.SETTINGS.elite_reward;toast("ELITES DEFEATED • +%d gold"%OrdinaryRoster.SETTINGS.elite_reward)
func show_stage_intro() -> void:
 if stage in announced_stages:return
 announced_stages.append(stage);frontend.stage_intro(stage)
func announce(text: String) -> void:
 announcement=text;announcement_time=4
 toast(text)
func stage_event(event_id: String) -> void:
 match event_id:
  "rush_1","rush_2":
   announce("MOB RUSH • 30 seconds")
   tone(180,0.5)
  "miniboss_1","miniboss_2":
   var direction=-Vector3(player.position.x,0,player.position.z).normalized()
   var group=BossEncounters.start(self,str(stage)+":"+event_id,false,player.position+direction*24)
   announce("MINIBOSS ENCOUNTER · %d bosses"%group.required);play_sound("ready")
  "endless":
   run_metrics["endless"]=int(run_metrics.get("endless",0))+1
   announce("ENDLESS MODE • Escape through the boss portal")
   tone(90,0.6)
func make_portal() -> void:
 if is_instance_valid(portal):return
 assert(forest_navigation.reachable(map_layout.portal))
 portal=Node3D.new();world.add_child(portal)
 portal.position=map_layout.portal
 GrimdarkObjects.portal(self)
 refresh_portal()
func refresh_portal() -> void:
 if not is_instance_valid(portal):return
 GrimdarkObjects.refresh_portal(self)
func activate_portal() -> bool:
 if portal_state=="summoned":return false
 if portal_state=="exit":return advance_stage()
 for active in enemies:
  if active.kind==8 and active.hp>0:return false
 var group=BossEncounters.start(self,str(stage)+":stage",true,portal.position)
 boss_spawned=true;portal_state="summoned";refresh_portal()
 announce("STAGE GUARDIANS · %d bosses"%group.required)
 tone(90,0.6)
 return true
func advance_stage() -> bool:
 if not boss_dead or portal_state!="exit":return false
 # Persist both sides of the transition; an interrupted generation can resume safely.
 if not save_run():toast("Cannot advance: checkpoint save failed");return false
 stage+=1;world_content_version=WORLD_CONTENT_VERSION
 map_seed_override=-1
 run_metrics["stage"]=maxi(stage,int(run_metrics.get("stage",1)))
 if stage_time<STAGE_SECONDS:run_metrics["early_stage"]=int(run_metrics.get("early_stage",0))+1
 if stage_time<=300:run_metrics["fast_clear"]=int(run_metrics.get("fast_clear",0))+1
 build_stage()
 loadout_runtime.cooldown=0;loadout_runtime.remaining=0
 resume();show_stage_intro()
 if not save_run():toast("Stage entered • checkpoint save failed")
 return true
func update_weapons(delta: float) -> void:
 for id in weapons:
  var state = weapons[id]
  state.clock -= delta
  if state.clock>0: continue
  var w = Catalog.WEAPONS[id]
  var rank = state.level
  var haste = stats.haste + (minf(moving_time,20)*0.02 if character==2 else 0)
  state.clock = float(w[3])/haste/(1+WeaponUpgrades.value(state,"haste"))
  var target = nearest(player.position,w[4]*stats.size*(1+WeaponUpgrades.value(state,"range")),w[1] in ["beam","rail"])
  # With no enemy in range, aiming weapons may target the nearest vase so every weapon can break them.
  if target.is_empty() and w[1] in Vases.AIM_KINDS:target=Vases.target(self,player.position,w[4]*stats.size*(1+WeaponUpgrades.value(state,"range")))
  var power = WeaponUpgrades.damage(id,state)
  var radius = stats.size*(1+WeaponUpgrades.value(state,"radius"))
  var count = mini(16,int(stats.count)+int(WeaponUpgrades.value(state,"count")))
  var color = Color(w[5])
  var origin = player.position+Vector3.UP
  var direction = (target.pos-origin).normalized() if not target.is_empty() else Vector3.FORWARD.rotated(Vector3.UP,player.yaw)
  if not target.is_empty() or w[1] in ["aura","sweep","orbit","mine","chrono","trail","frost_trail","reap","corrupt","dash_slash","cone"]:WeaponVFX.attack(self,id,origin,target.pos if not target.is_empty() else origin)
  match w[1]:
   "aura","sweep","corrupt","reap","dash_slash","cone":
    var r = float(w[4])*radius
    for e in nearby(origin,r):
     if w[1] in ["aura","reap","corrupt"] or direction.dot((e.pos-origin).normalized())>0.1:
      hit(e,power,id)
      if w[1]=="corrupt": e.poison=3;e["poison_source"]=id
    Vases.strike_arc(self,origin,direction,r,w[1] in ["aura","reap","corrupt"],id)
    if w[1]=="aura": flash(origin,color,r)
    else: slash_arc(origin,direction,r,color)
    if w[1]=="reap": health = minf(stats.max_health,health+1)
   "orbit","chrono":
    for i in orbit_count(id):
     var p = orbit_position(id,i)
     area(p,2*radius,power,id,"slow" if w[1]=="chrono" else "")
     if id!=4:flash(p,color,0.7)

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
     lightning_arc(origin,e.pos,color)
     Vases.strike_sphere(self,e.pos,1.2,id)
    if target.has("vase"):
     lightning_arc(origin,target.pos,color)
     Vases.strike_sphere(self,target.pos,1.6,id)
    if w[1]=="drain": health=minf(stats.max_health,health+3)
   "hitscan","beam","rail":
    if target.is_empty(): continue
    var length = float(w[4])*(1+WeaponUpgrades.value(state,"range"))
    var end = origin+direction*length
    beam(origin,end,color)
    Vases.strike_segment(self,origin,end,1.2*radius,id)
    var hits = 0
    for e in nearby(origin,length):
     var along = clampf((e.pos-origin).dot(direction),0,length)
     if e.pos.distance_to(origin+direction*along)<1.2*radius:
      hit(e,power,id)
      hits+=1
      if w[1]=="rail":
       for arc in nearby(e.pos,5+rank):
        if arc!=e: hit(arc,power*0.25,id); lightning_arc(e.pos,arc.pos,color)
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
  if not target.is_empty() or id==16:audio.emit(WeaponVFX.sound(id),origin,0.45 if id==16 else 1.0)
func launch(pos: Vector3, direction: Vector3, damage: float, id: int, color: Color, kind: String, rank: int) -> void:
 if projectiles.size()>=220: return
 var node = pool.acquire("shot%d"%id,projectile_mesh(kind),color,pos)
 node.scale = Vector3.ONE * stats.size
 var speed = (35 if kind in ["bullet","pierce","scatter"] else 20)*stats.projectile_speed*(1+WeaponUpgrades.value(weapons[id],"velocity"))
 var ricochets=(2 if kind=="bounce" else 0)+int(WeaponUpgrades.value(weapons[id],"ricochet"))
 if kind=="bullet":combat_fx.burst("muzzle_front",pos,1.5)
 projectiles.append({"node":node,"velocity":direction*speed,"damage":damage,"weapon":id,"kind":kind,"life":2.5*stats.duration,"ricochets":ricochets,"age":0.0,"pierce":rank+1 if kind in ["pierce","wave"] else 1,"hits":[],"hostile":false,"rank":rank})
func hostile_bolt(pos: Vector3, target: Vector3, damage: float = -1, speed: float = 13, style: String = "thorn") -> void:
 if projectiles.size()>=240: return
 var node = pool.acquire("hostile_"+style,projectile_mesh(style),Color("9fe1ff") if style=="soul" else Color("ff9b74"),pos)
 projectiles.append({"node":node,"velocity":(target-pos).normalized()*speed,"damage":damage if damage>=0 else 10.0*tier,"weapon":-1,"kind":"hostile","life":4.0,"age":0.0,"pierce":1,"hits":[],"hostile":true,"rank":1})
func segment_distance(p: Vector3, a: Vector3, b: Vector3) -> float:
 var segment = b-a
 var t = clampf((p-a).dot(segment)/maxf(segment.length_squared(),0.001),0,1)
 return p.distance_to(a+segment*t)
func update_projectiles(real_delta: float) -> void:
 for i in range(projectiles.size()-1,-1,-1):
  var p = projectiles[i]
  # Hostile projectiles follow Stopwatch time; the player's own projectiles never do.
  var delta=real_delta*(world_time.scale if p.hostile else 1.0)
  p.life -= delta
  p.age += delta
  var previous = p.node.position
  if p.kind=="rocket":
   var target = nearest(previous,25)
   if not target.is_empty(): p.velocity=p.velocity.lerp((target.pos-previous).normalized()*24*stats.projectile_speed,delta*6)
  if p.kind=="return" and p.age>0.6: p.velocity=(player.position+Vector3.UP-previous).normalized()*26*stats.projectile_speed
  if p.kind=="lob": p.velocity.y-=15*delta
  var next_position=p.node.position+p.velocity*delta
  var collision=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(previous,next_position,1))
  p.node.position=collision.position if not collision.is_empty() else next_position
  if not collision.is_empty() and not p.hostile and collision.collider is Node and collision.collider.has_meta("vase_id"):Vases.break_vase(self,int(collision.collider.get_meta("vase_id")),p.weapon)
  if not collision.is_empty() or p.node.position.y<terrain_height(p.node.position.x,p.node.position.z)+0.08:
   if collision.is_empty():p.node.position.y=terrain_height(p.node.position.x,p.node.position.z)+0.1
   combat_fx.burst("impact_concrete",p.node.position,1.5)
   if not p.hostile and p.kind in ["fireball","rocket","lob","dice"]:
    combat_fx.burst("explosion_small",p.node.position,1.5);area(p.node.position,3.5*stats.size,p.damage*0.7,p.weapon)
   pool.release(p.node);projectiles.remove_at(i);continue
  if p.velocity.length_squared()>0.01: p.node.look_at(p.node.position+p.velocity)
  if not settings.reduced and int(p.age*30)!=int((p.age-delta)*30) and effects.size()<55:
   trail(p.node.position,Color("ff9b74") if p.hostile else Color(Catalog.WEAPONS[p.weapon][5]))
  if p.hostile:
   if segment_distance(player.position+Vector3.UP,previous,p.node.position)<0.8: hurt(p.damage); p.life=0
  else:
   for e in nearby(p.node.position,4+ p.velocity.length()*delta):
    if e in p.hits or segment_distance(e.pos,previous,p.node.position)>maxf(1.0,float(e.get("radius",0.5)))*stats.size: continue
    hit(e,p.damage,p.weapon)
    if p.kind=="fireball": e.burn=3*stats.duration;e["burn_source"]=p.weapon
    impact(e.pos,Color(Catalog.WEAPONS[p.weapon][5]),2)
    p.hits.append(e)
    if p.kind in ["poison","spore"]:
     make_field(p.node.position,4*stats.size,p.damage*0.4,p.weapon,Color(Catalog.WEAPONS[p.weapon][5]),"poison",(3+p.rank*0.15)*stats.duration)
    if p.kind in ["fireball","rocket","lob","dice"]:
     combat_fx.burst("explosion_small",p.node.position,1.7)
     area(p.node.position,3.5*stats.size,p.damage*0.7,p.weapon)
     flash(p.node.position,Color(Catalog.WEAPONS[p.weapon][5]),3)
    if p.get("ricochets",0)>0:
     for target in nearby(p.node.position,14):
      if not target in p.hits:
       p.velocity=(target.pos-p.node.position).normalized()*22
       p.pierce+=1;p.ricochets-=1
       break
    p.pierce-=1
    if p.pierce<=0: p.life=0; break
  if p.life<=0:
   pool.release(p.node)
   projectiles.remove_at(i)
func make_field(pos: Vector3, radius: float, damage: float, id: int, color: Color, status: String, duration: float, mine: bool = false) -> void:
 if fields.size()>=55: return
 var node = mesh_node(WeaponArt.mesh("mine") if mine else cylinder(radius,0.08),Color.WHITE if mine else color.darkened(0.2),world,Vector3(pos.x,terrain_height(pos.x,pos.z)+0.12,pos.z),false if mine else true)
 if mine:node.material_override=null
 node.quaternion=Quaternion(Vector3.UP,ForestMap.normal(stage_map_seed(),pos.x,pos.z))
 fields.append({"node":node,"radius":radius,"damage":damage,"weapon":id,"status":status,"life":duration*(1+WeaponUpgrades.value(weapons[id],"duration") if weapons.has(id) else 1),"clock":0.3,"mine":mine})
func update_fields(delta: float) -> void:
 for i in range(fields.size()-1,-1,-1):
  var f = fields[i]
  f.life-=delta
  f.clock-=delta
  if f.clock<=0:
   var targets=nearby(f.node.position,f.radius)
   var vase_hits=Vases.strike_sphere(self,f.node.position,f.radius,f.weapon)
   if not f.mine or targets.size()>0 or vase_hits>0:
    for e in targets:
     hit(e,f.damage,f.weapon)
     if f.status=="poison":
      e.poison=4*stats.duration;e["poison_source"]=f.weapon
      if f.weapon==33: e.spore=true
     if f.status=="slow": e.slow=2*stats.duration
     if f.status=="pull": e.knock+=(f.node.position-e.pos).normalized()*8
    f.clock=0.5
    if f.mine and (targets.size()>0 or vase_hits>0):
     combat_fx.supplied_burst("debris",f.node.position,1.5);combat_fx.burst("explosion_small",f.node.position,clampf(f.radius/2,1,3));play_sound("explosion");flash(f.node.position,Color("ffc56a"),f.radius); f.life=0
  if f.life<=0: f.node.queue_free(); fields.remove_at(i)
func flash(pos: Vector3, color: Color, radius: float) -> void:
 if effects.size()>=effect_budget():return
 var node=pool.acquire("flash"+color.to_html(),effect_mesh("ring"),color,pos);node.scale=Vector3.ONE*radius
 effects.append({"node":node,"life":0.3})
func beam(a: Vector3,b: Vector3,color: Color) -> void:
 if a.distance_squared_to(b)<0.01 or effects.size()>=effect_budget():return
 var node=pool.acquire("beam"+color.to_html(),effect_mesh("beam"),color,(a+b)*0.5)
 node.scale=Vector3(1,1,a.distance_to(b));node.look_at(b);effects.append({"node":node,"life":0.13})
func update_effects(delta: float) -> void:
 if is_instance_valid(numbers):numbers.tick(delta)
 for i in range(effects.size()-1,-1,-1):
  # Hostile warning rings last as long as the (Stopwatch-slowed) attack they announce.
  effects[i].life-=delta*(world_time.scale if effects[i].get("telegraph",false) else 1.0)
  if effects[i].has("velocity"):
   effects[i].velocity+=Vector3.DOWN*delta*6
   effects[i].node.position+=effects[i].velocity*delta
  if effects[i].get("death",false):
   effects[i].node.rotation.z+=delta*3
   effects[i].node.position.y-=delta*0.8
   effects[i].node.scale*=maxf(0,1-delta*3)
  elif not effects[i].get("telegraph",false): effects[i].node.scale*=1+delta*2
  if effects[i].node is Label3D: effects[i].node.position.y+=delta*2
  if effects[i].life<=0:
   if effects[i].node.has_meta("pool_key"): pool.release(effects[i].node)
   else:
    effects[i].node.queue_free()
    if debug_combat:combat_counters.freed_nodes+=1
   effects.remove_at(i)
func update_pickups(delta: float) -> void:
 for i in range(pickups.size()-1,-1,-1):
  var p = pickups[i]
  p.age+=delta
  p.node.rotation.y+=delta*0.85
  p.node.position.y+=(sin(p.age*2)-sin((p.age-delta)*2))*0.06
  var distance = p.node.position.distance_to(player.position+Vector3.UP)
  if not p.get("attracted",false) and distance<5*stats.pickup:
   p["attracted"]=true;p["attraction_reason"]="pickup_range";p["attraction_distance"]=distance;p["attraction_radius"]=5*stats.pickup
  if p.get("magnet",false):
   p.node.position=WorldPickups.magnet_step(p,player.position+Vector3.UP,delta)
  elif p.get("attracted",false):
   p.node.position=p.node.position.move_toward(player.position+Vector3.UP,delta*maxf(10,18-distance))
  if distance<1.2:
   if p.get("red",false):grant_red_level()
   else:xp+=p.value*stats.xp
   audio.emit("pickup.xp",p.node.position,0.6)
   pool.release(p.node)
   pickups.remove_at(i)
 while xp>=Catalog.threshold(level):
  xp-=Catalog.threshold(level)
  level+=1
  on_level();pending_upgrades+=1
 if pending_upgrades>0 and mode in ["run","pause"]:
  pending_upgrades-=1;show_upgrades()
func grant_red_level() -> void:
 while xp>=Catalog.threshold(level):
  xp-=Catalog.threshold(level);level+=1;on_level();pending_upgrades+=1
 var fraction=xp/Catalog.threshold(level)
 level+=1;on_level();xp=fraction*Catalog.threshold(level);pending_upgrades+=1
func add_red_gem(pos: Vector3) -> void:
 pickups.append({"node":XPGems.acquire(self,pos,true),"value":0.0,"age":0.0,"red":true})
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
 for id in Catalog.ACTIVE_WEAPONS:
  if (weapons.has(id) and weapons[id].level<10) or (not weapons.has(id) and weapons.size()<weapon_limit() and (sandbox or MetaProgress.enabled(progress.data,"weapons",str(id)))):
   if not "w%d"%id in banished:
    var choice={"type":"weapon","id":id,"key":"w%d"%id}
    if weapons.has(id):choice.merge(WeaponUpgrades.proposal(id,rng));choice["expected_level"]=int(weapons[id].level)
    pool.append(choice)
 for name in Catalog.ACTIVE_TOMES:
  if (tomes.has(name) and tomes[name]<10) or (not tomes.has(name) and tomes.size()<tome_limit() and (sandbox or MetaProgress.enabled(progress.data,"tomes",name))):
   if not name in banished: pool.append({"type":"tome","id":name,"key":name})
 if pool.is_empty():
  for i in 3:pool.append({"type":"supply","id":str(i),"key":"supply"+str(i)})
 for choice in pool:
  if choice.type=="supply":continue
  var category="weapons" if choice.type=="weapon" else "tomes"
  var rank=int(weapons[choice.id].level) if choice.type=="weapon" and weapons.has(choice.id) else int(tomes.get(choice.id,0)) if choice.type=="tome" else 0
  choice["metadata"]=RewardCatalog.entry(category,choice.id,rank)
  if rank==0:choice.metadata.rarity="common";choice["acquisition"]=true
 return pool
func upgrade_choices(count: int=3) -> Array:
 var candidates=upgrade_pool()
 if not candidates.is_empty() and candidates[0].type=="supply":return candidates.slice(0,count)
 return RewardSelector.draw(candidates,count,rng)
func show_upgrades() -> void:
 frontend.upgrades()
 play_sound("level")

func apply_upgrade(choice: Dictionary) -> void:
 if choice.type=="supply":health=minf(stats.max_health,health+25);return
 if choice.type=="weapon":
  var id=int(choice.id)
  if weapons.has(id):
   if int(weapons[id].level)>=10 or int(choice.get("expected_level",weapons[id].level))!=int(weapons[id].level):return
   var proposal=choice if choice.has("attribute") else WeaponUpgrades.proposal(id,rng)
   if WeaponUpgrades.apply(id,weapons[id],proposal):
    weapons[id].level+=1;weapons[id]["rarity"]=choice.get("metadata",{}).get("rarity",weapons[id].get("rarity","common"))
  elif id in Catalog.ACTIVE_WEAPONS and (sandbox or MetaProgress.enabled(progress.data,"weapons",str(id))) and weapons.size()<weapon_limit():equip(id)
 else:
  var name=str(choice.id)
  if not Catalog.TOMES.has(name):return
  if not tomes.has(name) and not sandbox and (name not in Catalog.ACTIVE_TOMES or not MetaProgress.enabled(progress.data,"tomes",name)):return
  if not tomes.has(name) and tomes.size()>=tome_limit():return
  if int(tomes.get(name,0))>=10:return
  tome_rarities[name]="common" if not tomes.has(name) else choice.get("metadata",{}).get("rarity",tome_rarities.get(name,"common"))
  tomes[name]=tomes.get(name,0)+1
  var stat=Catalog.TOMES[name][0]
  stats[stat]+=Catalog.TOMES[name][1]
  if stat=="slide_friction":stats[stat]=maxf(0.15,stats[stat])
  if stat=="max_health": health+=Catalog.TOMES[name][1]
func award_item() -> Array:
 var available=available_items()
 if available.is_empty():return []
 var selected=RewardSelector.choose(RewardSelector.items(available),rng,Rarity.reward_weights(stats.luck))
 if selected.is_empty():return []
 var id=int(selected.id)
 apply_item(id)
 return Catalog.ITEMS[id]
func update_interactions(delta: float) -> void:
 RewardDrops.collect(self)
 if mode=="reward":return
 var closest: Dictionary={}
 var distance=4.0
 for obj in interactables:
  if obj.used: continue
  if obj.kind=="Shop" and obj.node.has_node("Seller"):obj.node.get_node("Seller").animate("idle",0,delta)
  var d=obj.node.position.distance_to(player.position)
  if obj.kind=="Free Chest":
   if d<=RewardDrops.SETTINGS.drop_pickup_radius and RewardDrops.queue_roll(self):
    obj.used=true;obj.node.hide();run_metrics["free_chests"]=int(run_metrics.get("free_chests",0))+1;run_metrics["chests"]=int(run_metrics.get("chests",0))+1;play_sound("level")
   continue
  if ShrineCharging.is_shrine(obj):
   ShrineCharging.tick(self,obj,d,delta)
   if mode=="shrine":return
   continue
  if d<distance: distance=d; closest=obj
 if mode=="run" and RewardDrops.present_next(self):return
 if is_instance_valid(portal) and portal.position.distance_to(player.position)<4:
  notice.text="E  /  "+("Advance to stage %d"%(stage+1) if portal_state=="exit" else ("Boss active • defeat the stage guardian" if portal_state=="summoned" else "Summon the stage boss"))
  if Input.is_action_just_pressed("interact"):activate_portal()
  return
 var vase=Vases.nearest_in_reach(self,player.position)
 if not vase.is_empty() and (closest.is_empty() or Vector2(vase.pos.x-player.position.x,vase.pos.z-player.position.z).length()<closest.node.position.distance_to(player.position)):
  notice.text="E  /  Smash vase"
  if Input.is_action_just_pressed("interact"):Vases.smash(self,vase)
  return
 if closest.is_empty(): return
 if closest.kind=="Boss Statue":
  notice.text="[%s] Increase Boss Count (+1 for this run)\nFuture miniboss/stage encounters: %d bosses"%[OS.get_keycode_string(bindings.interact),additional_boss_count+2]
  if Input.is_action_just_pressed("interact"):activate_boss_statue(closest)
  return
 if closest.kind=="Elite Statue":
  notice.text="Press E to summon Elite Enemies"
  if Input.is_action_just_pressed("interact"):activate_elite_statue(closest)
  return
 notice.text="E  /  %s%s"%[closest.kind," · %d gold"%chest_cost() if closest.kind=="Chest" else (" · %d gold per gem"%ImbueRules.cost(stage) if closest.kind==ImbueStation.KIND else "")]
 if not Input.is_action_just_pressed("interact"): return
 match closest.kind:
  "Shop":frontend.shop(closest);return
  "Imbue Station":frontend.imbue_station(closest);return
  "Chest":
   if available_items().is_empty():toast("Enable items in Unlocks before opening chests");return
   if gold<chest_cost():toast("Need %d gold"%chest_cost());return
   gold-=chest_cost();chests_opened+=1;run_metrics["chests"]=int(run_metrics.get("chests",0))+1
   if RewardDrops.queue_roll(self):RewardDrops.present_next(self)
  "Heal": health=minf(stats.max_health,health+40); toast("Restored 40 health")
 closest.used=true
 closest.node.scale=Vector3.ONE*0.5
 tone(600,0.15)
func update_hud() -> void:
 frontend.update_hud()
 if is_instance_valid(combat_debug_label):
  combat_debug_label.visible=debug_combat
  if debug_combat:combat_debug_label.text="COMBAT / frame: hits %d deaths %d new pooled nodes %d scenes %d frees %d\nFX %d (spawned %d) XP entities %d (merged %d) numbers %d"%[combat_counters.get("hits",0),combat_counters.get("deaths",0),pool.created-combat_pool_start,combat_counters.get("scenes",0),combat_counters.get("freed_nodes",0),combat_fx.active.size(),combat_fx.bursts_created-combat_burst_start,pickups.size(),combat_counters.get("xp_merged",0),numbers.active.size()]


func pause_menu() -> void:
 frontend.pause()
func show_build() -> void:
 frontend.inventory()

func finish_run(victory: bool) -> void:
 mode="results"
 world_time.reset()
 if not victory and health<=0:
  player.dead=true
  var dying_avatar=player.avatar
  var death_tween=dying_avatar.create_tween()
  death_tween.tween_method(func(_time):
   if is_instance_valid(dying_avatar): dying_avatar.animate("death",0,0.03),0.0,1.0,0.65)
 if not sandbox and FileAccess.file_exists("user://active-run.json"): DirAccess.remove_absolute("user://active-run.json")
 var unlocked=progress.finish(kills,elapsed,victory,selected_biome,sandbox)
 run_metrics["ultimates"]=loadout_runtime.uses
 MetaProgress.record(progress.data,{"weapon":selected_weapon,"trait":loadout_runtime.trait_id,"ultimate":loadout_runtime.ultimate_id,"time":elapsed,"kills":kills,"victory":victory,"metrics":run_metrics.duplicate(true)},sandbox)
 if not sandbox:progress.save()
 var col=clear_panel("VICTORY / INFINITY BROKEN" if victory else "THE WILD CLAIMS ANOTHER")
 var best=-1
 for id in damage_by_weapon:
  if best==-1 or damage_by_weapon[id]>damage_by_weapon[best]: best=id
 title("Survived %02d:%02d · Stage %d · Level %d\n%d kills · %.0f damage · %d gold\nHighest damage: %s\n%s"%[int(elapsed)/60,int(elapsed)%60,stage,level,kills,damage_total,gold,Catalog.WEAPONS[best][0] if best>=0 else "None","Sandbox: no progression written" if sandbox else "Quest progress saved • claim silver in Quests"],col,20)
 if unlocked.size()>0: title("Requirements met: "+", ".join(unlocked),col,18)
 button("Run again",col,begin_run)
 button("Main menu",col,func(): build_menu_world(); main_menu())
 tone(520 if victory else 110,0.5)
func show_progress() -> void:
 frontend.unlocks()

func sandbox_menu() -> void:
 mode="sandbox"
 var col=clear_panel("SANDBOX / PROGRESSION ISOLATED")
 var select=OptionButton.new()
 for id in Catalog.ACTIVE_WEAPONS:select.add_item(Catalog.WEAPONS[id][0],id)
 col.add_child(select)
 button("Equip / upgrade selected weapon",col,func(): equip(select.get_item_id(select.selected)); toast("Equipped or upgraded"))
 button("Set selected weapon to level 10",col,func():
  equip(select.get_item_id(select.selected))
  if weapons.has(select.get_item_id(select.selected)):weapons[select.get_item_id(select.selected)].level=10)
 button("Clear weapons",col,func():
  for id in weapons:
   for node in weapons[id].visuals: node.queue_free()
   for ally in weapons[id].summons: ally.node.queue_free()
  weapons.clear();gems.reset())
 button("Add random tome",col,func(): var names=Catalog.ACTIVE_TOMES; var name=names[rng.randi_range(0,names.size()-1)]; apply_upgrade({"type":"tome","id":name}))
 button("Add item",col,award_item)
 title("Map seed: %s • F6 overlay • F7 repeat • F8 next"%stage_map_seed(),col,18)
 var seed_input=LineEdit.new();seed_input.text=str(stage_map_seed());seed_input.placeholder_text="Map seed";col.add_child(seed_input)
 button("Generate entered seed",col,func():
  if seed_input.text.is_valid_int():map_seed_override=int(seed_input.text);build_stage();resume())
 button("Show regions / ramps / navigation",col,toggle_map_debug)
 button("Combat counters: "+str(debug_combat),col,func():
  debug_combat=not debug_combat
  if not is_instance_valid(combat_debug_label):
   combat_debug_label=Label.new();combat_debug_label.position=Vector2(20,180);combat_debug_label.add_theme_font_size_override("font_size",16);ui.add_child(combat_debug_label)
  combat_debug_label.visible=debug_combat;resume())
 button("Audio diagnostics",col,func():toast(JSON.stringify(audio.diagnostics())))
 button("Spawn 100 enemies",col,func(): for i in 100: spawn_enemy())
 button("Spawn Warden",col,func(): spawn_enemy(8))
 button("Add XP +100 / gold +100",col,func(): xp+=100; gold+=100)
 button("Invincibility: "+str(settings.invincible),col,func(): settings.invincible=not settings.invincible; sandbox_menu())
 button("Time scale: "+str(Engine.time_scale),col,func(): Engine.time_scale=2 if Engine.time_scale==1 else 1; sandbox_menu())
 button("Teleport to spawn",col,func(): player.position=map_layout.spawn+Vector3.UP)
 button("Resume",col,resume)
func settings_menu(back: Callable) -> void:
 frontend.settings(back)

func apply_settings() -> void:
 if is_instance_valid(grimdark_renderer):grimdark_renderer.apply_settings()
 if is_instance_valid(audio):audio.volumes(settings)
 get_viewport().scaling_3d_scale=float(settings.render_scale)
 get_viewport().msaa_3d=Viewport.MSAA_4X if int(settings.quality)==2 else Viewport.MSAA_DISABLED
 if is_instance_valid(world):
  for child in world.get_children():
   if child is DirectionalLight3D: child.shadow_enabled=int(settings.quality)>0
 if is_instance_valid(player): player.sensitivity=settings.sensitivity; player.inverted=settings.invert
func setup_audio() -> void:
 audio=RetroAudio.new();add_child(audio);audio.music_menu();apply_settings()
 sound_bank["hit"]=audio.streams[audio.events["player.damage"].files[0]];sound_bank["level"]=audio.streams[audio.events["reward.level_up"].files[0]]
 sound_bank["applause"]=audio.streams[audio.events["reward.applause"].files[0]];sound_bank["legendary"]=audio.streams[audio.events["reward.chest.legendary"].files[0]]
func play_sound(event: String,gain: float=1.0) -> void:
 if event in ["death","enemy.death","enemy.hit"]:return
 var aliases={"hit":"player.damage","purchase":"ui.purchase","level":"reward.level_up","menu":"ui.confirm","explosion":"combat.explosion","ready":"boss.warning","cast":"weapon.firestaff.cast","shot":"weapon.bow.fire","swing":"weapon.sword.swing","stone":"weapon.chunkers.impact","lightning":"weapon.lightning.zap","place":"weapon.mines.place","revolver":"weapon.revolver.fire","applause":"reward.applause","legendary":"reward.chest.legendary"}
 if is_instance_valid(audio):audio.emit(aliases.get(event,event),Vector3.INF,gain)
func tone(_frequency: float,_duration: float,_loudness: float=0.3) -> void:
 # Legacy UI/boss callsites now use cached events, never allocate PCM at runtime.
 play_sound("boss.warning" if _frequency<200 else "ui.confirm")

func update_special_visuals(delta: float) -> void:
 for id in weapons:
  var w = Catalog.WEAPONS[id]
  var state = weapons[id]
  var rank = state.level
  if w[1] in ["orbit","chrono"]:
   var count=orbit_count(id)
   while state.visuals.size()<count:
    var node=MeshInstance3D.new();node.mesh=WeaponArt.mesh("stone" if id==4 else ("shield" if id==8 else "blade"));world.add_child(node);state.visuals.append(node)
   while state.visuals.size()>count:state.visuals.pop_back().queue_free()
   var size_multiplier=stats.size*(1+WeaponUpgrades.value(state,"radius"))
   for i in state.visuals.size():
    state.visuals[i].position=orbit_position(id,i);state.visuals[i].scale=Vector3.ONE*size_multiplier
    state.visuals[i].rotation=Vector3(elapsed*0.45+i,-elapsed*1.2+i*2,elapsed*0.3) if id==4 else Vector3(0,-elapsed*3-i*TAU/count,0)
   if id==4:
    if not state.has("debris"):
     var debris=MultiMeshInstance3D.new();debris.multimesh=MultiMesh.new();debris.multimesh.transform_format=MultiMesh.TRANSFORM_3D;debris.multimesh.mesh=WeaponArt.mesh("stone");debris.multimesh.instance_count=12;world.add_child(debris);state.debris=debris
    for i in 12:
     var angle=elapsed*1.3+i*TAU/12;var p=player.position+Vector3(cos(angle)*(0.8+i%3*0.3),0.2+sin(elapsed*2+i)*0.12,sin(angle)*(0.8+i%3*0.3))
     state.debris.multimesh.set_instance_transform(i,Transform3D(Basis.from_euler(Vector3(angle,i,angle)).scaled(Vector3.ONE*0.08),p))
  if w[1]=="summon":
   var count=mini(8,1+int(stats.count)/2+rank/3)
   while state.summons.size()<count:
    var node=create_avatar(world,14,player.position+Vector3(rng.randf_range(-2,2),1,rng.randf_range(-2,2)))
    state.summons.append({"node":node,"clock":0.0})
   for i in state.summons.size():
    var summon=state.summons[i]
    summon.clock-=delta
    var node=summon.node
    var target=nearest(node.position,18*(1+WeaponUpgrades.value(state,"range")))
    var destination=player.position+Vector3(cos(elapsed+i)*3,0,sin(elapsed+i)*3) if target.is_empty() else target.pos
    node.position=node.position.move_toward(destination,delta*11*stats.speed)
    node.position.y=terrain_height(node.position.x,node.position.z)+0.3+sin(elapsed*3+i)*0.2
    if node.position.distance_to(destination)>0.2: node.look_at(Vector3(destination.x,node.position.y,destination.z))
    if not target.is_empty() and target.pos.distance_to(node.position)<3 and summon.clock<=0:
     hit(target,WeaponUpgrades.damage(id,state)*(1.8 if rank>=7 and i==0 else 1),id)
     flash(target.pos,Color(w[5]),0.8)
     summon.clock=0.9/stats.haste/(1+WeaponUpgrades.value(state,"haste"))

func _exit_tree() -> void:
 CombatFX.frames.clear()
 ForestAtmosphere.reset();StageThemes.reset()
 RigClips.reset()
 if is_instance_valid(music):
  music.stop()
  music.stream=null
 for audio in sfx:
  if is_instance_valid(audio):
   audio.stop()
   audio.stream=null

func prop_instance(key: String, mesh: Mesh, color: Color, pos: Vector3, size: Vector3 = Vector3.ONE, source_materials: bool=false, yaw_rotation: float=0) -> void:
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
  if not source_materials:batch.material_override=material
  world.add_child(batch)
  prop_batches[key]=batch
 decoration_checksum=hash(str(decoration_checksum)+key+str(pos)+str(size)+str(yaw_rotation))
 var mm=prop_batches[key].multimesh
 var index=mm.visible_instance_count
 mm.set_instance_transform(index,Transform3D(Basis(Vector3.UP,yaw_rotation).scaled(size),pos))
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

func projectile_mesh(kind: String) -> Mesh:
 if projectile_meshes.has(kind): return projectile_meshes[kind]
 if kind in ["bullet","scatter","bounce","return","lob","dice","wave"]:
  projectile_meshes[kind]=WeaponArt.mesh(kind);return projectile_meshes[kind]
 var parts: Array=[]
 match kind:
  "xp":return XPGems.mesh()
  "arrow","pierce":
   parts=[ModelBuilder.part(ModelBuilder.cube(Vector3(0.07,0.07,0.85)),Vector3.ZERO,"e8c990"),ModelBuilder.part(ModelBuilder.cone(0.17,0.35),Vector3(0,0,-0.5),"d9f2ee",Vector3(-PI/2,0,0))]
  "rocket":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.2,0.85,0.12),Vector3.ZERO,"f5cf99",Vector3(PI/2,0,0)),ModelBuilder.part(ModelBuilder.cube(Vector3(0.65,0.07,0.3)),Vector3(0,0,0.3),"f49a5e")]
  "spore","poison":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.3,0.48,0.15),Vector3.ZERO,"b5ed74"),ModelBuilder.part(ModelBuilder.cone(0.42,0.25,0.2),Vector3(0,0.2,0),"d6ffae")]
  "fireball","thorn":
   parts=[ModelBuilder.part(ModelBuilder.cone(0.28,0.8),Vector3.ZERO,"ffe2a0",Vector3(PI/2,0,0)),ModelBuilder.part(ModelBuilder.cone(0.2,0.65),Vector3(0,0,0.35),"ff9b55",Vector3(-PI/2,0,0))]
  _:
   parts=[ModelBuilder.part(ModelBuilder.cube(Vector3(0.14,0.14,0.55)),Vector3.ZERO,"e4f6ff"),ModelBuilder.part(ModelBuilder.cone(0.18,0.3),Vector3(0,0,-0.3),"c8efff",Vector3(-PI/2,0,0))]
 projectile_meshes[kind]=ModelBuilder.bake(parts)
 return projectile_meshes[kind]
func trail(pos: Vector3, color: Color) -> void:
 var node=pool.acquire("trail"+color.to_html(),effect_mesh("trail"),color,pos)
 effects.append({"node":node,"life":0.12})
func impact(pos: Vector3, color: Color, count: int) -> void:
 if settings.reduced: count=mini(count,2)
 for i in mini(count,maxi(0,80-effects.size())):
  var node=pool.acquire("spark"+color.to_html(),effect_mesh("spark"),color,pos+Vector3(rng.randf_range(-0.4,0.4),rng.randf_range(0,0.5),rng.randf_range(-0.4,0.4)))
  node.rotation=Vector3(rng.randf()*PI,0,rng.randf()*TAU)
  effects.append({"node":node,"life":0.22,"velocity":Vector3(rng.randf_range(-3,3),rng.randf_range(1,4),rng.randf_range(-3,3))})
func telegraph(pos: Vector3,radius: float,duration: float,color: Color) -> void:
 var node=pool.acquire("warning"+color.to_html(),effect_mesh("warning"),color,Vector3(pos.x,terrain_height(pos.x,pos.z)+0.1,pos.z))
 node.basis=Basis(Quaternion(Vector3.UP,ForestMap.normal(stage_map_seed(),pos.x,pos.z))).scaled(Vector3(radius,1,radius))
 effects.append({"node":node,"life":duration,"telegraph":true})
func save_run(path: String = "user://active-run.json") -> bool:
 var saved_weapons={}
 for id in weapons: saved_weapons[str(id)]={"level":weapons[id].level,"clock":weapons[id].clock,"rarity":weapons[id].get("rarity",RewardCatalog.entry("weapons",id).rarity),"upgrades":weapons[id].get("upgrades",{}),"legacy_damage":weapons[id].get("legacy_damage",1.0),"sockets":WeaponSockets.serialize(weapons[id])}
 var saved_enemies=[]
 for e in enemies:
  var record=e.duplicate(true)
  record.erase("variant");record.erase("move_direction");record.erase("crowd_start");record.erase("crowd_was_traversing");record.erase("crowd_last_solved");record.erase("crowd_body_height");record.erase("crowd_slot")
  for key in ["pos","knock","target","charge_direction"]:
   if record.has(key): record[key]=[record[key].x,record[key].y,record[key].z]
  saved_enemies.append(record)
 var saved_pickups=[]
 for pickup in pickups: saved_pickups.append({"position":[pickup.node.position.x,pickup.node.position.y,pickup.node.position.z],"value":pickup.value,"age":pickup.age,"red":pickup.get("red",false),"attracted":pickup.get("attracted",false),"attraction_reason":pickup.get("attraction_reason","")})
 var used=[]
 for object in interactables: used.append({"kind":object.kind,"used":object.used,"charge":object.charge,"tier":object.get("tier","Common"),"offers":object.get("offers",null),"gem_offers":object.get("gem_offers",[]),"gem_sold":object.get("gem_sold",[]),"sold":object.get("sold",[]),"shrine_reward":object.get("shrine_reward",{}),"golden":object.get("golden",false),"shrine_choices":object.get("shrine_choices",[])})
 var data={"version":2,"next_enemy_id":crowd.next_id,"drop_chests":RewardDrops.serialize(self),"vases_broken":Vases.serialize(self),"world_pickups":WorldPickups.serialize(self),"stopwatch":world_time.serialize(),"reward_queue":reward_queue,"active_reward":active_reward,"shrine_reward_queue":shrine_reward_queue,"active_shrine_reward":active_shrine_reward,"announced_stages":announced_stages,"gem_rng_state":str(gem_rng.state),"pending_upgrades":pending_upgrades+(1 if mode=="upgrade" else 0),"terrain_version":terrain_version,"world_content_version":world_content_version,"additional_boss_count":additional_boss_count,"boss_encounters":boss_encounters,"map_seed_override":map_seed_override,"stage_clock":stage_clock.serialize(),"boss_variant":boss_variant,"ghost_budget":ghost_budget,"portal_state":portal_state,"loadout":loadout_runtime.serialize(),"selected_weapon":selected_weapon,"run_metrics":run_metrics,"chests_opened":chests_opened,"legacy_weapon_slots":legacy_weapon_slots,"legacy_tome_slots":legacy_tome_slots,"minimap":serialize_minimap(),"variants":variants.serialize(),"spawn_rng_state":str(spawn_rng.state),"elite_active":elite_active,"elite_rewarded":elite_rewarded,"rng_state":str(rng.state),"character":character,"biome":biome,"selected_biome":selected_biome,"tier":tier,"stage":stage,"elapsed":elapsed,"stage_time":stage_time,"stats":stats,"health":health,"xp":xp,"level":level,"kills":kills,"gold":gold,"weapons":saved_weapons,"gems":gems.serialize(),"tomes":tomes,"tome_rarities":tome_rarities,"items":items,"sandbox":sandbox,"position":[player.position.x,player.position.y,player.position.z],"enemies":saved_enemies,"boss_spawned":boss_spawned,"boss_dead":boss_dead,"interactables":used,"damage_total":damage_total,"rerolls":rerolls,"banished":banished,"pickups":saved_pickups,"damage_by_weapon":damage_by_weapon,"gold_fraction":gold_fraction,"camera":[player.yaw,player.pitch,player.zoom]}
 var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if not file: return false
 file.store_string(JSON.stringify(data)); file.close()
 return DirAccess.rename_absolute(path+".tmp",path)==OK
func load_run(path: String = "user://active-run.json") -> bool:
 if not FileAccess.file_exists(path): return false
 var data=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not data is Dictionary or not int(data.get("version",0)) in [1,2]: return false
 if int(data.get("terrain_version",1))>4 or int(data.get("world_content_version",0))>WORLD_CONTENT_VERSION:return false
 var restored=RunEnemyVariants.new()
 if not restored.restore(data.get("variants",{})): return false
 for key in ["character","biome","tier","stage","stats","position","weapons","enemies"]:
  if not data.has(key): return false
 if data.position.size()!=3 or not data.stats is Dictionary: return false
 frontend.clear()
 if is_instance_valid(frontend.stage_banner):frontend.stage_banner.queue_free()
 frontend.stage_banner=null
 variants=restored
 announced_stages.clear()
 for value in data.get("announced_stages",[int(data.stage)]):announced_stages.append(int(value))
 pending_upgrades=int(data.get("pending_upgrades",0));gem_rng.seed=int(data.get("variants",{}).get("seed",0))+719477;gem_rng.state=int(data.get("gem_rng_state",gem_rng.state))
 additional_boss_count=maxi(0,int(data.get("additional_boss_count",0)))
 world_content_version=int(data.get("world_content_version",0))
 terrain_version=3 if int(data.get("terrain_version",1))==3 else 4
 weapon_damage_windows.clear()
 run_seed=variants.seed_value
 character=-1;biome=0;tier=int(data.tier);stage=maxi(1,int(data.stage));map_seed_override=int(data.get("map_seed_override",-1))
 loadout_runtime.restore(data.get("loadout",{}));selected_trait=loadout_runtime.trait_id;selected_ultimate=loadout_runtime.ultimate_id
 selected_weapon=int(data.get("selected_weapon",1));run_metrics=data.get("run_metrics",{});chests_opened=int(data.get("chests_opened",0))
 selected_character=character; selected_biome=int(data.get("selected_biome",biome)); selected_tier=tier
 stats=Catalog.base_stats(); stats.merge(data.stats,true)
 sandbox=bool(data.sandbox)
 legacy_weapon_slots=clampi(data.weapons.size(),2,4) if int(data.version)==1 else int(data.get("legacy_weapon_slots",0))
 legacy_tome_slots=clampi(data.tomes.size(),2,4) if int(data.version)==1 else int(data.get("legacy_tome_slots",0))
 weapons.clear()
 for id in data.weapons:
  equip(int(id)); weapons[int(id)]["rarity"]=data.weapons[id].get("rarity",RewardCatalog.entry("weapons",int(id)).rarity);weapons[int(id)].level=int(data.weapons[id].level); weapons[int(id)].clock=float(data.weapons[id].clock);weapons[int(id)].upgrades=data.weapons[id].get("upgrades",{});weapons[int(id)].legacy_damage=float(data.weapons[id].get("legacy_damage",1+(int(data.weapons[id].level)-1)*0.23))
  WeaponSockets.restore(weapons[int(id)],data.weapons[id].get("sockets"))
 gems.restore(data.get("gems"))
 tomes=data.tomes;tome_rarities=data.get("tome_rarities",{}); items=data.items; banished=data.banished; rerolls=int(data.rerolls)
 build_stage()
 elapsed=float(data.elapsed); stage_time=float(data.stage_time)
 boss_variant=str(data.get("boss_variant",boss_variant))
 if boss_variant not in ["chunkus","rock_golem"]:boss_variant="chunkus" if boss_variant=="sovereign" else "rock_golem"
 ghost_budget=float(data.get("ghost_budget",0))
 stage_clock.restore(data.get("stage_clock",{}),stage_time)
 stage_time=stage_clock.elapsed
 health=float(data.health); xp=float(data.xp); level=int(data.level); kills=int(data.kills); gold=int(data.gold)
 damage_total=float(data.damage_total)
 damage_by_weapon.clear()
 for id in data.get("damage_by_weapon",{}): damage_by_weapon[int(id)]=float(data.damage_by_weapon[id])
 gold_fraction=float(data.get("gold_fraction",0))
 if data.has("camera"):
  player.yaw=float(data.camera[0]); player.pitch=float(data.camera[1]); player.zoom=float(data.camera[2])
 invulnerability=0.5
 for record in data.get("pickups",[]):
  var pos=Vector3(record.position[0],record.position[1],record.position[2])
  var model=XPGems.acquire(self,pos,bool(record.get("red",false)))
  pickups.append({"node":model,"value":record.value,"age":record.age,"red":bool(record.get("red",false)),"attracted":bool(record.get("attracted",false)),"attraction_reason":str(record.get("attraction_reason","saved_attraction"))})
 player.position=Vector3(data.position[0],data.position[1],data.position[2])
 if int(data.get("terrain_version",1))<3:player.position=map_layout.spawn+Vector3.UP
 for record in data.enemies:
  if int(data.get("terrain_version",1))<3 and int(record.kind)<8:continue
  var e=spawn_enemy(int(record.kind),Vector3(record.pos[0],record.pos[1],record.pos[2]))
  if e.is_empty(): continue
  if record.has("encounter") and (int(data.get("terrain_version",1))>=3 or int(record.kind)!=8):Encounters.initialize(self,e,str(record.encounter))
  if record.has("roster_choice") and int(record.kind)<3:
   var choice=1 if record.roster_choice in ["skeleton","speedy_monster"] else 0
   e.variant=OrdinaryRoster.variant(int(record.kind),choice)
  for key in record:
   if key=="encounter" and int(data.get("terrain_version",1))<3 and int(record.kind)==8:continue
   if key in ["pos","knock","target","charge_direction"]: e[key]=Vector3(record[key][0],record[key][1],record[key][2])
   elif key in ["kind","phase","crowd_id"]: e[key]=int(record[key])
   else: e[key]=record[key]
 if int(data.get("terrain_version",1))<3:
  for enemy in enemies:enemy.pos.y=terrain_height(enemy.pos.x,enemy.pos.z)+0.65
 BossEncounters.restore(self,data.get("boss_encounters",{}))
 boss_spawned=bool(data.boss_spawned); boss_dead=bool(data.boss_dead)
 for i in interactables.size():
  var saved_index=i-1 if int(data.get("terrain_version",1))<3 else i
  if saved_index<0 or saved_index>=data.interactables.size():continue
  interactables[i].used=data.interactables[saved_index].used
  interactables[i].charge=data.interactables[saved_index].charge
  if world_content_version==0 and interactables[i].kind=="Charge Shrine":interactables[i].charge=minf(8,interactables[i].charge*8.0/12)
  if data.interactables[saved_index].get("offers") is Array:interactables[i]["offers"]=data.interactables[saved_index].offers
  interactables[i]["sold"]=data.interactables[saved_index].get("sold",[])
  interactables[i]["gem_offers"]=data.interactables[saved_index].get("gem_offers",[])
  interactables[i]["gem_sold"]=data.interactables[saved_index].get("gem_sold",[])
  interactables[i]["shrine_reward"]=data.interactables[saved_index].get("shrine_reward",{})
  interactables[i]["golden"]=data.interactables[saved_index].get("golden",interactables[i].get("golden",false))
  interactables[i]["shrine_choices"]=data.interactables[saved_index].get("shrine_choices",[])
  if ShrineCharging.is_shrine(interactables[i]):ShrineCharging.visual(self,interactables[i],false)
  if interactables[i].used:
   if interactables[i].kind=="Shop":interactables[i].node.hide()
   else:interactables[i].node.scale=Vector3.ONE*0.5
 portal_state=str(data.get("portal_state","exit" if boss_dead else ("summoned" if boss_spawned else "dormant")))
 refresh_portal()
 spawn_rng.state=int(data.get("spawn_rng_state",spawn_rng.state));elite_active=bool(data.get("elite_active",false));elite_rewarded=bool(data.get("elite_rewarded",false))
 rng.seed=run_seed; rng.state=int(data.rng_state)
 restore_minimap(data.get("minimap",{}))
 RewardDrops.restore(self,data.get("drop_chests",[]))
 Vases.restore(self,data.get("vases_broken",[]))
 WorldPickups.restore(self,data.get("world_pickups",[]))
 world_time.restore(data.get("stopwatch",{}))
 reward_queue=[]
 for id in data.get("reward_queue",[]):
  if int(id)>=0 and int(id)<Catalog.ITEMS.size():reward_queue.append(int(id))
 active_reward=int(data.get("active_reward",-1))
 if active_reward>=Catalog.ITEMS.size():active_reward=-1
 crowd.next_id=maxi(crowd.next_id,int(data.get("next_enemy_id",1)))
 rebuild_grid();crowd.rebuild(enemies)
 shrine_reward_queue=data.get("shrine_reward_queue",[]);active_shrine_reward=data.get("active_shrine_reward",{});mode="loading"
 if active_reward>=0:frontend.reward(Catalog.ITEMS[active_reward])
 else:resume()
 return true

func prop_collider(pos: Vector3, radius: float, height: float) -> void:
 var body=StaticBody3D.new();body.set_meta("forest_decoration",true)
 var shape=CollisionShape3D.new()
 var cylinder_shape=CylinderShape3D.new()
 cylinder_shape.radius=radius
 cylinder_shape.height=height
 shape.shape=cylinder_shape
 shape.position.y=height/2
 body.add_child(shape)
 world.add_child(body)
 body.position=pos
 var key=Vector2i(floori(pos.x/8),floori(pos.z/8))
 if not obstacles.has(key): obstacles[key]=[]
 obstacles[key].append({"pos":pos,"radius":radius})
func avoid_props(pos: Vector3,agent_radius: float=0.4) -> Vector3:
 var cell=Vector2i(floori(pos.x/8),floori(pos.z/8))
 for x in range(cell.x-1,cell.x+2):
  for z in range(cell.y-1,cell.y+2):
   for obstacle in obstacles.get(Vector2i(x,z),[]):
    var offset=Vector2(pos.x-obstacle.pos.x,pos.z-obstacle.pos.z)
    var safe=obstacle.radius+agent_radius
    var squared=offset.length_squared()
    if squared<safe*safe:
     if squared<0.0001:offset=Vector2.RIGHT;squared=1.0
     offset*=safe/sqrt(squared)
     pos.x=obstacle.pos.x+offset.x
     pos.z=obstacle.pos.z+offset.y
 return pos
func rock_mesh() -> Mesh:
 if not projectile_meshes.has("rock"):
  projectile_meshes["rock"]=ModelBuilder.bake([ModelBuilder.part(ModelBuilder.cone(1.1,1.4,0.6),Vector3.ZERO,"ffffff"),ModelBuilder.part(ModelBuilder.cone(0.65,0.8,0.15),Vector3(0.1,0.8,0),"ebefdf")])
 return projectile_meshes["rock"]
func grass_mesh() -> Mesh:
 if not projectile_meshes.has("grass"):
  projectile_meshes["grass"]=ModelBuilder.bake([ModelBuilder.part(ModelBuilder.cone(0.1,0.65),Vector3(0,0.28,0),"ffffff"),ModelBuilder.part(ModelBuilder.cone(0.08,0.4),Vector3(0.2,0.2,0),"dce8a8",Vector3(0,0,-0.3))])
 return projectile_meshes["grass"]

func effect_budget() -> int:
 return 28 if settings.reduced else 30+int(settings.visual_intensity*65)
func slash_arc(origin: Vector3,direction: Vector3,radius: float,color: Color) -> void:
 if effects.size()>=effect_budget():return
 var node=pool.acquire("slash"+color.to_html(),effect_mesh("slash"),color,origin)
 node.rotation.y=atan2(direction.x,direction.z);node.scale=Vector3.ONE*radius
 node.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
 effects.append({"node":node,"life":0.18})
func lightning_arc(a: Vector3, b: Vector3, color: Color) -> void:
 if is_instance_valid(combat_fx):combat_fx.burst("sparks_shower",b,0.4,0.16)
 var previous=a
 for i in range(1,6):
  var point=a.lerp(b,float(i)/5)
  if i<5: point+=Vector3(rng.randf_range(-0.3,0.3),rng.randf_range(-0.2,0.2),rng.randf_range(-0.3,0.3))
  if effects.size()<effect_budget(): beam(previous,point,color)
  previous=point

func schedule_blast(pos: Vector3, radius: float, damage: float, delay: float) -> void:
 telegraph(pos,radius,delay,Color("ff986b"))
 pending_blasts.append({"pos":pos,"radius":radius,"damage":damage,"delay":delay})
func update_blasts(delta: float) -> void:
 for i in range(pending_blasts.size()-1,-1,-1):
  var blast=pending_blasts[i]
  blast.delay-=world_time.hostile(delta)
  if blast.delay>0: continue
  combat_fx.burst("explosion_small",blast.pos,clampf(blast.radius/2,1,4))
  flash(blast.pos,Color("ffaf67"),blast.radius)
  impact(blast.pos,Color("ffd49b"),8)
  apply_player_blast(blast.pos,blast.radius,blast.damage)
  area(blast.pos,blast.radius,blast.damage*0.6,-1)
  pending_blasts.remove_at(i)

func weapon_limit() -> int:
 return 4 if sandbox else maxi(legacy_weapon_slots,int(progress.data.get("weapon_slots",2)))
func tome_limit() -> int:
 return 4 if sandbox else maxi(legacy_tome_slots,int(progress.data.get("tome_slots",2)))
func chest_cost() -> int:return 15+chests_opened*5
func available_items() -> Array:
 var result=[]
 for i in Catalog.ITEMS.size():
  if sandbox or MetaProgress.enabled(progress.data,"items",str(i)):result.append(i)
 return result
func apply_item(id: int) -> void:
 var item=Catalog.ITEMS[id];items.append(item[0]);stats[item[2]]=float(stats.get(item[2],0))+item[3]
 if item[2]=="max_health":health+=item[3]
 toast("%s • +%s %s"%[item[0],item[3],item[2]])
 tone(720,0.15)
func buy_shop(object: Dictionary, id: int, price: int) -> bool:
 if mode!="shop" or object.get("used",false) or not id in object.get("offers",[]) or id in object.get("sold",[]) or gold<price or not id in available_items():return false
 if price!=ShopSystem.price(id):return false
 gold-=price;apply_item(id);object.used=true
 if not object.has("sold"):object.sold=[]
 object.sold.append(id)
 if object.get("tier","")=="Legendary":run_metrics["legendary_shop"]=int(run_metrics.get("legendary_shop",0))+1
 if object.has("node") and is_instance_valid(object.node):
  combat_fx.burst("smoke_puff",object.node.position+Vector3.UP,2);object.node.hide()
 play_sound("purchase");resume();return true
func serialize_minimap() -> Dictionary:
 var cells=[]
 for cell in frontend.minimap.explored:cells.append([cell.x,cell.y])
 return {"all":frontend.minimap.reveal_all,"cells":cells}
func restore_minimap(data: Dictionary) -> void:
 frontend.minimap.reset(bool(data.get("all",loadout_runtime.trait_id=="seer")))
 for cell in data.get("cells",[]):
  if cell is Array and cell.size()==2:frontend.minimap.explored[Vector2i(int(cell[0]),int(cell[1]))]=true

func ability_visual(state: String) -> void:
 if not is_instance_valid(player) or not is_instance_valid(player.avatar):return
 if str(player.avatar.get_meta("ability_visual","base"))==state:return
 player.avatar.set_meta("ability_visual",state)
 for node in player.avatar.find_children("*","MeshInstance3D",true,false):
  if not node.has_meta("base_material"):node.set_meta("base_material",node.material_override)
  if state=="base":node.material_override=node.get_meta("base_material")
  else:
   var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=state!="ghost"
   material.albedo_color=Color(0.45,0.85,1.0,0.45) if state=="ghost" else Color(1.0,0.55,0.45,1)
   if state=="ghost":material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
   material.emission_enabled=true;material.emission=Color("88dcff") if state=="ghost" else Color("b84d36");material.emission_energy_multiplier=0.4
   node.material_override=material

func measured_dps(id: int, window: float=10) -> float:
 var total=0.0
 for sample in weapon_damage_windows.get(id,[]):
  if sample.time>=elapsed-window:total+=sample.damage
 return total/window
func weapon_tooltip(id: int) -> String:
 var state=weapons[id];var definition=Catalog.WEAPONS[id]
 var damage=WeaponUpgrades.damage(id,state)*stats.damage*loadout_runtime.damage_multiplier()
 var cooldown=float(definition[3])/stats.haste/(1+WeaponUpgrades.value(state,"haste"))
 var result="%s • Level %d\nDamage %.1f • Cooldown %.2fs"%[definition[0],state.level,damage,cooldown]
 if definition[1] in WeaponUpgrades.PROJECTILES:
  result+="\nProjectiles %d • Projectile velocity ×%.2f"%[mini(16,int(stats.count)+int(WeaponUpgrades.value(state,"count")))+(4 if definition[1]=="scatter" else 0),stats.projectile_speed*(1+WeaponUpgrades.value(state,"velocity"))]
 if definition[1] in ["bullet","bounce"]:result+="\nRicochets %d"%(WeaponUpgrades.value(state,"ricochet")+(2 if definition[1]=="bounce" else 0))
 result+="\nCritical chance %.0f%%"%(minf(1,stats.crit+WeaponUpgrades.value(state,"crit"))*100)
 for attribute in state.get("upgrades",{}):
  if attribute in ["range","radius","duration"]:result+="\n%s bonus +%.0f%%"%[attribute.capitalize(),WeaponUpgrades.value(state,attribute)*100]
 result+="\n"+SocketScreens.tooltip(state)
 return result+"\nMeasured DPS (last 10s): %.1f\nEstimated base single-target DPS: %.1f"%[measured_dps(id),damage/cooldown]

func navigation_direction(pos: Vector3,target: Vector3) -> Vector3:
 return forest_navigation.direction(pos,target) if is_instance_valid(forest_navigation) else Vector3(target.x-pos.x,0,target.z-pos.z).normalized()
func constrain_enemy_motion(previous: Vector3,next: Vector3) -> Vector3:
 return forest_navigation.constrain(previous,next) if is_instance_valid(forest_navigation) else next

func stage_map_seed() -> int:return map_seed_override if map_seed_override>=0 else run_seed+stage*73
func toggle_map_debug() -> void:
 if not sandbox:return
 map_debug=not map_debug
 if is_instance_valid(map_debug_node):map_debug_node.queue_free()
 if not map_debug:return
 var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
 for region in map_layout.regions:
  var r: Rect2=region.rect;var corners=[r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)]
  for i in 4:
   for p in [corners[i],corners[(i+1)%4]]:mesh.surface_set_color(Color.CYAN);mesh.surface_add_vertex(Vector3(p.x,region.height+0.2,p.y))
 for i in range(0,forest_navigation.edges.size(),2):
  for n in forest_navigation.edges[i]:
   if n<i:continue
   for cell in [i,n]:
    var p=Vector3(-95+(cell%ForestMap.SIDE)*2,0,-95+int(cell/ForestMap.SIDE)*2);p.y=terrain_height(p.x,p.z)+0.12
    mesh.surface_set_color(Color(0.8,0.9,0.1));mesh.surface_add_vertex(p)
 mesh.surface_end();map_debug_node=MeshInstance3D.new();map_debug_node.mesh=mesh
 var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;map_debug_node.material_override=mat;world.add_child(map_debug_node)
 for i in map_layout.regions.size():
  var region=map_layout.regions[i];var p=region.rect.get_center();var label=Label3D.new();label.text="Region %d • %.0fm"%[i,region.height];label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.pixel_size=0.03;map_debug_node.add_child(label);label.position=Vector3(p.x,region.height+3,p.y)
 var points=map_layout.pois.duplicate();points.append(map_layout.portal);points.append(map_layout.spawn);points.append(map_layout.elite)
 for i in points.size():
  var label=Label3D.new();label.text="POI %d"%i if i<12 else ("BOSS PORTAL" if i==12 else ("PLAYER SPAWN" if i==13 else "ELITE STATUE"));label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.pixel_size=0.02;label.no_depth_test=true;map_debug_node.add_child(label);label.position=points[i]+Vector3.UP*2
 toast("DEBUG MAP SEED %s"%stage_map_seed())

func enemy_line_clear(pos: Vector3,target: Vector3) -> bool:
 return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pos+Vector3.UP,target+Vector3.UP,1)).is_empty()

func create_elite_statue(position: Vector3=Vector3.INF) -> void:
 var statue=Node3D.new();statue.name="EliteStatue";world.add_child(statue);statue.position=map_layout.elite if position==Vector3.INF else position
 GrimdarkObjects.populate(statue,"Elite Statue",stage)
 interactables.append({"node":statue,"kind":"Elite Statue","used":false,"charge":0.0})
func activate_elite_statue(statue: Dictionary) -> bool:
 if statue.used or elite_active:return false
 statue.used=true;elite_active=true;elite_rewarded=false
 for i in OrdinaryRoster.SETTINGS.elite_count:
  var angle=i*TAU/OrdinaryRoster.SETTINGS.elite_count
  var point=statue.node.position+Vector3(cos(angle),0,sin(angle))*6
  spawn_enemy(13,point)
 combat_fx.burst("sparks_shower",statue.node.position,2);announce("ELITE ENCOUNTER • Obsidian Sentinels");return true

func effect_mesh(kind: String) -> Mesh:
 if effect_meshes.has(kind):return effect_meshes[kind]
 var mesh: Mesh
 match kind:
  "ring":
   var ring=TorusMesh.new();ring.inner_radius=0.85;ring.outer_radius=1;ring.rings=12;ring.ring_segments=8;mesh=ring
  "warning":
   var ring=TorusMesh.new();ring.inner_radius=0.97;ring.outer_radius=1;ring.rings=16;ring.ring_segments=8;mesh=ring
  "beam":mesh=box(Vector3(0.055,0.055,1))
  "trail":mesh=box(Vector3(0.06,0.06,0.18))
  "spark":mesh=ModelBuilder.cone(0.06,0.28)
  "slash":
   var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
   for i in 12:
    var a=-1.1+i*2.2/12;var b=a+2.2/12
    var outer_a=Vector3(sin(a),0,cos(a));var outer_b=Vector3(sin(b),0,cos(b))
    for point in [outer_a*0.8,outer_a,outer_b*0.8,outer_b*0.8,outer_a,outer_b]:tool.set_normal(Vector3.UP);tool.add_vertex(point)
   mesh=tool.commit()
 effect_meshes[kind]=mesh;return mesh
func prewarm_combat() -> void:
 var chests=[]
 for i in 8:chests.append(pool.acquire("reward_chest",RewardDrops.mesh(),Color.WHITE,Vector3.ZERO))
 for chest in chests:pool.release(chest)
 for body in ["stone","shield","blade"]:WeaponArt.mesh(body)
 for kind in ["ring","beam","trail","spark","slash","warning"]:effect_mesh(kind)
 for weapon in Catalog.WEAPONS:
  var color=Color(weapon[5])
  for pair in [["flash","ring"],["beam","beam"],["trail","trail"],["spark","spark"],["slash","slash"]]:
   var node=pool.acquire(pair[0]+color.to_html(),effect_mesh(pair[1]),color,Vector3.ZERO);pool.release(node)
 for w in Catalog.WEAPONS:projectile_mesh(w[1])
 projectile_mesh("xp")
 for id in ["impact_concrete","smoke_puff","blood_burst","explosion_small","muzzle_front","fire_torch","sparks_shower"]:CombatFX.sprite_frames(id)
 for model in ["Goblin","Skeleton","Imp","Puglin","Knight","Golem"]:
  for i in 4:
   var node=pool.acquire("corpse_"+model,BestiaryFrames.mesh(model,"enemy_idle",0),Color.WHITE,Vector3.ZERO,true);pool.release(node)
 var waiting=[]
 for i in 128:waiting.append(XPGems.acquire(self,Vector3.ZERO))
 for i in 8:waiting.append(XPGems.acquire(self,Vector3.ZERO,true))
 for node in waiting:pool.release(node)
func add_xp_drop(pos: Vector3,value: float) -> void:
 if debug_combat:combat_counters.xp_drops+=1
 # Merge spatially close rewards. All XP is retained, including boss multi-drops.
 for pickup in pickups:
  if not pickup.get("red",false) and not pickup.get("attracted",false) and pickup.node.position.distance_squared_to(pos)<9:
   pickup.value+=value
   pickup.node.scale=Vector3.ONE*clampf(1+sqrt(pickup.value)*0.04,1,2)
   if debug_combat:combat_counters.xp_merged+=1
   return
 var node=XPGems.acquire(self,pos)
 pickups.append({"node":node,"value":value,"age":0.0})

func orbit_count(id: int) -> int:
 return 2+mini(16,int(stats.count)+int(WeaponUpgrades.value(weapons[id],"count")))
func orbit_position(id: int,index: int) -> Vector3:
 var angle=elapsed*3+index*TAU/orbit_count(id)
 var radius=Catalog.WEAPONS[id][4]*stats.size*(1+WeaponUpgrades.value(weapons[id],"radius"))
 return player.position+Vector3(cos(angle)*radius,1.0,sin(angle)*radius)

func create_boss_statue(position: Vector3) -> void:
 var statue=Node3D.new();statue.name="BossMultiplierStatue";world.add_child(statue);statue.position=position
 GrimdarkObjects.populate(statue,"Boss Statue",stage)
 interactables.append({"node":statue,"kind":"Boss Statue","used":false,"charge":0.0})

func activate_boss_statue(statue: Dictionary) -> bool:
 if statue.used or statue.kind!="Boss Statue":return false
 statue.used=true;additional_boss_count+=1;statue.node.scale=Vector3.ONE*0.75
 combat_fx.burst("sparks_shower",statue.node.position,2);play_sound("ready")
 toast("ADDITIONAL BOSSES +%d · future encounters spawn %d bosses"%[additional_boss_count,1+additional_boss_count]);return true

func equipment_meta(category: String,id: Variant,rank: int=0) -> Dictionary:
 var meta=RewardCatalog.entry(category,id,rank)
 if category=="weapons" and weapons.has(int(id)):meta.rarity=weapons[int(id)].get("rarity",meta.rarity)
 if category=="tomes":meta.rarity=tome_rarities.get(str(id),meta.rarity)
 return meta
func apply_player_blast(center: Vector3,radius: float,damage: float) -> bool:
 if loadout_runtime.immune() or (player.position+Vector3.UP*0.65).distance_to(center)>=radius:return false
 hurt(damage)
 var direction=player.position-center;direction.y=0
 if direction.length_squared()<0.001:direction=Vector3.FORWARD
 player.launch(direction.normalized(),EnemyContact.SETTINGS.explosion_horizontal,EnemyContact.SETTINGS.explosion_upward,EnemyContact.SETTINGS.explosion_speed_cap,EnemyContact.SETTINGS.explosion_vertical_cap)
 return true

func hurt_contact(amount: float,attacker: Vector3) -> bool:
 var before=health;hurt(amount)
 if health>=before:return false
 var direction=player.position-attacker;direction.y=0
 if direction.length_squared()<0.001:direction=Vector3.FORWARD
 var horizontal=Vector3(player.velocity.x,0,player.velocity.z)
 var cap=maxf(horizontal.length(),12.0)
 horizontal=(horizontal+direction.normalized()*3.2).limit_length(cap)
 player.velocity.x=horizontal.x;player.velocity.z=horizontal.z
 return true

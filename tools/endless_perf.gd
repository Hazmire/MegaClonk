extends SceneTree
# Frame cost and draw calls with the ghost cap (600) alive and drawn, vs. the same stage with 500 ordinary enemies (software GL: compare, not absolute).
# usage: xvfb-run -a -s "-screen 0 1280x720x24" stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1280x720 --script tools/endless_perf.gd
var game: Node3D
func _initialize() -> void:call_deferred("run")
func measure(label: String) -> void:
 for i in 20:await process_frame
 var total=0.0;var calls=0;var frames=90
 for i in frames:
  var t=Time.get_ticks_usec();await process_frame;total+=Time.get_ticks_usec()-t;calls+=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
 print("PERF %s enemies=%d ghosts=%d frame_ms=%.1f draw_calls=%d"%[label,game.enemies.size(),game.ghost_count,total/frames/1000.0,calls/frames])
func run() -> void:
 MenuScreen.set_instant(true)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.6).timeout
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://endless-perf.json"
 game.sandbox=true;game.map_seed_override=9;game.next_run_seed=923;game.begin_run();game.resume();game.settings.invincible=true;game.spawn_clock=999
 await measure("empty")
 for i in 500:game.spawn_enemy(i%3,game.player.position+Vector3(cos(float(i))*(8+i%40),0,sin(float(i))*(8+i%40)))
 await measure("500_normal")
 game.enemies.clear();game.stage_clock.elapsed=599.9;game.stage_event("endless");game.endless_time=1500.0
 var fwd=-game.player.camera.global_transform.basis.z;fwd.y=0;fwd=fwd.normalized()
 for i in 600:
  var e=Ghosts.spawn(game,Endless.choose_tier(25.0,game.ghost_rng),game.player.position+fwd*(10+i%35)+Vector3(randf_range(-20,20),randf_range(0,9),0))
  if not e.is_empty():e.frozen=999.0
 await measure("600_ghosts_held")
 for e in game.enemies:e.frozen=0.0
 # live: ghosts keep spawning and dissipating on contact at minute 25 (the real worst case for the simulation)
 game.player.active=true;game.mode="run"
 await measure("ghosts_live_min25")
 quit()

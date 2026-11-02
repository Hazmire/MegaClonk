extends SceneTree
# Frame cost and draw calls per stage with ~500 enemies on screen (software GL under xvfb: compare before/after, not absolute numbers).
# usage: xvfb-run -a -s "-screen 0 1280x720x24" stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1280x720 --script tools/stage_perf.gd
var game: Node3D
func _initialize() -> void:call_deferred("run")
func run() -> void:
 MenuScreen.set_instant(true)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.6).timeout
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://stage-perf.json"
 game.sandbox=true;game.map_seed_override=9;game.next_run_seed=923;game.begin_run();game.resume();game.settings.invincible=true
 for s in [1,2,3,4]:
  game.stage=s;game.build_stage();game.resume();game.spawn_clock=999;game.enemies.clear()
  for i in 500:game.spawn_enemy(i%3,game.player.position+Vector3(cos(float(i))*(8+i%40),0,sin(float(i))*(8+i%40)))
  for i in 20:await process_frame
  var total=0.0;var calls=0;var frames=90
  for i in frames:
   var t=Time.get_ticks_usec();await process_frame;total+=Time.get_ticks_usec()-t;calls+=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
  print("PERF stage=%d enemies=%d frame_ms=%.1f draw_calls=%d"%[s,game.enemies.size(),total/frames/1000.0,calls/frames])
 quit()

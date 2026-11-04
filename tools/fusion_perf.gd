extends SceneTree
# Frame cost and draw calls at the 500-enemy stress build: baseline, Stopwatch active, two Fusion weapons, both (software GL under xvfb: compare, don't trust absolutes).
# usage: xvfb-run -a -s "-screen 0 1280x720x24" stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1280x720 --script tools/fusion_perf.gd
var game: Node3D
func _initialize() -> void:call_deferred("run")
func configure(wids: Array,gems: Array) -> void:
 game.weapons.clear()
 for w in wids:
  game.equip(w);game.weapons[w]["sockets"]={"unlocked":maxi(1,gems.size()),"gems":gems}
func run() -> void:
 MenuScreen.set_instant(true)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.6).timeout
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://fusion-perf.json"
 game.sandbox=true;game.map_seed_override=9;game.next_run_seed=923;game.begin_run();game.resume();game.settings.invincible=true
 for cfg in [["baseline",false,[]],["stopwatch",true,[]],["two_fusions",false,["fire","ice"]],["two_fusions_stopwatch",true,["fire","ice"]]]:
  game.stage=1;game.build_stage();game.resume();game.spawn_clock=999;game.enemies.clear();game.world_time.reset()
  configure([10,1],cfg[2])
  for i in 500:
   var e=game.spawn_enemy(i%3,game.player.position+Vector3(cos(float(i))*(8+i%40),0,sin(float(i))*(8+i%40)))
   if not e.is_empty():e.hp=1.0e9;e.max_hp=1.0e9
  for i in 30:
   if cfg[1]:game.world_time.activate()
   await process_frame
  var total=0.0;var calls=0;var frames=90;var worst=0.0
  for i in frames:
   if cfg[1]:game.world_time.activate()
   game.spawn_clock=999
   var t=Time.get_ticks_usec();await process_frame;var d=Time.get_ticks_usec()-t;total+=d;worst=maxf(worst,d);calls+=RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
  print("PERF %s enemies=%d frame_ms=%.1f worst_ms=%.1f draw_calls=%d"%[cfg[0],game.enemies.size(),total/frames/1000.0,worst/1000.0,calls/frames])
 quit()

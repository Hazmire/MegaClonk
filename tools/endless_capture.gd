extends SceneTree
# Real-render captures of endless mode at 1920x1080 into docs/images/endless/ (Forward+ / llvmpipe under xvfb).
# usage: xvfb-run -a -s "-screen 0 1920x1080x24" stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1920x1080 --script tools/endless_capture.gd [-- shots=hud,swarm,pause,results]
var game: Node3D
var hud: RunHud
var out="res://docs/images/endless/"
func _initialize() -> void:call_deferred("run")
func snap(label: String,wait: float=0.4) -> void:
 await create_timer(wait).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+label+".png");print("SHOT "+label)
func set_endless_clock(seconds: float) -> void:
 game.endless_time=seconds;game.endless_whole=int(seconds);game.endless_second.emit(int(seconds))
func run() -> void:
 var shots=["hud","swarm","pause","results"]
 for a in OS.get_cmdline_user_args():
  if a.begins_with("shots="):shots=Array(a.substr(6).split(","))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 MenuScreen.set_instant(true)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.6).timeout
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://endless-capture.json"
 game.next_run_seed=77;game.map_seed_override=9;game.begin_run();game.resume();game.spawn_clock=999;game.enemies.clear()
 hud=game.frontend.run_hud
 game.set_physics_process(false) # the capture drives the clocks itself
 await create_timer(0.8).timeout
 if "hud" in shots:
  # Before: the stage countdown (09:58 after two seconds, and 00:02 just before the switch).
  game.stage_clock.elapsed=2.0;game.stage_time=2.0;await snap("01a_hud_before_0958")
  game.stage_clock.elapsed=598.0;game.stage_time=598.0;await snap("01b_hud_before_0002")
  # The switch: the glitch, frozen mid-way, then the red 00:00 settling.
  game.stage_clock.elapsed=600.0;game.stage_time=600.0
  game.stage_event("endless");set_endless_clock(0.0)
  game.mode="pause";hud.update(0.0)
  hud.timer_fx.tick(0.0,0.0,true) # first tick applies the tier look
  hud.timer_fx.glitch_t=0.0
  for i in 6:hud.timer_fx.tick(0.04,0.0,true)
  await snap("02_glitch_frame",0.2)
  hud.timer_fx.glitch_t=0.5+0.5*0.55;hud.timer_fx.tick(0.0,0.0,true)
  await snap("03_red_0000_settling",0.2)
  hud.timer_fx.glitch_t=-1.0;hud.timer_fx.timer.scale=Vector2.ONE;hud.timer_fx.timer.modulate=Color.WHITE
  game.mode="run"
  for sample in [["04_hud_endless_0100",60.0],["05_hud_endless_0400",240.0],["06_hud_endless_0700",420.0],["07_hud_endless_1200",720.0]]:
   set_endless_clock(float(sample[1])+1.0);game.mode="run"
   await create_timer(2.0).timeout # let the embers and smoke fill in at real speed
   game.mode="pause";await snap(str(sample[0]),0.05);game.mode="run"
 if "swarm" in shots:
  game.mode="run";game.settings.invincible=true;game.sandbox=true
  var yaw=game.player.yaw;var forward=-game.player.camera.global_transform.basis.z;forward.y=0;forward=forward.normalized()
  var side=forward.cross(Vector3.UP)
  for sample in [["08_swarm_0min",0.0,40],["09_swarm_10min",600.0,220],["10_swarm_20min",1200.0,600]]:
   game.enemies.clear();game.ghost_count=0;set_endless_clock(float(sample[1]))
   var m=float(sample[1])/60.0;var n=int(sample[2])
   for i in n:
    var depth=randf_range(8.0,48.0);var lateral=randf_range(-0.9,0.9)*depth*0.9
    var at=game.player.position+forward*depth+side*lateral+Vector3(0,randf_range(0.0,9.0),0)
    var e=Ghosts.spawn(game,Endless.choose_tier(m,game.ghost_rng),at)
    if not e.is_empty():e.frozen=999.0;e.age=5.0;e.vel=forward*-2.0
   game.mode="pause";game.ghost_view.begin_frame()
   for e in game.enemies:if e.has("ghost"):Ghosts.draw(game,e)
   game.ghost_view.end_frame(0.0)
   await snap(str(sample[0]),0.5);print("  ghosts alive ",game.ghost_count)
 if "pause" in shots:
  game.enemies.clear();game.ghost_count=0;game.mode="run";set_endless_clock(263.0);game.sandbox=false
  game.frontend.pause();await snap("11_pause_strip",0.6)
  game.resume()
 if "results" in shots:
  game.sandbox=false;game.progress.data.best_endless_time=0.0;set_endless_clock(263.0);game.health=0.0
  game.finish_run(false);await snap("12_results_new_record",0.8)
 print("capture done");quit()

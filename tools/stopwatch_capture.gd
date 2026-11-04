extends SceneTree
# Real-render captures of the Stopwatch at 1920x1080 into docs/images/stopwatch/, once per stage's dressing.
# usage: xvfb-run -a -s "-screen 0 1920x1080x24" stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1920x1080 --script tools/stopwatch_capture.gd [-- stages=1,2,3]
var game: Node3D
var out="res://docs/images/stopwatch/"
func _initialize() -> void:call_deferred("run")
func snap(label: String,wait: float=0.0) -> void:
 if wait>0.0:await create_timer(wait).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+label+".png");print("SHOT "+label)
func run() -> void:
 var stages=[1,2,3]
 for a in OS.get_cmdline_user_args():
  if a.begins_with("stages="):stages=Array(a.substr(7).split(",")).map(func(x):return int(x))
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 MenuScreen.set_instant(true)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.6).timeout
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://stopwatch-capture.json"
 game.next_run_seed=77;game.map_seed_override=9;game.begin_run();game.resume();game.spawn_clock=999;game.set_physics_process(false);game.sandbox=true;game.settings.invincible=true
 process_frame.connect(func():
  if game.mode=="run":game.spawn_clock=999.0;game._physics_process(0.05)) # the capture drives the game itself: one 50 ms tick per rendered frame
 var wt: WorldTime=game.world_time
 for stage in stages:
  game.stage=stage;game.build_stage();game.resume();game.set_physics_process(false);game.enemies.clear();wt.reset();game.mode="run"
  var fwd=-game.player.camera.global_transform.basis.z;fwd.y=0;fwd=fwd.normalized();var side=fwd.cross(Vector3.UP)
  for i in 24:
   var at=game.player.position+fwd*(7.0+float(i%6)*3.0)+side*(float(i/6)-1.5)*3.5
   game.spawn_enemy(0,at)
  game.mode="run";await create_timer(0.8).timeout
  var tag="stage%d_"%stage
  await snap(tag+"0_before",0.1)
  wt.activate();await snap(tag+"1_pickup_wave",0.12)
  wt.remaining=7.0;await snap(tag+"2_frozen",0.9)
  wt.remaining=3.0;await create_timer(0.2).timeout
  wt.activate(4.0);await snap(tag+"3_extension_tag",0.25)
  wt.remaining=0.8;await snap(tag+"4_last_second",0.4)
  wt.remaining=0.04;await snap(tag+"5_release",0.25)
  wt.just_released=false;await create_timer(1.0).timeout
 print("capture done");quit()

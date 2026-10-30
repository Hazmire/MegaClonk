extends SceneTree
# Real-render capture of in-run UI states at 1920x1080 into docs/images/ingame/ (Forward+ / llvmpipe under xvfb).
# usage: xvfb-run -a -s "-screen 0 1920x1080x24" stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1920x1080 --script tools/ingame_capture.gd [-- only=hud,...]
var game: Node3D
var only: Array=[]
var out="res://docs/images/ingame/"
func _initialize() -> void:call_deferred("run")
func want(name: String) -> bool:return only.is_empty() or name in only
func snap(label: String,wait: float=0.4) -> void:
 await create_timer(wait).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+label+".png");print("SHOT "+label)
func start_run() -> void:
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://ingame-capture.json"
 game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999
func late_build() -> void:
 for id in Catalog.ACTIVE_WEAPONS.slice(0,4):game.equip(id)
 for t in Catalog.ACTIVE_TOMES.slice(0,4):game.apply_upgrade({"type":"tome","id":t})
 var n=0
 for id in Catalog.ITEM_IDS:
  if n>=26:break
  game.grant_item(id,true);n+=1
  if n%3==0:game.grant_item(id,true)
 for element in Elements.IDS:game.gems.add(element,2)
 game.amulets=2
func run() -> void:
 for a in OS.get_cmdline_user_args():
  if a.begins_with("only="):only=a.substr(5).split(",")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 MenuScreen.set_instant(true)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.6).timeout
 start_run()
 await create_timer(1.0).timeout
 if want("hud"):
  game.gold=22;game.kills=22;game.frontend.update_hud();await snap("hud-early",0.6)
  late_build();game.gold=1840;game.kills=412;game.frontend.update_hud();await snap("hud-late",0.6)
  game.health=20.0;game.frontend.update_hud();await snap("hud-low-hp",1.0)
  game.health=game.stats.max_health;game.world_time.freeze(3.0);game.frontend.update_hud();await snap("hud-stopwatch",1.0)
 quit(0)

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

 if want("toast"):
  var tq=game.frontend.run_hud.toasts
  game.gems.reset();game.gems.add("corrosive");game.gem_discovered("corrosive");await wait_phase(tq,"show",0.8);await snap("toast-gem-first",0.15)
  await wait_phase(tq,"idle",0.0)
  game.gems.add("corrosive");game.gem_discovered("corrosive");await wait_phase(tq,"show",0.8);await snap("toast-gem-repeat",0.15)
  game.gems.add("corrosive");game.gem_discovered("corrosive");await snap("toast-gem-merged",0.2)
  await wait_phase(tq,"idle",0.0)
  game.grant_item("imbued_amulet",false);await wait_phase(tq,"show",0.8);await snap("toast-amulet",0.15)
  await wait_phase(tq,"idle",0.0)
  game.grant_item(Catalog.ITEM_IDS[5],false);await wait_phase(tq,"show",0.8);await snap("toast-item",0.15)
  await wait_phase(tq,"idle",0.0)
  game.gems.add("ice");game.gem_discovered("ice");await create_timer(0.25).timeout;await snap("toast-burst",0.0)
  await wait_phase(tq,"idle",0.0)
  game.announce("ELITE ENCOUNTER • Obsidian Sentinels");game.frontend.event_label.text=game.announcement;game.frontend.update_hud();await snap("banner-elite",0.4)

 if want("boss"):
  game.enemies.clear();var bb=game.frontend.run_hud.bosses
  var sp=func(kind,off):
   var e=game.spawn_enemy(kind,game.player.position+off);e.speed=0.0;return e
  var b1=sp.call(8,Vector3(0,0,-14));game.frontend.update_hud();bb.refresh_now();await snap("boss-stage",0.5)
  var b2=sp.call(8,Vector3(60,0,60));var m1=sp.call(9,Vector3(-8,0,-10));var m2=sp.call(10,Vector3(40,0,-70))
  game.frontend.update_hud();bb.refresh_now();await snap("boss-two-plus-minis-pointer",0.6)
  b1.hp=b1.max_hp*0.18;game.frontend.update_hud();await snap("boss-enraged",0.6)
  b1.hp=0.0;game.frontend.update_hud();await snap("boss-slain",0.45)
  game.enemies.clear()
 if want("pause"):
  late_build();game.gold=1840;game.kills=412;game.elapsed=754.0;game.frontend.update_hud();await snap("hud-late-for-pause",0.3)
  game.pause_menu();await create_timer(0.6).timeout;await snap("pause",0.3)
  var ps=game.frontend.menu.get_child(0);ps.items["settings"].grab_focus();await snap("pause-settings-focus",0.2)
  ps.abandon.grab_focus();ps.abandon.holding=true;await create_timer(0.5).timeout;await snap("pause-abandon-hold",0.0)
  ps.abandon.holding=false
  game.frontend.settings(game.pause_menu);await create_timer(0.6).timeout;await snap("pause-settings",0.2)
  game.frontend.leave_settings();game.resume()
 quit(0)
func wait_phase(tq: RunToasts,phase: String,extra: float) -> void:
 var guard=0
 while tq.phase!=phase and guard<2000:
  await create_timer(0.05).timeout;guard+=1
 if extra>0.0:await create_timer(extra).timeout

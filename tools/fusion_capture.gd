extends SceneTree
# Real-render combat captures of the Fusions into docs/images/fusions/: six Fusions on one weapon (sword) and the eight forms with Steamforged.
# usage: xvfb-run -a -s "-screen 0 1920x1080x24" stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1920x1080 --script tools/fusion_capture.gd
var game: Node3D
var out="res://docs/images/fusions/"
const FORM_STAT={0:"crescents",1:"meteors",2:"strikes",6:"splits",7:"judgements",9:"vortices",10:"eruptions",15:"walls"}
func _initialize() -> void:call_deferred("run")
func snap(label: String) -> void:
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+label+".png");print("SHOT "+label)
func setup(wid: int,gems: Array) -> void:
 game.weapons.clear();game.equip(wid);game.selected_weapon=wid;game.weapons[wid]["sockets"]={"unlocked":2,"gems":gems}
 game.enemies.clear();game.projectiles.clear();game.wrt.forms.clear()
 var fwd=-game.player.camera.global_transform.basis.z;fwd.y=0;fwd=fwd.normalized();var side=fwd.cross(Vector3.UP)
 for i in 18:
  var e=game.spawn_enemy(0,game.player.position+fwd*(5.0+float(i%6)*1.6)+side*(float(i/6)-1.0)*2.4)
  if not e.is_empty():e.hp=1.0e9;e.max_hp=1.0e9;e.frozen=1.0e6 # held in place by the enemy's own stun, so the screen is not under the Stopwatch look
func advance(seconds: float) -> void:
 var n=int(seconds/0.033)
 for i in n:
  game.spawn_clock=999.0;game.mode="run";game._physics_process(0.033)
  if i%3==0:await process_frame
func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 MenuScreen.set_instant(true)
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.6).timeout
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://fusion-capture.json"
 game.next_run_seed=77;game.map_seed_override=9;game.begin_run();game.resume();game.set_physics_process(false);game.sandbox=true;game.settings.invincible=true
 var pairs={"steamforged":["fire","ice"],"plasma":["electricity","fire"],"aurora":["electricity","ice"],"livewire":["corrosive","electricity"],"pyrebile":["corrosive","fire"],"rimerot":["corrosive","ice"]}
 for f in pairs:
  setup(0,pairs[f]);await advance(2.2);await snap("sword_%s"%f)
 for wid in FORM_STAT:
  setup(wid,pairs.steamforged);var guard=0
  while int(game.wrt.forms.stats.get(FORM_STAT[wid],0))<1 and guard<400:await advance(0.1);guard+=1
  await advance(0.25);await snap("form_%s"%Fusions.WEAPON_KEYS[wid])
 print("capture done");quit()

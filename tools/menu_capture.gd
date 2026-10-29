extends SceneTree
# Real-render capture of every menu screen/state at 1920x1080 into docs/images/menus/ (Forward+ / llvmpipe under xvfb).
# usage: xvfb-run -a stdbuf -oL tools/godot.sh --path . --rendering-driver vulkan --resolution 1920x1080 --script tools/menu_capture.gd [-- only=main,loadout]
# The demo profile below is seeded data (not a real save): silver, kill counts and five finished runs, so the screens have content.
var game: Node
var only: Array=[]
var out="res://docs/images/menus/"
func _initialize() -> void:call_deferred("run")
func want(name: String) -> bool:return only.is_empty() or name in only
func snap(label: String,wait: float=0.35) -> void:
 await create_timer(wait).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png(out+label+".png");print("SHOT "+label)
func seed_profile() -> void:
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://menu-capture.json"
 var d=game.progress.data
 d.silver=452;d.kills=140;d.best=120.0
 d.quest_metrics={"weapon:9":63.0,"weapon:10":49.0,"weapon:0":22.0,"chests":2.0}
 var runs=[[212,512.0,0,"momentum","nova"],[188,447.0,9,"sentry","berserk"],[150,366.0,6,"glider","ghost"],[96,240.0,1,"climber","nova"],[61,130.0,10,"seer","berserk"],[40,95.0,0,"climber","nova"]]
 d.leaderboard=[]
 for r in runs:d.leaderboard.append({"kills":r[0],"time":r[1],"weapon":r[2],"trait":r[3],"ultimate":r[4],"victory":false})
 for key in ["weapons:2","weapons:9","weapons:10","tomes:Multishot","tomes:Greed"]:
  if not key in d.entries:d.entries.append(key)
 d.loadout={"weapon":9,"trait":"momentum","ultimate":"nova"};game.selected_weapon=9;game.selected_trait="momentum";game.selected_ultimate="nova"
func run() -> void:
 for a in OS.get_cmdline_user_args():
  if a.begins_with("only="):only=a.substr(5).split(",")
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 MenuScreen.instant=true
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.6).timeout
 seed_profile()
 var fe=game.frontend
 if want("main"):
  fe.home();await snap("main-menu",0.6)
 if want("loadout"):
  fe.play_screen();await snap("loadout-closed",0.7)
  var screen=fe.menu.get_child(fe.menu.get_child_count()-1)
  screen.open_list("weapons");await snap("loadout-open",0.6)
 if want('unlocks'):
  for tab in ['weapons','tomes','traits','ultimates','items']:
   if tab=='items':
    for key in ['items:bitter_wine','items:mourners_veil']:MetaProgress.toggle(game.progress.data,'items',key.get_slice(':',1))
    MenuData.debug_locked_items=['hex_penny','witch_bottle','coven_sigil','devils_bargain','anvil_first_forge','saints_finger','gem_loupe']
   fe.active_tab=tab;fe.unlocks();await snap('unlocks-'+tab,0.6)
   if tab=='items':
    var s2=fe.menu.get_child(fe.menu.get_child_count()-1)
    s2.tiles['tinder_pouch'].grab_focus();await snap('unlocks-items-gem',0.5)
    s2.set_filter('legendary');s2.tiles['headsmans_oath'].grab_focus();await snap('unlocks-items-legendary',0.5)
    s2.set_filter('all');s2.tiles['hex_penny'].grab_focus();await snap('unlocks-items-locked',0.5)
   if tab=='weapons':
    var screen=fe.menu.get_child(fe.menu.get_child_count()-1)
    screen.tiles['9'].grab_focus();await snap('unlocks-weapons-scythes',2.2)
    screen.tiles['15'].grab_focus();await snap('unlocks-weapons-locked',1.2)
 quit()

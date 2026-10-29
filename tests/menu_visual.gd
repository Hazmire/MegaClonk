extends SceneTree
var game: Node
func _initialize() -> void:call_deferred("run")
func capture(label: String) -> void:
 await create_timer(0.15).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/menu_"+label+".png")
func run() -> void:
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.5).timeout
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://visual-menu-test.json"
 game.frontend.home();await capture("home")
 game.frontend.play_screen();await capture("play")
 game.frontend.unlocks();await capture("unlocks")
 game.frontend.quests();await capture("quests")
 game.frontend.settings(game.frontend.home);await capture("settings")
 game.sandbox=false;game.selected_weapon=1;game.selected_trait="momentum";game.selected_ultimate="nova";game.next_run_seed=110;game.begin_run();game.settings.invincible=true;game.settings.focus_pause=false
 game.spawn_clock=999
 await create_timer(0.5).timeout
 game.update_hud();await capture("hud")
 game.show_upgrades();await capture("levelup")
 game.grant_item("whetstone");game.grant_item("salted_pork");game.frontend.inventory();await capture("inventory")
 var shop={"offers":[0,1,2],"sold":[]};game.gold=100;game.frontend.shop(shop);await capture("shop")
 game.frontend.reward("whetstone");await capture("reward")
 game.queue_free();await create_timer(0.15).timeout
 quit()

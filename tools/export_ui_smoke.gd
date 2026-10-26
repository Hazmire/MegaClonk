extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 game.frontend.upgrades();await process_frame
 game.pending_upgrades=0;game.frontend.inventory();await process_frame
 game.gold=100;game.frontend.shop({"tier":"Common","offers":[1],"used":false,"sold":[]});await process_frame
 game.frontend.reward(Catalog.ITEMS[10]);await create_timer(1.8).timeout
 game.grant_red_level();game.resume();await process_frame
 game.queue_free();await process_frame;await process_frame
 print("EXPORTED REWARD UI SMOKE COMPLETE");quit()

extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.map_seed_override=9;game.next_run_seed=923;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="reward"
 var began=Time.get_ticks_usec()
 for i in 1000:game.add_xp_drop(Vector3(20+(i%25)*4,20,20+(i/25)*4),1)
 var drop_ms=(Time.get_ticks_usec()-began)/1000.0
 began=Time.get_ticks_usec()
 for i in 120:game.update_pickups(1.0/60)
 var tick_ms=(Time.get_ticks_usec()-began)/120000.0
 began=Time.get_ticks_usec()
 for i in 20:
  game.frontend.upgrades();await process_frame
 var upgrades_ms=(Time.get_ticks_usec()-began)/20000.0
 began=Time.get_ticks_usec()
 for i in 20:
  game.frontend.reward(Catalog.ITEMS[10]);await process_frame
 var reel_ms=(Time.get_ticks_usec()-began)/20000.0
 print(JSON.stringify({"unmerged_gems":game.pickups.size(),"drop_1000_ms":drop_ms,"gem_update_ms_per_tick":tick_ms,"upgrade_open_ms_including_frame":upgrades_ms,"roulette_open_ms_including_frame":reel_ms,"renderer":"headless; rendering excluded; software-host timing only"}))
 game.queue_free();await process_frame;await process_frame;quit()

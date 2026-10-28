extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.enemies.clear();game.mode="run";game.frontend.enter_run();game.frontend.stage_banner.hide();game.notice.hide()
 game.weapons.clear()
 for id in [0,1,2,7]:game.equip(id)
 game.tomes={"Wind":2,"Wisdom":3,"Iron":1,"Might":4};game.health=67;game.stats.max_health=100;game.player.arm.rotation=Vector3(-.55,0,0);game.player.camera.current=true;game.update_hud()
 await create_timer(.3).timeout;await process_frame;await RenderingServer.frame_post_draw
 DirAccess.make_dir_recursive_absolute("res://docs/images/dark-feedback");root.get_texture().get_image().save_png("res://docs/images/dark-feedback/hud.png")
 print("HUD CAPTURE left HP=",game.frontend.health_text.text," model bar=",game.frontend.character_health.position," visible=",game.frontend.character_health.visible)
 game.queue_free();await process_frame;await process_frame;quit()

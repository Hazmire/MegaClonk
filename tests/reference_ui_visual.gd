extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(name: String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/images/rewards/"+name+".png")
 print("CAPTURE "+name)
func run():
 DirAccess.make_dir_recursive_absolute("res://docs/images/rewards")
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause";Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 game.weapons.clear()
 for id in [0,1,2,6]:game.equip(id);game.weapons[id].level=3
 for id in ["Might","Haste","Wisdom","Iron"]:game.apply_upgrade({"type":"tome","id":id})
 for id in Catalog.ITEMS.size():game.apply_item(id)
 game.apply_item(1);game.apply_item(1);game.apply_item(2)
 game.gold=245;game.level=12;game.elapsed=149;game.health=83
 for size in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2560,1440)]:
  root.size=size;DisplayServer.window_set_size(size)
  game.frontend.upgrades();await capture("upgrades_"+str(size.x))
  game.frontend.inventory();await capture("build_"+str(size.x))
 root.size=Vector2i(1280,720);DisplayServer.window_set_size(Vector2i(1280,720))
 game.frontend.shop({"tier":"Rare","offers":[0,6,8],"sold":[],"used":false});await capture("shop")
 game.frontend.reward(Catalog.ITEMS[10]);await create_timer(0.4).timeout;await capture("roulette");await create_timer(1.5).timeout;await capture("legendary_reveal")
 game.add_xp_drop(game.player.position+Vector3(2,0.7,1),5);game.add_red_gem(game.player.position+Vector3(-2,0.7,1))
 game.pending_upgrades=0;game.resume();game.set_physics_process(false);game.player.active=false;await capture("gems")
 game.queue_free();await process_frame;await process_frame;await process_frame;quit()

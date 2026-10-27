extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(name: String):
 await create_timer(0.1).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/polish_"+name+".png")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.next_run_seed=123;game.map_seed_override=9;game.settings.focus_pause=false;game.begin_run();game.mode="pause";Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;game.player.active=false;game.set_physics_process(false)
 game.frontend.hud_root.hide();var origin=game.map_layout.spawn;game.player.position=origin+Vector3.UP*0.02
 var camera=Camera3D.new();game.world.add_child(camera);camera.position=origin+Vector3(3,1.9,5);camera.look_at(origin+Vector3.UP);camera.current=true
 for state in ["idle","run","jump","slide","crouch"]:
  game.player.avatar.animate(state,6,0.1)
  for i in 20:game.player.avatar.animate(state,6,0.02)
  await capture(state)
 for i in 20:game.player.avatar.animate("idle",0,0.02)
 game.weapons.clear();game.equip(4);game.elapsed=2;game.update_special_visuals(0.016)
 camera.position=origin+Vector3(9,7,12);camera.look_at(origin+Vector3.UP);await capture("chunkers")
 game.weapons.clear();game.equip(1);game.equip(7);game.equip(2);game.equip(33)
 for i in 12:game.spawn_enemy(0,origin+Vector3((i-6)*1.4,0,-6))
 game.rebuild_grid();game.update_weapons(1);game.update_enemies(0.1);game.update_effects(0.016);game.combat_fx.tick(0.05);await capture("combat")
 camera.position=origin+Vector3(0,3,-6);camera.look_at(origin+Vector3(0,18,80));await capture("fog_cliffs")
 game.queue_free();await process_frame;await process_frame;await process_frame;quit()

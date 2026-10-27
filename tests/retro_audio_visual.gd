extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(name: String):
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://docs/images/retro-audio/"+name+".png");print("CAPTURE "+name)
func run():
 DirAccess.make_dir_recursive_absolute("res://docs/images/retro-audio")
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.settings.reduced=false;game.settings.visual_intensity=1;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause";game.enemies.clear();game.frontend.menu.hide();game.frontend.hud_root.hide();game.notice.hide()
 var pos=game.map_layout.spawn;var enemy=game.spawn_enemy(0,pos+Vector3(0,0,-4));enemy.age=5;enemy.hp=10000;enemy.max_hp=10000
 var camera=Camera3D.new();game.world.add_child(camera);camera.position=pos+Vector3(3,3,4);camera.look_at(enemy.pos+Vector3.UP*.4);camera.current=true
 game.hit(enemy,5,0);game.enemy_view.begin_frame();game.enemy_view.draw_enemy(enemy,game.player.position);game.enemy_view.end_frame();await capture("white_hit")
 enemy.hit_time=0;game.enemy_view.begin_frame();game.enemy_view.draw_enemy(enemy,game.player.position);game.enemy_view.end_frame();await capture("restored")
 game.frontend.settings(game.frontend.home)
 for node in RewardScreens.descendants(game.frontend.menu):
  if node is TabContainer:node.current_tab=2
 await capture("audio_settings")
 game.queue_free();await process_frame;await process_frame;quit()

extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(name: String):
 await create_timer(0.2).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/forest_"+name+".png")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await create_timer(0.3).timeout
 game.settings.focus_pause=false;game.next_run_seed=626;game.selected_trait="seer";game.begin_run();game.mode="pause";game.player.active=false;game.player.position=Vector3(0,0.02,0);game.set_physics_process(false)
 var camera=Camera3D.new();game.world.add_child(camera);camera.position=Vector3(80,115,100);camera.look_at(Vector3.ZERO);camera.current=true
 game.frontend.hud_root.hide();await capture("overhead")
 game.player.camera.current=true;game.player.zoom=6;game.player.arm.spring_length=6
 for state in ["idle","run","jump","fall","crouch","slide"]:
  for i in 20:game.player.avatar.animate(state,4,0.0167)
  await capture(state)
 game.player.avatar.animate("idle",0,0.3)
 game.enemies.clear()
 for kind in 8:
  for choice in 2:
   game.variants.selections[kind]=choice
   var p=Vector3((kind-3.5)*2,0,-5-choice*4);p.y=game.terrain_height(p.x,p.z)+0.65
   game.spawn_enemy(kind,p)
 game.update_enemies(0.16);await capture("monsters_a")
 game.update_enemies(0.25);await capture("monsters_b")
 game.sandbox=true;game.toggle_map_debug();camera.current=true;await capture("navigation")
 game.queue_free();await process_frame;await process_frame
 var showcase=load("res://scenes/showcase/assets.tscn").instantiate();root.add_child(showcase);await create_timer(0.4).timeout;game=showcase
 await capture("showcase");showcase.queue_free();await process_frame;await process_frame;quit()

extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(label: String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/images/protagonist/game_"+label+".png")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.map_seed_override=9;game.next_run_seed=123;game.settings.focus_pause=false
 game.begin_run();game.mode="pause";game.player.active=false;game.set_physics_process(false)
 game.enemies.clear();game.frontend.hud_root.hide();game.notice.hide()
 var origin=game.map_layout.spawn;game.player.position=origin+Vector3.UP*.02
 var camera=Camera3D.new();game.world.add_child(camera);camera.fov=45;camera.position=origin+Vector3(2,1.55,3.3);camera.look_at(origin+Vector3.UP*.9);camera.current=true
 var actor=game.player.avatar
 for entry in [["idle","idle",0.0],["run","run",8.0],["critical","critical_walk",3.0],["crouch","crouch",0.0],["slide","slide",9.0],["jump","jump",8.0]]:
  actor.set_motion_context(0,true,1,10,true)
  for i in 40:actor.animate("idle",0,.02)
  if entry[0]=="jump":actor.set_motion_context(0,false,1,10,true)
  for i in 30:actor.animate(entry[1],entry[2],.02)
  if entry[0]=="jump":game.player.position.y+=.7
  await capture(entry[0])
  game.player.position=origin+Vector3.UP*.02
 actor.set_motion_context(0,true,1,10,true)
 for i in 30:actor.animate("idle",0,.02)
 game.frontend.hud_root.show();game.update_hud();game.player.camera.current=true;game.player.arm.rotation=Vector3(-.4,PI,0);game.player.arm.spring_length=6
 await capture("playable")
 game.queue_free();await process_frame;await process_frame
 print("INVESTIGATOR GAMEPLAY RENDERS COMPLETE");quit()

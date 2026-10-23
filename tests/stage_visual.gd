extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(label: String):
 await create_timer(0.2).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/stage_"+label+".png")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game)
 await create_timer(0.2).timeout
 game.next_run_seed=542;game.selected_trait="seer";game.begin_run();game.settings.focus_pause=false;game.settings.invincible=true
 game.player.position=game.portal.position+Vector3(0,0,7);game.player.yaw=0
 await capture("dormant")
 game.activate_portal();await capture("summoned")
 for i in range(game.enemies.size()-1,-1,-1):
  if game.enemies[i].kind==8:game.kill_enemy(i)
 await capture("exit")
 game.activate_portal();await capture("next")
 game.queue_free();await process_frame;await process_frame;quit()

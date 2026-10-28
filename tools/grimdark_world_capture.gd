extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(name: String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/images/grimdark/"+name+".png");print("CAPTURE "+name)
func camera(position: Vector3,target: Vector3) -> Camera3D:
 var view=Camera3D.new();game.world.add_child(view);view.position=position;view.look_at(target);view.current=true;return view
func run():
 DirAccess.make_dir_recursive_absolute("res://docs/images/art-reset")
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.settings.reduced=false;game.settings.visual_intensity=1;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause";Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 for stage_value in [1,2,3]:
  game.stage=stage_value;game.build_stage();game.mode="pause";game.player.active=false;game.frontend.menu.hide();game.frontend.hud_root.hide();game.notice.hide();game.frontend.stage_intro(stage_value)
  var pos=game.map_layout.spawn;game.player.position=pos;camera(pos+Vector3(4,5,11),pos+Vector3(0,3,-15));await create_timer(1).timeout;await capture("stage_"+str(stage_value))
 game.queue_free();await process_frame;await process_frame;quit()

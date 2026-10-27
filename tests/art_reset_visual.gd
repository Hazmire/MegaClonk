extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(name: String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/images/art-reset/"+name+".png");print("CAPTURE "+name)
func camera(position: Vector3,target: Vector3) -> Camera3D:
 var view=Camera3D.new();game.world.add_child(view);view.position=position;view.look_at(target);view.current=true;return view
func run():
 DirAccess.make_dir_recursive_absolute("res://docs/images/art-reset")
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.settings.reduced=false;game.settings.visual_intensity=1;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause";Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 for stage_value in [1,2,3]:
  game.stage=stage_value;game.build_stage();game.mode="pause";game.player.active=false;game.frontend.menu.hide();game.frontend.hud_root.hide();game.notice.hide();game.frontend.stage_intro(stage_value)
  var pos=game.map_layout.spawn;game.player.position=pos;camera(pos+Vector3(4,5,11),pos+Vector3(0,3,-15));await create_timer(1).timeout;await capture("stage_"+str(stage_value))
 game.stage=1;game.build_stage();game.mode="pause";game.player.active=false;game.frontend.menu.hide();game.frontend.hud_root.hide();game.notice.hide()
 var path=game.portal_wind.guidance.route(game.map_layout.spawn)
 for label in ["far","medium","close"]:
  var desired=90 if label=="far" else 40 if label=="medium" else 7
  var best=INF;var selected=path[0]
  for point in path:
   var difference=absf(point.distance_to(game.portal.position)-desired)
   if difference<best:best=difference;selected=point
  game.player.position=selected;var next=game.portal_wind.guidance.waypoint(selected);var ahead=next-selected;ahead.y=0;ahead=ahead.normalized()
  camera(selected-ahead*8+Vector3.UP*5,selected+ahead*8+Vector3.UP*1.3)
  await create_timer(2).timeout;print("GUIDANCE ",label," distance=",selected.distance_to(game.portal.position)," prox=",game.portal_wind.proximity);await capture("guidance_"+label)
 game.player.position=game.portal.position+Vector3(5,0,4);game.portal_state="summoned";game.refresh_portal()
 camera(game.portal.position+Vector3(9,6,11),game.portal.position+Vector3.UP*2);await create_timer(0.3).timeout;await capture("portal_vortex")
 var position=game.map_layout.spawn;camera(position+Vector3(14,7,18),position+Vector3(0,25,-80));await capture("rocky_boundary")
 game.frontend.active_tab="weapons";game.frontend.unlocks();await capture("weapon_icons")
 game.frontend.upgrades();await capture("common_acquisitions")
 game.queue_free();await process_frame;await process_frame;quit()

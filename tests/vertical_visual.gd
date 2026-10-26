extends SceneTree
var game: Node
var caption: Label
func _initialize():call_deferred("run")
func capture(name: String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/images/vertical/"+name+".png")
 print("CAPTURE "+name)
func run():
 DirAccess.make_dir_recursive_absolute("res://docs/images/vertical")
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.next_run_seed=42;game.map_seed_override=0;game.begin_run();game.mode="pause";game.player.active=false;game.set_physics_process(false);game.frontend.hud_root.hide();game.notice.hide();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 var layer=CanvasLayer.new();root.add_child(layer);caption=Label.new();caption.position=Vector2(20,15);caption.add_theme_font_size_override("font_size",22);caption.add_theme_color_override("font_shadow_color",Color.BLACK);caption.add_theme_constant_override("shadow_offset_x",2);caption.add_theme_constant_override("shadow_offset_y",2);layer.add_child(caption)
 var seeds=[0,1,2,3,4,5,6,7,8,9,10,11]
 for seed_value in seeds:
  game.map_seed_override=seed_value;game.build_stage();game.mode="pause";game.player.active=false;game.frontend.hud_root.hide();game.notice.hide()
  var env=game.world.get_child(0).environment;env.fog_enabled=false
  var camera=Camera3D.new();game.world.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=244;camera.far=700;camera.position=Vector3(170,265,170);camera.look_at(Vector3(0,18,0));camera.current=true
  for marker in [[game.map_layout.spawn,Color("50ff87")],[game.map_layout.portal,Color("e188ff")],[game.map_layout.elite,Color("ffd166")]]:
   game.mesh_node(game.cylinder(2,7),marker[1],game.world,marker[0]+Vector3.UP*3.5,false)
  caption.text="SEED %02d | %d regions | %d ramps | 0 / 12 / 24 / 36m\nGreen: spawn  Purple: portal  Gold: elite | Debug overview: fog disabled"%[seed_value,game.map_layout.regions.size(),game.map_layout.ramps.size()]
  await capture("seed_%02d"%seed_value)
 game.map_seed_override=9;game.build_stage();game.mode="pause";game.player.active=false;game.frontend.hud_root.hide();game.notice.hide()
 var origin=game.map_layout.spawn
 var camera=Camera3D.new();game.world.add_child(camera);camera.position=origin+Vector3(5,4,8);camera.look_at(origin+Vector3(0,1,-8));camera.current=true
 caption.text="Forest play view | actual distance fog, warm light and blue cloud sky";await capture("forest_view")
 camera.position=Vector3(0,52,0);camera.look_at(Vector3(70,70,40));caption.text="Sky inspection | static soft clouds and horizon gradient | fog enabled";await capture("sky")
 game.queue_free();layer.queue_free();await process_frame;await process_frame;await process_frame;quit()

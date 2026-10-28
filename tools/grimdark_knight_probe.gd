extends SceneTree
func _initialize():call_deferred("run")
func run():
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("3b3f43");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.8;root.add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-35,-20,0);root.add_child(light)
 for i in 2:
  var model=load("res://assets/grimdark/knight/"+("knight.glb" if i==0 else "Knight_ready.glb")).instantiate();root.add_child(model);model.position.x=-1.5 if i==0 else 1.5
  for player in model.find_children("*","AnimationPlayer",true,false):player.play("k_idle");player.advance(.1)
  var label=Label3D.new();label.text="ORIGINAL" if i==0 else "NORMALIZED";label.position=Vector3(model.position.x,2.4,0);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;root.add_child(label)
 var camera=Camera3D.new();root.add_child(camera);camera.position=Vector3(0,1.6,7);camera.look_at(Vector3(0,1,0));camera.current=true;camera.fov=40
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("/tmp/knight-pair.png");quit()

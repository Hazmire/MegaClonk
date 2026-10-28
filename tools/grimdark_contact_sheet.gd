extends SceneTree
func _initialize():call_deferred("run")
func run():
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("535759");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.8;root.add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-40,-25,0);root.add_child(light)
 var ids=["Character_Monster"]
 for i in range(1,9):ids.append("Character_Monster_%02d"%i)
 for i in [5,7,10]:ids.append("Character_Killer_%02d"%i)
 for i in ids.size():
  var node=MeshInstance3D.new();node.mesh=load("res://assets/grimdark/baked/enemies/"+ids[i]+"_enemy_idle_0.res");node.position=Vector3((i%6-2.5)*3,0,int(i/6)*4);root.add_child(node)
  var label=Label3D.new();label.text=ids[i].replace("Character_","");label.font_size=32;label.pixel_size=.01;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.position=node.position+Vector3.UP*2.3;root.add_child(label)
 var camera=Camera3D.new();camera.position=Vector3(0,6,23);root.add_child(camera);camera.fov=32;camera.look_at(Vector3(0,1.5,2));camera.current=true
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/grimdark-contact-sheet.png");quit()

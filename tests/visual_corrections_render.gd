extends SceneTree
var failures=[]
func _initialize():call_deferred("run")
func run():
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color.RED;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=1;env.environment.ambient_light_color=Color.WHITE;root.add_child(env)
 var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-25,-15,0);root.add_child(sun)
 var source=StandardMaterial3D.new();var pixels=Image.create(2,2,false,Image.FORMAT_RGBA8);pixels.fill(Color(0.1,.7,.2,0));source.albedo_texture=ImageTexture.create_from_image(pixels)
 for i in 2:
  var panel=MeshInstance3D.new();panel.mesh=QuadMesh.new();panel.mesh.size=Vector2(2.5,2.5);panel.position=Vector3(-1.4 if i==0 else 1.4,1,0);root.add_child(panel)
  if i==0:panel.material_override=GrimdarkMaterials.material(source)
  else:
   var mat=ForestAtmosphere.floor_material();panel.material_override=mat;mat.set_shader_parameter("stone_low",Color(.1,.5,.2));mat.set_shader_parameter("stone_high",Color(.15,.6,.25))
 var camera=Camera3D.new();root.add_child(camera);camera.current=true;camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=6
 for side in [1,-1]:
  camera.position=Vector3(0,1,6*side);camera.look_at(Vector3(0,1,0));await process_frame;await process_frame;await process_frame;await RenderingServer.frame_post_draw
  var picture=root.get_texture().get_image()
  for x in [-1.4,1.4]:
   var screen=camera.unproject_position(Vector3(x,1,0));var color=picture.get_pixelv(Vector2i(screen))
   if color.r>color.g*1.5 or color.g<.05:failures.append({"side":side,"x":x,"color":str(color)})
  picture.save_png("/tmp/opaque-corrections-"+str(side)+".png")
 print("OPAQUE OCCLUSION RENDER: ",failures)
 quit(0 if failures.is_empty() else 1)

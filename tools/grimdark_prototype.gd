extends SceneTree
class PrototypeWorld extends Node3D:
 var settings={"render_scale":1.0,"retro_scale":.5,"psx_dither":true,"psx_warp":.25,"psx_snap":.35}
func _initialize():call_deferred("run")
func run():
 var game=PrototypeWorld.new();root.add_child(game)
 var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("28302e");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("89958c");env.environment.ambient_light_energy=.8;game.add_child(env)
 var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-25,0);light.light_color=Color("b2b9ae");light.light_energy=1.3;game.add_child(light)
 for pair in [["tree_rt_1",Vector3(-3,0,-3),5.0],["dead_tree_rt_1",Vector3(4,0,-3),5.0],["forest_Rock",Vector3(-2,0,0),1.2],["palace_shrine",Vector3(3,0,1),1.3]]:
  var node=MeshInstance3D.new();node.mesh=GrimdarkMaterials.mesh(load("res://assets/grimdark/baked/props/"+pair[0]+".res"),1,true);node.scale=Vector3.ONE*pair[2];node.position=pair[1];game.add_child(node)
 var knight=load("res://assets/grimdark/knight/Knight_ready.glb").instantiate();game.add_child(knight)
 for mesh in knight.find_children("*","MeshInstance3D",true,false):
  mesh.mesh=mesh.mesh.duplicate()
  for i in mesh.mesh.get_surface_count():mesh.mesh.surface_set_material(i,GrimdarkMaterials.material(mesh.mesh.surface_get_material(i),1,false,true))
 for player in knight.find_children("*","AnimationPlayer",true,false):player.play("k_idle");player.advance(.15)
 var floor=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(50,50);floor.mesh=plane;var base=StandardMaterial3D.new();base.albedo_texture=load("res://assets/grimdark/horror/PS1_ForestAsset/dirt.JPG");floor.material_override=GrimdarkMaterials.material(base);game.add_child(floor)
 var camera=Camera3D.new();game.add_child(camera);camera.position=Vector3(7,4,9);camera.look_at(Vector3(0,1,0));camera.current=true
 var renderer=GrimdarkRenderer.new();game.add_child(renderer);renderer.setup(game)
 var layer=CanvasLayer.new();layer.layer=5;game.add_child(layer);var label=Label.new();label.text="GRIMDARK PSX FOUNDATION • 640×360 WORLD / FULL-RES UI";label.position=Vector2(20,20);layer.add_child(label)
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("/tmp/grimdark-prototype.png");print("PROTOTYPE RESOLUTION ",renderer.viewport.size)
 game.queue_free();await process_frame;await process_frame;quit()

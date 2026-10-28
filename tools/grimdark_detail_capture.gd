extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func shot(name: String):
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/images/grimdark/"+name+".png")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause";game.frontend.menu.hide();game.frontend.hud_root.hide();game.notice.hide()
 if is_instance_valid(game.frontend.stage_banner):game.frontend.stage_banner.hide()
 var center=game.map_layout.spawn
 var camera=Camera3D.new();game.world.add_child(camera);camera.current=true
 for object in game.interactables:object.node.hide()
 var display=Node3D.new();game.world.add_child(display);display.position=center
 var kinds=["Chest","Shop","Charge Shrine","Elite Statue","Boss Statue"]
 for i in kinds.size():
  var node=Node3D.new();display.add_child(node);node.position=Vector3((i-2)*4,0,0);GrimdarkObjects.populate(node,kinds[i],1)
  var label=Label3D.new();node.add_child(label);label.text=kinds[i];label.position.y=3.8;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=28;label.pixel_size=.01
 camera.position=center+Vector3(0,6,17);camera.look_at(center+Vector3.UP*1.5);await shot("interactables")
 display.queue_free();await process_frame
 var actors=Node3D.new();game.world.add_child(actors);actors.position=center
 var models=["Goblin","Skeleton","Imp","BlightHusk","Behemoth","Golem"]
 for i in models.size():
  var node=MeshInstance3D.new();actors.add_child(node);node.mesh=BestiaryFrames.mesh(models[i],"enemy_move",2);node.position=Vector3((i-2.5)*2.3,0,0)
  var label=Label3D.new();node.add_child(label);label.text=models[i];label.position.y=2.4;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.font_size=22;label.pixel_size=.01
 camera.position=center+Vector3(0,4,13);camera.look_at(center+Vector3.UP);await shot("enemy_roster")
 actors.queue_free();await process_frame
 game.player.position=center;camera.position=center+Vector3(1.5,2.3,4);camera.look_at(center+Vector3.UP)
 game.player.avatar.animate("idle",0,.1);await shot("knight_idle")
 game.player.avatar.set_damage_flash(true);await shot("knight_damage_red")
 game.player.avatar.set_damage_flash(false)
 game.frontend.enter_run();game.mode="run";game.update_hud();await shot("hud")
 game.queue_free();await process_frame;await process_frame;print("GRIMDARK DETAIL CAPTURES COMPLETE");quit()

extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(name: String):
 await create_timer(0.12).timeout;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/dynamic_"+name+".png")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.settings.focus_pause=false;game.sandbox=true;game.next_run_seed=42;game.map_seed_override=9;game.begin_run();game.mode="pause";game.player.active=false;game.set_physics_process(false);game.frontend.hud_root.hide()
 var layer=CanvasLayer.new();root.add_child(layer);var label=Label.new();label.position=Vector2(20,20);label.add_theme_font_size_override("font_size",24);layer.add_child(label)
 for seed_value in (0 if "--encounters-only" in OS.get_cmdline_user_args() else 10):
  game.map_seed_override=seed_value;game.build_stage();game.mode="pause";game.player.active=false
  var camera=Camera3D.new();game.world.add_child(camera);camera.position=Vector3(120,170,145);camera.look_at(Vector3.ZERO);camera.current=true
  game.mesh_node(game.cylinder(3,6),Color("61ff87"),game.world,game.map_layout.spawn+Vector3.UP*3,false)
  game.mesh_node(game.cylinder(3,6),Color("dba3ff"),game.world,game.map_layout.portal+Vector3.UP*3,false)
  label.text="SEED %d • %d regions • %d ramps • spawn %s\nGreen: player spawn / Purple: boss portal"%[seed_value,game.map_layout.regions.size(),game.map_layout.ramps.size(),str(game.map_layout.spawn)]
  await capture("seed_%02d"%seed_value)
 game.map_seed_override=9;game.build_stage();game.mode="pause";game.player.active=false;game.player.position=game.map_layout.spawn+Vector3.UP*0.02
 var origin=game.map_layout.spawn
 var close_camera=Camera3D.new();game.world.add_child(close_camera);close_camera.position=origin+Vector3(7,3.7,8);close_camera.look_at(origin+Vector3.UP);close_camera.current=true
 close_camera.position=origin+Vector3(2.8,1.7,4);close_camera.look_at(origin+Vector3.UP)
 for frame in [0.0,0.165,0.33,0.495]:
  game.player.avatar.animate("run",RangerStride.METRES_PER_SECOND,0.016)
  game.player.avatar.playback.seek(frame,true);game.player.avatar.playback.advance(0);label.text="Ranger fitted skeletal stride • t=%.3f"%frame;await capture("stride_"+str(frame))
 close_camera.position=origin+Vector3(7,3.7,8);close_camera.look_at(origin+Vector3.UP)
 game.enemies.clear()
 for i in 5:
  var e=game.spawn_enemy(0 if i<2 else (1 if i<4 else 2),origin+Vector3((i-2)*3,0,-5))
  e.variant=OrdinaryRoster.variant(0 if i<2 else (1 if i<4 else 2),i%2);e.age=1;e.state="move"
 game.update_enemies(0.1);label.text="Goblin / KayKit Skeleton / Exploding Bug / Speedy Monster / Large";await capture("roster")
 game.enemies.clear();var elite=game.spawn_enemy(13,origin+Vector3(-3,0,-6));elite.age=1
 var boss=game.spawn_enemy(8,origin+Vector3(6,0,-12));Encounters.initialize(game,boss,"rock_golem");boss.age=1
 game.update_enemies(0);label.text="Obsidian Sentinel • elite emblem / Rock Golem";await capture("elite_golem")
 game.enemies.clear();boss=game.spawn_enemy(8,origin+Vector3(4,0,-12));Encounters.initialize(game,boss,"chunkus");boss.age=1;boss.ability_clock=0;game.update_enemies(0.01);label.text="Big Chunkus • captured five-metre AOE warning";await capture("chunkus")
 game.queue_free();layer.queue_free();await process_frame;await process_frame;quit()

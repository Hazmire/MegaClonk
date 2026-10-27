extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func capture(name: String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/images/stage-swarms/"+name+".png");print("CAPTURE "+name)
func camera_at(position: Vector3,target: Vector3) -> Camera3D:
 var camera=Camera3D.new();game.world.add_child(camera);camera.position=position;camera.look_at(target);camera.current=true;return camera
func run():
 DirAccess.make_dir_recursive_absolute("res://docs/images/stage-swarms")
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.invincible=true;game.settings.focus_pause=false;game.next_run_seed=42;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
 for stage in [1,2,3]:
  game.stage=stage;game.build_stage();game.mode="pause";game.player.active=false;game.frontend.menu.hide();game.frontend.hud_root.hide();game.notice.hide();game.frontend.stage_intro(stage)
  var origin=game.map_layout.spawn;camera_at(origin+Vector3(5,5,10),origin+Vector3(0,1,-13))
  await create_timer(0.6).timeout;await capture("stage_%d"%stage)
 game.stage=1;game.build_stage();game.mode="pause";game.player.active=false;game.frontend.hud_root.hide();game.notice.hide()
 if is_instance_valid(game.frontend.stage_banner):game.frontend.stage_banner.hide()
 var origin: Vector3=game.map_layout.spawn
 for i in 50:
  var p=origin+Vector3(3+int(i/10)*1.05,0,(i%10-5)*1.05)
  var e=game.spawn_enemy(0,p);e.cooldown=999;e.age=1
 for i in 300:game.update_enemies(1.0/60)
 var peak=0.0
 for e in game.enemies:peak=maxf(peak,e.get("crowd_height",0))
 print("VISIBLE SWARM MAX FOOT LIFT ",peak)
 camera_at(origin+Vector3(-7,6,12),origin+Vector3(3,1,0));await capture("swarm")
 game.enemies.clear();game.enemy_view.begin_frame();game.enemy_view.end_frame();var shrine={};var statue={}
 for object in game.interactables:
  if ShrineCharging.is_shrine(object):shrine=object
  if object.kind=="Boss Statue":statue=object
 game.player.position=shrine.node.position;ShrineCharging.tick(game,shrine,0,4)
 camera_at(shrine.node.position+Vector3(8,5,10),shrine.node.position+Vector3.UP*1.4);await capture("shrine_charging")
 ShrineCharging.tick(game,shrine,0,4);game.combat_fx.tick(1,true);game.update_effects(1);await capture("shrine_complete")
 game.player.position=statue.node.position+Vector3(2,0,0);game.mode="run";game.notice.show();game.update_interactions(0)
 camera_at(statue.node.position+Vector3(5,3,6),statue.node.position+Vector3.UP*1.5);await capture("boss_statue")
 game.additional_boss_count=2;game.activate_portal();BossEncounters.tick(game,0.1)
 for e in game.enemies:e.age=2;e.ability_clock=999
 game.update_enemies(0.02);game.update_hud();game.frontend.enter_run();game.player.active=false
 camera_at(game.portal.position+Vector3(13,18,22),game.portal.position+Vector3.UP*2);await capture("multiple_bosses")
 for e in game.enemies.duplicate():
  if e.kind==8:e.hp=0;game.kill_enemy(game.enemies.find(e))
 game.combat_fx.tick(1,true);game.update_effects(1);game.update_enemies(0);game.frontend.hud_root.hide();game.notice.hide()
 var chest: Vector3=game.drop_chests[0].node.position
 camera_at(chest+Vector3(3,2,4),chest+Vector3.UP*0.4);await capture("reward_chest")
 game.queue_free();await process_frame;await process_frame;await process_frame;quit()

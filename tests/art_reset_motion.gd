extends SceneTree
var game: Node
func _initialize():call_deferred("run")
func shot(path: String):
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(path)
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.settings.visual_intensity=1;game.settings.reduced=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause";game.frontend.menu.hide();game.frontend.hud_root.hide();game.notice.hide()
 var wind=game.portal_wind;wind.set_process(false)
 var path=wind.guidance.route(game.map_layout.spawn);var selected=path[0]
 for point in path:
  if absf(point.distance_to(game.portal.position)-40)<absf(selected.distance_to(game.portal.position)-40):selected=point
 game.player.position=selected;var ahead=wind.guidance.waypoint(selected)-selected;ahead.y=0;ahead=ahead.normalized()
 var camera=Camera3D.new();game.world.add_child(camera);camera.position=selected-ahead*7+Vector3.UP*4;camera.look_at(selected+ahead*8+Vector3.UP);camera.current=true
 for i in 90:wind.simulate(1.0/30)
 DirAccess.make_dir_recursive_absolute("/tmp/art-motion")
 for frame in 16:
  for tick in 8:wind.simulate(1.0/30)
  await shot("/tmp/art-motion/frame_%02d.png"%frame)
 var center=game.map_layout.spawn;game.player.position=center;game.player.velocity=Vector3.ZERO;game.mode="run";game.health=100;game.invulnerability=0;game.loadout_runtime.reset("climber","nova");game.player.active=true
 camera.position=center+Vector3(8,6,12);camera.look_at(center+Vector3.UP*2)
 var e=game.spawn_enemy(1,center+Vector3.RIGHT*2);e.variant=OrdinaryRoster.variant(1,0);e.detonated=false;e.damage=10
 EnemySimulation.detonate(game,e)
 for i in 12:await physics_frame;game.combat_fx.tick(1.0/60,true)
 await shot("res://docs/images/art-reset/explosion_launch.png");print("LAUNCH RENDER position=",game.player.position," velocity=",game.player.velocity)
 game.player.active=false;game.player.position=center;game.enemies.clear();game.weapons.clear();game.equip(1);game.equip(2);game.equip(4);game.equip(7)
 for i in 16:
  var target=game.spawn_enemy(-1,center+Vector3(cos(i)*5,0,sin(i)*5));target.hp=100000
 for i in 12:
  game.update_weapons(1.0/60);game.update_projectiles(1.0/60);game.combat_fx.tick(1.0/60,true);game.update_effects(1.0/60);await process_frame
 game.combat_fx.supplied_burst("shatter",center+Vector3(3,0,0),2);game.combat_fx.supplied_burst("debris",center+Vector3(3,0,0),2)
 await create_timer(0.15).timeout;await shot("res://docs/images/art-reset/combat_effects.png")
 game.queue_free();await process_frame;await process_frame;print("ART RESET MOTION COMPLETE");quit()

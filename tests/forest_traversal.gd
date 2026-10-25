extends SceneTree
var errors=[]
var checks=0
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:errors.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.next_run_seed=626;game.begin_run();game.mode="pause";game.player.active=false
 var ramp={}
 for r in game.map_layout.ramps:
  if r.h0!=r.h1:ramp=r;break
 var p0=ramp.rect.get_center();var p1=p0
 if ramp.axis==0:p0.x=ramp.rect.position.x+1;p1.x=ramp.rect.end.x-1
 else:p0.y=ramp.rect.position.y+1;p1.y=ramp.rect.end.y-1
 var low=p0 if ramp.h0<ramp.h1 else p1;var high=p1 if ramp.h0<ramp.h1 else p0
 var player=game.player
 for up in [true,false]:
  var from=low if up else high;var to=high if up else low
  player.position=Vector3(from.x,game.terrain_height(from.x,from.y)+0.05,from.y);player.velocity=Vector3.ZERO
  var direction=Vector3(to.x-from.x,0,to.y-from.y).normalized();player.yaw=atan2(-direction.x,-direction.z)
  await physics_frame
  player.active=true;Input.action_press("forward")
  for i in 220:player._physics_process(1.0/60)
  Input.action_release("forward");player.active=false
  var traveled=Vector2(player.position.x-from.x,player.position.z-from.y).length()
  check(traveled>23,"Player traverses planar ramp "+("up" if up else "down"))
  check(absf(player.position.y-game.terrain_height(player.position.x,player.position.z))<0.3,"Player stays grounded at ramp endpoint")
 player.active=false
 var original=Vector3(low.x,game.terrain_height(low.x,low.y)+0.65,low.y)
 var target=Vector3(high.x,game.terrain_height(high.x,high.y),high.y)
 for reverse in [false,true]:
  var from=original if not reverse else target+Vector3.UP*0.65;var to=target if not reverse else original-Vector3.UP*0.65
  player.position=to;game.forest_navigation.refresh(to);game.enemies.clear()
  var enemy=game.spawn_enemy(0,from);enemy.cooldown=999;enemy.state="move"
  for i in 1200:EnemySimulation.step(game,enemy,1.0/60)
  check(Vector2(enemy.pos.x-to.x,enemy.pos.z-to.z).length()<3,"Enemy pursues across elevation "+("down" if reverse else "up"))
  check(absf(enemy.pos.y-game.terrain_height(enemy.pos.x,enemy.pos.z)-0.65)<0.05,"Enemy stays aligned to collision surface")
 var actor=player.avatar
 for input in ["idle","run","jump","fall","crouch","slide"]:
  for i in 20:actor.animate(input,4,0.0167)
  check(actor.playback.is_playing(),"Ranger plays "+input)
 actor.animate("crouch",0,0.2);actor.rig.force_update_all_bone_transforms()
 check(actor.rig.get_bone_global_pose(actor.rig.find_bone("Head")).origin.y<1,"Crouch is a lowered skeletal pose")
 for model in ["Imp","Puglin"]:
  var a=BestiaryFrames.mesh(model,"enemy_move",0).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
  var b=BestiaryFrames.mesh(model,"enemy_move",4).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
  check(a!=b,"Baked locomotion changes actual mesh vertices: "+model)
 var before=game.decoration_checksum;var previous_world=game.world;game.build_stage();game.player.active=false
 check(game.decoration_checksum==before,"Same seed reproduces decoration transforms")
 await process_frame
 check(not is_instance_valid(previous_world),"Stage rebuild cleans previous world/nav/collision")
 var nav_path=game.forest_navigation.server_path(Vector3.ZERO,game.map_layout.portal)
 check(not nav_path.is_empty() and nav_path[-1].distance_to(game.map_layout.portal)<1,"Godot navigation path reaches elevated portal")
 game.queue_free();await process_frame;await process_frame
 print("FOREST TRAVERSAL RESULT: %d checks, %d failures"%[checks,errors.size()]);quit(0 if errors.is_empty() else 1)

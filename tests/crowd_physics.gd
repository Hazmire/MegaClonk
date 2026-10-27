extends SceneTree
class FlatWorld extends Node:
 var player: BonkPlayer
 var loadout_runtime=LoadoutRuntime.new()
 func terrain_height(_x: float,_z: float) -> float:return 0.0
 func constrain_enemy_motion(_from: Vector3,to: Vector3) -> Vector3:return to
var checks=0
var failures=[]
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func enemy(id: int,p: Vector3) -> Dictionary:
 return {"pos":p,"hp":100,"crowd_id":id,"radius":0.5,"kind":0,"speed":3.0,"scale":1.0,"state":"move","variant":{"modules":["melee"],"visual_scale":1.0},"move_direction":Vector3.LEFT}
func _initialize():call_deferred("run")
func run():
 var world=FlatWorld.new();root.add_child(world);world.player=BonkPlayer.new();world.player.stats=Catalog.base_stats();world.add_child(world.player);await process_frame
 var crowd=CrowdPhysics.new();var one=enemy(1,Vector3(0,0.65,0));crowd.rebuild([one]);world.player.position=Vector3(-2,0,0)
 var filtered=crowd.player_velocity(world,Vector3(20,0,0),0.2)
 check(world.player.position.x+filtered.x*0.2<=-0.83,"Swept player capsule cannot tunnel through an enemy")
 world.loadout_runtime.ultimate_id="ghost";world.loadout_runtime.remaining=3
 check(crowd.player_velocity(world,Vector3(20,0,0),0.2).x==20,"Ghost form still phases through enemy bodies")
 world.loadout_runtime.remaining=0;world.player.position=Vector3(0,10,0)
 check(crowd.player_velocity(world,Vector3(20,0,0),0.2).x==20,"Vertical separation permits jumping over bodies")
 world.player.position=Vector3.ZERO
 var enemies=[]
 for i in 50:enemies.append(enemy(i+1,Vector3(2+int(i/10)*1.05,0.65,(i%10-5)*1.05)))
 var peak=0.0
 for tick in 240:
  crowd.rebuild(enemies)
  for e in enemies:
   crowd.prepare(e);var direction=-Vector3(e.pos.x,0,e.pos.z).normalized();e.move_direction=direction;e.pos+=direction*0.045
   crowd.resolve(world,e,1.0/60);peak=maxf(peak,e.get("crowd_height",0))
 check(peak>0.7,"Dense pursuit creates actual supported vertical crowd climbing")
 check(enemies.all(func(e):return e.pos.is_finite() and e.crowd_height>=0 and e.crowd_height<=2.801),"Crowd stacking is finite and capped rather than an endless tower")
 check(world.player.position==Vector3.ZERO,"Crowd pressure cannot launch or teleport the player")
 # Unsupported bodies return to the floor under a bounded fall rate.
 var raised=enemy(100,Vector3(6,0.65,0));raised.crowd_height=2.8;raised.pos.y+=2.8
 for i in 60:
  crowd.rebuild([raised]);crowd.prepare(raised);crowd.resolve(world,raised,1.0/60)
 check(raised.crowd_height==0 and is_equal_approx(raised.pos.y,0.65),"Unsupported crowd bodies settle back onto terrain")
 var reports=[]
 for count in [50,100,250,500]:
  enemies.clear()
  for i in count:enemies.append(enemy(i+1,Vector3(4+int(i/20)*1.1,0.65,(i%20-10)*1.1)))
  var times=[];var max_checks=0
  for frame in 90:
   var started=Time.get_ticks_usec();crowd.rebuild(enemies)
   for e in enemies:
    crowd.prepare(e);e.move_direction=-Vector3(e.pos.x,0,e.pos.z).normalized();e.pos+=e.move_direction*0.03;crowd.resolve(world,e,1.0/60)
   times.append((Time.get_ticks_usec()-started)/1000.0);max_checks=maxi(max_checks,crowd.checks)
  var sum=0.0
  for time in times:sum+=time
  reports.append({"enemies":count,"crowd_ms_mean":sum/times.size(),"crowd_ms_worst":times.max(),"max_broadphase_candidates":max_checks})
  check(max_checks<=count*CrowdPhysics.SETTINGS.crowd_neighbour_budget*4+count,"Local crowd work has a fixed per-agent inspection budget: "+str(count))
 print("CROWD PROFILE: "+JSON.stringify(reports))
 world.queue_free();await process_frame;await process_frame
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.invincible=true;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false)
 var start: Vector3=game.player.position;var blocker=game.spawn_enemy(0,start+Vector3(0,0,-2));blocker.pos=start+Vector3(0,0.65,-2);game.crowd.rebuild(game.enemies)
 Input.action_press("forward")
 for i in 60:await physics_frame
 check(game.player.position.z>=blocker.pos.z+0.80,"Actual CharacterBody movement is physically obstructed by an enemy")
 game.loadout_runtime.ultimate_id="ghost";game.loadout_runtime.remaining=3
 for i in 24:await physics_frame
 Input.action_release("forward")
 check(game.player.position.z<blocker.pos.z-0.5,"Actual Ghost Form movement can phase through the same body")
 game.queue_free();await process_frame;await process_frame
 print("CROWD PHYSICS: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

extends SceneTree
var failures=[]
var checks=0
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();await process_frame;game.set_physics_process(false);game.player.active=false;game.mode="pause"
 var shrines=[]
 for object in game.interactables:
  if ShrineCharging.is_shrine(object):shrines.append(object)
 check(shrines.size()>=3 and game.shrine_orbs.multimesh.instance_count==shrines.size(),"All shrine types share one visible instanced orb batch")
 var probe=shrines[-1];game.player.position=probe.node.position;game.weapons.clear();game.settings.invincible=true
 var nearby=game.spawn_enemy(0,probe.node.position+Vector3(3,0,0));game.mode="run";game._physics_process(0.1)
 check(not nearby.is_empty() and probe.charge>0 and not Input.is_action_pressed("interact"),"Real gameplay charges a shrine automatically with an enemy nearby")
 game.mode="pause";probe.charge=0

 for object in shrines.slice(0,3):
  var before=game.stats.duplicate();game.player.position=object.node.position
  ShrineCharging.tick(game,object,0,3)
  check(object.charge==3 and not object.used,"Proximity begins charging without an interaction key")
  ShrineCharging.tick(game,object,6,2)
  check(is_equal_approx(object.charge,0.6) and not object.used,"Leaving the 5m orb decays fifteen percentage points per second")
  ShrineCharging.tick(game,object,0,4)
  check(is_equal_approx(object.charge,4.6) and not object.used,"Returning continues prior progress")
  ShrineCharging.tick(game,object,0,3.4)
  game.mode="loading";ShrineRewards.present_next(game)
  check(game.stats==before and game.active_shrine_reward.choices.size()==3,"Completion fixes three choices and grants nothing before selection")
  ShrineRewards.select(game,0);game.mode="pause"
  var modified=[]
  for key in game.stats:
   if game.stats[key]!=before[key]:modified.append(key)
  check(object.used and object.charge==8 and modified.size()==1 and modified[0] in game.stats,"Eight accumulated seconds and a selection grant exactly one actual stat upgrade")
  var earned=game.stats.duplicate();ShrineCharging.tick(game,object,0,20)
  check(game.stats==earned,"Completed shrine cannot be farmed")
  check(object.node.get_node("ChargeProgress").text.ends_with("COMPLETE"),"Completed shrine switches its progress display to complete")
 var pending=shrines[-1];pending.charge=3.5
 check(game.save_run("user://shrines-test.json") and game.load_run("user://shrines-test.json"),"Partial and completed shrines save/load")
 var completed=0;var retained=false
 for object in game.interactables:
  if ShrineCharging.is_shrine(object):
   if object.used:completed+=1
   if is_equal_approx(object.charge,3.5):retained=true
 check(completed==3 and retained,"Save retains independent shrine progress and exactly-once completion")
 game.queue_free();await process_frame;await process_frame
 print("SHRINE CHARGING: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

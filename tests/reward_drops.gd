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
 var count=game.items.size();var before=game.drop_chests.size()
 for kind in [13,9,10,8]:
  var enemy=game.spawn_enemy(kind,game.player.position+Vector3(6,0,0));var index=game.enemies.find(enemy);game.kill_enemy(index)
  check(enemy.chest_dropped and game.drop_chests.size()==before+1,"Defeated elite/miniboss/boss creates one free chest: "+str(kind));before+=1
  check(not RewardDrops.from_enemy(game,enemy) and game.drop_chests.size()==before,"Repeated death cannot duplicate its chest")
 check(game.items.size()==count,"Death does not grant an unseen immediate item before pickup")
 check(game.drop_chests.all(func(drop):return game.forest_navigation.reachable(drop.node.position) and absf(drop.node.position.y-game.terrain_height(drop.node.position.x,drop.node.position.z)-0.05)<0.01),"Dropped chests rest on reachable terrain")
 var next_id=game.crowd.next_id
 check(game.save_run("user://drops-ground.json"),"Uncollected chest checkpoint saves")
 game.begin_run()
 check(game.load_run("user://drops-ground.json") and game.drop_chests.size()==4 and game.crowd.next_id>=next_id,"Uncollected chests and non-reused enemy IDs survive a fresh run/load")
 game.mode="run";game.gold=0
 for drop in game.drop_chests:drop.node.position=game.player.position
 RewardDrops.collect(game)
 check(game.drop_chests.is_empty() and game.mode=="reward" and game.reward_queue.size()==3 and game.active_reward>=0,"Multiple touch pickups queue one roulette at a time without E")
 check(game.gold==0 and game.items.size()==count+1,"First free chest awards once and costs no gold")
 var expected=game.items.duplicate();var active=game.active_reward
 check(game.save_run("user://drops-active.json") and game.load_run("user://drops-active.json"),"Active roulette and queued rewards save/load")
 check(game.active_reward==active and game.items==expected and game.reward_queue.size()==3 and game.mode=="reward","Loading reopens the active reveal without awarding it twice")
 for i in 4:game.resume()
 check(game.mode=="run" and game.active_reward==-1 and game.reward_queue.is_empty() and game.items.size()==count+4,"All queued rewards grant exactly once then resume gameplay")
 game.resume();check(game.items.size()==count+4,"Repeated resume cannot duplicate an exhausted reward queue")
 var ordinary=game.spawn_enemy(0,game.player.position+Vector3(6,0,0));check(not RewardDrops.from_enemy(game,ordinary),"Ordinary kills retain XP and do not produce guaranteed reward chests")

 var free_node=Node3D.new();game.world.add_child(free_node);free_node.position=game.player.position
 var free={"node":free_node,"kind":"Free Chest","used":false,"charge":0.0};game.interactables.append(free)
 var price=game.chest_cost();var items_before=game.items.size();game.update_interactions(0)
 check(free.used and game.items.size()==items_before+1 and game.gold==0,"Rare world chests also collect automatically without payment")
 check(game.chest_cost()==price,"Free chests do not inflate the paid chest price")
 game.resume()
 game.queue_free();await process_frame;await process_frame
 print("REWARD DROPS: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

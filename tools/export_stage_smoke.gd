extends SceneTree
func _initialize():call_deferred("run")
func require(value: bool,message: String) -> bool:
 if not value:push_error(message);quit(1)
 return value
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.invincible=true;game.map_seed_override=9;game.next_run_seed=923;game.begin_run();game.set_physics_process(false);game.player.active=false
 for number in [1,2,3]:
  game.stage=number;game.build_stage();await process_frame
  if not require(ForestAtmosphere.floor_material().get_shader_parameter("moss_high")==StageThemes.config(number).moss_high,"Compiled stage theme did not apply"):return
  var counts={}
  for object in game.interactables:counts[object.kind]=int(counts.get(object.kind,0))+1
  if not require(counts.get("Chest",0)>=15 and counts.get("Shop",0)>=3 and counts.get("Elite Statue",0)>=2 and counts.get("Boss Statue",0)>=1,"Compiled world omitted required objects"):return
 game.mode="run";var shrine={};var statue={}
 for object in game.interactables:
  if ShrineCharging.is_shrine(object):shrine=object
  if object.kind=="Boss Statue":statue=object
 game.player.position=shrine.node.position;ShrineCharging.tick(game,shrine,0,8)
 if not require(shrine.used and game.active_shrine_reward.get("choices",[]).size()==3,"Compiled shrine did not offer three fixed stats"):return
 ShrineRewards.select(game,0)
 game.activate_boss_statue(statue);game.activate_portal();BossEncounters.tick(game,0.1)
 var bosses=[]
 for e in game.enemies:
  if e.kind==8:bosses.append(e)
 if not require(bosses.size()==2,"Compiled multiplier did not create two bosses"):return
 game.kill_enemy(game.enemies.find(bosses[0]))
 if not require(not game.boss_dead,"Compiled encounter completed after the first boss"):return
 game.kill_enemy(game.enemies.find(bosses[1]))
 if not require(game.boss_dead and game.drop_chests.size()==2,"Compiled boss death/chest accounting failed"):return
 for drop in game.drop_chests:drop.node.position=game.player.position
 game.mode="run";RewardDrops.collect(game);await process_frame
 var granted=game.items.size()
 game.save_run("user://export-stage-smoke.json");game.load_run("user://export-stage-smoke.json");await process_frame
 if not require(game.items.size()==granted and game.reward_queue.size()==1,"Compiled active reward duplicated or lost its queue on load"):return
 game.resume();game.resume();await process_frame
 if not require(game.items.size()==granted+1 and game.active_reward==-1,"Compiled queued chest did not grant exactly once"):return
 game.queue_free();await process_frame;await process_frame
 print("EXPORTED STAGE SWARMS SMOKE COMPLETE");quit()

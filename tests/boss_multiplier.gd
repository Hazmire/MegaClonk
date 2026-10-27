extends SceneTree
var checks=0
var failures=[]
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();await process_frame;game.set_physics_process(false);game.player.active=false;game.mode="pause"
 check(game.additional_boss_count==0,"New run starts without additional bosses")
 var statue={}
 for object in game.interactables:
  if object.kind=="Boss Statue":statue=object;break
 check(not statue.is_empty() and game.forest_navigation.reachable(statue.node.position),"A reachable distinctive boss statue is generated")
 game.player.position=statue.node.position;Input.action_press("interact");game.update_interactions(0);Input.action_release("interact")
 check(statue.used and game.additional_boss_count==1,"Existing interact action activates the boss statue")
 check(not game.activate_boss_statue(statue) and game.additional_boss_count==1,"Boss statue activates exactly once")
 game.stage_event("miniboss_1");var mini=game.boss_encounters[str(game.stage)+":miniboss_1"]
 check(mini.required==2 and mini.members.size()==2,"Boss modifier increases the timed miniboss encounter")
 var before=game.enemies.size();game.stage_event("miniboss_1")
 check(game.enemies.size()==before,"Repeated timed encounter cannot duplicate its bosses")
 game.create_boss_statue(game.player.position+Vector3(4,0,0));game.activate_boss_statue(game.interactables[-1])
 check(game.additional_boss_count==2 and mini.required==2,"Activating during combat affects future encounters only")
 check(game.activate_portal(),"Portal starts the multiplied main encounter")
 BossEncounters.tick(game,0.1);var main=game.boss_encounters[str(game.stage)+":stage"]
 check(main.required==3 and main.members.size()==3 and main.pending.is_empty(),"Main encounter spawns one plus the current modifier")
 var main_bosses=[];var configs={}
 for e in game.enemies:
  configs[str(e.crowd_id)]=e.encounter
  if e.kind==8:main_bosses.append(e)
 var separate=true
 for i in main_bosses.size():
  for j in range(i+1,main_bosses.size()):
   if Vector2(main_bosses[i].pos.x-main_bosses[j].pos.x,main_bosses[i].pos.z-main_bosses[j].pos.z).length()<4:separate=false
 check(separate and main_bosses.all(func(e):return game.forest_navigation.reachable(e.pos)),"Multiple bosses use separate valid reachable locations")
 check(not game.activate_portal(),"Active main encounter cannot be summoned twice")
 game.frontend.update_boss_bars();check(game.frontend.boss_widgets.size()==4,"Five bosses use a bounded compact four-row health display")
 check(game.save_run("user://multiboss.json") and game.load_run("user://multiboss.json"),"Boss modifier and active encounters save/load")
 var restored=true;main_bosses=[]
 for e in game.enemies:
  if configs.get(str(e.crowd_id),"")!=e.encounter or e.variant.id!=e.encounter:restored=false
  if e.kind==8:main_bosses.append(e)
 check(restored and game.additional_boss_count==2,"Loading restores each boss's actual variant and run modifier")
 for i in main_bosses.size():
  var e=main_bosses[i];e.hp=0;game.kill_enemy(game.enemies.find(e))
  if i<2:check(not game.boss_dead and game.portal_state=="summoned","A partial main-boss defeat cannot unlock the portal")
 check(game.boss_dead and game.portal_state=="exit" and game.drop_chests.size()==3,"Last stage boss opens the portal; each drops a free chest")
 for e in game.enemies.duplicate():
  if e.kind in [9,10]:e.hp=0;game.kill_enemy(game.enemies.find(e))
 check(game.drop_chests.size()==5 and game.boss_encounters["1:miniboss_1"].complete,"Each miniboss also drops one chest and its encounter completes")
 check(game.advance_stage() and game.additional_boss_count==2 and game.stage==2,"Boss modifier persists across stage transitions")
 # Independent variant rolls can produce mixed main encounters.
 var mixed=false
 for seed in 12:
  game.enemies.clear();game.boss_encounters.clear();game.run_seed=seed
  var group=BossEncounters.start(game,"sample",true,game.map_layout.portal);BossEncounters.tick(game,0.1);var types={}
  for e in game.enemies:types[e.encounter]=true
  mixed=mixed or types.size()>1
 check(mixed,"Independent boss variant rolls permit mixed Chunkus/Golem encounters")
 game.enemies.clear();game.boss_encounters.clear()
 var golems=[]
 for i in 3:
  var e=game.spawn_enemy(8,game.map_layout.spawn+Vector3(i*7,0,-12));Encounters.initialize(game,e,"rock_golem");golems.append(e)
 for tick in 6:
  for boss in golems:boss.ability_clock=0;Encounters.step(game,boss,0.01)
 var living=[];var owners={}
 for e in game.enemies:
  if e.get("encounter","")=="lesser_golem" and e.hp>0:living.append(e);owners[e.summon_owner]=int(owners.get(e.summon_owner,0))+1
 check(living.size()==24 and owners.size()>=2 and owners.values().all(func(value):return value<=12),"Golems retain abilities with distinct owners, twelve each and twenty-four globally")
 var doomed=golems[0];game.kill_enemy(game.enemies.find(doomed));var own_living=0;var other_living=0
 for e in living:
  if e.hp>0:
   if e.summon_owner==doomed.owner_key:own_living+=1
   else:other_living+=1
 check(own_living==0 and other_living>0,"One golem's death cleans only its own summons")
 # Capacity does not silently omit required bosses: pending members remain counted.
 game.enemies.clear();game.boss_encounters.clear()
 for i in 500:game.enemies.append({"hp":1,"kind":0,"pos":game.map_layout.spawn+Vector3(10,0,0),"radius":0.5})
 var pending=BossEncounters.start(game,"capacity",true,game.map_layout.portal)
 check(pending.required==3 and pending.pending.size()==3 and pending.remaining==3,"Full enemy capacity queues all required bosses without dropping them")
 game.enemies.resize(499);BossEncounters.tick(game,0.1)
 check(pending.members.size()==1 and pending.pending.size()==2 and pending.remaining==3,"Freed capacity admits pending bosses without completing the encounter")
 game.enemies.clear();game.boss_encounters.clear();game.begin_run();check(game.additional_boss_count==0,"Beginning a new run resets the boss modifier")
 game.queue_free();await process_frame;await process_frame
 print("BOSS MULTIPLIER: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

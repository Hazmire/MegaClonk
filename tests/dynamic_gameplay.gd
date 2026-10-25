extends SceneTree
var checks=0
var failures=[]
var game: Node
func verify(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress.storage_path="user://dynamic-test-profile.json";game.next_run_seed=42;game.map_seed_override=9;game.begin_run();game.mode="pause";game.player.active=false;game.settings.invincible=false
 await physics_frame;await physics_frame
 verify(game.player.position.distance_to(game.map_layout.spawn)<0.5,"Player starts at deterministic peripheral spawn")
 verify(OrdinaryRoster.variant(0,0).health==OrdinaryRoster.variant(0,1).health and OrdinaryRoster.variant(0,0).speed==OrdinaryRoster.variant(0,1).speed and OrdinaryRoster.variant(0,0).damage==OrdinaryRoster.variant(0,1).damage,"Goblin and Skeleton share identical gameplay stats")
 verify(OrdinaryRoster.variant(0,0).model!=OrdinaryRoster.variant(0,1).model,"Basic variants use different geometry")
 var random=RandomNumberGenerator.new();random.seed=123;var counts=[0,0,0]
 for i in 10000:counts[OrdinaryRoster.choose(random)]+=1
 verify(absf(counts[0]/10000.0-0.75)<0.02 and absf(counts[1]/10000.0-0.2)<0.02 and absf(counts[2]/10000.0-0.05)<0.01,"Seeded ordinary weighting is 75/20/5")
 game.enemies.clear();var basics={};var specials={}
 for i in 40:
  basics[game.spawn_enemy(0,Vector3.ZERO).variant.id]=true;specials[game.spawn_enemy(1,Vector3.ZERO).variant.id]=true
 verify(basics.size()==2 and specials.size()==2,"Variants are selected independently per spawn")
 var large=game.spawn_enemy(2,Vector3.ZERO)
 verify(large.hp>=250 and large.speed==1.8 and large.radius>1 and large.variant.visual_scale==2,"Large enemy has matching high health and physical hit radius")
 var first=game.enemies[0];game.player.position=Vector3(7,0,0);var before=first.pos;EnemySimulation.step(game,first,0.1)
 verify(first.pos.distance_to(before)>0.1 and first.age==0,"AI moves while visual emergence is still active")
 game.enemy_view.begin_frame();game.enemy_view.draw_enemy(first,game.player.position);game.enemy_view.end_frame()
 var batch=game.enemy_view.batches[first.variant.visual_model+"enemy_move0"].multimesh
 verify(game.enemy_view.last_transforms[first.variant.id].origin.y<first.pos.y-1,"Spawn model begins below its active entity")
 game.enemies.clear();game.player.position=Vector3.ZERO;game.health=100;game.invulnerability=0
 var bug=game.spawn_enemy(1,Vector3(1,0,0));bug.variant=OrdinaryRoster.variant(1,0);bug.damage=20;bug.cooldown=0
 EnemySimulation.step(game,bug,0.01)
 verify(bug.action=="explode" and bug.windup==0.6 and bug.hp>0,"Bug begins a visible 0.6 second warning")
 verify(game.health==100,"Bug warning deals no early damage")
 EnemySimulation.step(game,bug,0.61)
 verify(bug.detonated and bug.hp==0 and game.health<100,"Bug explosion damages and destroys itself")
 var health=game.health;EnemySimulation.detonate(game,bug);verify(game.health==health,"Bug cannot detonate twice")
 game.enemies.clear()
 var persistent=game.spawn_enemy(0,Vector3(4,0,0));persistent.variant=OrdinaryRoster.variant(0,1);persistent.roster_choice="skeleton"
 var saved_choice=persistent.roster_choice;var saved_rng=str(game.spawn_rng.state)
 verify(game.save_run("user://dynamic-choices.json") and game.load_run("user://dynamic-choices.json"),"Per-spawn roster checkpoint reloads")
 game.mode="pause";game.player.active=false
 verify(game.enemies[0].variant.id==saved_choice and str(game.spawn_rng.state)==saved_rng,"Checkpoint preserves exact visual choice and dedicated spawn RNG")
 game.enemies.clear();game.health=100;game.invulnerability=0;game.player.position=Vector3.ZERO
 var boss=game.spawn_enemy(8,Vector3(12,0,0));Encounters.initialize(game,boss,"chunkus");boss.ability_clock=0.01
 game.frontend.update_boss_bars();verify(game.frontend.boss_widgets[0].label.text.contains("Big Chunkus"),"Chunkus name and health appear on boss UI")
 verify(not game.activate_portal(),"Portal refuses a duplicate active main boss")
 Encounters.step(game,boss,0.02);var captured=boss.target
 verify(boss.aoe_remaining==1.5 and boss.ability_clock>9.9,"Chunkus captures a 1.5 second AOE on ten second cadence")
 verify(game.health==100,"Chunkus warning does not damage early")
 game.player.position=Vector3(10,0,10);Encounters.step(game,boss,1.0)
 verify(boss.target==captured,"Chunkus AOE stays at original cast position")
 Encounters.step(game,boss,0.51);verify(game.health==100,"Player can escape Chunkus AOE")
 boss.ability_clock=0;game.player.position=Vector3.ZERO;game.invulnerability=0;Encounters.step(game,boss,0.01);Encounters.step(game,boss,1.51)
 verify(game.health==60,"Chunkus deals configured forty damage at detonation")
 boss.hp=0;game.kill_enemy(game.enemies.find(boss));verify(game.boss_dead and game.portal_state=="exit","New boss death preserves portal progression")
 game.enemies.clear();boss=game.spawn_enemy(8,Vector3(15,0,0));Encounters.initialize(game,boss,"rock_golem")
 game.frontend.update_boss_bars();verify(game.frontend.boss_widgets[0].label.text.contains("Rock Golem"),"Rock Golem name appears on boss UI")
 for wave in 6:boss.ability_clock=0;Encounters.step(game,boss,0.01)
 verify(boss.ability_clock>11.9,"Rock Golem resets a twelve-second summon cadence")
 var summoned=[]
 for enemy in game.enemies:
  if enemy.has("summon_owner"):summoned.append(enemy)
 verify(summoned.size()==12,"Golem active summon cap is exactly twelve")
 verify(summoned[0].speed>boss.speed and summoned[0].max_hp<boss.max_hp and summoned[0].scale<boss.scale,"Lesser golems are weaker faster and visibly smaller")
 boss.hp=0;game.kill_enemy(game.enemies.find(boss))
 var living=0
 for enemy in summoned:
  if enemy.hp>0:living+=1
 verify(living==0,"Golem death cleans up owned summons")
 game.enemies.clear();var statue={}
 for object in game.interactables:
  if object.kind=="Elite Statue":statue=object
 verify(not statue.is_empty() and game.forest_navigation.reachable(statue.node.position),"One reachable elite statue is generated")
 game.player.position=statue.node.position
 game.update_interactions(0.01);verify(game.notice.text.contains("summon Elite Enemies"),"Elite statue exposes its actual interaction prompt independently of portal")
 verify(game.activate_elite_statue(statue),"Elite statue activates")
 verify(game.enemies.size()==3 and game.enemies[0].elite and game.enemies[0].variant.visual_model=="Knight","Statue creates three distinct-model marked elites")
 verify(not game.activate_elite_statue(statue),"Statue cannot reactivate")
 game.enemy_view.begin_frame()
 for e in game.enemies:game.enemy_view.draw_enemy(e,game.player.position)
 game.enemy_view.end_frame();verify(game.enemy_view.batches.elite_emblems.multimesh.visible_instance_count==3,"Elite emblems render for all three elites")
 verify(game.save_run("user://dynamic-elites.json") and game.load_run("user://dynamic-elites.json"),"Active elite encounter checkpoint reloads")
 game.mode="pause";game.player.active=false
 verify(game.elite_active and game.enemies.size()==3 and game.enemies[0].elite,"Active elite group and one-use statue survive reload")
 var gold=game.gold
 while not game.enemies.is_empty():game.enemies[0].hp=0;game.kill_enemy(0)
 verify(game.elite_rewarded and game.gold>=gold+90,"Final elite awards exactly-once encounter gold")
 var rewarded=game.gold;verify(not game.activate_elite_statue(statue) and game.gold==rewarded,"Completed encounter cannot be farmed")
 verify(game.save_run("user://dynamic-test-run.json") and game.load_run("user://dynamic-test-run.json"),"New encounter state saves and reloads")
 game.mode="pause";game.player.active=false
 verify(game.elite_rewarded and not game.elite_active,"Elite completion survives save/load")
 # Select an actual vertical terrain edge with safe flat lower/upper landing.
 await physics_frame;await physics_frame
 var sample={}
 for index in game.map_layout.planes.size():
  var x=-95+(index%96)*2;var z=-95+int(index/96)*2
  if maxf(absf(x),absf(z))>85:continue
  for dir in [Vector3.RIGHT,Vector3.BACK]:
   var lo=Vector3(x,game.terrain_height(x,z)+0.65,z);var hi=lo+dir*3;hi.y=game.terrain_height(hi.x,hi.z)+0.65
   if hi.y-lo.y<5:continue
   var good=true
   for point in [lo-dir,hi,hi+dir*2]:
    if game.forest_navigation.blocked.has(ForestMap.index(point.x,point.z)) or ForestMap.normal(game.stage_map_seed(),point.x,point.z).dot(Vector3.UP)<0.999:good=false
   if good:sample={"low":lo,"high":hi+dir*3};break
  if not sample.is_empty():break
 verify(not sample.is_empty(),"Climbing test locates a real procedural cliff")
 if not sample.is_empty():
  game.enemies.clear();game.player.position=sample.high;var climber=game.spawn_enemy(0,sample.low);climber.cooldown=999
  var climbed=false
  for i in 900:
   EnemySimulation.step(game,climber,1.0/60)
   if not climber.get("climb",{}).is_empty():climbed=true
  verify(climbed,"Enemy detects a real cliff and begins climbing")
  verify(climber.pos.y>sample.low.y+4 and climber.pos.distance_to(game.player.position+Vector3.UP*0.65)<3,"Enemy reaches upper landing and resumes pursuit")
  verify(climber.get("climb",{}).is_empty(),"Enemy does not remain suspended at cliff top")
  climber.pos=Vector3(94,game.terrain_height(94,0)+0.65,0);game.player.position=Vector3(110,40,0)
  for i in 100:EnemySimulation.step(game,climber,0.02)
  verify(absf(climber.pos.x)<=94 and climber.get("climb",{}).is_empty(),"Enemy cannot climb the outer boundary")
 var actor=game.player.avatar;actor.animate("run",RangerStride.METRES_PER_SECOND,0.2)
 verify(is_equal_approx(actor.playback.speed_scale,1),"Ranger stride rate matches calibrated actual velocity")
 var clip=actor.playback.get_animation("move");verify(clip.length==RangerStride.LENGTH and clip.get_track_count()>=65,"Ranger locomotion animates the actual full skeleton")
 var max_foot_error=0.0
 actor.playback.play("move",0)
 for frame in 20:
  var phase=float(frame)/20*RangerStride.STANCE
  actor.playback.seek(phase*RangerStride.LENGTH,true);actor.playback.advance(0);actor.rig.force_update_all_bone_transforms()
  var bone=actor.rig.find_bone("foot_l")
  max_foot_error=maxf(max_foot_error,absf(actor.rig.get_bone_global_pose(bone).origin.y-actor.rig.get_bone_global_rest(bone).origin.y))
 verify(max_foot_error<0.025,"Stance ankle remains planted within 2.5 cm across the actual skeletal cycle")
 game.enemies.clear();game.player.position=game.map_layout.spawn;game.settings.invincible=true
 for i in 400:game.spawn_enemy()
 BestiaryFrames.prewarm()
 for i in 10:game.update_enemies(1.0/60);game.rebuild_grid()
 var started=Time.get_ticks_usec()
 for i in 120:game.update_enemies(1.0/60);game.rebuild_grid()
 print("DYNAMIC BENCHMARK 400 ordinary enemies: %.2f ms/tick, headless simulation and spatial rebuild"%((Time.get_ticks_usec()-started)/120000.0))
 verify(game.enemies.size()==400,"400 new-roster enemies remain active during benchmark")
 game.queue_free();await process_frame;await process_frame
 print("DYNAMIC RESULT: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

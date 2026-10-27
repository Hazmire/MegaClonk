extends SceneTree
var game: Node
var rendered=false
var result={}
func _initialize():call_deferred("run")
func summary(samples: Array) -> Dictionary:
 var sum=0.0
 for sample in samples:sum+=sample
 var ordered=samples.duplicate();ordered.sort()
 return {"mean_ms":sum/samples.size(),"worst_ms":ordered[-1],"p95_ms":ordered[int((ordered.size()-1)*0.95)]}
func clear_case():
 game.enemies.clear();game.crowd.buckets.clear();game.boss_encounters.clear();game.reward_queue.clear();game.active_reward=-1
 for drop in game.drop_chests:game.pool.release(drop.node)
 game.drop_chests.clear()
 for effect in game.effects:
  if effect.node.has_meta("pool_key"):game.pool.release(effect.node)
  else:effect.node.queue_free()
 game.effects.clear();game.projectiles.clear();game.fields.clear();game.weapons.clear()
 game.mode="run";game.frontend.enter_run();game.player.active=false
func step():
 game.update_enemies(1.0/60);game.rebuild_grid();game.combat_fx.tick(1.0/60,true);game.update_effects(1.0/60);game.update_hud();game.portal_wind._process(1.0/60)
func measure(frames: int) -> Dictionary:
 var cpu=[];var frame=[]
 for i in frames:
  var began=Time.get_ticks_usec();step();cpu.append((Time.get_ticks_usec()-began)/1000.0)
  if rendered:await process_frame;await RenderingServer.frame_post_draw
  frame.append((Time.get_ticks_usec()-began)/1000.0)
 return {"cpu":summary(cpu),"viewport_frame":summary(frame),"rendered":rendered}
func run():
 rendered=DisplayServer.get_name()!="headless"
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.invincible=true;game.settings.focus_pause=false;game.settings.fps=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.portal_wind.set_process(false)
 var setup=[]
 for stage in [1,2,3]:
  game.stage=stage;var began=Time.get_ticks_usec();game.build_stage();game.portal_wind.set_process(false);setup.append({"stage":stage,"ms":(Time.get_ticks_usec()-began)/1000.0})
 var center=game.map_layout.spawn
 for candidate in ForestPlacement.candidates(game.map_layout):
  var valid=true
  for i in 16:
   var p=candidate+Vector3(cos(i*TAU/16),0,sin(i*TAU/16))*20
   if maxf(absf(p.x),absf(p.z))>90 or absf(game.terrain_height(p.x,p.z)-candidate.y)>0.1:valid=false;break
  if valid:center=candidate;break
 game.player.position=center+Vector3.UP*0.02
 var camera=Camera3D.new();game.world.add_child(camera);camera.position=center+Vector3(10,13,17);camera.look_at(center+Vector3.UP);camera.current=true
 if is_instance_valid(game.frontend.stage_banner):game.frontend.stage_banner.hide()
 result={"renderer":DisplayServer.get_name(),"stage_setup":setup,"hardware_limit":"Cloud host; CPU scope AI/contact/crowd/grid/FX/HUD plus ambient/guidance/vortex CPU. Viewport timings include Mesa only when rendered. No native Windows or gaming-GPU FPS proof.","swarms":[]}
 for count in [50,100,250,500]:
  clear_case()
  for i in count:
   var angle=i*2.39996;var p=center+Vector3(cos(angle),0,sin(angle))*(4+float(i%10)*0.55)
   var e=game.spawn_enemy(-1,p)
   if not e.is_empty():e.hp=1000000;e.max_hp=e.hp;e.cooldown=999;e.age=1
  for i in 45:step()
  if rendered:await process_frame;await RenderingServer.frame_post_draw
  var metrics=await measure(12 if rendered else 120);metrics.enemies=game.enemies.size();metrics.requested=count
  result.swarms.append(metrics);print("SWARM PROFILE "+JSON.stringify(metrics))
 clear_case()
 for id in [1,2,4,7]:game.equip(id)
 for i in 80:game.spawn_enemy(-1,center+Vector3(cos(i)*12,0,sin(i)*12))
 for i in 60:
  game.update_weapons(1.0/60);game.update_projectiles(1.0/60);step()
 var weapon_cpu=[]
 for i in 120:
  var began=Time.get_ticks_usec();game.update_weapons(1.0/60);game.update_projectiles(1.0/60);step();weapon_cpu.append((Time.get_ticks_usec()-began)/1000.0)
 result.four_weapons=summary(weapon_cpu);result.four_weapons.active=game.weapons.size()
 clear_case();game.additional_boss_count=7
 var group=BossEncounters.start(game,"profile",true,game.map_layout.portal)
 for i in 12:BossEncounters.tick(game,0.5)
 for e in game.enemies:e.ability_clock=0;e.cooldown=0
 result.multiboss=await measure(18 if rendered else 180);result.multiboss.bosses=group.spawned;result.multiboss.pending=group.pending.size()
 var minions=0
 for e in game.enemies:
  if e.get("encounter","")=="lesser_golem" and e.hp>0:minions+=1
 result.multiboss.lesser_golems=minions
 clear_case();var drops=[]
 for i in 25:
  var e=game.spawn_enemy(13,center+Vector3(7,0,0));var began=Time.get_ticks_usec();game.kill_enemy(game.enemies.find(e));drops.append((Time.get_ticks_usec()-began)/1000.0)
 result.chest_death=summary(drops);result.chest_death.chests=game.drop_chests.size()
 for chest in game.drop_chests:chest.node.position=game.player.position
 var began=Time.get_ticks_usec();RewardDrops.collect(game);result.collect_25_and_first_reel_ms=(Time.get_ticks_usec()-began)/1000.0;result.queued_presentations=game.reward_queue.size()+1
 clear_case();var shrine={}
 for object in game.interactables:
  if ShrineCharging.is_shrine(object):shrine=object;break
 game.player.position=shrine.node.position
 var samples=[]
 for i in (12 if rendered else 120):
  began=Time.get_ticks_usec();game.update_interactions(1.0/60);samples.append((Time.get_ticks_usec()-began)/1000.0)
  if rendered:await process_frame;await RenderingServer.frame_post_draw
 result.shrine_interactions_cpu=summary(samples)
 DirAccess.make_dir_recursive_absolute("res://builds")
 var file=FileAccess.open("res://builds/art-reset-profile-"+("rendered" if rendered else "headless")+".json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close();print("STAGE UPDATE PROFILE: "+JSON.stringify(result))
 game.queue_free();await process_frame;await process_frame;await process_frame;quit()

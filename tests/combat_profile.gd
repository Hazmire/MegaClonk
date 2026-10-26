extends SceneTree
var game: Node
var report={}
var rendered=false
var samples=60
func _initialize():call_deferred("run")
func stats(values: Array) -> Dictionary:
 var sorted=values.duplicate();sorted.sort();var total=0.0
 for value in sorted:total+=value
 return {"mean_ms":total/maxi(1,sorted.size()),"p95_ms":sorted[mini(sorted.size()-1,int(sorted.size()*0.95))],"p99_ms":sorted[mini(sorted.size()-1,int(sorted.size()*0.99))],"worst_ms":sorted[-1]}
func clear_case():
 game.enemies.clear();game.projectiles.clear();game.weapons.clear()
 for effect in game.effects:
  if effect.node.has_meta("pool_key"):game.pool.release(effect.node)
  else:effect.node.queue_free()
 game.effects.clear()
 for p in game.pickups:game.pool.release(p.node)
 game.pickups.clear()
 for field in game.fields:field.node.queue_free()
 game.fields.clear()
func fill(count: int,near: bool=false):
 for i in count:
  var angle=float(i)*2.39996;var radius=3+float(i%10)*0.5 if near else 12+float(i%12)*0.4
  var e=game.spawn_enemy(i%3,game.player.position+Vector3(cos(angle),0,sin(angle))*radius)
  e.hp=1000000;e.max_hp=1000000;e.age=1;e.cooldown=999
 game.rebuild_grid()
func run():
 rendered=DisplayServer.get_name()!="headless";samples=40 if rendered else 80
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.map_seed_override=9;game.next_run_seed=1234;game.sandbox=true;game.settings.focus_pause=false;game.settings.invincible=true;game.begin_run();game.mode="pause";Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;game.player.active=false;game.set_physics_process(false)
 for argument in OS.get_cmdline_user_args():
  if argument=="--legacy-terrain":game.terrain_version=3;game.build_stage();game.player.active=false
 var origin=game.map_layout.regions[0].get("anchor",game.map_layout.regions[0].rect.get_center())
 var candidates=ForestPlacement.candidates(game.map_layout)
 for candidate in candidates:
  var clear=true
  for i in 16:
   var point=candidate+Vector3(cos(i*TAU/16),0,sin(i*TAU/16))*18
   if maxf(absf(point.x),absf(point.z))>90 or absf(game.terrain_height(point.x,point.z)-candidate.y)>0.1:clear=false;break
  if clear:origin=Vector2(candidate.x,candidate.z);break
 var center=Vector3(origin.x,game.terrain_height(origin.x,origin.y)+0.02,origin.y);game.player.position=center
 var cam=Camera3D.new();game.world.add_child(cam);cam.position=center+Vector3(8,12,15);cam.look_at(center+Vector3.UP);cam.current=true
 await physics_frame;await physics_frame
 var scenarios=["idle","moving","enemies25","enemies100","enemies250","continuous_weapons","repeated_hits","deaths100","aoe250","boss","elite","grass_off","wind_on","wind_off"]
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--only="):scenarios=scenarios.filter(func(name):return name in arg.trim_prefix("--only=").split(","))
 for name in scenarios:
  clear_case();await process_frame
  if name.begins_with("enemies"):fill(int(name.trim_prefix("enemies")))
  if name in ["continuous_weapons","repeated_hits","deaths100","aoe250"]:fill(250 if name=="aoe250" else 100,true)
  if name=="continuous_weapons":
   for id in [1,4,7,33]:game.equip(id)
  if name=="boss":game.spawn_enemy(8,center+Vector3(10,0,0))
  if name=="elite":
   for i in 3:game.spawn_enemy(13,center+Vector3(i*3,0,-8))
  if name=="grass_off":
   for key in game.prop_batches:
    if 'grass' in str(key).to_lower() or 'Fern' in str(key) or 'Flower' in str(key):game.prop_batches[key].hide()
  if name in ["wind_on","wind_off"]:
   for key in game.prop_batches:
    if str(key).begins_with("wind_grass"):game.prop_batches[key].visible=name=="wind_on"
  var frame=[];var work=[];var hits=[];var deaths=[];var draw=[];var physics=[];var nodes=[];var particles=[];var memory=[];var max_pickups=0;var max_numbers=0
  for step in samples:
   var began=Time.get_ticks_usec();game.elapsed+=1.0/60
   if name=="moving":game.player.position.x=center.x+sin(float(step)*0.03)*3
   game.update_enemies(1.0/60);game.rebuild_grid()
   if name=="continuous_weapons":game.update_weapons(1.0/60);game.update_projectiles(1.0/60);game.update_special_visuals(1.0/60)
   var hit_start=Time.get_ticks_usec()
   if name=="repeated_hits":
    for i in mini(20,game.enemies.size()):game.hit(game.enemies[i],1,7)
   if name in ["deaths100","aoe250"] and step==5:
    for e in game.enemies:game.hit(e,10000000,34)
   hits.append((Time.get_ticks_usec()-hit_start)/1000.0)
   var death_start=Time.get_ticks_usec()
   for i in range(game.enemies.size()-1,-1,-1):
    if game.enemies[i].hp<=0:game.kill_enemy(i)
   deaths.append((Time.get_ticks_usec()-death_start)/1000.0)
   game.update_effects(1.0/60);game.update_pickups(1.0/60);game.combat_fx.tick(1.0/60)
   work.append((Time.get_ticks_usec()-began)/1000.0)
   draw.append(float(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
   physics.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))*1000)
   nodes.append(float(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)));memory.append(float(Performance.get_monitor(Performance.MEMORY_STATIC)))
   particles.append(float(game.combat_fx.active.size()));max_pickups=maxi(max_pickups,game.pickups.size())
   var number_count=0
   for effect in game.effects:
    if effect.node is Label3D:number_count+=1
   if game.get("numbers")!=null:number_count+=game.numbers.active.size()
   max_numbers=maxi(max_numbers,number_count)
   await process_frame
   frame.append((Time.get_ticks_usec()-began)/1000.0)
  report[name]={"frame":stats(frame),"script_work":stats(work),"hit_pipeline":stats(hits),"death_pipeline":stats(deaths),"engine_physics":stats(physics),"draw_calls_peak":draw.max(),"node_peak":nodes.max(),"memory_bytes_peak":memory.max(),"flipbooks_peak":particles.max(),"xp_entities_peak":max_pickups,"damage_numbers_peak":max_numbers,"enemy_count_end":game.enemies.size(),"fps_from_frame_mean":1000.0/maxf(0.01,stats(frame).mean_ms)}
  print("PROFILE ",name," ",JSON.stringify(report[name]))
 var output="res://builds/combat-profile.json"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
 report["context"]={"terrain_version":game.terrain_version,"origin":[center.x,center.y,center.z],"rendered":rendered,"renderer":"Mesa software OpenGL" if rendered else "headless","samples_per_case":samples,"engine":Engine.get_version_info().string,"note":"Frame durations include process-frame scheduling; script_work isolates manually advanced combat. Dummy audio. Physics monitor excludes the manually driven enemy simulation."}
 DirAccess.make_dir_recursive_absolute("res://builds");var file=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 clear_case();game.queue_free();await process_frame;await process_frame;quit()

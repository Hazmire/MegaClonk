extends SceneTree
# Headless CPU profile of the in-run HUD (RunHud) with 500 enemies and the Loadout B stress build from the items report
# (every item x5, four gem-socketed weapons). Measures FrontEnd.update_hud() per frame plus the node count before/after, to show the HUD
# does not rebuild nodes while the build is unchanged. CPU only: the paper-minimap draw and fog shader are GPU/canvas work and not measured.
# Writes builds/hud-perf-profile.json.
var game: Node3D
func _initialize():call_deferred("run")
func summary(samples: Array) -> Dictionary:
 samples.sort();var total=0.0
 for v in samples:total+=v
 return {"avg_ms":snappedf(total/samples.size(),0.001),"p95_ms":snappedf(samples[int(samples.size()*0.95)],0.001),"max_ms":snappedf(samples[-1],0.001)}
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-hud-perf.json"
 game.sandbox=true;game.map_seed_override=9;game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999;await physics_frame;game.mode="run"
 game.items.clear();game.irt.reset();game.weapons.clear()
 for id in Catalog.ITEM_IDS:
  for i in 5:game.grant_item(id,true)
 for id in [0,1,2,7]:game.equip(id)
 for t in Catalog.ACTIVE_TOMES.slice(0,4):game.apply_upgrade({"type":"tome","id":t})
 for element in Elements.IDS:game.gems.add(element,3)
 game.amulets=2
 for count in [0,500]:
  game.enemies.clear()
  for i in count:
   var a=TAU*float(i)/maxi(1,count);var rad=3.0+float(i%7)*1.6
   var e=game.spawn_enemy(0,game.player.position+Vector3(cos(a)*rad,0,sin(a)*rad))
   if not e.is_empty():e.hp=1.0e9;e.max_hp=1.0e9;e.speed=0.0
  game.frontend.update_hud();await process_frame
  var nodes_before=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
  var samples=[];var rebuilds=0;var last_sig=game.frontend.run_hud.build_signature_drawn
  for frame in 600:
   game.kills+=1;game.gold+=1;game.health=maxf(1.0,game.health-0.05)
   var t=Time.get_ticks_usec();game.frontend.update_hud();samples.append((Time.get_ticks_usec()-t)/1000.0)
   if game.frontend.run_hud.build_signature_drawn!=last_sig:rebuilds+=1;last_sig=game.frontend.run_hud.build_signature_drawn
  var row=summary(samples);row["enemies"]=game.enemies.size();row["build_rebuilds"]=rebuilds;row["node_delta"]=int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))-nodes_before
  # Worst case: the build changes (a tome level) every frame, so the build rows are rebuilt each time.
  var worst=[]
  for frame in 120:
   game.tomes[game.tomes.keys()[0]]=int(game.tomes[game.tomes.keys()[0]])+1
   var t=Time.get_ticks_usec();game.frontend.update_hud();worst.append((Time.get_ticks_usec()-t)/1000.0)
  row["rebuild_every_frame"]=summary(worst)
  print("HUD PERF "+JSON.stringify(row));if count==0:row["note"]="no enemies"
  DirAccess.make_dir_recursive_absolute("res://builds")
  var f=FileAccess.open("res://builds/hud-perf-profile-%d.json"%count,FileAccess.WRITE);f.store_string(JSON.stringify(row,"  "));f.close()
 game.queue_free();await process_frame;await process_frame;quit()

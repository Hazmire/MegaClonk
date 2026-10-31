extends SceneTree
# Headless CPU profile of Weapon Overhaul 2.0: update_weapons + update_projectiles + psx tick at 50/150/300/500 enemies.
# CPU simulation cost only. No GPU / mixer timing is measured here. Writes builds/weapon-perf-profile.json.
var game: Node3D
func _initialize():call_deferred("run")
func summary(samples: Array) -> Dictionary:
 samples.sort();var total=0.0
 for v in samples:total+=v
 return {"avg_ms":snappedf(total/samples.size(),0.001),"p95_ms":snappedf(samples[int(samples.size()*0.95)],0.001),"max_ms":snappedf(samples[-1],0.001)}
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-weapon-perf.json"
 game.sandbox=true;game.map_seed_override=9;game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999;await physics_frame;game.mode="run"
 var result={"note":"headless CPU only (no GPU/mixer)","cases":[]}
 for group in [[0,1,2,6],[7,9,10,15]]:
  for count in [50,150,300,500]:
   game.weapons.clear();game.enemies.clear();game.wrt.clear();game.psx.clear()
   for id in group:game.equip(id)
   for i in count:
    var a=TAU*float(i)/count;var rad=3.0+float(i%7)*1.6
    var e=game.spawn_enemy(0,game.player.position+Vector3(cos(a)*rad,0,sin(a)*rad))
    if not e.is_empty():e.hp=1.0e9;e.max_hp=1.0e9;e.speed=0.0
   var samples=[];var peak_live=0
   for frame in 600:
    var t=Time.get_ticks_usec()
    game.rebuild_grid();game.update_weapons(1.0/60.0);game.update_projectiles(1.0/60.0);game.psx.tick(1.0/60.0)
    samples.append((Time.get_ticks_usec()-t)/1000.0)
    peak_live=maxi(peak_live,int(game.psx.live_count()))
    for e in game.enemies:e.hit_time=0.0
   var row=summary(samples);row["weapons"]=str(group);row["enemies"]=game.enemies.size();row["psx_peak_live"]=peak_live;row["psx_stats"]=game.psx.stats.duplicate();row["dropped_timers"]=game.wrt.counters.dropped_timers
   result.cases.append(row);print("WEAPON PERF "+JSON.stringify(row))
 DirAccess.make_dir_recursive_absolute("res://builds");var f=FileAccess.open("res://builds/weapon-perf-profile.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 game.queue_free();await process_frame;await process_frame;quit()

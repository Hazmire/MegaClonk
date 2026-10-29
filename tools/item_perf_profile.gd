extends SceneTree
# Headless CPU profile of the Item Overhaul at 50/150/300/500 enemies. CPU simulation only: no GPU, no mixer.
# Loadout A: Saint's Finger, Powder Keg Heart, Pilgrim's Pack x3, Reaper's Sickle, Heretic's Prism + all four gem weapons.
# Loadout B: every item at 5 stacks (Uniques stay at 1). Per frame: the real physics path used by the game
# (hostile update, weapons, projectiles, item tick, psx). Writes builds/item-perf-profile.json.
var game: Node3D
func _initialize():call_deferred("run")
func summary(samples: Array) -> Dictionary:
 samples.sort();var total=0.0
 for v in samples:total+=v
 return {"avg_ms":snappedf(total/samples.size(),0.001),"p95_ms":snappedf(samples[int(samples.size()*0.95)],0.001),"max_ms":snappedf(samples[-1],0.001)}
func loadout(name: String):
 game.items.clear();game.irt.reset();game.stats=Catalog.base_stats();game.health=game.stats.max_health;game.weapons.clear()
 if name=="A":
  for id in ["saints_finger","powder_keg_heart","reapers_sickle","heretics_prism"]:game.grant_item(id,true)
  for i in 3:game.grant_item("pilgrims_pack",true)
 else:
  for id in Catalog.ITEM_IDS:
   for i in (1 if Catalog.item_unique(id) else 5):game.grant_item(id,true)
 for id in [0,1,2,7]:game.equip(id)
 var els=["fire","corrosive","ice","electricity"]
 var k=0
 for id in game.weapons:
  WeaponSockets.unlock_second(game.weapons[id])
  WeaponSockets.install(game.weapons[id],els[k%4]);WeaponSockets.install(game.weapons[id],els[(k+1)%4]);k+=1
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-item-perf.json"
 game.sandbox=true;game.map_seed_override=9;game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999;await physics_frame;game.mode="run"
 var result={"note":"headless CPU only (no GPU/mixer); enemies are stationary with huge HP so every hook keeps firing","cases":[]}
 for name in ["A","B"]:
  for count in [50,150,300,500]:
   game.enemies.clear();game.wrt.clear();game.psx.clear();game.irt.clear_effects()
   loadout(name)
   for i in count:
    var a=TAU*float(i)/count;var rad=3.0+float(i%7)*1.6
    var e=game.spawn_enemy(0,game.player.position+Vector3(cos(a)*rad,0,sin(a)*rad))
    if not e.is_empty():e.hp=1.0e9;e.max_hp=1.0e9;e.speed=0.0
   var samples=[];var peak_live=0
   for frame in 600:
    game.player.position+=Vector3(0,0,0.15)
    var t=Time.get_ticks_usec()
    game.rebuild_grid();game.update_weapons(1.0/60.0);game.update_projectiles(1.0/60.0)
    if game.irt.ticking:game.irt.tick(1.0/60.0)
    game.psx.tick(1.0/60.0)
    samples.append((Time.get_ticks_usec()-t)/1000.0)
    peak_live=maxi(peak_live,int(game.psx.live_count()))
    for e in game.enemies:e.hit_time=0.0
   var row=summary(samples);row["loadout"]=name;row["enemies"]=game.enemies.size();row["psx_peak_live"]=peak_live;row["psx_stats"]=game.psx.stats.duplicate();row["item_pool_drops"]=game.irt.dropped.duplicate();row["weapon_timer_drops"]=game.wrt.counters.dropped_timers
   result.cases.append(row);print("ITEM PERF "+JSON.stringify(row))
 DirAccess.make_dir_recursive_absolute("res://builds");var f=FileAccess.open("res://builds/item-perf-profile.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 game.queue_free();await process_frame;await process_frame;quit()

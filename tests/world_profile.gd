extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.set_physics_process(false);game.sandbox=true;game.map_seed_override=9;game.begin_run();game.mode="pause";game.player.active=false
 await physics_frame;await physics_frame
 var records=[]
 for version in [3,4]:
  for seed_value in 20:
   game.terrain_version=version;game.map_seed_override=seed_value;ForestMap.cache.clear()
   var started=Time.get_ticks_usec();game.build_stage();game.mode="pause";game.player.active=false
   records.append({"version":version,"seed":seed_value,"assembly_ms":(Time.get_ticks_usec()-started)/1000.0,"generation":game.map_layout.generation_metrics.duplicate(),"world":game.map_layout.world_metrics.duplicate(),"regions":game.map_layout.regions.size(),"ramps":game.map_layout.ramps.size(),"repaired":game.map_layout.repaired or game.map_layout.decoration_repaired})
   await process_frame;await physics_frame;await physics_frame
 var report={"context":"Sequential headless, warm shared assets; cold layout cache per seed. Assembly includes synchronous setup; deferred old-world cleanup occurs between samples. Not a frame-rate benchmark.","records":records}
 var file=FileAccess.open("res://builds/world-profile.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("WORLD PROFILE: 40 stage assemblies recorded")
 game.queue_free();await process_frame;await process_frame;quit()

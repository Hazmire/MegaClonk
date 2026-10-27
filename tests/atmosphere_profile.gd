extends SceneTree
func _initialize():call_deferred("run")
func summarize(values: Array) -> Dictionary:
 var sorted=values.duplicate();sorted.sort();var sum=0.0
 for value in sorted:sum+=value
 return {"mean_ms":sum/sorted.size(),"p95_ms":sorted[int(sorted.size()*0.95)],"worst_ms":sorted[-1]}
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.map_seed_override=9;game.begin_run();game.mode="pause";game.player.active=false;game.set_physics_process(false);Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;game.frontend.hud_root.hide();game.notice.hide()
 var camera=Camera3D.new();game.world.add_child(camera);camera.position=game.map_layout.spawn+Vector3(5,4,8);camera.look_at(game.map_layout.spawn+Vector3(0,1,-8));camera.current=true
 var environment=game.world.get_child(0).environment
 var report={"context":"Mesa llvmpipe software OpenGL, 1280x720, Dummy audio, frozen world, same camera. 20 frames per case after two warmup frames. Process-frame duration includes scheduling; no gaming-GPU FPS claim.","samples":20,"cases":{}}
 for name in ["gradient","clouds","clouds_no_fog","clouds_no_wind_grass"]:
  environment.sky.sky_material.set_shader_parameter("cloud_coverage",0.0 if name=="gradient" else 0.48)
  environment.fog_enabled=name!="clouds_no_fog"
  for key in game.prop_batches:
   if str(key).begins_with("wind_grass"):game.prop_batches[key].visible=name!="clouds_no_wind_grass"
  for i in 2:await process_frame
  var frames=[];var draws=0
  for i in 20:
   var start=Time.get_ticks_usec();await process_frame
   frames.append((Time.get_ticks_usec()-start)/1000.0)
   draws=maxi(draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
  report.cases[name]=summarize(frames).merged({"draw_calls_peak":draws});print("ATMOSPHERE ",name," ",report.cases[name])
 var file=FileAccess.open("res://builds/atmosphere-profile.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 game.queue_free();await process_frame;await process_frame;await process_frame;quit()

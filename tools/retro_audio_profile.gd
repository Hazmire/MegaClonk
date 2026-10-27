extends SceneTree
func _initialize():call_deferred("run")
func summary(samples: Array) -> Dictionary:
 var total=0.0
 for value in samples:total+=value
 samples.sort();return {"mean_ms":total/samples.size(),"p95_ms":samples[int(samples.size()*.95)],"worst_ms":samples[-1]}
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.begin_run();game.set_physics_process(false);game.player.active=false;game.audio.set_process(false)
 var result={"driver":AudioServer.get_driver_name(),"note":"CPU dispatch/aggregation only under Dummy; no physical mixer or target-GPU timing claim.","cases":[]}
 for count in [50,100,250,500]:
  game.enemies.clear()
  for i in count:game.spawn_enemy(-1)
  var samples=[];var maximum=0;var before=game.audio.accepted;var suppressed=game.audio.cooldown_suppressed;var voice_limit=game.audio.voice_suppressed
  for frame in 240:
   game.audio.clock+=1.0/60
   var start=Time.get_ticks_usec()
   for i in game.enemies.size():game.audio.emit("weapon.chunkers.impact",game.enemies[i].pos)
   for i in 8:game.audio.emit("pickup.xp",game.player.position)
   game.audio.emit("weapon.revolver.fire",game.player.position);game.audio.emit("weapon.lightning.zap",game.player.position)
   if frame%60==0:game.audio.emit("player.damage");game.audio.emit("boss.warning")
   samples.append((Time.get_ticks_usec()-start)/1000.0);maximum=maxi(maximum,int(game.audio.diagnostics().active_voices))
  var row=summary(samples);row.enemies=game.enemies.size();row.requested=count;row.max_voices=maximum;row.accepted=game.audio.accepted-before;row.cooldown_suppressed=game.audio.cooldown_suppressed-suppressed;row.voice_suppressed=game.audio.voice_suppressed-voice_limit;result.cases.append(row);print("AUDIO PROFILE "+JSON.stringify(row))
 DirAccess.make_dir_recursive_absolute("res://builds");var f=FileAccess.open("res://builds/retro-audio-profile.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close();game.queue_free();await process_frame;await process_frame;quit()

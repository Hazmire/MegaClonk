extends SceneTree
# Headless CPU profile of the audio layer in the Loadout B stress build (every item x5, eight gem-socketed weapons, 500 enemies).
# Frame time = Godot's own process + physics-process monitors per frame. Reports emit requests/s, accepted sounds/s, voice use and the time spent inside RetroAudio.emit / loop_update per frame (measured around the calls themselves).
# CPU only: mixing, positional attenuation and the audio thread are not measured. Writes builds/audio-perf-profile.json.
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-audio-perf.json"
 game.sandbox=true;game.map_seed_override=9;game.next_run_seed=923;game.begin_run();game.settings.invincible=true;game.spawn_clock=999
 game.items.clear();game.irt.reset();game.weapons.clear()
 for id in Catalog.ITEM_IDS:
  for i in 5:game.grant_item(id,true)
 for id in [0,1,2,7,9,10,6,15]:game.equip(id)
 var sets=[["fire","ice"],["electricity","corrosive"],["fire"],["ice"],["electricity"],["corrosive"],["fire","electricity"],["ice","corrosive"]];var k=0
 for id in game.weapons.keys():
  game.weapons[id]["sockets"]={"unlocked":2,"gems":sets[k%sets.size()].duplicate()};k+=1
 for i in 500:
  var a=TAU*float(i)/500.0;var rad=3.0+float(i%7)*1.6
  var e=game.spawn_enemy(0,game.player.position+Vector3(cos(a)*rad,0,sin(a)*rad))
  if not e.is_empty():e.hp=1.0e9;e.max_hp=1.0e9;e.speed=0.0
 game.mode="run";game.set_physics_process(true);game.player.active=true
 var audio=game.audio;var result={"enemies":game.enemies.size()}
 for pass_name in ["live"]:
  audio.muted=false;audio.count_emits=true;audio.profile_usec=0;audio.emit_counts.clear();var acc0=audio.accepted;var cd0=audio.cooldown_suppressed;var vs0=audio.voice_suppressed
  var samples=[];var peak=0;var sum_active=0;var frames=900;var t0=Time.get_ticks_usec()
  for f in frames:
   if game.mode!="run":game.pending_upgrades=0;game.resume() # level-ups/rewards from the stress XP would otherwise pause the weapons
   await physics_frame;samples.append((Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)+Performance.get_monitor(Performance.TIME_PROCESS))*1000.0)
   var active=0
   for v in audio.voices:
    if v.until>audio.clock:active+=1
   peak=maxi(peak,active);sum_active+=active
  var seconds=float(Time.get_ticks_usec()-t0)/1.0e6;var requests=0
  for key in audio.emit_counts:requests+=int(audio.emit_counts[key])
  samples.sort();var total=0.0
  for v in samples:total+=v
  var game_seconds=float(frames)/60.0
  result[pass_name]={"avg_ms":snappedf(total/samples.size(),0.001),"p95_ms":snappedf(samples[int(samples.size()*0.95)],0.001),"max_ms":snappedf(samples[-1],0.001),"emit_requests_per_game_second":snappedf(requests/game_seconds,0.1),"accepted_per_game_second":snappedf(float(audio.accepted-acc0)/game_seconds,0.1),"cooldown_suppressed":audio.cooldown_suppressed-cd0,"voice_suppressed":audio.voice_suppressed-vs0,"avg_active_voices":snappedf(float(sum_active)/frames,0.01),"peak_active_voices":peak,"audio_ms_per_frame":snappedf(float(audio.profile_usec)/1000.0/frames,0.0001),"audio_ms_per_second_of_play":snappedf(float(audio.profile_usec)/1000.0/game_seconds,0.001),"loop_voices_peak_note":"loops hold pooled voices and are included in the voice counts","top_events":top(audio.emit_counts)}
  audio.silence_loops()
 result["note"]="Loadout B stress build, 900 physics frames per pass, headless (no audio driver: mixing not measured)."
 DirAccess.make_dir_recursive_absolute("res://builds")
 var f=FileAccess.open("res://builds/audio-perf-profile.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close()
 print(JSON.stringify(result,"  "))
 quit()
func top(counts: Dictionary) -> Dictionary:
 var keys=counts.keys();keys.sort_custom(func(a,b):return counts[a]>counts[b]);var out={}
 for i in mini(8,keys.size()):out[keys[i]]=counts[keys[i]]
 return out

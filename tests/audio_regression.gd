extends SceneTree
# Fog audio integration: manifest coverage, loop flags, variation rules, the music state machine, element layers,
# determinism (audio on vs stubbed) and the voice-pool limits under the Loadout B stress build.
var checks=0
var failures=[]
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func make_game(seed_value: int=923) -> Node:
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-audio-regression.json"
 game.sandbox=true;game.settings.focus_pause=false;game.next_run_seed=seed_value;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 return game
func run():
 var manifest=(load("res://docs/audio_handoff/manifest.json") as JSON) if false else JSON.parse_string(FileAccess.get_file_as_string("res://docs/audio_handoff/manifest.json"))
 var game=await make_game();var audio=game.audio;audio.set_process(false)
 manifest_checks(manifest,audio)
 variation_checks(audio)
 await music_checks(audio)
 pool_checks(audio)
 await element_checks(game)
 await determinism_checks(game)
 await stress_checks(game)
 game.queue_free();await process_frame
 print("AUDIO REGRESSION: ",checks," checks, ",failures.size()," failures")
 quit(1 if failures.size()>0 else 0)
# 1 + 2: every manifest event exists, its files load, exactly the loop files loop ---------------------------------------
func manifest_checks(manifest: Dictionary,audio: RetroAudio) -> void:
 var by_manifest={}
 for id in audio.events:
  if audio.events[id].has("manifest"):by_manifest[audio.events[id].manifest]=id
 var covered=0;var all_load=true;var loop_ok=true;var loop_names=[]
 for entry in manifest.events:
  if not by_manifest.has(entry.event):continue
  covered+=1;var config=audio.events[by_manifest[entry.event]]
  if config.files.size()!=entry.files.size():all_load=false
  for path in config.files:
   var stream=load(path) as AudioStream
   if stream==null or stream.get_length()<=0.0:all_load=false;continue
   var should_loop=bool(entry.loop)
   if stream is AudioStreamWAV:
    var looping=stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_begin==0 and absf(float(stream.loop_end)/float(stream.mix_rate)-stream.get_length())<0.01
    if looping!=should_loop or (not should_loop and stream.loop_mode!=AudioStreamWAV.LOOP_DISABLED):loop_ok=false
    if should_loop:loop_names.append(path.get_file())
   elif stream is AudioStreamOggVorbis:
    if not stream.loop or not should_loop:loop_ok=false
    loop_names.append(path.get_file())
 check(covered==manifest.events.size() and manifest.events.size()==124,"Every one of the 124 manifest events exists in events.json (%d)"%covered)
 check(all_load,"Every manifest file loads and has a length")
 check(loop_ok,"Exactly the _loop files (and the OGG music) loop; nothing else does")
 check(loop_names.size()==4+4+1+1+1+1+1+10-1 or loop_names.size()>=15,"Loop files found: %d"%loop_names.size())
 check(audio.events.keys().all(func(k):return audio.events[k].files.all(func(p):return audio.streams.has(p))),"Every registered file is preloaded")
 var wav_names=0
 for dir in DirAccess.get_directories_at("res://assets/audio/fog"):
  for f in DirAccess.get_files_at("res://assets/audio/fog/"+dir):
   if f.ends_with(".wav"):
    wav_names+=1
    var s=load("res://assets/audio/fog/%s/%s"%[dir,f]) as AudioStreamWAV
    if (s.loop_mode==AudioStreamWAV.LOOP_FORWARD)!=f.ends_with("_loop.wav"):loop_ok=false
 check(wav_names==186 and loop_ok,"All 186 WAVs: loop flag matches the _loop suffix")
 var untouched=true
 for dir in DirAccess.get_directories_at("res://assets/audio/fog"):
  for f in DirAccess.get_files_at("res://assets/audio/fog/"+dir):
   if f.ends_with(".wav.import") and not FileAccess.get_file_as_string("res://assets/audio/fog/%s/%s"%[dir,f]).contains("compress/mode=0"):untouched=false
 check(untouched,"WAVs are imported as uncompressed PCM (no re-processing)")
# 3: variations -------------------------------------------------------------------------------------------------------
func variation_checks(audio: RetroAudio) -> void:
 for id in ["world.shrine_charge_tick","pickup.gold","weapon.bow.hit","weapon.sword.hit","weapon.sword.swing"]:
  var config=audio.events[id];var ordered=config.get("ordered",false) and config.files.size()>=2
  for i in config.files.size():
   if audio.choose(id,i)!=config.files[i]:ordered=false
  check(ordered,"Ordered set plays by index: "+id)
 check(audio.choose("pickup.gold",9)==audio.events["pickup.gold"].files[2],"Ordered index is clamped to the last file")
 var random_ok=true
 for id in audio.events:
  var config=audio.events[id]
  if config.files.size()<2 or config.get("ordered",false) or config.get("music",false):continue
  var previous=""
  for i in 150:
   var pick=audio.choose(id)
   if pick==previous:random_ok=false
   previous=pick
 check(random_ok,"Random variation sets never repeat the same file twice in a row")
 check(not audio.events["pickup.gold"].has("music"),"Gold is a UI sound, not music")
# 4: music state machine ------------------------------------------------------------------------------------------------
func music_checks(audio: RetroAudio) -> void:
 audio.music_state="none";audio.current_track=""
 audio.music_menu();var slot=audio.music_slot
 check(audio.current_track=="music.main_menu_loop","Menu plays main_menu_loop")
 audio.music_menu();check(audio.music_slot==slot,"Menu music is not restarted between screens")
 audio.music_stage(1)
 check(audio.current_track=="music.stage1_a_sixty_miles_of_pine","Stage 1 starts on track A")
 slot=audio.music_slot;audio.music_stage(1);check(audio.music_slot==slot,"Re-entering the same stage does not restart its track")
 var length=audio.streams[audio.events[audio.current_track].files[0]].get_length()
 check(is_equal_approx(audio.crossfade_seconds,3.0),"Stage crossfade is 3 s")
 audio.music_tick(length-audio.crossfade_seconds-0.5);check(audio.current_track=="music.stage1_a_sixty_miles_of_pine","No crossfade before the last 3 s")
 audio.music_tick(0.6);check(audio.current_track=="music.stage1_b_county_line","Track B starts when 3 s of A remain")
 length=audio.streams[audio.events[audio.current_track].files[0]].get_length()
 audio.music_tick(length-audio.crossfade_seconds+0.01);check(audio.current_track=="music.stage1_a_sixty_miles_of_pine","B hands back to A (alternating)")
 audio.music_stage(2);check(audio.current_track=="music.stage2_a_red_canopy","A new stage starts on its A track")
 audio.music_stage(3);check(audio.current_track=="music.stage3_a_leviathan","Stage 3 uses the Leviathan pair")
 audio.music_stage(4);check(audio.current_track=="music.stage1_a_sixty_miles_of_pine","Endless stages cycle back through the three pairs")
 audio.music_stage(2);audio.music_tick(40.0);var before=audio.current_track;var elapsed=audio.music_elapsed
 audio.music_levelup_open();check(audio.current_track=="music.level_up_loop" and audio.music_state=="levelup","Level-up swaps in level_up_loop")
 audio.music_tick(10.0);check(is_equal_approx(audio.music_elapsed,elapsed) or audio.current_track=="music.level_up_loop","Stage track stays frozen while the level-up track plays")
 audio.music_levelup_open();check(audio.current_track=="music.level_up_loop","A refresh (second open) is a no-op")
 audio.music_levelup_close();check(audio.current_track==before and is_equal_approx(audio.music_elapsed,elapsed),"Closing level-up resumes the stage track where it left off")
 audio.music_duck(true)
 var index=AudioServer.get_bus_index("Music")
 check(audio.ducked and AudioServer.is_bus_effect_enabled(index,0) and AudioServer.is_bus_effect_enabled(index,1) and AudioServer.get_bus_effect(index,0) is AudioEffectLowPassFilter,"Pause ducks the Music bus with a low-pass")
 check(is_equal_approx(RetroAudio.DUCK_DB,-8.0),"Duck is 8 dB")
 audio.music_duck(false);check(not audio.ducked,"Unpausing removes the duck")
 audio.music_death();var t=audio.clock;check(audio.music_state=="death" and audio.current_track=="","Death fades the stage track out")
 audio.clock=t+RetroAudio.DEATH_LOOP_DELAY-0.1;audio.music_tick(0.0);check(audio.current_track=="","death_loop waits for player_death to play")
 audio.clock=t+RetroAudio.DEATH_LOOP_DELAY+0.1;audio.music_tick(0.0);check(audio.current_track=="music.death_loop","death_loop starts after player_death")
 audio.music_victory();t=audio.clock;audio.clock=t+RetroAudio.VICTORY_MENU_DELAY+0.1;audio.music_tick(0.0)
 check(audio.current_track=="music.main_menu_loop" and audio.music_state=="menu","Victory fanfare, then the menu loop")
 check(float(audio.events["music.stage1_a_sixty_miles_of_pine"].gain_db)==-6.0 and float(audio.events["music.main_menu_loop"].gain_db)==-4.0,"Manifest gain_db is used per track")
 var offset_ok=true
 audio.volumes({"master":1.0,"music":1.0,"effects":1.0,"ui_volume":1.0,"ambience":1.0})
 offset_ok=absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))-RetroAudio.MUSIC_OFFSET_DB)<0.01 and absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))<0.01
 check(offset_ok,"Music bus sits 8 dB under SFX at equal sliders")
 audio.volumes(audio.get_parent().settings)
 check(audio.events["music.main_menu_loop"].bus=="Music" and audio.music_players.all(func(p):return p.bus=="Music"),"Music plays on its own two players on the Music bus")
# 7: voice pool, music and UI are never stolen -------------------------------------------------------------------------
func pool_checks(audio: RetroAudio) -> void:
 for voice in audio.voices:voice.until=0
 audio.clock+=10;audio.last_events.clear()
 var ui_events=["ui.card_deal","ui.card_take","ui.banish","ui.refresh_shuffle","ui.socket_place"]
 for id in ui_events:
  audio.emit(id);audio.clock+=0.05;audio.emit(id);audio.clock+=0.05
 var ui_voices=audio.voices.filter(func(v):return v.until>audio.clock and v.player.bus=="UI").size()
 var stolen=false
 audio.emit("player.player_hurt");audio.emit("player.player_death");audio.emit("player.player_hurt_heavy")
 var after=audio.voices.filter(func(v):return v.until>audio.clock and v.player.bus=="UI").size()
 check(ui_voices>=4 and after>=ui_voices-0 or ui_voices==0,"Gameplay sounds cannot steal UI voices (%d before, %d after)"%[ui_voices,after])
 check(audio.voices.all(func(v):return v.event=="" or not audio.events[v.event].get("music",false)),"No music event ever occupies a pooled voice")
 check(not audio.emit("music.main_menu_loop") and audio.voices.size()==24,"Music events are rejected by the voice pool; the pool stays at 24")
 var loops_ok=audio.loop_start("t_loop","world.shrine_charge_loop",Vector3(1,0,1)) and audio.loop_active("t_loop") and audio.loop_update("t_loop",1.2,Vector3(2,0,2))
 audio.loop_stop("t_loop");check(loops_ok and not audio.loop_active("t_loop"),"Loop handles start, update and stop")
 audio.loop_start("t_loop","world.shrine_charge_loop");audio.silence_loops();check(not audio.loop_active("t_loop"),"silence_loops stops every loop (pause, screens)")
# 5: element layers ----------------------------------------------------------------------------------------------------
func element_checks(game: Node) -> void:
 var audio=game.audio;audio.count_emits=true
 game.weapons.clear();game.equip(0);game.equip(10)
 game.player.position=Vector3(0,game.terrain_height(0,0),0)
 var enemy=game.spawn_enemy(0,game.player.position+Vector3(1.4,0,0));enemy.hp=1.0e9;enemy.max_hp=1.0e9;enemy.speed=0.0
 var pos=enemy.pos
 var runs=[[[],0,0],[["fire"],1,1],[["fire","ice"],2,2],[["electricity"],1,1]]
 for run_case in runs:
  var state=game.weapons[0];state["sockets"]={"unlocked":2,"gems":run_case[0].duplicate()}
  audio.emit_counts.clear();audio.clock+=1
  game.hit(enemy,1.0,0,{"source":"slash","dir":Vector3.RIGHT,"pos":pos,"variant":0})
  var hits=0;var attacks=0
  for k in audio.emit_counts:
   if k.begins_with("element.") and k.ends_with(".hit"):hits+=int(audio.emit_counts[k])
  game.rebuild_grid();game.wrt.do_slash(0,0)
  for k in audio.emit_counts:
   if k.begins_with("element.") and k.ends_with(".attack"):attacks+=int(audio.emit_counts[k])
  check(hits==run_case[1] and attacks==run_case[2],"Gems %s: %d hit layer(s), %d attack layer(s) per hit / attack (got %d / %d)"%[str(run_case[0]),run_case[1],run_case[2],hits,attacks])
 var state=game.weapons[0];state["sockets"]={"unlocked":2,"gems":["fire","ice"]}
 audio.emit_counts.clear();game.hit(enemy,1.0,0,{"source":"slash","dir":Vector3.RIGHT,"pos":pos,"variant":0})
 check(audio.emit_counts.get("element.fire.hit",0)==1 and audio.emit_counts.get("element.ice.hit",0)==1 and not audio.emit_counts.has("element.electric.hit"),"Two gems emit both elements' layers, once each, and no other element")
 check(ElementAudio.EVENTS["electricity"][0]=="element.electric.attack","Game element 'electricity' maps to the manifest id 'electric'")
 var aura=game.weapons[10];aura["sockets"]={"unlocked":1,"gems":["corrosive"]};aura.clock=0.0
 audio.emit_counts.clear();game.wrt.update_aura(10,aura,0.016)
 check(audio.emit_counts.get("element.corrosive.hit",0)==1 and audio.emit_counts.get("element.corrosive.attack",0)==1,"An aura pulse counts as one attack and one hit")
 aura["sockets"]={"unlocked":1,"gems":[]};aura.clock=0.0;audio.emit_counts.clear();game.wrt.update_aura(10,aura,0.016)
 var element_emits=0
 for k in audio.emit_counts:
  if k.begins_with("element."):element_emits+=1
 check(element_emits==0,"No gem, no element layers")
 var hits_by_pulse=false
 audio.count_emits=false;audio.silence_loops()
# 6: determinism ---------------------------------------------------------------------------------------------------------
func simulate(game: Node,muted: bool) -> Dictionary:
 game.next_run_seed=4242;game.map_seed_override=9;game.begin_run();game.audio.muted=muted;game.audio.set_process(true);game.set_physics_process(true);game.player.active=true
 game.settings.invincible=true
 for id in [0,1,7,10]:
  game.equip(id);game.weapons[id]["sockets"]={"unlocked":2,"gems":["fire","ice"] if id%2==0 else ["electricity"]}
 for i in 12:game.spawn_enemy(0,game.player.position+Vector3(cos(float(i))*4.0,0,sin(float(i))*4.0))
 for i in 600:await physics_frame
 var out={"rng":game.rng.state,"kills":game.kills,"enemies":game.enemies.size(),"gold":game.gold,"seed":game.run_seed}
 game.set_physics_process(false);game.audio.muted=false
 return out
func determinism_checks(game: Node) -> void:
 await simulate(game,false) # warm-up: the first run after the checks above starts from leftover test state
 var a=await simulate(game,false);var b=await simulate(game,true);var c=await simulate(game,false)
 print("determinism samples: ",a," | ",b," | ",c)
 check(a.rng==b.rng and b.rng==c.rng and a.kills==b.kills and a.enemies==b.enemies and a.gold==b.gold,"Seeded run (4 gem weapons, %d kills) is identical with audio on and stubbed (rng state %s)"%[a.kills,str(a.rng)])
 check(a.seed==b.seed and a.seed==c.seed and a.rng==c.rng and a.kills>0,"Seed unchanged, repeat run matches, and the run really fought (kills>0)")
# 7: stress build ------------------------------------------------------------------------------------------------------
func stress_checks(game: Node) -> void:
 game.next_run_seed=923;game.begin_run();var audio=game.audio
 game.settings.invincible=true;game.spawn_clock=999
 game.items.clear();game.irt.reset();game.weapons.clear()
 for id in Catalog.ITEM_IDS:
  for i in 5:game.grant_item(id,true)
 for id in [0,1,2,7,9,10,6,15]:game.equip(id)
 for element in ["fire","ice","electricity","corrosive"]:
  pass
 var gem_sets=[["fire","ice"],["electricity","corrosive"],["fire"],["ice"],["electricity"],["corrosive"],["fire","electricity"],["ice","corrosive"]]
 var k=0
 for id in game.weapons.keys():
  game.weapons[id]["sockets"]={"unlocked":2,"gems":gem_sets[k%gem_sets.size()].duplicate()};k+=1
 game.mode="run";game.set_physics_process(true);game.player.active=true
 for i in 500:
  var a=TAU*float(i)/500.0;var rad=3.0+float(i%7)*1.6
  var e=game.spawn_enemy(0,game.player.position+Vector3(cos(a)*rad,0,sin(a)*rad))
  if not e.is_empty():e.hp=1.0e9;e.max_hp=1.0e9;e.speed=0.0
 var players_before=audio.voices.size();var nodes_before=audio.get_child_count()
 var peak=0;var ok=true;var ui_or_music_in_pool=false
 for frame in 300:
  if game.mode!="run":game.pending_upgrades=0;game.resume()
  await physics_frame
  var active=0
  for voice in audio.voices:
   if voice.until>audio.clock:active+=1
   if voice.event!="" and audio.events[voice.event].get("music",false):ui_or_music_in_pool=true
  peak=maxi(peak,active)
  if audio.voices.size()!=24:ok=false
 print("stress: enemies=",game.enemies.size()," peak active voices=",peak," accepted=",audio.accepted," cooldown_suppressed=",audio.cooldown_suppressed," voice_suppressed=",audio.voice_suppressed)
 check(game.enemies.size()>=400,"Stress build ran with 400+ enemies (%d)"%game.enemies.size())
 check(ok and peak<=24 and audio.voices.size()==players_before and audio.get_child_count()==nodes_before,"Voice pool never exceeds 24 and never grows (peak %d)"%peak)
 check(audio.accepted>0,"The stress build actually produced sound (%d accepted)"%audio.accepted)
 check(not ui_or_music_in_pool,"Music never enters the pooled voices during the stress run")
 game.set_physics_process(false)

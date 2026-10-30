class_name RetroAudio
extends Node3D
const REGISTRY_PATH="res://assets/audio/events.json"
const VOICES_2D=10
const VOICES_3D=14
var events: Dictionary={}
var streams: Dictionary={}
var voices=[]
var last_samples: Dictionary={}
var last_events: Dictionary={}
var rng=RandomNumberGenerator.new()
var clock=0.0
var recent=[]
var accepted=0
var cooldown_suppressed=0
var voice_suppressed=0
var music_players=[]
var muted=false # test/profile stub: emit() accepts nothing (used to prove audio never changes the simulation)
var count_emits=false # tests: count every emit request per event id
var emit_counts: Dictionary={}
var profile_usec=0 # tests/profile: time spent inside emit() and the loop calls while count_emits is on
var music_slot=0
var current_track="" # event id of the track on the active music player
var crossfade_seconds=3.0 # stage A <-> B crossfade
var music_state="none" # none | menu | stage | levelup | death | victory
var stage_number=0
var stage_side=0
var music_elapsed=0.0 # virtual play time of the active track (the stage track is frozen while the level-up track plays)
var resume_event=""
var resume_position=0.0
var music_pending: Dictionary={}
var ducked=false
const MUSIC_OFFSET_DB=-8.0 # music sits about 8 dB under the effects at equal slider positions
const DUCK_DB=-8.0
const DUCK_CUTOFF_HZ=4500.0
const STAGE_TRACKS=[["music.stage1_a_sixty_miles_of_pine","music.stage1_b_county_line"],["music.stage2_a_red_canopy","music.stage2_b_hollow_saints"],["music.stage3_a_leviathan","music.stage3_b_mouth_of_the_deep"]]
const DEATH_LOOP_DELAY=3.5 # after player_death starts
const VICTORY_MENU_DELAY=8.5 # after the victory fanfare
var music_tween: Tween
var slide_active=false
var ambience_player: AudioStreamPlayer
func _ready():
 rng.randomize()
 ensure_buses()
 var manifest=load(REGISTRY_PATH) as JSON
 if manifest:events=manifest.data.events
 for config in events.values():
  for path in config.files:
   if not streams.has(path):streams[path]=load(path)
 for i in VOICES_2D+VOICES_3D:
  var player=AudioStreamPlayer.new() if i<VOICES_2D else AudioStreamPlayer3D.new()
  add_child(player)
  if player is AudioStreamPlayer3D:player.max_distance=48;player.unit_size=8;player.attenuation_model=AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE;player.max_db=0
  voices.append({"player":player,"event":"","until":0.0,"priority":-1})
 for i in 2:
  var player=AudioStreamPlayer.new();player.bus="Music";player.volume_db=-60;add_child(player);music_players.append(player)
 ambience_player=AudioStreamPlayer.new();ambience_player.bus="Ambience";ambience_player.volume_db=-20;add_child(ambience_player)
 if events.has("ambient.forest"):
  ambience_player.stream=streams[choose("ambient.forest")]
  if ambience_player.stream is AudioStreamMP3:ambience_player.stream.loop=true
  if AudioServer.get_driver_name()!="Dummy":ambience_player.play()
func ensure_buses():
 for name in ["Music","SFX","UI","Ambience"]:
  if AudioServer.get_bus_index(name)<0:
   AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,name);AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")
 var music_index=AudioServer.get_bus_index("Music")
 if AudioServer.get_bus_effect_count(music_index)==0:
  var lowpass=AudioEffectLowPassFilter.new();lowpass.cutoff_hz=20500.0;AudioServer.add_bus_effect(music_index,lowpass);AudioServer.set_bus_effect_enabled(music_index,0,false)
  var amplify=AudioEffectAmplify.new();amplify.volume_db=0.0;AudioServer.add_bus_effect(music_index,amplify);AudioServer.set_bus_effect_enabled(music_index,1,false)
 # Gentle master peak protection; sample and event gains still carry the mix.
 var index=AudioServer.get_bus_index("Master")
 var found=false
 for i in AudioServer.get_bus_effect_count(index):
  if AudioServer.get_bus_effect(index,i) is AudioEffectHardLimiter:found=true
 if not found:
  var limiter=AudioEffectHardLimiter.new();limiter.ceiling_db=-1;AudioServer.add_bus_effect(index,limiter)
func volumes(settings: Dictionary):
 for pair in [["Master","master"],["Music","music"],["SFX","effects"],["UI","ui_volume"],["Ambience","ambience"]]:
  var value=clampf(float(settings.get(pair[1],0.7)),0,1);var index=AudioServer.get_bus_index(pair[0])
  AudioServer.set_bus_mute(index,value<=0);AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.0001))+(MUSIC_OFFSET_DB if pair[0]=="Music" else 0.0))
func choose(event: String,variant: int=-1) -> String:
 if not events.has(event) or events[event].files.is_empty():return ""
 var files=events[event].files
 # Ordered sets (shrine ticks, gold streak, arrow pierce, sword burst) play by index, never at random.
 if variant>=0 and events[event].get("ordered",false):last_samples[event]=mini(variant,files.size()-1);return files[mini(variant,files.size()-1)]
 var index=rng.randi_range(0,files.size()-1)
 if files.size()>1 and index==int(last_samples.get(event,-1)):index=(index+1+rng.randi_range(0,files.size()-2))%files.size()
 last_samples[event]=index;return files[index]
func emit(event: String,position_value: Vector3=Vector3.INF,gain: float=1.0,pitch_multiplier: float=1.0,variant: int=-1,loop_key: String="") -> bool:
 if not count_emits:return _emit(event,position_value,gain,pitch_multiplier,variant,loop_key)
 var started=Time.get_ticks_usec();var accepted_now=_emit(event,position_value,gain,pitch_multiplier,variant,loop_key);profile_usec+=Time.get_ticks_usec()-started;return accepted_now
func _emit(event: String,position_value: Vector3,gain: float,pitch_multiplier: float,variant: int,loop_key: String) -> bool:
 if event.begins_with("enemy.") or not events.has(event):return false
 if count_emits:emit_counts[event]=int(emit_counts.get(event,0))+1
 if muted:return false
 var config=events[event]
 if config.get("music",false):return false # music has its own players
 if loop_key=="" and clock-float(last_events.get(event,-100))<float(config.get("cooldown",0.05)):cooldown_suppressed+=1;return false
 var priority=int(config.get("priority",1));var spatial=position_value.is_finite();var candidate=-1;var active_event=0
 for i in voices.size():
  var voice=voices[i]
  if voice.until>clock and voice.event==event:active_event+=1
  if spatial!=(voice.player is AudioStreamPlayer3D):continue
  if voice.until<=clock:candidate=i
 if active_event>=int(config.get("max_voices",3)):voice_suppressed+=1;last_events[event]=clock;return false
 if candidate<0:
  var lowest=priority
  for i in voices.size():
   var voice=voices[i]
   if spatial!=(voice.player is AudioStreamPlayer3D):continue
   if voice.player.bus=="UI" and config.get("bus","SFX")!="UI":continue
   if int(voice.priority)<lowest:lowest=int(voice.priority);candidate=i
 if candidate<0:voice_suppressed+=1;last_events[event]=clock;return false
 var path=choose(event,variant)
 if path.is_empty():return false
 var stream=streams[path];var voice=voices[candidate];var player=voice.player;player.stop();player.stream=stream;player.bus=config.get("bus","SFX")
 var pitch=float(config.get("pitch",0.04));player.pitch_scale=float(config.get("base_pitch",1.0))*rng.randf_range(1-pitch,1+pitch)*pitch_multiplier
 player.volume_db=float(config.get("gain_db",-12))+linear_to_db(maxf(gain,0.001))+rng.randf_range(-0.7,0.7)
 if spatial:player.global_position=position_value
 if AudioServer.get_driver_name()!="Dummy":player.play()
 voice.event=event;voice.until=clock+maxf(0.02,stream.get_length()/player.pitch_scale);voice.priority=priority;voice["key"]=loop_key
 if loop_key!="":voice.until=clock+1.0e9
 last_events[event]=clock;accepted+=1;recent.append(event)
 if recent.size()>16:recent.pop_front()
 return true
# Looping sounds (shrine charge, heartbeat, aura, scythes, element layers) hold one pooled voice under a key.
func loop_start(key: String,event: String,position_value: Vector3=Vector3.INF,gain: float=1.0,pitch_multiplier: float=1.0) -> bool:
 if loop_active(key):return true
 return emit(event,position_value,gain,pitch_multiplier,-1,key)
func loop_active(key: String) -> bool:
 for voice in voices:
  if voice.get("key","")==key and voice.until>clock:return true
 return false
func loop_update(key: String,pitch_multiplier: float,position_value: Vector3=Vector3.INF,gain: float=1.0) -> bool:
 if not count_emits:return _loop_update(key,pitch_multiplier,position_value,gain)
 var started=Time.get_ticks_usec();var found=_loop_update(key,pitch_multiplier,position_value,gain);profile_usec+=Time.get_ticks_usec()-started;return found
func _loop_update(key: String,pitch_multiplier: float,position_value: Vector3,gain: float) -> bool:
 for voice in voices:
  if voice.get("key","")==key and voice.until>clock:
   var config=events[voice.event];var player=voice.player
   player.pitch_scale=float(config.get("base_pitch",1.0))*pitch_multiplier
   player.volume_db=float(config.get("gain_db",-12))+linear_to_db(maxf(gain,0.001))
   if position_value.is_finite() and player is AudioStreamPlayer3D:player.global_position=position_value
   return true
 return false
func silence_loops() -> void:
 for voice in voices:
  if voice.get("key","")!="":voice.player.stop();voice.until=0;voice.key=""
func loop_stop(key: String) -> void:
 for voice in voices:
  if voice.get("key","")==key:voice.player.stop();voice.until=0;voice.key=""
static func element_id(element: String) -> String:
 return "electric" if element=="electricity" else element
func stop_event(event: String):
 for voice in voices:
  if voice.event==event:voice.player.stop();voice.until=0
func _process(delta: float):
 clock+=delta;music_tick(delta)
# --- Music state machine -----------------------------------------------------------------------------------
# menu (every out-of-run screen, never restarted between screens) -> stage N (A, then B ~3 s crossfaded, alternating) ->
# level-up swaps in level_up_loop and resumes the stage track where it left off -> death / victory results.
func music_menu() -> void:
 if music_state=="menu":return
 music_state="menu";music_pending={};music_duck(false);music_play("music.main_menu_loop",1.5)
func music_stage(stage: int) -> void:
 if music_state=="stage" and stage_number==stage:return
 music_state="stage";music_pending={};stage_number=stage;stage_side=0;music_duck(false);music_play(stage_track(stage,0),1.5)
func stage_track(stage: int,side: int) -> String:return STAGE_TRACKS[posmod(stage-1,STAGE_TRACKS.size())][side]
func music_levelup_open() -> void:
 if music_state!="stage":return
 resume_event=current_track;resume_position=music_elapsed;music_state="levelup";music_play("music.level_up_loop",1.5)
func music_levelup_close() -> void:
 if music_state!="levelup":return
 music_state="stage";music_play(resume_event,1.2,resume_position)
func music_death() -> void:
 music_state="death";music_duck(false);music_fade_out(1.0);music_pending={"event":"music.death_loop","at":clock+DEATH_LOOP_DELAY,"state":"death"}
func music_victory() -> void:
 music_state="victory";music_duck(false);music_fade_out(1.5);music_pending={"event":"music.main_menu_loop","at":clock+VICTORY_MENU_DELAY,"state":"menu"}
func music_duck(on: bool) -> void:
 if on==ducked:return
 ducked=on;var index=AudioServer.get_bus_index("Music")
 if AudioServer.get_bus_effect_count(index)<2:return
 var lowpass=AudioServer.get_bus_effect(index,0) as AudioEffectLowPassFilter;var amplify=AudioServer.get_bus_effect(index,1) as AudioEffectAmplify
 AudioServer.set_bus_effect_enabled(index,0,true);AudioServer.set_bus_effect_enabled(index,1,true)
 if duck_tween and duck_tween.is_valid():duck_tween.kill()
 duck_tween=create_tween().set_parallel(true)
 duck_tween.tween_property(amplify,"volume_db",DUCK_DB if on else 0.0,0.3);duck_tween.tween_property(lowpass,"cutoff_hz",DUCK_CUTOFF_HZ if on else 20500.0,0.3)
 if not on:duck_tween.chain().tween_callback(func():AudioServer.set_bus_effect_enabled(index,0,false);AudioServer.set_bus_effect_enabled(index,1,false))
var duck_tween: Tween
func music_fade_out(seconds: float) -> void:
 if music_tween and music_tween.is_valid():music_tween.kill()
 music_tween=create_tween().set_parallel(true)
 for player in music_players:music_tween.tween_property(player,"volume_db",-60.0,seconds)
 music_tween.chain().tween_callback(func():for player in music_players:player.stop())
 current_track=""
func music_play(event: String,fade: float,from: float=0.0) -> void:
 if not events.has(event) or not events[event].has("music"):return
 var config=events[event];var stream=streams.get(config.files[0]) as AudioStream
 if stream==null:return
 if music_tween and music_tween.is_valid():music_tween.kill()
 var old=music_players[music_slot];music_slot=1-music_slot;var next=music_players[music_slot];next.stop();next.stream=stream;next.volume_db=-60
 if AudioServer.get_driver_name()!="Dummy":next.play(from)
 current_track=event;music_elapsed=from
 music_tween=create_tween().set_parallel(true);music_tween.tween_property(next,"volume_db",float(config.get("gain_db",-6)),fade);music_tween.tween_property(old,"volume_db",-60.0,fade)
 music_tween.chain().tween_callback(old.stop)
func music_tick(delta: float) -> void:
 if not music_pending.is_empty() and clock>=float(music_pending.at):
  var pending=music_pending;music_pending={};music_state=str(pending.state);music_play(str(pending.event),2.0)
 if music_state=="stage" and current_track!="":
  music_elapsed+=delta
  var length=float(streams[events[current_track].files[0]].get_length())
  if music_elapsed>=length-crossfade_seconds:
   stage_side=1-stage_side;music_play(stage_track(stage_number,stage_side),crossfade_seconds)
func diagnostics() -> Dictionary:
 var count=0
 for voice in voices:
  if voice.until>clock:count+=1
 return {"active_voices":count,"players":voices.size(),"accepted":accepted,"cooldown_suppressed":cooldown_suppressed,"voice_suppressed":voice_suppressed,"recent":recent.duplicate(),"bus_db":bus_levels()}
func bus_levels() -> Dictionary:
 var result={}
 for name in ["Master","Music","SFX","UI","Ambience"]:result[name]=AudioServer.get_bus_volume_db(AudioServer.get_bus_index(name))
 return result
func _exit_tree():
 if music_tween and music_tween.is_valid():music_tween.kill()
 for player in music_players:player.stop();player.stream=null
 if is_instance_valid(ambience_player):ambience_player.stop();ambience_player.stream=null
 for voice in voices:voice.player.stop();voice.player.stream=null
 voices.clear();music_players.clear();streams.clear()

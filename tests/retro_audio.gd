extends SceneTree
var checks=0
var failures=[]
func check(value: bool,label: String):
 checks+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error(label)
class MotionProbe extends Node3D:
 var velocity=Vector3.ZERO
 var posture="standing"
 var ground=true
 func is_on_floor():return ground
 func get_floor_normal():return Vector3.UP
class MotionGame extends Node:
 var player
 var audio
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 var audio=game.audio;audio.set_process(false)
 check(audio.voices.size()==24 and audio.music_players.size()==2,"Bounded 24 SFX/UI voices and two music crossfade players")
 for name in ["Master","Music","SFX","UI","Ambience"]:check(AudioServer.get_bus_index(name)>=0,"Independent native audio bus: "+name)
 check(audio.events.size()>=30 and audio.streams.size()>100,"Only curated/preloaded event resources registered")
 for event in ["weapon.revolver.fire","weapon.lightning.strike","weapon.shotgun.fire","weapon.scythes.hit","player.damage","player.footstep.grass","player.footstep.rock","player.slide","pickup.xp","combat.explosion"]:
  var files=audio.events[event].files;var previous="";var varied=true
  for i in 200:
   var sample=audio.choose(event)
   if not sample in files or sample==previous:varied=false
   previous=sample
  check(files.size()>=3 and varied,"Appropriate variation pool avoids immediate repeats: "+event)
 var byte_count=0
 for path in audio.streams:
  check(ResourceLoader.exists(path),"Selected audio dependency loads: "+path.get_file())
  if path.begins_with("res://assets/audio/sfx/"):byte_count+=FileAccess.get_file_as_bytes(path).size()
 check(byte_count>0 and not DirAccess.dir_exists_absolute("res://assets/audio/sfx/library"),"Source library stays outside project; curated byte count="+str(byte_count))
 audio.volumes({"master":0,"music":.2,"effects":.8,"ui_volume":.4,"ambience":.3})
 check(AudioServer.is_bus_mute(0),"Master zero mutes exactly")
 check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))-linear_to_db(.2))<.01,"Music gain converts linear slider to decibels")
 check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))-linear_to_db(.8))<.01,"SFX gain independent from music")
 audio.volumes(game.settings)
 game.progress.storage_path="user://retro-audio-settings-test.json";var old=game.progress.data.settings.duplicate(true);game.settings.ui_volume=.25;game.settings.ambience=.45;game.progress.data.settings=game.settings.duplicate(true);game.progress.save()
 var restored=Progress.new();restored.load_save(game.progress.storage_path)
 check(is_equal_approx(float(restored.data.settings.ui_volume),.25) and restored.data.settings.has("sensitivity"),"Audio settings survive profile reload while preserving gameplay settings")
 game.progress.data.settings=old;game.progress.save()
 for v in audio.voices:v.until=0
 audio.clock=100;audio.last_events.clear();var accepted=audio.accepted
 for i in 1000:audio.emit("pickup.xp",game.player.position)
 check(audio.accepted==accepted+1 and audio.cooldown_suppressed>=999,"Mass XP collection aggregates without a voice per gem")
 audio.clock=101;audio.emit("weapon.revolver.fire",Vector3(4,2,1))
 var spatial=false
 for v in audio.voices:
  if v.event=="weapon.revolver.fire" and v.until>audio.clock:spatial=v.player is AudioStreamPlayer3D and v.player.global_position==Vector3(4,2,1) and v.player.bus=="SFX"
 check(spatial,"Positional weapon event uses preallocated 3D voice and SFX bus")
 for v in audio.voices:v.until=audio.clock+10;v.priority=1;v.event="ui.hover"
 check(audio.emit("player.damage"),"Player damage preempts lower-priority voices")
 for v in audio.voices:v.until=audio.clock+10;v.priority=5;v.event="player.damage"
 audio.last_events.erase("ui.confirm")
 check(not audio.emit("ui.confirm"),"Low-priority UI cannot steal protected important voices")
 for v in audio.voices:v.until=0
 audio.clock+=20;audio.last_events.clear();game.weapons.clear();game.equip(0);game.enemies.clear()
 var e=game.spawn_enemy(0,game.player.position+Vector3(4,0,0));e.hp=10000;e.max_hp=e.hp
 accepted=audio.accepted;var burst=game.combat_fx.bursts_created;game.hit(e,1,0)
 check(e.hit_time>0 and e.hit_time<=.12 and game.combat_fx.bursts_created>burst,"Damage immediately sets brief flash and pooled impact particles")
 check(audio.accepted==accepted,"Enemy ordinary damage triggers no generic pain/hit audio")
 var shader=FileAccess.get_file_as_string("res://shaders/enemy_feedback.gdshader")
 check(shader.contains("mix(vec3(1.0),vec3(0.45,1.0,0.35),flash_tint)") and not shader.contains("vec3(1.0,0.025,0.015)"),"Shared textured enemy feedback mixes to white (light green only for Aura hits)")
 e.hit_time=0;game.enemy_view.begin_frame();game.enemy_view.draw_enemy(e,game.player.position);game.enemy_view.end_frame()
 var restored_flash=true
 for batch in game.enemy_view.batches.values():
  for i in batch.multimesh.visible_instance_count:
   if batch.multimesh.get_instance_custom_data(i).r>0:restored_flash=false
 check(restored_flash,"Expired enemy flash restores original shared appearance")
 game.stats=Catalog.base_stats();game.health=100;game.invulnerability=0;game.loadout_runtime.reset("climber","nova");game.player.velocity=Vector3.ZERO
 var position=game.player.position;var applied=game.hurt_contact(10,position+Vector3.RIGHT)
 check(applied and game.player.velocity.x<0 and game.player.velocity.y==0 and game.player.velocity.length()<4,"Contact damage makes a restrained directional horizontal shunt")
 var velocity=game.player.velocity;var health=game.health;game.hurt_contact(10,position+Vector3.RIGHT)
 check(game.player.velocity==velocity and game.health==health,"Invulnerability prevents repeated damage and shunt stacking")
 game.player.launch(Vector3.LEFT,18,13)
 check(game.player.velocity.y>=13 and absf(game.player.velocity.x)>12,"Explosion launch remains substantially stronger than contact shunt")
 var required=["weapon.sword.swing","weapon.sword.hit","weapon.sword.crit","weapon.firestaff.cast","weapon.firestaff.impact","weapon.firestaff.crit","weapon.lightning.strike","weapon.lightning.thunder","weapon.lightning.chain","weapon.lightning.crit","weapon.bow.fire","weapon.bow.hit","weapon.bow.crit","weapon.revolver.fire","weapon.revolver.hit","weapon.revolver.ricochet","weapon.revolver.crit","weapon.aura.hum","weapon.aura.pulse","weapon.aura.crit","weapon.scythes.throw","weapon.scythes.hit","weapon.scythes.catch","weapon.scythes.crit","weapon.shotgun.fire","weapon.shotgun.hit","weapon.shotgun.crit"]
 check(required.all(func(k):return audio.events.has(k)),"Every Weapon Overhaul attack/hit/crit/special event is registered")
 check(audio.events.keys().all(func(k):return not (k.begins_with("weapon.") and (k.contains("chunkers") or k.contains("bone") or k.contains("bananarang") or k.contains("mines") or k.contains("aegis")))),"No audio events remain for removed weapons")
 check(audio.events["weapon.shotgun.fire"].base_pitch<audio.events["weapon.revolver.fire"].base_pitch and audio.events["weapon.shotgun.fire"].gain_db>audio.events["weapon.revolver.fire"].gain_db,"Shotgun report is lower and heavier than revolver")
 check(audio.events["weapon.aura.hum"].max_voices==1 and audio.events["weapon.aura.hum"].cooldown>=1.5,"Aura hum is a single slow voice (no per-frame sound)")
 check(audio.tracks.size()==1 and not audio.menu_track.is_empty(),"Exactly one supplied looping menu and game track configured")
 var track=audio.current_track;var slot=audio.music_slot;audio.music_stage(game.stage)
 check(audio.current_track==track and audio.music_slot==slot,"Same-stage music does not restart")
 audio.music_stage(2);check(audio.current_track==track and audio.music_slot==slot,"Stage transitions preserve the same looping game track")
 var probe=MotionProbe.new();root.add_child(probe);var motion_game=MotionGame.new();motion_game.player=probe;motion_game.audio=audio;var motion=MovementAudio.new()
 for voice in audio.voices:voice.until=0
 audio.clock+=10;audio.last_events.clear();accepted=audio.accepted;probe.velocity=Vector3.ZERO
 motion.tick(motion_game,1)
 check(audio.accepted==accepted,"Standing still emits no footsteps")
 probe.velocity=Vector3(8,0,0)
 for i in 30:audio.clock+=.1;motion.tick(motion_game,.1)
 check(audio.accepted>accepted and audio.recent.has("player.footstep.grass"),"Grounded movement emits distance-based grass footsteps")
 accepted=audio.accepted;probe.ground=false;probe.velocity=Vector3(8,-6,0)
 for i in 10:audio.clock+=.1;motion.tick(motion_game,.1)
 check(audio.accepted==accepted,"Airborne movement emits no footsteps")
 probe.ground=true;audio.clock+=1;motion.tick(motion_game,.1)
 check(audio.recent.back()=="player.land","A grounded transition after a fall emits landing audio")
 probe.posture="sliding";audio.clock+=1;motion.tick(motion_game,.1)
 check(audio.recent.back()=="player.slide","Sliding starts its own scrape instead of footsteps")
 probe.posture="standing";motion.tick(motion_game,.01)
 probe.queue_free();motion_game.free()
 audio.stop_event("player.slide");check(not audio.voices.any(func(v):return v.event=="player.slide" and v.until>audio.clock),"Slide stop silences its pooled voices")
 var sliders=0
 for tab in ["Display","Graphics","Audio","Gameplay"]:
  SettingsScreen.last_tab=tab;game.frontend.settings(game.frontend.home);await process_frame
  for n in RewardScreens.descendants(game.frontend.menu):
   if n is HSlider:sliders+=1
 check(sliders>=7,"Settings (all four tabs) retain graphics/gameplay controls and all five audio sliders")
 game.frontend.reward("hourglass_damned");await process_frame;audio.clock+=2;audio.last_events.clear();accepted=audio.accepted;var skip=game.frontend.chest_skip;skip.call();var after=audio.accepted
 check(after>accepted and not audio.voices.any(func(v):return v.event=="reward.chest.tick" and v.until>audio.clock),"Chest skip stops cycling and plays predetermined reveal celebration")
 skip.call();check(audio.accepted==after,"Repeated reveal callback cannot play another celebration")
 check(not game.frontend.chest_skip.is_valid(),"Reveal closure clears skip action to prevent duplicate celebration")
 game.queue_free();await process_frame;await process_frame;await process_frame
 print("RETRO AUDIO: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

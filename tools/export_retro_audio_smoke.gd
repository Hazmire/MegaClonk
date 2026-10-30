extends SceneTree
func _initialize():call_deferred("run")
func require(value: bool,label: String) -> bool:
 if not value:push_error(label);quit(1)
 return value
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.begin_run();game.set_physics_process(false);game.player.active=false
 var audio=game.audio
 if not require(not audio.events.keys().any(func(e):return str(e).begins_with("enemy.")),"Compiled enemy sounds remain active"):return
 game.health=25;game.stats.max_health=100;game.tomes={"Wind":2};game.update_hud();await process_frame
 var hud_rows=game.frontend.run_hud.build_box
 if not require(hud_rows.get_child(3).get_children().filter(func(n):return n.tooltip_text!="").size()==1 and hud_rows.get_child(3).position.y>=hud_rows.get_child(1).position.y+hud_rows.get_child(1).size.y,"Compiled tome row missing or misplaced"):return
 if not require(game.frontend.health_text.text=="25 / 100" and game.frontend.character_health.value==25 and game.frontend.character_health.size.y<=7.1,"Compiled health bars/numbers incorrect"):return
 if not require(audio.events.size()>=30 and audio.voices.size()==24,"Compiled audio registry/pool incomplete"):return
 for config in audio.events.values():
  for path in config.files:
   if not require(audio.streams.has(path) and audio.streams[path].get_length()>0,"Compiled sample missing: "+path):return
 for event in audio.events.keys().filter(func(k):return audio.events[k].get("music",false)):
  if not require(audio.streams[audio.events[event].files[0]].get_length()>60,"Compiled music missing"):return
 if not require(not FileAccess.file_exists("res://Helton.Yan.s.Pixel.Combat.zip") and not DirAccess.dir_exists_absolute("res://assets/vendor/audio"),"Bulk/unused source audio exported"):return
 audio.volumes({"master":0,"music":.2,"effects":.8,"ui_volume":.4,"ambience":.3})
 if not require(AudioServer.is_bus_mute(0) and absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))-(linear_to_db(.2)+RetroAudio.MUSIC_OFFSET_DB))<.01,"Compiled audio buses incorrect"):return
 audio.volumes(game.settings);var previous=""
 for i in 20:
  var selected=audio.choose("weapon.revolver.fire")
  if not require(selected!=previous,"Compiled sound variations repeat immediately"):return
  previous=selected
 game.health=100;game.invulnerability=0;game.stats=Catalog.base_stats();game.player.velocity=Vector3.ZERO;game.loadout_runtime.reset("climber","nova")
 if not require(game.hurt_contact(10,game.player.position+Vector3.RIGHT) and game.player.velocity.x<0 and game.player.velocity.y==0,"Compiled contact shunt incorrect"):return
 var health=game.health;var velocity=game.player.velocity;game.hurt_contact(10,game.player.position+Vector3.RIGHT)
 if not require(game.health==health and game.player.velocity==velocity,"Compiled contact damage ignores immunity"):return
 audio.music_stage(2)
 if not require(audio.current_track=="music.stage2_a_red_canopy","Compiled stage music incorrect"):return
 game.queue_free();await process_frame;await process_frame;await process_frame
 print("EXPORTED RETRO AUDIO V11 SMOKE COMPLETE");quit()

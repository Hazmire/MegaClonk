extends SceneTree
var failures: Array[String]=[]
var count=0
func check(value: bool, label: String):
 count+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func run():
 var clock=StageClock.new()
 check(clock.remaining()==600,"Stage starts at 10:00")
 check(clock.advance(119).is_empty(),"No event before first threshold")
 check(clock.advance(1)==["rush_1"],"Rush at 08:00 remaining")
 check(clock.pressure()>=1.8,"Rush increases spawn pressure")
 check(clock.advance(60)==["miniboss_1"],"First encounter threshold at 07:00")
 check(clock.advance(250)==["rush_2","miniboss_2"],"Frame crossing multiple thresholds loses no events")
 var saved=clock.serialize();var restored=StageClock.new();restored.restore(saved)
 check(restored.advance(0).is_empty(),"Load does not repeat events")
 check(restored.advance(200)==["endless"] and restored.remaining()==0,"Endless activates once and clock stays zero")
 check(restored.advance(100).is_empty(),"Endless does not repeat")
 var previous=restored.pressure();restored.advance(90)
 check(restored.pressure()>previous,"Endless pressure increases gradually")
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://stage-loop-profile.json"
 game.next_run_seed=542;game.selected_trait="seer";game.selected_ultimate="ghost";game.map_seed_override=9;game.begin_run()
 game.mode="pause";game.player.active=false
 check(game.stage_time==0 and game.portal_state=="dormant","New run has dormant portal and fresh clock")
 check(game.portal.position.distance_to(game.player.position)>40 and abs(game.portal.position.x)<90 and abs(game.portal.position.z)<90,"Portal is away from spawn inside playable interior")
 check(game.player.avatar is KnightVisual and game.player.avatar.rig.get_bone_count()==14,"Supplied fourteen-bone Knight rig loads")
 check(game.player.avatar.playback.has_animation("k_idle"),"Supplied idle animation loads")
 var body=game.player.avatar.surfaces[0]
 check(body.get_surface_override_material(0).get_shader_parameter("u_albedo_texture")!=null,"Supplied Knight armour atlas is explicitly bound")
 for pose in ["idle","run","turn","jump","fall","crouch","slide","hit","death"]:
  game.player.avatar.animate(pose,8,0.1)
  check(game.player.avatar.playback.is_playing(),"Knight animation state "+pose)
 check(game.activate_portal() and game.boss_spawned and game.portal_state=="summoned","Dormant portal summons boss immediately")
 check(not game.activate_portal(),"Active boss blocks stage travel and duplicate summons")
 var boss={}
 for e in game.enemies:
  if e.kind==8:boss=e
 game.kill_enemy(game.enemies.find(boss))
 check(game.boss_dead and game.portal_state=="exit" and game.mode=="pause","Boss death unlocks exit without ending stage")
 game.stage_clock.advance(135);game.stage_time=game.stage_clock.elapsed
 game.gold=123;game.level=7;game.stats.damage=1.35
 game.weapons[game.selected_weapon].level=4
 game.loadout_runtime.cooldown=60
 var selection=game.variants.serialize()
 check(game.save_run("user://stage-loop-checkpoint.json"),"Checkpoint saves portal and event state")
 check(game.load_run("user://stage-loop-checkpoint.json"),"Checkpoint restores")
 game.mode="pause";game.player.active=false
 check(game.stage_clock.fired.has("rush_1") and game.stage_clock.advance(0).is_empty(),"Live save preserves fired events")
 check(game.portal_state=="exit" and game.boss_dead,"Live save restores exit state")
 check(game.advance_stage() and game.stage==2 and game.stage_time==0,"Exit advances to stage 2 with reset countdown")
 game.mode="pause";game.player.active=false
 check(game.gold==123 and game.level==7 and game.stats.damage==1.35 and game.weapons[game.selected_weapon].level==4,"Stage travel preserves build, stats, gold and level")
 check(game.variants.serialize()==selection,"Stage travel preserves per-run variants")
 check(game.portal_state=="dormant" and game.stage_clock.fired.is_empty(),"New stage resets portal and events")
 check(game.loadout_runtime.cooldown==0 and game.frontend.minimap.reveal_all,"New stage readies ultimate and preserves Cartographer")
 game.stage_clock.advance(601);game.stage_time=game.stage_clock.elapsed
 check(game.activate_portal(),"Boss can be summoned during endless mode")
 check(game.save_run("user://stage-loop-checkpoint.json") and game.load_run("user://stage-loop-checkpoint.json") and game.stage==2,"Stage number survives save/load")
 game.mode="pause";game.player.active=false
 var before=game.stage_time;game._physics_process(10)
 check(game.stage_time==before,"Paused simulation stops stage clock")
 for file in ["user://stage-loop-checkpoint.json","user://active-run.json","user://stage-loop-profile.json"]:
  if FileAccess.file_exists(file):DirAccess.remove_absolute(file)
 game.queue_free();await process_frame;await process_frame
 print("STAGE LOOP RESULT: %d checks, %d failures"%[count,failures.size()]);quit(0 if failures.is_empty() else 1)

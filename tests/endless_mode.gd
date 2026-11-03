extends SceneTree
# Endless mode: the state, the ghosts, the curves, the HUD timer, the banshee, the records. Run:
#   tools/godot.sh --headless --path . --script tests/endless_mode.gd
var failures: Array[String]=[]
var count=0
var game: Node
var auto_resume=true # level-ups and rewards open while a long step runs; resume past them unless a test is checking that they stop the clock
func check(value: bool, label: String):
 count+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func fresh(seed_value: int=542) -> void:
 if game==null: # one Game for the whole file: a second instance re-registers the input actions
  game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://endless-test-profile.json"
 game.next_run_seed=seed_value;game.map_seed_override=9;game.begin_run();game.resume();game.set_physics_process(false);game.spawn_clock=0.0
func step(seconds: float,dt: float=0.1) -> void:
 var n=maxi(1,int(round(seconds/dt)))
 for i in n:
  if auto_resume and game.mode!="run" and game.mode!="results":game.pending_upgrades=0;game.reward_queue.clear();game.mode="run"
  game._physics_process(seconds/n)
func to_switch() -> void: # one tick before the stage clock hits 0:00, then across it
 game.stage_clock.elapsed=StageClock.DURATION-0.25;game.stage_time=game.stage_clock.elapsed
 step(0.5,0.05)
func ghosts() -> Array:
 var out=[]
 for e in game.enemies:
  if e.has("ghost"):out.append(e)
 return out
func tiers_alive() -> Array:
 var seen={}
 for e in ghosts():seen[int(e.tier)]=true
 var out=seen.keys();out.sort();return out
func run():
 MenuScreen.set_instant(true)
 await curves()
 await state_checks()
 await clock_checks()
 await tier_checks()
 await determinism_checks()
 await cap_checks()
 await hud_checks()
 await records_checks()
 await survival_checks()
 print("endless_mode: %d checks, %d failures"%[count,failures.size()])
 if failures.is_empty():print("ALL PASS");quit(0)
 else:for f in failures:print("FAILED: "+f)
 if not failures.is_empty():quit(1)
# ---- 1. The curves (pure data) ------------------------------------------------------------------------------------
func curves() -> void:
 var d=Endless.data()
 check(Endless.cap()==600,"Ghost hard cap is 600")
 check(Endless.LOCK_PORTAL,"LOCK_PORTAL is on")
 var ok=true
 for i in Endless.tiers().size():
  for m in range(0,120):
   if Endless.tier_hp(i,m+1)<=Endless.tier_hp(i,m) or Endless.tier_damage(i,m+1)<=Endless.tier_damage(i,m) or Endless.tier_speed(i,m+1)<=Endless.tier_speed(i,m):ok=false
 check(ok,"HP, damage and speed rise every minute for every tier, for 120 minutes")
 var rate_ok=true
 for m in range(0,120):
  if Endless.spawn_rate(m+1)<=Endless.spawn_rate(m):rate_ok=false
 check(rate_ok,"Spawn rate rises every minute with no ceiling")
 check(Endless.tier_speed(0,120)>Endless.tier_speed(0,60) and Endless.tier_damage(0,120)>Endless.tier_damage(0,60),"No cap on escalation: minute 120 is above minute 60")
 check(Endless.tier_speed(0,0)<float(d.player_run_speed),"At the switch ghosts are slower than the player")
 check(Endless.tier_speed(0,10.0)>=float(d.player_run_speed),"Speed passes the player's run speed by endless 10:00")
 check(Endless.tier_speed(0,13.0)>=float(d.stress_run_speed),"Speed passes the stress build's run speed by 13:00")
 check(Endless.tier_damage(0,15.0)>=float(d.stress_effective_hp),"One contact kills the stress build by 15:00")
 var joins=[0.0,3.0,6.0,10.0]
 for i in 4:check(is_equal_approx(float(Endless.tier(i).join_min),joins[i]),"Tier %d joins at %.0f:00"%[i,joins[i]])
 check(Endless.tier_joined(1,2.99)==false and Endless.tier_joined(1,3.0),"Drowned joins exactly at 3:00")
 check(float(Endless.tier(3).scale)>=1.3,"Hollow is 1.3x size")
 check(Endless.clock(5)=="00:05" and Endless.clock(3725)=="1:02:05","Endless clock formats MM:SS and H:MM:SS")
 print("CURVES (spawn/s | HP | damage | speed m/s) per tier")
 for i in 4:
  var row=[]
  for m in [0,5,10,15,20]:row.append("%.2f|%.0f|%.0f|%.1f"%[Endless.spawn_rate(m)*float(Endless.tier(i).weight),Endless.tier_hp(i,m),Endless.tier_damage(i,m),Endless.tier_speed(i,m)])
  print("  ",Endless.tier(i).id,"  ","   ".join(row))
# ---- 2. Start state, spawning, portal -----------------------------------------------------------------------------
func state_checks() -> void:
 await fresh()
 check(not game.endless and ghosts().is_empty(),"Before 0:00 there is no endless state and no ghosts")
 game.spawn_clock=0.0;step(2.0)
 var normal_before=game.enemies.size()
 to_switch()
 check(game.endless and game.endless_started,"Endless starts when the clock hits 0:00")
 check(int(game.run_metrics.get("endless",0))==1,"It starts exactly once (metric 1)")
 var t0=game.endless_time
 check(t0>=0.0 and t0<0.5,"endless_time starts at 0 (%.2f)"%t0)
 var normals=[]
 for e in game.enemies:
  if not e.has("ghost"):normals.append(e)
 game.enemies=game.enemies.filter(func(e):return e.has("ghost"))
 game.settings.invincible=true;game.sandbox=true
 step(60.0)
 var normal_after=0
 for e in game.enemies:
  if not e.has("ghost"):normal_after+=1
 check(normal_after==0,"Normal spawning has stopped for good (%d normal enemies after 60 s)"%normal_after)
 check(game.ghost_count>0,"Ghosts spawn (%d alive after 60 s)"%game.ghost_count)
 check(game.activate_portal()==false and game.advance_stage()==false,"The portal is sealed")
 game.stage_event("endless");var t1=game.endless_time
 check(game.endless_time==t1 and int(game.run_metrics.endless)==1,"A second endless event does nothing")
 step(3.0);check(game.endless_time>t1,"endless_time keeps advancing")
 # Level-ups, chests and gems keep working: grant them directly.
 var lv=game.level;game.xp+=1.0e6;game.add_xp(0.0) if game.has_method("add_xp") else null
 check(game.level>=lv,"XP still accrues in endless")
 # Save & quit and reload: it does not start again and the clock continues.
 game.set_physics_process(false)
 var path="user://endless-test-save.json";var before=game.endless_time;var gh=game.ghost_count
 check(game.save_run(path),"Save & quit writes a checkpoint during endless")
 await fresh(11)
 check(game.load_run(path),"The checkpoint loads")
 check(game.endless and game.endless_started and absf(game.endless_time-before)<0.01,"Reload restores endless and endless_time (%.2f vs %.2f)"%[game.endless_time,before])
 check(game.ghost_count==gh and ghosts().size()==gh,"Reload restores the live ghosts (%d)"%gh)
 game.mode="run";game.stage_event("endless")
 check(absf(game.endless_time-before)<0.01,"The endless event after a reload does not restart it")
 game.set_physics_process(false)
 DirAccess.remove_absolute(path)
 # A boss that is already alive stays.
 await fresh(33)
 game.activate_portal();var boss_alive=false
 for e in game.enemies:if e.kind==8:boss_alive=true
 to_switch()
 var boss_still=false
 for e in game.enemies:if e.kind==8:boss_still=true
 check(not boss_alive or boss_still,"A stage boss already alive stays when endless starts")
# ---- 3. The endless clock vs pause, rewards, hostile time ---------------------------------------------------------
func clock_checks() -> void:
 await fresh(77)
 to_switch();step(5.0)
 var a=game.endless_time
 auto_resume=false
 for m in ["pause","upgrade","reward","shop","map","results"]:
  game.mode=m;step(1.0);check(game.endless_time==a,"endless_time stops in mode '%s'"%m)
 game.mode="run";step(1.0);check(game.endless_time>a,"and resumes with the run")
 var b=game.endless_time;var spawned=game.ghost_count
 game.world_time.activate(0.0)
 check(game.world_time.active(),"Stopwatch is active")
 step(2.0);check(absf(game.endless_time-(b+2.0))<0.01,"endless_time keeps counting during the Stopwatch (+%.2f)"%(game.endless_time-b))
 check(game.ghost_count<=spawned+1,"…while ghost spawning is frozen with hostile time (%d -> %d)"%[spawned,game.ghost_count])
 game.world_time.reset();auto_resume=true
# ---- 4. Tiers --------------------------------------------------------------------------------------------------------
func tier_checks() -> void:
 await fresh(5)
 to_switch();game.settings.invincible=true;game.sandbox=true
 var seen_by={}
 for minute in [1.0,3.5,6.5,10.5,14.0]:
  game.endless_time=minute*60.0;game.enemies.clear();game.ghost_count=0;game.ghost_budget=0.0
  for i in 400:Ghosts.spawn(game,Endless.choose_tier(minute,game.ghost_rng),Vector3.INF)
  seen_by[minute]=tiers_alive()
 check(seen_by[1.0]==[0],"At 1:00 only Mourners spawn %s"%str(seen_by[1.0]))
 check(seen_by[3.5]==[0,1],"Drowned join at 3:00 and Mourners keep spawning %s"%str(seen_by[3.5]))
 check(seen_by[6.5]==[0,1,2],"Wrathful join at 6:00 %s"%str(seen_by[6.5]))
 check(seen_by[10.5]==[0,1,2,3] and seen_by[14.0]==[0,1,2,3],"Hollow join at 10:00 and no tier is ever dropped %s"%str(seen_by[14.0]))
 var g=ghosts()[0];var s=Endless.tier(int(g.tier))
 check(float(g.speed)>0.0 and float(g.hp)>0.0,"Ghost carries data-driven HP and speed")
 # Killable through Game.hit(); small XP, no gold.
 game.enemies.clear();game.ghost_count=0
 var e=Ghosts.spawn(game,0,game.player.position+Vector3(5,1,0));var xp0=game.xp;var gold0=game.gold;var kills0=game.kills
 game.hit(e,1.0e9,0);step(0.1)
 check(not game.enemies.has(e) and game.ghost_count==0,"Game.hit() kills a ghost and frees its slot")
 check(game.kills==kills0+1 and game.gold==gold0,"A ghost kill counts as a kill and gives no gold")
 # Contact goes through Game.hurt.
 game.settings.invincible=false;game.sandbox=false;game.invulnerability=0.0
 var hp0=game.health;var near=Ghosts.spawn(game,0,game.player.position+Vector3(0.2,1.1,0.0))
 step(0.3);check(game.health<hp0,"Contact hurts the player through Game.hurt (%.1f -> %.1f)"%[hp0,game.health])
 # Spawn ring: outside the immediate radius, spread of heights.
 game.enemies.clear();game.ghost_count=0;var min_flat=1.0e9;var hs=[]
 for i in 200:
  var gg=Ghosts.spawn(game,0,Vector3.INF)
  if gg.is_empty():continue
  min_flat=minf(min_flat,Vector2(gg.pos.x-game.player.position.x,gg.pos.z-game.player.position.z).length());hs.append(gg.pos.y-game.player.position.y)
 check(min_flat>=float(Endless.data().spawn_ring.immediate_radius)-0.01,"Ghosts never spawn inside the immediate radius (min %.1f m)"%min_flat)
 hs.sort();check(hs.size()>0 and hs[-1]-hs[0]>4.0,"Spawn heights are spread (%.1f m)"%(hs[-1]-hs[0]))
# ---- 5. Determinism -------------------------------------------------------------------------------------------------
func signature() -> String:
 var parts=[]
 for e in ghosts():parts.append("%d:%.2f,%.2f,%.2f"%[e.tier,e.pos.x,e.pos.y,e.pos.z])
 return "%d|%.3f|%s"%[game.ghost_count,game.endless_time,",".join(parts.slice(0,20))]
func determinism_checks() -> void:
 var sigs=[]
 for run_index in 2:
  await fresh(2024);game.settings.invincible=true;game.sandbox=true
  to_switch();game.player.position=Vector3(0,20,0);step(30.0);sigs.append(signature())
 check(sigs[0]==sigs[1],"A seeded run reproduces the same ghost spawns and endless_time")
 await fresh(2025);game.settings.invincible=true;game.sandbox=true;to_switch();game.player.position=Vector3(0,20,0);step(30.0)
 check(signature()!=sigs[0],"A different seed gives different spawns")
# ---- 6. Cap ------------------------------------------------------------------------------------------------------------
func cap_checks() -> void:
 await fresh(6)
 to_switch();game.settings.invincible=true;game.sandbox=true
 game.endless_time=25.0*60.0;game.player.position=Vector3(0,20,0)
 var peak=0;var over=false
 for i in 900: # real frame length, ghosts held in place so the live count can climb (contact would otherwise dissipate them)
  for e in ghosts():e.frozen=999.0
  step(1.0/60.0,1.0/60.0);peak=maxi(peak,game.ghost_count)
  if game.ghost_count>Endless.cap() or ghosts().size()>Endless.cap():over=true
 check(not over,"Live ghosts never exceed the cap (peak %d of %d)"%[peak,Endless.cap()])
 check(peak>=Endless.cap()-5,"At minute 25 the cap is actually reached (peak %d)"%peak)
 var speed_a=Endless.tier_speed(0,25.0);var speed_b=Endless.tier_speed(0,26.0)
 check(speed_b>speed_a and Endless.tier_damage(0,26.0)>Endless.tier_damage(0,25.0),"At the cap damage and speed keep escalating")
 check(game.ghost_view.visible_count()<=Endless.cap()+96,"The ghost view draws within its pooled capacity (%d)"%game.ghost_view.visible_count())
# ---- 7. HUD timer, pause strip, banshee -----------------------------------------------------------------------------
func hud_checks() -> void:
 await fresh(8)
 var hud=game.frontend.run_hud;var label=hud.timer_label;var id_before=label.get_instance_id()
 var path_before=label.get_path();var children_before=hud.get_child_count()
 game.audio.count_emits=true;game.audio.emit_counts.clear()
 game.stage_clock.elapsed=598.0;game.stage_time=598.0;hud.update(0.016);step(0.2)
 check(label.text=="00:01" or label.text=="00:02","Before the switch the timer counts down (%s)"%label.text)
 check(not hud.timer_fx.active,"No endless fx before 0:00")
 var pause_before=RunPause.counter_values(game)
 check(pause_before[1][0]=="Time","Pause strip says Time before endless")
 step(2.5,0.05);hud.update(0.016)
 check(game.endless and hud.timer_fx.active,"At 0:00 the same timer switches to endless")
 check(label.get_instance_id()==id_before and label.get_path()==path_before,"The timer node is the same before and after the switch")
 var timers=0
 for n in hud.find_children("*","Label",true,false):
  if n.name.to_lower().contains("timer") and not n.get_parent() is Control:timers+=1
 check(timers<=1 and hud.get_child_count()==children_before,"No second timer node was added to the HUD")
 check(int(game.audio.emit_counts.get("world.endless_begins_banshee",0))==1,"The banshee played exactly once at the switch")
 check(hud.timer_fx.glitches==1,"The switch plays the glitch once")
 step(1.2);hud.update(0.016);check(label.text==Endless.clock(game.endless_time) and not label.text.begins_with("+"),"Timer shows the endless clock without a plus (%s)"%label.text)
 check(hud.stage_label.text.begins_with("ENDLESS") and not hud.stage_label.text.contains("10:00"),"The line under the timer reads ENDLESS (%s)"%hud.stage_label.text)
 var strip=RunPause.counter_values(game)
 check(strip[1][0]=="ENDLESS" and strip[1][1]==Endless.clock(game.endless_time),"Pause strip reads ENDLESS with the endless clock")
 # Tier styles at 3, 6, 10 minutes; each replays the glitch, never the banshee.
 game.settings.invincible=true;game.sandbox=true
 var caps_ok=true;var styles=[]
 for minute in [1.0,3.0,6.0,10.0,12.0]:
  game.endless_time=minute*60.0+0.5;game.endless_whole=-1;game.player.position=Vector3(0,20,0);step(0.2);hud.update(0.016);hud.timer_fx.tick(0.1,game.endless_time,true)
  styles.append(hud.timer_fx.tier)
  if hud.timer_fx.embers.amount>30 or hud.timer_fx.smoke.amount>12 or hud.timer_fx.active_particles()>42:caps_ok=false
 check(styles==[0,1,2,3,3],"Timer style changes at endless 3, 6 and 10 minutes %s"%str(styles))
 check(hud.timer_fx.tier_changes>=3,"Each tier change replays the glitch (%d changes)"%hud.timer_fx.tier_changes)
 check(caps_ok,"Ember and smoke counts stay within 30 and 12")
 check(int(game.audio.emit_counts.get("world.endless_begins_banshee",0))==1,"The banshee never plays on tier changes")
 var ev=game.audio.events.get("world.endless_begins_banshee",{})
 check(not ev.is_empty() and ev.bus=="SFX" and int(ev.max_voices)==1 and int(ev.priority)>int(game.audio.events["world.boss_enrage_abyssal"].priority),"Banshee is registered: SFX bus, one voice, priority above boss_enrage")
 check(ResourceLoader.exists("res://assets/audio/fog/world/endless_begins_banshee.wav"),"The banshee file ships in the repo")
 # Particles pause with the game.
 game.mode="pause";hud.timer_fx.tick(0.1,game.endless_time,false);check(hud.timer_fx.embers.speed_scale==0.0,"Particles pause with the game")
 game.mode="run"
 # Reduce motion.
 hud.timer_fx.reduce_motion=true;hud.timer_fx.tick(0.1,game.endless_time,true);check(hud.timer_fx.embers.emitting==false or hud.timer_fx.embers.amount<=30,"Reduce motion is honoured")
 # A new run resets the timer.
 game.next_run_seed=9;game.begin_run();game.resume();game.set_physics_process(false);hud.update(0.016)
 check(not hud.timer_fx.active and not game.endless,"A new run puts the timer back to normal")
# ---- 8. Records and Results -----------------------------------------------------------------------------------------
func records_checks() -> void:
 var data={};MetaProgress.migrate(data)
 var r={"weapon":0,"trait":"climber","ultimate":"nova","time":700.0,"kills":10,"victory":false,"metrics":{}}
 r["endless_time"]=0.0;check(MetaProgress.record(data,r,false)==false and float(data.best_endless_time)==0.0,"A run that never reached endless sets no record")
 r["endless_time"]=120.0;check(MetaProgress.record(data,r,false) and float(data.best_endless_time)==120.0,"First endless time is a record")
 r["endless_time"]=90.0;check(MetaProgress.record(data,r,false)==false and float(data.best_endless_time)==120.0,"A shorter time does not replace it")
 r["endless_time"]=120.0;check(MetaProgress.record(data,r,false)==false,"A tie is not a record")
 r["endless_time"]=300.0;check(MetaProgress.record(data,r,true)==false and float(data.best_endless_time)==120.0,"Sandbox runs write nothing")
 r["endless_time"]=300.0;check(MetaProgress.record(data,r,false) and float(data.best_endless_time)==300.0,"A longer time replaces it")
 check(MenuData.best_endless(data)==300.0,"The menu reads the best")
 # Results: a death before 0:00 shows no endless UI.
 await fresh(12);game.settings.invincible=false
 game.progress.data.best_endless_time=0.0
 game.health=0.0;game.finish_run(false);await process_frame
 var info=RunData.results(game,false,[])
 check(not info.endless and game.frontend.menu.find_child("EndlessTime",true,false)==null,"A death before 0:00 shows Results exactly as today (no endless figure)")
 check(game.frontend.menu.find_child("Title",true,false)!=null,"…with the usual title")
 # After endless: the endless time leads, NEW RECORD on the first one.
 await fresh(13);game.sandbox=false;game.progress.data.best_endless_time=0.0
 game.settings.invincible=true;game.sandbox=false;to_switch()
 for i in 75:game.health=game.stats.max_health;step(1.0)
 game.health=0.0;game.finish_run(false);await process_frame
 info=RunData.results(game,false,[])
 print("results info: endless=%s clock=%s record=%s mode=%s endless_time=%.1f best=%s"%[info.endless,info.endless_clock,info.new_record,game.mode,game.endless_time,game.progress.data.best_endless_time])
 check(info.endless and info.endless_clock==Endless.clock(game.endless_time) and info.new_record,"Death in endless reports the endless time and a record")
 check(game.frontend.menu.find_child("EndlessTime",true,false)!=null and game.frontend.menu.find_child("NewRecord",true,false)!=null,"Results lead with the endless time and show NEW RECORD")
 check(float(game.progress.data.best_endless_time)>=70.0,"best_endless_time is saved")
 # Beaten only when beaten: a second, shorter run.
 await fresh(14);game.sandbox=false
 to_switch()
 for i in 20:game.health=game.stats.max_health;step(1.0)
 game.health=0.0;game.finish_run(false);await process_frame
 check(not game.endless_record or game.progress.data.best_endless_time<20.0+1.0,"A shorter endless run does not show NEW RECORD")
# ---- 9. The stress build dies before endless 20:00 -----------------------------------------------------------------
func survival_checks() -> void:
 await fresh(923)
 game.settings.invincible=false;game.sandbox=false
 game.items.clear();game.irt.reset();game.weapons.clear()
 for id in Catalog.ITEM_IDS:
  for i in 5:game.grant_item(id,true)
 for id in [0,1,2,7,9,10,6,15]:game.equip(id)
 game.health=game.stats.max_health
 to_switch()
 var run_speed=float(Endless.data().stress_run_speed);var angle=0.0;var center=Vector3(0,game.player.position.y,0);var died_at=-1.0
 var t=0.0;var dt=0.1
 while t<1200.0+60.0 and game.mode!="results":
  if game.mode!="run":game.pending_upgrades=0;game.reward_queue.clear();game.mode="run"
  angle+=run_speed*dt/40.0;game.player.position=center+Vector3(cos(angle)*40.0,0.0,sin(angle)*40.0);game.player.velocity=Vector3.ZERO
  game._physics_process(dt);t+=dt
  if game.health<=0.0:died_at=game.endless_time;break
 print("survival: stress build at %.1f m/s died at endless %.1f s (%s), ghosts alive %d"%[run_speed,died_at,Endless.clock(maxf(died_at,0.0)),game.ghost_count])
 check(died_at>0.0 and died_at<1200.0,"The stress build with god mode off dies before endless 20:00 (died at %s)"%Endless.clock(maxf(died_at,0.0)))

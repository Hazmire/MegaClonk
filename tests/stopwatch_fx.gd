extends SceneTree
# Stopwatch: hostile time is exactly 0, nothing hostile moves or hurts, everything resumes; the StopwatchFX look; sound loop; weather; layers.
var failures: Array[String]=[]
var count=0
var game: Node
func check(value: bool, label: String):
 count+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func fresh(seed_value: int=311) -> void:
 if game==null:
  game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://stopwatch-fx-profile.json"
 game.next_run_seed=seed_value;game.map_seed_override=9;game.begin_run();game.resume();game.set_physics_process(false);game.spawn_clock=0.0
func step(seconds: float,dt: float=0.05) -> void:
 var n=maxi(1,int(round(seconds/dt)))
 for i in n:
  if game.mode!="run":game.mode="run"
  game._physics_process(seconds/n)
func run():
 MenuScreen.set_instant(true)
 await freeze_rules()
 await durations()
 await fx_checks()
 await sound_and_weather()
 print("stopwatch_fx: %d checks, %d failures"%[count,failures.size()])
 if failures.is_empty():print("ALL PASS");quit(0)
 else:
  for f in failures:print("FAILED: "+f)
  quit(1)
func snapshot() -> Array:
 var out=[]
 for e in game.enemies:out.append(e.pos)
 return out
func freeze_rules() -> void:
 await fresh();game.sandbox=false;game.settings.invincible=false
 var wt: WorldTime=game.world_time
 game.enemies.clear();game.projectiles.clear()
 var far=game.spawn_enemy(0,game.player.position+Vector3(20,0,0))
 var close=game.spawn_enemy(0,game.player.position+Vector3(1.5,0,0))
 var boss=game.spawn_enemy(8,game.player.position+Vector3(0,0,-25))
 var ghost=Ghosts.spawn(game,0,game.player.position+Vector3(-12,0,6))
 game.hostile_bolt(game.player.position+Vector3(10,1,0),game.player.position+Vector3(0,1,0))
 var bolt=game.projectiles[game.projectiles.size()-1];var bolt_start: Vector3=bolt.node.position
 await process_frame
 step(0.5) # let spawn heights settle
 wt.activate();var health=game.health;var enemies_before=game.enemies.size()
 var tracked=[far,close,boss,ghost];var start_pos=[]
 for who in tracked:start_pos.append(who.pos)
 var ok_zero=true;var spawn_ok=true;var hp_ok=true
 for i in 150: # 7.5 s of the 8 s
  game.spawn_clock=0.0
  game._physics_process(0.05)
  if wt.hostile(0.05)!=0.0 or wt.scale!=0.0:ok_zero=false
  if game.enemies.size()>enemies_before:spawn_ok=false
  if game.health<health-0.001:hp_ok=false
 var still=true;var alive=0
 for k in tracked.size():
  if not game.enemies.has(tracked[k]):continue
  alive+=1
  var d=Vector2(tracked[k].pos.x-start_pos[k].x,tracked[k].pos.z-start_pos[k].z).length()
  if d>0.001:still=false;print("MOVED ",k," ",d)
 check(ok_zero,"Hostile time is exactly 0 for the whole Stopwatch")
 check(still and alive>=3,"Enemies, bosses and ghosts do not move for 7.5 s (%d bodies tracked)"%alive)
 check(spawn_ok,"No spawns happen while frozen")
 check(hp_ok and game.health>=health-0.001,"No contact or projectile damage reaches the player while frozen")
 check(Engine.time_scale==1.0,"Engine.time_scale is never touched")
 check(wt.remaining<0.51,"The effect is nearly over after 8 s")
 # the player keeps acting: a player-owned damage still lands and nothing about player time is scaled
 var target=game.spawn_enemy(0,game.player.position+Vector3(4,0,0));target.hp=500.0;target.max_hp=500.0;var hp0=float(target.hp)
 wt.activate()
 game.hit(target,50.0,0,{})
 check(float(target.hp)<hp0,"Damage lands on frozen enemies")
 # resume: same state, then they move again
 wt.reset();var held=snapshot();step(1.0);var moved=false;var now=snapshot()
 for k in mini(held.size(),now.size()):
  if Vector2(held[k].x-now[k].x,held[k].z-now[k].z).length()>0.01:moved=true
 check(moved,"Everything resumes from the same state on release")
 # a hostile bolt does not move while frozen
 game.projectiles.clear();game.hostile_bolt(game.player.position+Vector3(10,1,0),game.player.position+Vector3(0,1,0))
 var b2=game.projectiles[game.projectiles.size()-1];var p0: Vector3=b2.node.position
 wt.activate();game.update_projectiles(0.2)
 check(b2.node.position.distance_to(p0)==0.0,"Enemy projectiles do not move while frozen")
 wt.reset()
func durations() -> void:
 await fresh()
 var wt: WorldTime=game.world_time
 wt.reset()
 wt.activate();check(is_equal_approx(wt.remaining,8.0) and is_equal_approx(wt.fraction(),1.0),"A plain Stopwatch lasts 8 s")
 wt.tick(2.0);check(is_equal_approx(wt.fraction(),6.0/8.0),"Fraction is time left over total (6/8)")
 wt.activate();check(is_equal_approx(wt.remaining,8.0),"A refresh mid-freeze restores 8 s, it never stacks")
 wt.reset();wt.activate(4.0);check(is_equal_approx(wt.remaining,12.0) and is_equal_approx(wt.fraction(),1.0),"A longer Stopwatch (item bonus) lasts 12 s")
 wt.tick(3.0);check(is_equal_approx(wt.fraction(),9.0/12.0),"Fraction with the bonus is left/total (9/12)")
 wt.tick(20.0);check(not wt.active() and wt.just_released and wt.scale==1.0,"It releases exactly once at the end")
 wt.tick(0.1);check(not wt.just_released,"just_released lasts one tick")
 wt.freeze(3.0);check(wt.frozen() and wt.hostile(1.0)==0.0 and is_equal_approx(wt.remaining,3.0),"The Hourglass freezes hostile time the same way")
 wt.tick(3.5);check(not wt.active() and wt.scale==1.0,"The Hourglass releases")
 wt.reset()
func fx_checks() -> void:
 var fx=StopwatchFX.new();root.add_child(fx);await process_frame
 var origin=Vector2(960,540)
 check(fx.layer<game.frontend.layer,"The HUD is never on the effect's layer or below it (%d < %d)"%[fx.layer,game.frontend.layer])
 var started=[0];var ext=[0.0];var rel=[0]
 fx.started.connect(func():started[0]+=1);fx.extended.connect(func(a):ext[0]=a);fx.released.connect(func():rel[0]+=1)
 var left=8.0
 fx.update(left,origin);fx.advance(0.016)
 check(fx.active and started[0]==1 and is_equal_approx(fx.total,8.0),"Start: effect begins with total 8 s")
 var frac_ok=true;var red_ok=true
 while left>0.0:
  left=maxf(0.0,left-0.05);fx.update(left,origin);fx.advance(0.05)
  if fx.active:
   if absf(fx.shown_frac-fx.remaining/fx.total)>0.2 and fx.shown_frac>fx.remaining/fx.total+0.001:frac_ok=false
   if (fx.remaining<=1.0)!=fx.warn:red_ok=false
 check(frac_ok,"Ticks never show more than time left over total")
 check(red_ok,"Red appears only in the last 1.0 s")
 check(rel[0]==1 and not fx.active,"Release fires once at the end")
 for i in 40:fx.advance(0.05)
 check(fx.out_t<0.0 and fx.radius==0.0,"The colour flood finishes and nothing lingers")
 # extension: another pickup mid-freeze
 fx.update(6.0,origin);fx.advance(0.016);fx.update(3.0,origin);fx.advance(0.016);fx.update(8.0,origin);fx.advance(0.016)
 check(ext[0]>4.9 and fx.tag.begins_with("+") and is_equal_approx(fx.total,8.0),"Extension: total becomes the new time left and the +n.ns tag shows (%s)"%fx.tag)
 var wave_before=fx.wave_t
 check(wave_before<0.0 or wave_before>0.2,"No second wave on extension (wave not restarted)")
 for i in 8:fx.advance(0.05)
 check(fx.shown_frac>0.99 or fx.shown_frac>=fx.remaining/fx.total-0.001,"Ticks sweep to full within the refill time")
 check(fx.lit_ticks(0.5)==30 and fx.lit_ticks(1.0)==60,"60 edge ticks: half the fraction lights 30")
 fx.update(0.0,origin);fx.reset();check(not fx.active and fx.flash_a==0.0 and fx.punch_t<0.0,"reset() clears everything")
 fx.reduce_motion=true;fx.update(8.0,origin);fx.advance(0.016)
 check(fx.punch_t<0.0,"Reduce motion disables the zoom punch")
 fx.queue_free()
func sound_and_weather() -> void:
 await fresh();game.audio.count_emits=true;game.audio.emit_counts.clear()
 var wt: WorldTime=game.world_time;wt.reset()
 var fe: FrontEnd=game.frontend
 wt.activate();wt.tick(0.016);RunAudio.stopwatch(game)
 check(game.audio.loop_active(RunAudio.STOPWATCH_KEY),"The stopwatch loop plays while it lasts")
 game.audio.silence_loops();check(not game.audio.loop_active(RunAudio.STOPWATCH_KEY),"The loop stops on pause")
 RunAudio.stopwatch(game);check(game.audio.loop_active(RunAudio.STOPWATCH_KEY),"The loop restarts after the pause")
 wt.activate();RunAudio.stopwatch(game)
 check(int(game.audio.emit_counts.get("powerup.stopwatch_end",0))==0,"An extension plays no new cue")
 wt.tick(20.0);RunAudio.stopwatch(game)
 check(not game.audio.loop_active(RunAudio.STOPWATCH_KEY) and int(game.audio.emit_counts.get("powerup.stopwatch_end",0))==1,"The loop stops on release and the end cue plays once")
 # weather
 var weather=game.player.get_node_or_null(StageDressing.WEATHER_NAME) as GPUParticles3D
 if weather==null:
  weather=GPUParticles3D.new();weather.name=StageDressing.WEATHER_NAME;game.player.add_child(weather)
 fe.weather_node=weather
 wt.reset();fe.update_stopwatch(0.016);check(is_equal_approx(weather.speed_scale,1.0),"Weather runs at full speed when not frozen")
 wt.activate();fe.update_stopwatch(0.016);check(is_equal_approx(weather.speed_scale,0.05),"Weather nearly stops while frozen")
 game.mode="pause";weather.speed_scale=1.0;fe.update_stopwatch(0.016);check(is_equal_approx(weather.speed_scale,0.05),"Weather is re-frozen after a pause mid-freeze")
 game.mode="levelup";weather.speed_scale=1.0;fe.update_stopwatch(0.016);check(is_equal_approx(weather.speed_scale,0.05),"Weather is re-frozen after a level-up mid-freeze")
 wt.reset();fe.update_stopwatch(0.016);check(is_equal_approx(weather.speed_scale,1.0),"Weather is restored on release")
 check(Engine.time_scale==1.0,"Engine.time_scale untouched at the end")
 game.mode="run"

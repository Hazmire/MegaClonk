extends SceneTree
# Fix pass 2: menu hover retrigger, socket hover loudness, Attack Speed label, armour %, lifesteal chance, Difficulty stat,
# credit-based slow-start spawner, enemy distance LOD.
var checks=0
var failures=[]
var game: Node3D
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-fix2.json";game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume();game.spawn_clock=999
 await physics_frame
 # --- audio: menu hover retriggers quickly; socket hover is not buried ---
 var a=game.audio;var ev=a.events
 check(float(ev["ui.hover"].cooldown)<=0.05 and int(ev["ui.hover"].max_voices)>=4,"Menu hover has a short cooldown and several voices (cd %s, voices %s)"%[ev["ui.hover"].cooldown,ev["ui.hover"].max_voices])
 a.last_events.clear();var accepted=0
 for i in 8:
  a.clock+=0.04
  if a.emit("ui.hover"):accepted+=1
 check(accepted>=7,"Eight hovers 40 ms apart retrigger without waiting for the clip (%d accepted)"%accepted)
 check(float(ev["ui.socket_hover"].gain_db)>=0.0,"The quiet socket-hover sample is boosted")
 # --- labels ---
 check(RunData.label("haste")=="Attack speed" and BuildStats.help("haste").begins_with("Attack speed"),"Haste is shown as Attack speed")
 # --- armour is a damage-reduction percentage with falloff ---
 check(is_equal_approx(Armor.reduction(75.0),0.5) and Armor.reduction(0.0)==0.0 and Armor.reduction(1e6)<1.0,"Armour reduction = armour / (75 + armour), never 100%")
 check(BuildStats.value("armor",75.0)=="50%" and BuildStats.value("armor",0.0)=="0%","Armour is displayed as a percentage")
 game.settings.invincible=false;game.stats.evasion=0.0;game.stats.armor=0.0;game.loadout_runtime.reset("climber","nova")
 game.invulnerability=0;game.health=100;game.hurt(20);var plain=100.0-game.health
 game.stats.armor=75.0;game.invulnerability=0;game.health=100;game.hurt(20);var armoured=100.0-game.health
 check(is_equal_approx(armoured,plain*0.5),"75 armour halves incoming damage (%.1f vs %.1f)"%[armoured,plain])
 game.settings.invincible=true
 # --- lifesteal: chance to restore 1 HP per hit; over 100% adds guaranteed HP ---
 var total=0.0;game.stats.lifesteal=0.5
 for i in 600:total+=game.lifesteal_hp()
 check(total/600.0>0.42 and total/600.0<0.58,"50%% lifesteal restores 1 HP about half the time (%.2f avg)"%(total/600.0))
 game.stats.lifesteal=2.5;total=0.0;var low=9.0
 for i in 600:
  var h=game.lifesteal_hp();total+=h;low=minf(low,h)
 check(low>=2.0 and total/600.0>2.4 and total/600.0<2.6,"250%% lifesteal always restores 2 HP and a third half the time (%.2f avg)"%(total/600.0))
 game.stats.lifesteal=0.0
 game.weapons.clear();game.equip(0);game.enemies.clear()
 var dummy=game.spawn_enemy(0,game.player.position+Vector3(3,0,0));dummy.hp=1e9;dummy.max_hp=1e9
 game.stats.lifesteal=1.0;game.health=50.0;game.stats.crit=0.0;game.hit(dummy,10.0,0)
 check(is_equal_approx(game.health,51.0),"A hit with 100% lifesteal restores exactly 1 HP")
 game.stats.lifesteal=0.0
 # --- Difficulty: hp, damage, speed and spawn count ---
 game.enemies.clear();game.stats.difficulty=1.0
 var e1=game.spawn_enemy(0,game.player.position+Vector3(20,0,0));var rate1=game.spawn_rate()
 game.enemies.clear();game.stats.difficulty=2.0
 var e2=game.spawn_enemy(0,game.player.position+Vector3(20,0,0));var rate2=game.spawn_rate()
 check(e2.max_hp>e1.max_hp*1.9 and e2.damage>e1.damage*1.9 and e2.speed>e1.speed*1.2,"Difficulty 2 raises enemy hp (x%.2f), damage (x%.2f) and speed (x%.2f)"%[e2.max_hp/e1.max_hp,e2.damage/e1.damage,e2.speed/e1.speed])
 check(rate2>rate1*1.9,"Difficulty 2 roughly doubles the spawn rate (%.2f vs %.2f /s)"%[rate2,rate1])
 game.stats.difficulty=1.0;game.enemies.clear()
 # --- credit-based spawner: slow start, grows over time, reacts to living count ---
 game.stage=1;game.stage_clock.reset()
 var start_rate=game.spawn_rate()
 check(start_rate<=1.0,"The first stage starts slow (%.2f enemies/s with the field clear)"%start_rate)
 var spawned=0.0;var living=0
 for i in 120:
  game.stage_clock.elapsed=float(i)*0.5;game.enemies.clear();for k in living:game.enemies.append({"kind":0})
  var step=game.spawn_rate()*0.5;spawned+=step;living=int(spawned)
 check(spawned<45.0,"Nothing killed: under 45 enemies in the first minute (%.0f)"%spawned)
 game.enemies.clear();game.stage_clock.elapsed=300.0;var mid_clear=game.spawn_rate()
 game.stage_clock.elapsed=0.0;game.stage_clock.elapsed=60.0;var early=game.spawn_rate()
 check(mid_clear>early*2.0,"The spawn rate grows over the stage (%.2f at 1:00, %.2f at 5:00)"%[early,mid_clear])
 var cap_fill:Array[Dictionary]=[];for k in 400:cap_fill.append({"kind":0})
 game.enemies.assign(cap_fill);var crowded=game.spawn_rate();game.enemies.clear()
 check(mid_clear>crowded*2.5 and crowded>0.0,"Clearing enemies earns up to ~3x the spawns of leaving them alive (%.2f vs %.2f /s)"%[mid_clear,crowded])
 game.stage_clock.reset()
 # --- distance LOD: far enemies update on a fraction of the frames and still draw ---
 game.enemies.clear();game.crowd.buckets.clear();game.player.active=false
 var far=game.spawn_enemy(0,game.player.position+Vector3(70,0,0));far.age=5.0;far.hp=1e9;far.max_hp=1e9;far.cooldown=999
 var near=game.spawn_enemy(0,game.player.position+Vector3(6,0,0));near.age=5.0;near.hp=1e9;near.max_hp=1e9;near.cooldown=999
 game.rebuild_grid()
 var far_moves=0;var near_moves=0
 for i in 12:
  var fp=far.pos;var np=near.pos
  game.update_enemies(1.0/60.0)
  if far.pos!=fp:far_moves+=1
  if near.pos!=np:near_moves+=1
 check(near_moves>=11 and far_moves<=4 and far_moves>=2,"A far enemy thinks every 4th frame, a near one every frame (%d vs %d of 12)"%[far_moves,near_moves])
 check(far.has("view") and far.has("lod_acc"),"Skipped frames redraw the cached pose and carry the time over")
 print("FIX_PASS_2: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)

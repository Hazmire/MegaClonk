extends SceneTree
# Fix pass after endless mode: ghost waves and collision, spawn ramp, E/Space skip, Tab closes the build screen, chest banish, vases give no items, gem gravity.
var failures: Array[String]=[]
var count=0
var game: Node
func check(value: bool, label: String):
 count+=1
 if value:print("PASS: "+label)
 else:failures.append(label);push_error("FAIL: "+label)
func _initialize():call_deferred("run")
func fresh(seed_value: int=542) -> void:
 if game==null:
  game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();MetaProgress.migrate(game.progress.data);game.progress.storage_path="user://endless-fix-profile.json"
 game.next_run_seed=seed_value;game.map_seed_override=9;game.begin_run();game.resume();game.set_physics_process(false);game.spawn_clock=0.0
func step(seconds: float,dt: float=0.05) -> void:
 var n=maxi(1,int(round(seconds/dt)))
 for i in n:
  if game.mode!="run" and game.mode!="results":game.pending_upgrades=0;game.reward_queue.clear();game.mode="run"
  game._physics_process(seconds/n)
func ghosts() -> Array:
 var out=[]
 for e in game.enemies:
  if e.has("ghost"):out.append(e)
 return out
func run():
 MenuScreen.set_instant(true)
 await waves()
 await collision()
 await spawn_ramp()
 await input_checks()
 await banish_checks()
 await vase_and_gems()
 print("endless_fix_pass_1: %d checks, %d failures"%[count,failures.size()])
 if failures.is_empty():print("ALL PASS");quit(0)
 else:
  for f in failures:print("FAILED: "+f)
  quit(1)
func waves() -> void:
 await fresh();game.settings.invincible=true;game.sandbox=true
 game.stage_clock.elapsed=StageClock.DURATION-0.05;game.stage_time=game.stage_clock.elapsed
 step(0.1,0.01)
 var g=ghosts();var lo=1.0e9;var hi=0.0;var quadrants={}
 for e in g:
  var d=Vector2(e.pos.x-game.player.position.x,e.pos.z-game.player.position.z);lo=minf(lo,d.length());hi=maxf(hi,d.length())
  quadrants[int(d.x>0)*2+int(d.y>0)]=true
 check(g.size()>=28 and g.size()<=32,"Instantly about 30 ghosts spawn when endless starts (%d)"%g.size())
 check(lo>=9.5 and hi<=15.6,"…in a ring 10-15 m from the player (%.1f-%.1f m)"%[lo,hi])
 check(quadrants.size()==4,"…all the way around the player")
 check(Endless.wave_count(5.0)>Endless.wave_count(0.0)*2.0 and Endless.wave_count(10.0)>Endless.wave_count(5.0),"Wave size grows every minute (%.0f at 0, %.0f at 5, %.0f at 10)"%[Endless.wave_count(0),Endless.wave_count(5),Endless.wave_count(10)])
 game.enemies.clear();game.ghost_count=0;game.endless_time=300.0;game.ghost_budget=0.0;step(0.05,0.01)
 check(ghosts().size()>=Endless.wave_count(5.0)-3 or ghosts().size()>=Endless.cap()-3,"A minute-5 wave is %d ghosts at once"%ghosts().size())
 game.enemies.clear();game.ghost_count=0;game.ghost_budget=0.0;step(0.05,0.01);var first=ghosts().size()
 step(Endless.wave_interval()-0.5,0.05);var mid=ghosts().size()
 step(1.0,0.05)
 check(ghosts().size()>mid or mid>=Endless.cap(),"A new wave arrives every %.0f s"%Endless.wave_interval())
func collision() -> void:
 await fresh(7);game.settings.invincible=true;game.sandbox=true
 game.stage_clock.elapsed=StageClock.DURATION-0.05;game.stage_time=game.stage_clock.elapsed;step(0.1,0.01)
 game.enemies.clear();game.ghost_count=0;game.ghost_budget=999.0
 var centre=game.player.position+Vector3(0,40,0)
 var a=Ghosts.spawn(game,0,centre);var b=Ghosts.spawn(game,0,centre+Vector3(0.05,0,0))
 for i in 20:Ghosts.separate(game,0.016)
 var reach=float(a.radius)+float(b.radius)
 check(a.pos.distance_to(b.pos)>=reach-0.02,"Two overlapping ghosts are pushed apart (%.2f >= %.2f)"%[a.pos.distance_to(b.pos),reach])
 game.enemies.clear();game.ghost_count=0
 for i in 300:Ghosts.spawn(game,i%4,centre+Vector3(game.ghost_rng.randf_range(-2,2),game.ghost_rng.randf_range(-2,2),game.ghost_rng.randf_range(-2,2)))
 for i in 60:Ghosts.separate(game,0.016)
 var list=ghosts();var worst=1.0e9
 for i in list.size():
  for j in range(i+1,list.size()):worst=minf(worst,list[i].pos.distance_to(list[j].pos)/(float(list[i].radius)+float(list[j].radius)))
 check(worst>=0.85,"A packed swarm of 300 resolves to near no overlap (worst pair at %.0f%% of touching)"%(worst*100.0))
 # Frozen time: no collision work.
 var p0=list[0].pos;Ghosts.separate(game,0.0);check(list[0].pos==p0,"Collision does nothing while hostile time is frozen")
func spawn_ramp() -> void:
 await fresh(9)
 game.stage_clock.elapsed=180.0;var at_three=game.spawn_rate()
 game.stage_clock.elapsed=420.0;var later=game.spawn_rate()
 # The base curve alone grows ~2.5x between 3:00 and 7:00; the ramp (1 + 0.35 per minute after 3:00) must lift it well past that.
 check(later/at_three>4.0,"After 3:00 the spawn rate ramps faster (x%.1f from 3:00 to 7:00; the old curve alone is ~x2.5)"%(later/at_three))
 game.stage_clock.elapsed=120.0;var early=game.spawn_rate();game.stage_clock.elapsed=0.0;var start=game.spawn_rate()
 check(early/start<3.5,"Before 3:00 the curve is unchanged (x%.1f from 0:00 to 2:00)"%(early/start))
func key(code: int) -> InputEventKey:
 var e=InputEventKey.new();e.keycode=code;e.physical_keycode=code;e.pressed=true;return e
func input_checks() -> void:
 await fresh(10)
 # E and Space skip the chest reel; held E does too.
 for code in [KEY_SPACE,KEY_E]:
  game.reward_queue.clear();game.active_reward="";game.reward_queue.append(ItemDrops.roll_chest(game));RewardDrops.present_next(game)
  var screen=game.frontend.menu.find_children("*","RunChest",true,false)[0] as RunChest
  screen.phase="spinning";screen._input(key(code))
  check(screen.phase=="reveal","Key %s skips the chest reel"%OS.get_keycode_string(code))
  game.resume()
 # Tab closes the build screen.
 game.show_build();check(game.mode=="build","Tab opens the build screen")
 var action=InputEventAction.new();action.action="inspect";action.pressed=true
 game._input(action);check(game.mode=="run","Tab again closes it")
func banish_checks() -> void:
 await fresh(11);game.items.clear();game.irt.reset()
 var first=ItemDrops.roll_chest(game);game.reward_queue.append(first);RewardDrops.present_next(game)
 check(game.item_stacks(first)==1 and game.mode=="reward","The chest gave %s"%first)
 var screen=game.frontend.menu.find_children("*","RunChest",true,false)[0] as RunChest
 screen.go_reveal();check(screen.banish_button!=null and game.chest_banishes_left==3,"The reveal offers Banish with 3 left")
 var current=first;var seen=[first]
 for n in 3:
  check(game.banish_chest_item(current),"Banish %d works"%(n+1))
  check(game.item_stacks(current)==0 and current in game.banished_items,"…the item is taken back and banished (%s)"%current)
  var next=game.active_reward
  if n<2:check(next!="" and next!=current,"…and the chest rolls a replacement (%s)"%next)
  current=next;seen.append(next)
 check(game.chest_banishes_left==0,"Only 3 banishes per run")
 check(game.banish_chest_item(current)==false,"A fourth banish is refused")
 var leaked=false
 for i in 3000:
  if ItemDrops.roll_chest(game) in game.banished_items:leaked=true
 check(not leaked,"Banished items never roll from a chest again")
 # Saved with the run.
 var path="user://endless-fix-save.json";game.mode="run";check(game.save_run(path),"Run saves")
 var banned=game.banished_items.duplicate();await fresh(12);check(game.load_run(path) and game.banished_items==banned and game.chest_banishes_left==0,"Banished items and the remaining count survive Save & quit")
 DirAccess.remove_absolute(path)
 await fresh(13);check(game.chest_banishes_left==3 and game.banished_items.is_empty(),"A new run starts with 3 banishes")
func vase_and_gems() -> void:
 await fresh(14)
 var hits=0
 for i in 6000:if ItemDrops.roll_vase(game)!="":hits+=1
 check(hits==0,"Vases never give items (%d/6000)"%hits)
 game.pickups.clear();var ground=game.terrain_height(game.player.position.x+6,game.player.position.z)
 game.add_xp_drop(Vector3(game.player.position.x+6,ground+12.0,game.player.position.z),5.0)
 var start=game.pickups[game.pickups.size()-1].node.position.y
 for i in 60:game.update_pickups(0.05)
 var y=game.pickups[game.pickups.size()-1].node.position.y
 check(start>ground+10.0 and y<ground+0.9 and y>ground,"An XP gem dropped in mid-air falls to the ground (%.1f m up -> %.2f m)"%[start-ground,y-ground])

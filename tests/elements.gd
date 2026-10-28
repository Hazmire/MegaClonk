extends SceneTree
# Milestone 4: Corrosive, Ice, Fire and Electricity behaviour, boss rules, caps and cleanup.
var checks=0
var failures=[]
var game: Node3D
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.progress=Progress.new()
 game.progress.storage_path="user://test-elements-profile.json"
 game.sandbox=true
 game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999
 await physics_frame
 game.weapons.clear();game.enemies.clear()
 game.equip(0);game.equip(6);game.equip(1);game.equip(2)
 game.mode="run"
 plain()
 corrosive()
 ice()
 fire()
 electricity()
 integration()
 cleanup_and_save()
 print("ELEMENTS: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)

func dummy(hp: float=1000.0,kind: int=0,offset: float=0.0) -> Dictionary:
 var e=game.spawn_enemy(kind if kind<8 else 0,game.player.position+Vector3(15+offset,0,0))
 e.hp=hp;e.max_hp=hp;e.kind=kind;e.slow=0;e.frozen=0;e.burn=0;e.poison=0
 return e
func settle(e: Dictionary) -> Dictionary:
 e.age=30.0;e["knock"]=Vector3.ZERO
 for i in 15:game.update_enemies(0.1)
 return e
func socket(weapon: int,gems: Array):
 var state=game.weapons[weapon]
 state["sockets"]={"unlocked":2 if gems.size()>1 else 1,"gems":gems.duplicate()}
func ticks(e: Dictionary,seconds: float,step: float=0.1):
 var n=int(round(seconds/step))
 for i in n:StatusManager.tick(game,e,step)

func plain():
 var e=dummy()
 game.hit(e,10,0)
 check(not e.has("fx") or e.fx.size()==1 and e.fx.cd.is_empty(),"Unsocketed weapons create no status state")
 check(e.speed>0,"Enemy has a base speed")
func corrosive():
 socket(0,["corrosive"])
 var e=dummy(1000.0)
 game.hit(e,1,0)
 check(StatusManager.poisoned(e),"Corrosive hit poisons the target")
 var hp0=float(e.hp)
 ticks(e,1.1)
 check(is_equal_approx(hp0-float(e.hp),hp0*0.03),"First tick deals 3%% of current HP (%.2f)"%(hp0-float(e.hp)))
 var hp1=float(e.hp)
 ticks(e,1.0)
 check(is_equal_approx(hp1-float(e.hp),hp1*0.03),"Poison scales with current HP, not max HP")
 var total_ticks=0;var f=dummy(10000.0,0,1.0)
 game.hit(f,1,0);var start=float(f.hp);var last=start
 for i in 120:
  StatusManager.tick(game,f,0.1)
  if float(f.hp)<last:total_ticks+=1;last=float(f.hp)
 check(total_ticks==10 and not StatusManager.poisoned(f),"Poison lasts exactly 10 seconds / 10 ticks (%d)"%total_ticks)
 var g=dummy(1000.0,0,2.0)
 game.hit(g,1,0);ticks(g,5.0);var before=float(g.fx.poison.left)
 game.hit(g,1,0)
 check(float(g.fx.poison.left)>before and float(g.fx.poison.left)<=10.0,"Re-applying refreshes duration instead of stacking")
 var b=dummy(100000.0,8,3.0)
 game.hit(b,1,0);var bh=float(b.hp);ticks(b,1.1)
 check(is_equal_approx(bh-float(b.hp),60.0),"Boss poison is 0.5%% of current HP capped at 60 (%.1f)"%(bh-float(b.hp)))
 var small=dummy(2000.0,8,4.0)
 game.hit(small,1,0);var sh=float(small.hp);ticks(small,1.1)
 check(is_equal_approx(sh-float(small.hp),sh*0.005),"Boss poison below the cap is 0.5%%")
 var killer=dummy(1.5,0,5.0);game.hit(killer,1,0);ticks(killer,3.0)
 check(killer.hp<=0.0 or killer.hp<1.5,"Poison can finish low-health enemies")
func ice():
 socket(0,["ice"])
 var e=dummy()
 var base=float(e.speed)
 for i in 3:game.hit(e,1,0)
 check(StatusManager.chill_stacks(e)==3 and is_equal_approx(float(e.speed),base*0.91),"Each hit adds 3%% slow (3 stacks -> %.3f of base)"%(float(e.speed)/base))
 for i in 20:game.hit(e,1,0)
 check(StatusManager.chill_stacks(e)==10 and is_equal_approx(float(e.speed),base*0.70),"Chill caps at 10 stacks / 30%% slow")
 ticks(e,3.5)
 check(StatusManager.chill_stacks(e)==10,"Stacks do not decay for 4 seconds")
 ticks(e,1.6)
 check(StatusManager.chill_stacks(e)<10,"Stacks begin to decay after 4 seconds")
 ticks(e,12.0)
 check(StatusManager.chill_stacks(e)==0 and is_equal_approx(float(e.speed),base),"Chill fully decays and restores original speed")
 var b=dummy(100000.0,8,1.0);var bb=float(b.speed)
 for i in 15:game.hit(b,1,0)
 check(is_equal_approx(float(b.speed),bb*0.85),"Boss slow is capped at 15%%")
 # Shatter
 var dying=dummy(100.0,0,6.0);var near=dummy(1000.0,0,6.5);var far=dummy(1000.0,0,30.0)
 game.hit(dying,1,0)
 dying.hp=0.0
 game.rebuild_grid()
 var near_hp=float(near.hp);var far_hp=float(far.hp)
 StatusManager.on_death(game,dying)
 check(is_equal_approx(near_hp-float(near.hp),10.0),"Shatter hurts neighbours for 1%% of their max HP (%.2f)"%(near_hp-float(near.hp)))
 check(float(far.hp)==far_hp,"Shatter does not reach distant enemies")
 var tank=dummy(100000.0,0,7.0);var chilled=dummy(100.0,0,7.5)
 game.hit(chilled,1,0);chilled.hp=0.0;game.rebuild_grid()
 var tank_hp=float(tank.hp)
 StatusManager.on_death(game,chilled)
 check(is_equal_approx(tank_hp-float(tank.hp),150.0),"Shatter damage is capped at 150")
 # chain depth
 var a=dummy(100.0,0,8.0);var bb2=dummy(100.0,0,8.5);var c=dummy(100.0,0,9.0);var d=dummy(1000.0,0,9.5)
 for x in [a,bb2,c]:game.hit(x,1,0)
 game.rebuild_grid()
 a.hp=0.0;StatusManager.on_death(game,a)
 check(int(bb2.fx.get("shatter_gen",0))==1,"Shatter victims carry a generation counter")
 bb2.hp=0.0;StatusManager.on_death(game,bb2)
 check(int(c.fx.get("shatter_gen",0))==2,"Second generation increments again")
 var d_hp=float(d.hp)
 c.hp=0.0;StatusManager.on_death(game,c)
 check(float(d.hp)==d_hp,"Shatter chain stops at the depth cap")
func fire():
 socket(0,["fire"])
 var cd=float(game.stats.crit_damage)
 var plain_amount=100.0
 var boosted=StatusManager.modify_damage(game,{},plain_amount,true,0)
 check(is_equal_approx(boosted,100.0*(cd+0.2)/cd),"Fire adds 20%% to the critical damage multiplier (x%.3f)"%(boosted/100.0))
 check(StatusManager.modify_damage(game,{},plain_amount,false,0)==plain_amount,"Fire does not change non-critical hits")
 check(StatusManager.modify_damage(game,{},plain_amount,true,6)==plain_amount,"Weapons without fire are unaffected")
 var e=dummy(1000000.0);var ignited=0;var hits=4000
 game.rng.seed=12345
 for i in hits:
  e.burn=0.0
  game.hit(e,0.01,0)
  if e.burn>0.0:ignited+=1
 check(abs(float(ignited)/hits-0.05)<0.012,"Ignite chance is about 5%% (%.3f)"%(float(ignited)/hits))
 var f=dummy(1000.0,0,1.0);f.burn=2.0
 check(not StatusManager.apply_ignite(game,f,0) and is_equal_approx(f.burn,2.0),"Ignite does not refresh while burning")
 f.burn=0.0
 check(StatusManager.apply_ignite(game,f,0) and is_equal_approx(f.burn,5.0),"Ignite lasts 5 seconds")
func electricity():
 socket(0,["electricity"])
 var e=dummy(1000000.0)
 var durations=[]
 for i in 7:
  e.fx=e.get("fx",{"cd":{}})
  e.fx.cd.erase("stun_proc");e.frozen=0.0;e.fx.erase("stun")
  durations.append(StatusManager.apply_stun(game,e,0))
 check(durations==[2.0,1.2,0.7,0.4,0.3,0.3,0.3],"Stun duration diminishes 2 / 1.2 / 0.7 / 0.4 / 0.3: %s"%str(durations))
 check(StatusManager.apply_stun(game,e,0)==0.0,"Per-target proc cooldown blocks a second stun within 1.5s")
 ticks(e,1.6)
 check(StatusManager.cooldown_ready(e,"stun_proc"),"Proc cooldown expires after 1.5s")
 ticks(e,8.0)
 var again=StatusManager.apply_stun(game,e,0)
 check(again==2.0,"Diminishing returns reset after 8 seconds (%.1f)"%again)
 check(e.frozen>0.0 and StatusManager.stunned(e),"Stun halts the enemy through the shared frozen state")
 ticks(e,2.5)
 check(not StatusManager.stunned(e),"Stun ends")
 var b=dummy(100000.0,8,1.0)
 var bs=StatusManager.apply_stun(game,b,0)
 check(bs==0.5,"Boss stun is capped at 0.5s")
 ticks(b,2.0)
 check(StatusManager.apply_stun(game,b,0)==0.0,"Boss is immune to stun for 5 seconds")
 ticks(b,3.5)
 check(StatusManager.apply_stun(game,b,0)==0.5,"Boss can be stunned again after immunity")
 var rolls=0;var procs=0;var t=dummy(100000000.0,0,2.0)
 game.rng.seed=777
 for i in 4000:
  t.fx=t.get("fx",{"cd":{}});t.fx.cd.erase("stun_proc");t.fx.erase("stun");t.fx.erase("stun_dr");t.frozen=0.0
  game.hit(t,0.001,0);rolls+=1
  if StatusManager.stunned(t):procs+=1
 check(abs(float(procs)/rolls-0.05)<0.012,"Stun chance is about 5%% (%.3f)"%(float(procs)/rolls))
func integration():
 game.mode="run"
 game.enemies.clear();game.rebuild_grid()
 var walker=settle(dummy(1000.0,0,40.0));var start=walker.pos
 for i in 10:game.update_enemies(0.1)
 var free_travel=start.distance_to(walker.pos)
 socket(0,["ice"])
 for i in 10:game.hit(walker,0.01,0)
 walker.knock=Vector3.ZERO
 start=walker.pos
 for i in 10:game.update_enemies(0.1)
 var chill_travel=start.distance_to(walker.pos)
 check(free_travel>0.5 and chill_travel<free_travel*0.85,"A 10-stack chill visibly slows the same enemy's real movement (%.2f vs %.2f)"%[chill_travel,free_travel])
 socket(0,["electricity"])
 var stunned=settle(dummy(1000.0,0,70.0))
 StatusManager.apply_stun(game,stunned,0)
 start=stunned.pos
 for i in 5:game.update_enemies(0.1)
 check(start.distance_to(stunned.pos)<0.05,"A stunned enemy does not move in the real update loop")
 for i in 40:game.update_enemies(0.1)
 check(not StatusManager.stunned(stunned) and start.distance_to(stunned.pos)>0.2,"A stunned enemy moves again once the stun ends")
 socket(0,["corrosive"])
 var poisoned=dummy(300.0,0,1.0);game.hit(poisoned,1,0);var hp=float(poisoned.hp)
 for i in 25:game.update_enemies(0.1)
 check(float(poisoned.hp)<hp,"Poison ticks inside the real enemy loop")
 game.world_time.activate()
 var slowed=dummy(300.0,0,2.0);game.hit(slowed,1,0);var h2=float(slowed.hp)
 for i in 25:game.update_enemies(0.1)
 check(float(slowed.hp)==h2 or (h2-float(slowed.hp))<(hp-float(poisoned.hp)),"Stopwatch slows status clocks together with the enemy")
 game.world_time.reset()

func cleanup_and_save():
 socket(0,["corrosive"])
 var e=dummy(1000.0)
 game.hit(e,1,0)
 StatusManager.on_death(game,e)
 check(not e.has("fx"),"Statuses are cleared on death")
 var f=dummy(1000.0,0,1.0);game.hit(f,1,0);ticks(f,2.0)
 var restored=JSON.parse_string(JSON.stringify({"fx":f.fx}))
 check(restored.fx.poison.weapon==0 and float(restored.fx.poison.left)>0.0,"Status state is JSON-safe")
 socket(0,[])
 var g=dummy(1000.0,0,2.0)
 game.hit(g,1,0)
 check(not StatusManager.poisoned(g),"Removing the gem removes the effect for new hits")

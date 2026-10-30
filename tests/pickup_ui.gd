extends SceneTree
# Feedback round: running gold/XP totals, gem banner, weapon sockets on the HUD.
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
 game.progress=Progress.new();game.progress.storage_path="user://test-pickup-ui.json"
 game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999
 await physics_frame
 tally()
 await hud()
 print("PICKUP_UI: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)

func settle_counter(t: PickupTally,seconds: float):
 for i in int(seconds/0.02):t.update(game,0.02)
func tally():
 var t=PickupTally.new()
 game.gold=0;game.xp=0.0;game.level=1
 t.reset(game)
 check(t.gold_text()=="" and t.xp_text()=="","Nothing is shown before any gain")
 game.gold=10;t.update(game,0.02)
 check(t.gold_text().begins_with("$") and t.xp_text()=="","Gold shows with a $ and no XP number appears")
 settle_counter(t,0.6)
 check(t.gold_text()=="$10","The gold number settles on the total ($10)")
 # Rapid count-up for a big burst, instead of jumping.
 game.gold=30;t.update(game,0.02)
 var first=int(t.gold_text().substr(1))
 check(first<30 and first>=10,"A 20-gold burst counts up rather than jumping (first frame $%d)"%first)
 var seen=[first]
 for i in 60:
  t.update(game,0.02)
  var v=int(t.gold_text().substr(1))
  if v!=seen.back():seen.append(v)
 check(seen.size()>3 and seen.back()==30,"The number ticks upward through intermediate values to $30 (%s)"%str(seen))
 check(t.gold_total()==30,"True total is 30")
 # bounce on increase
 game.gold=31;t.update(game,0.02);t.update(game,0.02)
 check(t.gold.bounce>0.3,"Each increase kicks a bounce (%.2f)"%t.gold.bounce)
 var small=t.gold.bounce
 settle_counter(t,0.8)
 check(t.gold.bounce<0.05,"The bounce settles back down")
 var big=PickupTally.new();game.gold=0;big.reset(game);game.gold=5;big.update(game,0.02);settle_counter(big,0.5);game.gold=500;big.update(game,0.02);big.update(game,0.02)
 var low=PickupTally.new();game.gold=0;low.reset(game);game.gold=2;low.update(game,0.02);low.update(game,0.02)
 check(big.gold.bounce>=low.gold.bounce,"Larger totals bounce at least as hard")
 # XP
 game.gold=0;t=PickupTally.new();game.xp=0.0;t.reset(game)
 game.xp=20.0;t.update(game,0.02);game.xp=44.0;t.update(game,0.02);settle_counter(t,1.0)
 check(t.xp_text()=="+44","XP shows with a + (+44)")
 # lifespan: stays up for four seconds after the last gain, and extends with new gains
 settle_counter(t,2.5)
 check(t.xp_text()=="+44","Total is still showing 3.5 seconds after the last gain")
 game.xp=50.0;t.update(game,0.02);settle_counter(t,3.0)
 check(t.xp_text()=="+50","A new gain keeps the same running total and restarts the timer (+50)")
 settle_counter(t,1.5)
 check(t.xp_text()=="","The total clears after four seconds without gains")
 game.xp=60.0;t.update(game,0.02);settle_counter(t,1.0)
 check(t.xp_text()=="+10","The next gain starts again from zero (+10)")
 game.gold=100;var spend=PickupTally.new();spend.reset(game);game.gold=60;spend.update(game,0.02)
 check(spend.gold_text()=="","Spending gold shows nothing")
 # level-up
 var t2=PickupTally.new();game.level=3;game.xp=0.0;t2.reset(game)
 var threshold=Catalog.threshold(game.level)
 game.xp=threshold-5.0;t2.update(game,0.02)
 game.level+=1;game.xp=8.0;t2.update(game,0.02);settle_counter(t2,2.0)
 check(t2.xp_text()=="+%d"%floori(threshold+8.0),"A level-up neither loses nor doubles XP (%s, expected +%d, threshold %s)"%[t2.xp_text(),roundi(threshold+8.0),str(threshold)])
 check(PickupTally.GOLD_COLOR.r>0.9 and PickupTally.GOLD_COLOR.g>0.7 and PickupTally.GOLD_COLOR.b<0.4,"Gold total is gold coloured")
 check(PickupTally.XP_COLOR.b>0.9 and PickupTally.XP_COLOR.r<0.5,"XP total is blue")
 game.level=1;game.xp=0.0;game.gold=0
 # real-time clock: several HUD updates in one frame must not age the totals faster
 var fe=game.frontend
 var before_msec=fe.last_hud_msec
 var d1=fe.real_delta();var d2=fe.real_delta();var d3=fe.real_delta()
 check(d2<0.02 and d3<0.02,"Back-to-back HUD updates in the same frame add almost no time (%.4f, %.4f)"%[d2,d3])
 # pickup integration: coins fly to the player and pay on arrival
 game.mode="run";game.gold=0;game.world_pickups.clear()
 var e_pos=game.player.position+Vector3(25,0.5,0)
 WorldPickups.spawn_gold(game,e_pos,7)
 check(game.gold==0 and game.world_pickups.size()==1 and game.world_pickups[0].attracted,"A kill coin is not paid until it reaches the player")
 var travel_ticks=0
 while not game.world_pickups.is_empty() and travel_ticks<400:
  WorldPickups.update(game,1.0/60);travel_ticks+=1
 check(game.gold==7 and travel_ticks>10 and travel_ticks<300,"The coin flies from 25 m away and pays on arrival (%d ticks)"%travel_ticks)
 WorldPickups.spawn_gold(game,e_pos,5);WorldPickups.spawn_gold(game,e_pos,6)
 check(WorldPickups.settle(game)==11 and game.gold==18 and game.world_pickups.is_empty(),"Coins still in flight are paid out when a stage or run ends")
 game.gold=0
func hud():
 game.mode="run"
 game.weapons.clear();game.equip(0)
 game.frontend.update_hud()
 var found=0
 for n in RewardScreens.descendants(game.frontend.run_hud.build_box):
  if n is SocketPips:found+=1
 check(found==1,"The top-left weapon icon shows its socket diamonds")
 WeaponSockets.install(game.weapons[0],"fire")
 game.frontend.update_hud()
 var filled=false
 for n in RewardScreens.descendants(game.frontend.run_hud.build_box):
  if n is SocketPips and n.gems==["fire"]:filled=true
 check(filled,"The HUD socket diamond updates when a gem is installed")
 game.gems.reset();game.gold=0
 var toasts=game.frontend.run_hud.toasts;var q=toasts.queue
 var pending=func():
  var out=q.waiting.map(func(w):return w.key)
  if not q.current.is_empty():out.append(q.current.key)
  return out
 var datas=func(key):
  var all=q.waiting.duplicate()
  if not q.current.is_empty():all.append(q.current)
  return all.filter(func(w):return w.key==key)[0].data
 game.gem_discovered("ice")
 check("gem:ice" in pending.call() and datas.call("gem:ice").name=="Ice Gem","Gem toast names the element")
 check(datas.call("gem:ice").color.b>datas.call("gem:ice").color.r,"Ice toast is coloured blue")
 game.gem_discovered("corrosive")
 var c: Color=datas.call("gem:corrosive").color
 check(c.g>c.r and c.g>c.b,"Corrosive toast is coloured green")
 game.gem_discovered("fire")
 c=datas.call("gem:fire").color
 check(c.r>c.b,"Fire toast is coloured orange/red")
 for i in 900:toasts._process(0.02)
 check(not q.busy() and toasts.phase=="idle","The toast sequence finishes by itself without blocking")
 WorldPickups.collect(game,{"kind":"gem","element":"electricity"})
 check(game.gems.count("electricity")==1 and "gem:electricity" in pending.call(),"Picking up a gem raises its toast")

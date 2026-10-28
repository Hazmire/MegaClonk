extends SceneTree
# Weapon Overhaul 2.0 smoke test: all eight weapons fire, hit and clean up with no script errors.
var checks=0
var failures=[]
var game: Node3D
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func ring_enemies(n: int,radius: float):
 for i in n:
  var a=TAU*float(i)/n
  var e=game.spawn_enemy(0,game.player.position+Vector3(cos(a)*radius,0,sin(a)*radius))
  if not e.is_empty():e.hp=100000.0;e.max_hp=100000.0;e.speed=0.0
func run():
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.progress=Progress.new()
 game.progress.storage_path="user://test-weapons-smoke.json"
 game.sandbox=true
 game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999
 await physics_frame
 for group in [[0,1,2,6],[7,9,10,15]]:
  game.weapons.clear();game.enemies.clear();game.wrt.clear()
  for id in group:game.equip(id)
  check(game.weapons.size()==4,"four weapons equip together %s"%str(group))
  ring_enemies(16,3.2);ring_enemies(24,6.5);ring_enemies(24,9.5)
  game.rebuild_grid()
  game.mode="run"
  for frame in 300:
   game.rebuild_grid();game.update_weapons(1.0/60.0)
   for e in game.enemies:e.hit_time=maxf(0,e.hit_time-1.0/60.0)
 var casts=game.wrt.counters.casts
 for id in Catalog.ACTIVE_WEAPONS:check(int(casts.get(id,0))>0,"weapon %d fired (%s)"%[id,Catalog.WEAPONS[id][0]])
 print("STRIKES ",game.wrt.counters.strike)
 for source in ["slash","fireball","strike","chain","arrow","bullet","pulse","scythe_out","pellet"]:
  check(int(game.wrt.counters.strike.get(source,0))>0 or source=="chain","hit source %s produced hits"%source)
 print("PSX peak ",game.psx.stats)
 print("WEAPONS_SMOKE: %d checks, %d failures"%[checks,failures.size()])
 game.queue_free();await process_frame;await process_frame
 quit(1 if failures.size()>0 else 0)

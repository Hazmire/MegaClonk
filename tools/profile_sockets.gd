extends SceneTree
# Headless CPU profile of the enemy simulation plus weapon-hit load at several crowd sizes,
# comparing: no sockets, one element, every element, a dual combo, and Stopwatch active.
# Rendering is excluded (headless), so these numbers are simulation cost only.
# Run: tools/godot.sh --headless --path . --script tools/profile_sockets.gd
var game: Node3D
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://profile-sockets.json"
 game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true;game.spawn_clock=999;game.mode="pause"
 await physics_frame
 for model in ["Imp","Puglin"]:
  for frame in 8:BestiaryFrames.mesh(model,"enemy_move",frame)
  for frame in 2:BestiaryFrames.mesh(model,"enemy_idle",frame)
 var scenarios=[
  ["no sockets",[]],
  ["corrosive",["corrosive"]],
  ["ice",["ice"]],
  ["fire",["fire"]],
  ["electricity",["electricity"]],
  ["fire+ice combo",["fire","ice"]],
  ["corrosive+electricity combo",["corrosive","electricity"]],
 ]
 print("PROFILE enemies | scenario | ms/tick (sim + hits) | statuses active")
 for count in [50,100,250,500]:
  for scenario in scenarios:
   prepare(count,scenario[1])
   var result=measure()
   print("PROFILE %4d | %-28s | %7.2f | %d"%[count,scenario[0],result[0],result[1]])
  prepare(count,["corrosive","ice"]);game.world_time.activate()
  var result=measure()
  print("PROFILE %4d | %-28s | %7.2f | %d"%[count,"ice+corrosive + Stopwatch",result[0],result[1]])
  game.world_time.reset()
 quit()
func prepare(count: int,gems: Array):
 game.enemies.clear();game.world_time.reset()
 game.weapons.clear();game.equip(0)
 game.weapons[0]["sockets"]={"unlocked":2 if gems.size()>1 else 1,"gems":gems.duplicate()}
 game.health=100
 for i in count:game.spawn_enemy(i%8,game.player.position+Vector3(4+(i%25)*0.9,0,-12+int(i/25)*0.9))
 for e in game.enemies:e.hp=1.0e9;e.max_hp=1.0e9;e.age=30.0
 game.rebuild_grid()
 for i in 10:game.update_enemies(1.0/60);game.rebuild_grid()
# One tick = enemy update + hits on a slice of the crowd (the weapon load of a busy fight).
func measure() -> Array:
 var ticks=120
 var began=Time.get_ticks_usec()
 for i in ticks:
  game.elapsed+=1.0/60
  var slice=maxi(1,game.enemies.size()/10)
  for k in slice:game.hit(game.enemies[(i*slice+k)%game.enemies.size()],0.001,0)
  game.update_enemies(1.0/60);game.rebuild_grid()
 var ms=(Time.get_ticks_usec()-began)/(1000.0*ticks)
 var active=0
 for e in game.enemies:
  if e.has("fx") or float(e.burn)>0.0:active+=1
 return [ms,active]

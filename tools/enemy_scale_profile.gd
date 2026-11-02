extends SceneTree
# Root-cause profile for "too many enemies on screen": per-phase CPU cost of one physics frame at 50..500 live enemies,
# with the player standing in a normal loadout (4 weapons) so weapon hit work is included.
# usage: tools/godot.sh --headless --path . --script tools/enemy_scale_profile.gd
var game: Node
func _initialize():call_deferred("run")
func ms(t0: int) -> float:return (Time.get_ticks_usec()-t0)/1000.0
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.invincible=true;game.settings.focus_pause=false;game.settings.fps=false;game.settings.numbers=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false)
 game.terrain_version=3;game.build_stage();game.resume();game.spawn_clock=1e9;game.player.active=false
 var center=game.map_layout.spawn;game.player.position=center+Vector3.UP*0.02
 for id in [0,1,7,9]:game.equip(id)
 for count in [50,100,200,350,500]:
  game.enemies.clear();game.crowd.buckets.clear()
  for i in count:
   var a=i*2.39996;var p=center+Vector3(cos(a),0,sin(a))*(10+float(i%25)*0.9)
   var e=game.spawn_enemy(-1,p)
   if not e.is_empty():e.hp=1e9;e.max_hp=1e9;e.cooldown=999;e.age=2.0
  var acc={"crowd.rebuild":0.0,"enemy_loop":0.0,"grid":0.0,"weapons":0.0,"projectiles":0.0,"hud":0.0,"other":0.0}
  var frames=90;var hits0=0
  for f in 20:game.update_enemies(1.0/60);game.rebuild_grid()
  for f in frames:
   var t=Time.get_ticks_usec();game.crowd.rebuild(game.enemies);acc["crowd.rebuild"]+=ms(t)
   t=Time.get_ticks_usec();game.update_enemies(1.0/60);acc["enemy_loop"]+=ms(t)
   t=Time.get_ticks_usec();game.rebuild_grid();acc["grid"]+=ms(t)
   t=Time.get_ticks_usec();game.update_weapons(1.0/60);acc["weapons"]+=ms(t)
   t=Time.get_ticks_usec();game.update_projectiles(1.0/60);game.update_blasts(1.0/60);game.update_pickups(1.0/60);acc["projectiles"]+=ms(t)
   t=Time.get_ticks_usec();game.update_hud();acc["hud"]+=ms(t)
   t=Time.get_ticks_usec()
   for i in range(game.enemies.size()-1,-1,-1):
    if game.enemies[i].hp<=0:game.kill_enemy(i)
   acc["other"]+=ms(t)
  var line="enemies=%d (live %d) per-frame ms:"%[count,game.enemies.size()]
  var total=0.0
  for k in acc:line+=" %s=%.2f"%[k,acc[k]/frames];total+=acc[k]/frames
  print(line+" TOTAL=%.2f"%total)
 # --- inside the enemy loop: cost per call-site (ordinary enemies mirror Game.update_enemies) ---
 for count in [100,250,500]:
  game.enemies.clear();game.crowd.buckets.clear()
  for i in count:
   var a=i*2.39996;var p=center+Vector3(cos(a),0,sin(a))*(10+float(i%25)*0.9)
   var e=game.spawn_enemy(-1,p)
   if not e.is_empty():e.hp=1e9;e.max_hp=1e9;e.cooldown=999;e.age=2.0
  var acc={"contact":0.0,"simulate(nav+move)":0.0,"crowd.prepare":0.0,"crowd.resolve":0.0,"draw_enemy":0.0}
  var sub={"navigation_direction":0.0,"EnemyTraversal.move":0.0}
  for f in 20:game.update_enemies(1.0/60)
  var frames=60
  for f in frames:
   var delta=1.0/60;game.crowd.rebuild(game.enemies);game.enemy_view.begin_frame()
   for e in game.enemies:
    if e.hp<=0:continue
    e.age+=delta
    var t=Time.get_ticks_usec();EnemyContact.step(game,e,delta);acc["contact"]+=ms(t)
    if e.kind>=8:continue
    t=Time.get_ticks_usec();game.crowd.prepare(e);acc["crowd.prepare"]+=ms(t)
    t=Time.get_ticks_usec();EnemySimulation.step(game,e,delta);acc["simulate(nav+move)"]+=ms(t)
    t=Time.get_ticks_usec();game.crowd.resolve(game,e,delta);acc["crowd.resolve"]+=ms(t)
    t=Time.get_ticks_usec();game.enemy_view.draw_enemy(e,game.player.position);acc["draw_enemy"]+=ms(t)
   game.enemy_view.end_frame()
   var t2=Time.get_ticks_usec()
   for e in game.enemies:game.navigation_direction(e.pos,game.player.position)
   sub["navigation_direction"]+=ms(t2)
   t2=Time.get_ticks_usec()
   for e in game.enemies:EnemyTraversal.move(game,e,e.speed,delta)
   sub["EnemyTraversal.move"]+=ms(t2)
  var line="enemies=%d per-frame ms:"%count
  for k in acc:line+=" %s=%.2f"%[k,acc[k]/frames]
  line+=" | isolated:"
  for k in sub:line+=" %s=%.2f"%[k,sub[k]/frames]
  print("DETAIL "+line)
 quit()

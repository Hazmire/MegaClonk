extends SceneTree
# Runs inside the exported pack: vases, Imbue Station, power-ups and elements work when compiled.
func _initialize():call_deferred("run")
func require(value: bool,message: String) -> bool:
 if not value:push_error(message);quit(1)
 return value
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false
 if not require(game.vases.size()>=25 and game.vases.size()<=40,"Compiled stage lost its vases"):return
 if not require(ImbueStation.count(game)==1,"Compiled stage must have exactly one Imbue Station"):return
 var count_before=game.pickups.size()+game.world_pickups.size()+game.gold
 if not require(Vases.smash(game,game.vases[0]) and game.vases[0].broken,"Compiled vase smash failed"):return
 WorldPickups.stopwatch(game)
 if not require(game.world_time.active() and Engine.time_scale==1.0,"Compiled Stopwatch state wrong"):return
 game.world_time.reset()
 game.equip(0);game.gems.add("ice",1);game.gold=900;game.stage=1
 if not require(ImbueRules.install(game,0,"ice").ok and game.gold==400,"Compiled imbue install failed"):return
 var e=game.spawn_enemy(0,game.player.position+Vector3(12,0,0));e.hp=1000.0;e.max_hp=1000.0
 game.hit(e,1,0)
 if not require(StatusManager.chill_stacks(e)==1,"Compiled chill did not apply"):return
 game.frontend.imbue_station(ImbueStation.find(game));await process_frame
 if not require(game.mode=="imbue","Compiled Imbue Station screen did not open"):return
 print("EXPORTED SOCKETS SMOKE COMPLETE")
 quit()

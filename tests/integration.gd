extends SceneTree
var game: Node3D
var checks = 0
var failures: Array[String] = []
func verify(condition: bool, description: String) -> void:
 checks += 1
 if not condition:
  failures.append(description)
  push_error("FAIL: " + description)
 else: print("PASS: " + description)
func _initialize() -> void:
 call_deferred("run")
# Combat fixtures retain the original seed-9 flat patch; new terrain has
# dedicated 200-seed collision/navigation and traversal coverage.
func run() -> void:
 var stats = Catalog.base_stats()
 verify(Catalog.damage(10,stats,false)==10,"Base damage")
 stats.damage=1.5
 verify(Catalog.damage(10,stats,true)==30,"Multipliers and critical damage")
 verify(Catalog.threshold(10)>Catalog.threshold(9),"Increasing XP thresholds")
 verify(Catalog.WEAPONS.size()==8 and Catalog.ACTIVE_WEAPONS.size()==8 and Catalog.CHARACTERS.size()==21,"Content roster sizes")
 var save=Progress.new()
 save.data.kills=200
 save.data.currency=33
 verify(save.save("user://test-progress.json"),"Atomic save write")
 var restored=Progress.new()
 restored.storage_path="user://test-progress.json"
 verify(restored.load_save("user://test-progress.json") and restored.data.kills==200 and restored.data.currency==33,"Save/load round trip")
 verify(0 in restored.data.unlocked and 1 in restored.data.unlocked,"Starting characters remain unlocked after JSON round trip")
 var before=restored.data.duplicate(true)
 restored.finish(999,200,true,0,true)
 verify(restored.data==before,"Sandbox does not change progression")
 var unlocked=restored.finish(100,200,false,0,false)
 verify(unlocked is Array and restored.data.runs==1 and restored.data.kills==300,"Lifetime progression records the run (items are all unlocked from the start now)")
 # Isolate integration profile from the actual player's profile.
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.progress=Progress.new()
 game.progress.storage_path="user://test-game-profile.json"
 game.sandbox=true
 # Deterministic flat combat fixture; map variety has separate 100-seed coverage.
 game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true
 game.spawn_clock=999
 game.weapons.clear()
 await physics_frame
 verify(is_instance_valid(game.player) and game.player.camera.current,"Player and camera instantiated")
 var start=game.player.position
 Input.action_press("forward")
 for i in 50: await physics_frame
 Input.action_release("forward")
 verify(game.player.position.distance_to(start)>2,"Movement traverses collidable terrain")
 for i in 60: await physics_frame
 Input.action_press("jump")
 var y=game.player.position.y
 for i in 8: await physics_frame
 Input.action_release("jump")
 verify(game.player.position.y>y+0.5,"Jump physics")
 game.mode="pause"
 game.player.active=false
 game.enemies.clear()
 var e=game.spawn_enemy(0,game.player.position+Vector3(0,0,-3))
 game.rebuild_grid()
 var original_hp=e.hp
 game.stats.crit=0
 game.hit(e,10,0)
 verify(e.hp==original_hp-10,"Enemy receives damage")
 game.weapons.clear()
 game.equip(0)
 var pool=game.upgrade_pool()
 verify(pool.size()>3,"Meaningful level-up choices")
 game.apply_upgrade({"type":"tome","id":"Might"})
 verify(game.stats.damage>1 and game.tomes.Might==1,"Tome applies stat modifier")
 var item_count=game.item_total()
 game.award_item()
 verify(game.item_total()==item_count+1,"Item reward applied")
 game.stats.lifesteal=0
 game.stats.damage=1
 game.stats.crit=0
 var successful_weapons=0
 for id in Catalog.ACTIVE_WEAPONS:
  game.weapons.clear()
  game.projectiles.clear()
  game.wrt.clear()
  game.enemies.clear()
  game.player.position=Vector3(0,1,0)
  for i in 48:
   var angle=(i%16)*TAU/16
   var radius=[1.5,4.8,10.0][i/16]
   var target=game.spawn_enemy(0,Vector3(cos(angle)*radius,0,sin(angle)*radius))
   target.hp=100000
   target.max_hp=100000
  game.rebuild_grid()
  game.equip(id)
  var damage_before=game.damage_total
  game.update_weapons(1)
  for i in 150:
   game.update_weapons(1.0/60)
   game.update_projectiles(1.0/60)
   game.update_effects(1.0/60)
  if game.damage_total>damage_before: successful_weapons+=1
  else: failures.append("Weapon damage: "+Catalog.WEAPONS[id][0])
 verify(successful_weapons==8,"All 8 weapons produce damage against nearby enemies (%d/8)"%successful_weapons)
 game.projectiles.clear()
 game.enemies.clear()
 var poisoned=game.spawn_enemy(0,Vector3(3,0,0))
 poisoned.hp=1000
 poisoned.max_hp=1000
 poisoned.poison=2
 poisoned.slow=2
 game.rebuild_grid()
 var pos=poisoned.pos
 game.update_enemies(0.5)
 verify(poisoned.hp<1000 and poisoned.pos.distance_to(pos)<2,"Poison damage and slow status")
 game.character=1
 var armor=game.stats.armor
 game.on_level()
 verify(game.stats.armor>armor,"Character armor passive")
 game.character=0
 var luck=game.stats.luck
 game.on_level()
 verify(game.stats.luck>luck,"Character luck passive")
 game.weapons.clear()
 var pause_start=game.elapsed
 game.pause_menu()
 await physics_frame
 verify(game.elapsed==pause_start and not game.player.active,"Pause stops gameplay and controller")
 game.xp=Catalog.threshold(game.level)
 game.update_pickups(0)
 verify(game.mode=="upgrade" and game.choices.size()==3,"Level up pauses for three choices")
 game.resume()
 for id in [0,1,2,6]: game.equip(id)
 verify(game.weapons.size()==4,"Four-weapon slot limit")
 game.enemies.clear()
 game.stage_time=181
 game.boss_spawned=false
 game.resume()
 await physics_frame
 await physics_frame
 verify(not game.boss_spawned,"Stage timer does not summon the boss automatically")
 game.activate_portal()
 verify(game.boss_spawned,"Portal summons stage boss")
 var boss: Dictionary={}
 for enemy in game.enemies:
  if enemy.kind==8: boss=enemy
 verify(not boss.is_empty(),"Boss exists")
 if not boss.is_empty():
  boss.hp=0
  game.kill_enemy(game.enemies.find(boss))
 verify(game.boss_dead and is_instance_valid(game.portal),"Boss death opens exit portal")
 game.mode="pause"
 game.stage=3
 game.finish_run(true)
 verify(game.mode=="results","Victory results transition")
 game.resume()
 game.health=0
 await physics_frame
 await physics_frame
 verify(game.mode=="results","Defeat results transition")
 game.mode="pause"
 # Independent simulation benchmark with 400 enemies and all bounded arrays active.
 game.enemies.clear()
 game.health=100
 for i in 400: game.spawn_enemy(i%8)
 game.rebuild_grid()
 # Load each shared animation frame before measuring steady-state simulation.
 for model in ["Imp","Puglin"]:
  for frame in 8:BestiaryFrames.mesh(model,"enemy_move",frame)
  for frame in 2:BestiaryFrames.mesh(model,"enemy_idle",frame)
 for i in 10:game.update_enemies(1.0/60);game.rebuild_grid()
 var began=Time.get_ticks_usec()
 for i in 120:
  game.update_enemies(1.0/60)
  game.rebuild_grid()
 var ms=(Time.get_ticks_usec()-began)/120000.0
 print("BENCHMARK 400 enemies CPU simulation mean: %.2f ms/tick (headless; rendering excluded)"%ms)
 verify(game.enemies.size()>=400,"400-enemy simulation retains entities")
 print("RESULT: %d checks, %d failures"%[checks,failures.size()])
 for failure in failures: print("FAILED: "+failure)
 game.queue_free()
 await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)

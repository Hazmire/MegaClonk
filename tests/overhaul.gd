extends SceneTree
var checks=0
var failures: Array[String]=[]
var game: Node
func verify(value: bool, description: String) -> void:
 checks+=1
 if value: print("PASS: "+description)
 else: failures.append(description); push_error("FAIL: "+description)
func ticks(count: int) -> void:
 for i in count: await physics_frame
func solid(pos: Vector3, size: Vector3) -> StaticBody3D:
 var body=StaticBody3D.new()
 var collision=CollisionShape3D.new()
 var shape=BoxShape3D.new(); shape.size=size; collision.shape=shape
 body.add_child(collision); game.world.add_child(body); body.position=pos
 return body
func _initialize() -> void: call_deferred("run")
func run() -> void:
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.progress.storage_path="user://overhaul-test-profile.json"
 game.sandbox=true
 game.next_run_seed=500
 # Deterministic flat combat fixture; map variety has separate 100-seed coverage.
 game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.mode="pause"
 game.player.active=true
 var p=game.player
 await ticks(45)
 verify(not InputMap.has_action("sprint"),"Sprint input action removed")
 verify(InputMap.has_action("crouch") and game.bindings.crouch==KEY_CTRL,"Rebindable Ctrl crouch input")
 Input.action_press("crouch")
 await ticks(3)
 verify(p.posture=="crouching","Stationary crouch state")
 verify(is_equal_approx(p.collider.shape.height,p.crouched_height),"Crouch lowers capsule height")
 var ceiling=solid(p.position+Vector3(0,1.4,0),Vector3(3,0.4,3))
 await ticks(3)
 Input.action_release("crouch")
 await ticks(3)
 verify(not p.can_stand() and p.posture=="crouching","Ceiling blocks standing when crouch is released")
 ceiling.queue_free()
 await ticks(3)
 verify(p.posture=="standing" and is_equal_approx(p.collider.shape.height,p.standing_height),"Standing restores capsule after clearance")
 Input.action_press("forward")
 await ticks(55)
 var before=Vector3(p.velocity.x,0,p.velocity.z).length()
 Input.action_press("crouch")
 await ticks(2)
 var after=Vector3(p.velocity.x,0,p.velocity.z).length()
 verify(before>=p.slide_initiation_speed and p.posture=="sliding","Slide begins above configured threshold")
 verify(after>before*0.85 and after<=before+0.2,"Slide preserves momentum without entry boost")
 Input.action_press("jump")
 await ticks(3)
 Input.action_release("jump")
 verify(p.velocity.y>0 and Vector3(p.velocity.x,0,p.velocity.z).length()>before*0.8,"Slide jump preserves horizontal momentum")
 Input.action_release("forward"); Input.action_release("crouch")
 var v=Vector3(0,0,-10)
 verify(is_equal_approx(p.air_velocity(Vector3(0,0,-17),Vector3.RIGHT,0.1).length(),17),"Air steering redirects slide momentum without adding speed")
 var flat=p.slide_velocity(v,Vector3.UP,Vector3.ZERO,0.1)
 var downhill=p.slide_velocity(v,Vector3(0,cos(0.4),-sin(0.4)),Vector3.ZERO,0.1)
 var uphill=p.slide_velocity(v,Vector3(0,cos(0.4),sin(0.4)),Vector3.ZERO,0.1)
 verify(downhill.length()>flat.length(),"Tangential gravity accelerates downhill slide")
 verify(uphill.length()<flat.length(),"Uphill slope slows slide")
 verify(p.slide_velocity(v,Vector3.UP,Vector3.RIGHT,0.1).x>0,"Slide steering changes direction")
 verify(p.slide_velocity(v*10,Vector3.UP,Vector3.ZERO,0.1).length()<=p.max_slide_speed+0.001,"Slide practical speed cap")
 # Real inclined StaticBody test, separate from the finite terrain.
 p.active=true
 Input.action_press("crouch")
 var ramp=solid(Vector3(110,5,0),Vector3(32,0.6,10))
 ramp.rotation.z=-0.32
 p.position=Vector3(110,10,0); p.velocity=Vector3.ZERO
 await ticks(65)
 verify(p.is_on_floor(),"Player settles on real inclined collision")
 p.set_posture("sliding"); p.velocity=Vector3(8,0,0)
 await ticks(25)
 verify(Vector3(p.velocity.x,0,p.velocity.z).length()>8,"Real downhill ramp accelerates sliding body")
 p.position=Vector3(110,10,0); p.velocity=Vector3.ZERO; p.set_posture("crouching")
 await ticks(65)
 p.set_posture("sliding"); p.velocity=Vector3(-8,0,0)
 await ticks(25)
 verify(Vector3(p.velocity.x,0,p.velocity.z).length()<8,"Real uphill ramp reduces sliding body speed")
 Input.action_release("crouch")
 ramp.queue_free()
 p.position=Vector3(0,3,0); p.velocity=Vector3.ZERO
 await ticks(35)
 var avatar=p.avatar
 for state in ["idle","run","turn","jump","fall","crouch","slide","hit","death"]:
  avatar.animate(state,8,0.1)
  verify(avatar.playback.is_playing(),"Player animation playback for "+state)
 game.player.active=false
 game.enemies.clear()
 verify(EnemyCatalog.VARIANTS.size()==8,"All eight existing archetypes retained")
 var model_paths={}
 for kind in 8:
  verify(EnemyCatalog.VARIANTS[kind].size()==2,"Exactly two variants: "+EnemyCatalog.ARCHETYPES[kind])
  for choice in 2:
   var config=EnemyCatalog.variant(kind,choice)
   verify(ResourceLoader.exists(config.model) and load(config.model) is ArrayMesh,"Committed model loads: "+config.id)
   model_paths[config.model]=true
 verify(model_paths.size()>=5,"Animated zombie, crab and retained elite resources cover sixteen behaviors")
 var one=RunEnemyVariants.new(); one.initialize(500)
 var two=RunEnemyVariants.new(); two.initialize(500)
 verify(one.selections==two.selections,"Deterministic seed selections")
 var encoded=JSON.parse_string(JSON.stringify(one.serialize()))
 verify(two.restore(encoded) and one.selections==two.selections,"Variant registry JSON save/load")
 var diversity={}
 var b_count=0
 for seed_index in 128:
  two.initialize(seed_index)
  diversity[str(two.selections)]=true
  for selection in two.selections: b_count+=selection
 verify(diversity.size()>20 and b_count>400 and b_count<624,"Seeds produce varied approximately 50/50 combinations")
 game.variants.initialize(500)
 var chosen=game.variants.selections.duplicate()
 for kind in 8:
  var a=game.spawn_enemy(kind,Vector3(8,0,0))
  var b=game.spawn_enemy(kind,Vector3(10,0,0))
  verify(a.variant.id==b.variant.id and a.speed==a.variant.speed,"Per-archetype consistent spawn configuration "+str(kind))
 game.stage=2
 game.build_stage()
 game.mode="pause"
 verify(game.variants.selections==chosen,"Stage transitions preserve selected variants")
 game.enemies.clear()
 game.player.position.y=game.terrain_height(game.player.position.x,game.player.position.z)
 game.variants.selections[3]=1
 var ranged=game.spawn_enemy(3,game.player.position+Vector3(0,0,-8))
 ranged.cooldown=0
 var start=ranged.pos
 EnemySimulation.step(game,ranged,0.1)
 verify(ranged.state=="windup","Ranged attack windup")
 EnemySimulation.step(game,ranged,1.0)
 verify(game.projectiles.size()==3 and Vector2(ranged.pos.x,ranged.pos.z)==Vector2(start.x,start.z),"Stationary cactus fires visible fan")
 var shot=game.projectiles.back()
 verify(shot.hostile and shot.damage==ranged.damage and shot.velocity.length()>0,"Hostile projectile config and damage")
 game.settings.invincible=false; game.invulnerability=0; game.health=100
 shot.node.position=game.player.position+Vector3.UP
 shot.velocity=Vector3.ZERO
 game.update_projectiles(0.01)
 verify(game.health<100,"Ranged projectile applies impact damage")
 game.enemies.clear(); game.projectiles.clear()
 game.variants.selections[1]=1
 var spider=game.spawn_enemy(1,game.player.position+Vector3(0.5,0,0))
 spider.variant=OrdinaryRoster.variant(1,0)
 spider.cooldown=0
 game.rebuild_grid()
 game.invulnerability=0; game.health=100
 EnemySimulation.step(game,spider,0.01)
 verify(spider.state=="windup" and not spider.detonated,"Explosion has visible pre-detonation windup")
 EnemySimulation.step(game,spider,1.0)
 verify(spider.detonated and spider.hp<=0 and game.health<100,"Proximity explosion damages player once")
 game.invulnerability=0
 var hp=game.health
 EnemySimulation.detonate(game,spider)
 verify(game.health==hp,"Repeat detonation cannot damage again")
 game.enemies.clear()
 game.variants.selections[6]=1
 var death_spider=game.spawn_enemy(6,game.player.position+Vector3(0.5,0,0))
 death_spider.hp=0; game.invulnerability=0; game.health=100
 var kill_before=game.kills
 game.kill_enemy(0)
 verify(death_spider.detonated and game.health==100 and game.pending_blasts.size()==1,"Death blast schedules a visible dodge window")
 game.update_blasts(0.5)
 verify(game.health<100 and game.kills==kill_before+1 and game.pending_blasts.is_empty(),"Death explosion triggers once with normal kill rewards")
 game.enemies.clear()
 game.variants.selections[0]=0
 var melee=game.spawn_enemy(0,game.player.position+Vector3(0.5,0,0))
 melee.cooldown=0; game.invulnerability=0; game.health=100
 EnemyContact.step(game,melee,0.01);EnemySimulation.step(game,melee,0.01); EnemySimulation.step(game,melee,0.5)
 verify(game.health<100 and melee.state=="move","Ordinary contact applies damage without melee windup or recovery")
 game.weapons.clear(); game.equip(1)
 verify(game.save_run("user://overhaul-run-test.json"),"Active run snapshot write")
 var saved_variants=game.variants.selections.duplicate()
 var saved_kills=game.kills
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 verify(game.load_run("user://overhaul-run-test.json") and game.variants.selections==saved_variants and game.kills==saved_kills,"Actual run resume preserves variant registry and run state")
 game.mode="pause"
 verify(game.projectile_mesh("fireball")!=game.projectile_mesh("pierce"),"Distinct fire and arrow projectile meshes")
 game.player.active=false
 game.enemies.clear()
 for kind in 8:
  for choice in 2:
   game.variants.selections[kind]=choice
   var e=game.spawn_enemy(kind,Vector3(kind*2,0,choice*3+8));e.variant=game.variants.lookup(kind)
 game.update_enemies(0.016)
 verify(game.enemy_view.models.size()>=16,"All sixteen variants enter animated instanced renderer")
 print("OVERHAUL RESULT: %d checks, %d failures"%[checks,failures.size()])
 game.queue_free()
 await create_timer(0.15).timeout
 quit(0 if failures.is_empty() else 1)

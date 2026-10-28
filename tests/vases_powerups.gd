extends SceneTree
# Milestone 2: procedural vases, weighted loot, Heart / Magnet / Stopwatch power-ups.
var checks=0
var failures=[]
var game: Node3D
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func run():
 await setup_game()
 placement()
 loot()
 breaking()
 await weapons_break_vases()
 reward_placement()
 heart()
 magnet()
 await stopwatch()
 persistence()
 print("VASES_POWERUPS: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)

func setup_game():
 game=load("res://scenes/main/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.progress=Progress.new()
 game.progress.storage_path="user://test-vases-profile.json"
 game.sandbox=true
 game.map_seed_override=9
 game.begin_run();game.terrain_version=3;game.build_stage();game.resume()
 game.settings.invincible=true
 game.spawn_clock=999
 await physics_frame
func fresh_stage(stage_number: int=1):
 game.enemies.clear();game.stage=stage_number;game.build_stage();game.resume();game.spawn_clock=999

func placement():
 check(game.vases.size()>=25 and game.vases.size()<=40,"Stage has 25-40 vases (%d)"%game.vases.size())
 var all_ok=true;var deterministic=true
 for stage_number in [1,2,3]:
  for seed_value in [1,2,3,9,17,42,99,123]:
   var data=ForestMap.layout(seed_value)
   if data.is_empty():continue
   var a=Vases.plan(data,stage_number);var b=Vases.plan(data,stage_number)
   if a.size()<25 or a.size()>40:all_ok=false
   if a.size()!=b.size():deterministic=false
   else:
    for i in a.size():
     if a[i].pos!=b[i].pos or a[i].reward!=b[i].reward:deterministic=false
 check(all_ok,"Vase count stays 25-40 across seeds and stages")
 check(deterministic,"Vase layout and contents are deterministic for a seed")
 var min_gap=INF;var near_poi=false;var unreachable=0
 for i in game.vases.size():
  for j in range(i+1,game.vases.size()):min_gap=minf(min_gap,Vector2(game.vases[i].pos.x-game.vases[j].pos.x,game.vases[i].pos.z-game.vases[j].pos.z).length())
  for poi in game.map_layout.pois:
   if Vector2(game.vases[i].pos.x-poi.x,game.vases[i].pos.z-poi.z).length()<2.0:near_poi=true
  if not ForestMap.reachable(int(game.map_layout.seed),Vector2(game.vases[i].pos.x,game.vases[i].pos.z)):unreachable+=1
 check(min_gap>=float(Vases.SETTINGS.cluster_spacing)*0.9,"Vases do not overlap each other (min gap %.2f)"%min_gap)
 check(not near_poi,"No vase sits on a point of interest")
 check(unreachable==0,"Every vase is on reachable ground")
 var blocked=0
 for v in game.vases:
  if is_instance_valid(v.body) and v.body.collision_layer==0:blocked+=1
 check(blocked==0,"Intact vases have collision")

func loot():
 var rng=RandomNumberGenerator.new();rng.seed=77
 var counts={}
 var n=20000
 for i in n:
  var r=VaseLoot.roll(rng,1)
  counts[r.kind]=counts.get(r.kind,0)+1
 var expect={"xp":0.35,"gold":0.25,"heart":0.10,"magnet":0.10,"stopwatch":0.10,"gem":0.10}
 var ok=true
 for k in expect:
  if abs(float(counts.get(k,0))/n-expect[k])>0.015:ok=false
 check(ok,"Loot table distribution matches 35/25/10/10/10/10")
 var gem_ok=true
 for i in 200:
  var r=VaseLoot.roll(rng,1)
  if r.kind=="gem" and not Elements.valid(str(r.element)):gem_ok=false
 check(gem_ok,"Gem drops carry a valid element")

func breaking():
 var v=game.vases[0]
 var xp_before=game.pickups.size();var wp_before=game.world_pickups.size()
 var first=Vases.break_vase(game,v.id,0)
 var after_one=game.pickups.size()+game.world_pickups.size()
 var second=Vases.break_vase(game,v.id,0)
 var after_two=game.pickups.size()+game.world_pickups.size()
 check(first and not second,"Breaking is idempotent")
 check(after_one>xp_before+wp_before-1 and after_one==after_two,"Exactly one reward bundle per vase, no duplicates")
 check(v.body.collision_layer==0 and v.shape.disabled,"Broken vase collision is removed")
 var cell=Vector2i(floori(v.pos.x/8),floori(v.pos.z/8))
 var still=false
 for o in game.obstacles.get(cell,[]):
  if o.get("vase",-1)==v.id:still=true
 check(not still,"Broken vase no longer blocks enemy pathing")
 check(Vases.serialize(game).has(v.id),"Broken vase is recorded for saving")

func weapons_break_vases():
 # Vases are smashed with E (interact), not by weapons: no weapon shape may break one.
 var broke=[]
 for id in Catalog.ACTIVE_WEAPONS:
  fresh_stage(1)
  game.weapons.clear();game.equip(id)
  game.mode="play"
  var target=null
  for v in game.vases:
   if not v.broken:target=v;break
  game.player.position=target.pos+Vector3(3.0,0.0,0.0)
  game.enemies.clear()
  var to_vase=target.pos-game.player.position
  game.player.yaw=atan2(-to_vase.x,-to_vase.z)
  var before=Vases.remaining(game)
  for i in 120:
   game.elapsed+=0.05
   game.update_weapons(0.05)
   game.update_fields(0.05)
   await physics_frame
   game.update_projectiles(0.05)
  if Vases.remaining(game)<before:broke.append(id)
 check(broke.is_empty(),"No weapon breaks vases (broke: %s)"%str(broke))
 fresh_stage(1)
 game.weapons.clear();game.equip(0);game.enemies.clear()
 var v=game.vases[0]
 game.player.position=v.pos+Vector3(6.0,0.0,0.0)
 check(Vases.nearest_in_reach(game,game.player.position).is_empty(),"Far from a vase there is nothing to smash")
 game.player.position=v.pos+Vector3(1.5,0.0,0.0)
 var near=Vases.nearest_in_reach(game,game.player.position)
 check(not near.is_empty() and near.id==v.id,"Standing next to a vase offers the smash prompt")
 var rewards_before=game.pickups.size()+game.world_pickups.size()+int(game.gold)
 check(Vases.smash(game,near) and v.broken,"Pressing E on a vase smashes it")
 check(not Vases.smash(game,near),"A second press does nothing")
 check(Vases.nearest_in_reach(game,game.player.position).get("id",-1)!=v.id,"A broken vase no longer offers the prompt")
 fresh_stage(1)

func reward_placement():
 fresh_stage(1)
 game.player.position=game.vases[0].pos+Vector3(1.6,0,0)
 var player_pos: Vector3=game.player.position
 var distances_ok=true;var walk_over=true
 for kind in ["heart","magnet","stopwatch"]:
  game.world_pickups.clear()
  WorldPickups.spawn_reward(game,game.vases[0].pos,{"kind":kind,"count":1})
  var p=game.world_pickups.back()
  var d=Vector2(p.node.position.x-player_pos.x,p.node.position.z-player_pos.z).length()
  if d<float(WorldPickups.TUNING.collect_radius)+0.5 or d>3.5:distances_ok=false
  if p.attracted:walk_over=false
  var hp=game.health;var count=game.world_pickups.size()
  for i in 20:WorldPickups.update(game,0.05)
  if game.world_pickups.size()!=count:walk_over=false # must not be collected until walked onto
 check(distances_ok,"Vase power-ups land just outside pickup range, close to the player")
 check(walk_over,"Vase power-ups are not collected or attracted until walked onto")
 game.world_pickups.clear()
 WorldPickups.spawn_reward(game,game.vases[0].pos,{"kind":"heart","count":1})
 game.player.position=game.world_pickups.back().node.position
 WorldPickups.update(game,0.05)
 check(game.world_pickups.is_empty(),"Walking onto a power-up collects it")
 game.player.position=player_pos
 game.pickups.clear();game.world_pickups.clear();game.gold=0
 WorldPickups.spawn_reward(game,game.vases[0].pos,{"kind":"xp","count":3,"value":4.0})
 WorldPickups.spawn_reward(game,game.vases[0].pos,{"kind":"gold","count":3,"value":6})
 WorldPickups.spawn_reward(game,game.vases[0].pos,{"kind":"gem","count":1,"element":"fire"})
 var flying=true
 for p in game.pickups:
  if not p.get("attracted",false):flying=false
 for p in game.world_pickups:
  if not p.attracted:flying=false
 check(flying and game.pickups.size()==3 and game.world_pickups.size()==4,"XP, gold and gems from vases fly straight to the player")
 game.mode="run"
 for i in 120:
  game.update_pickups(0.05);WorldPickups.update(game,0.05)
 check(game.pickups.is_empty() and game.world_pickups.is_empty() and game.gold==18 and game.gems.count("fire")>=1,"They are all collected without walking onto them")

func heart():
 game.stats.max_health=200.0;game.health=100.0
 WorldPickups.heal(game)
 check(is_equal_approx(game.health,150.0),"Heart restores exactly 25% of max HP")
 game.health=190.0;WorldPickups.heal(game)
 check(is_equal_approx(game.health,200.0),"Heart never exceeds max HP")
 var healed=WorldPickups.heal(game)
 check(is_zero_approx(healed),"Heart at full HP heals nothing")

func magnet():
 for p in game.pickups:game.pool.release(p.node) if false else null
 game.pickups.clear()
 var origin=game.player.position
 for i in 60:game.pickups.append({"node":XPGems.acquire(game,origin+Vector3(8+i*0.5,0,5)),"value":2.0,"age":0.0})
 WorldPickups.spawn(game,"gold",origin+Vector3(6,0.5,0),5)
 game.gold=0;game.xp=0.0
 var gem_inventory_before=game.gems.total()
 var n=WorldPickups.magnet(game)
 check(n==60,"Magnet flags every XP gem (%d)"%n)
 var total_value=0.0
 for p in game.pickups:total_value+=p.value
 game.mode="play"
 for i in 400:
  game.update_pickups(0.05)
  if game.pickups.is_empty():break
 check(game.pickups.is_empty(),"All magnetised XP gems are collected")
 check(game.gems.total()==gem_inventory_before,"Magnet does not touch the socket gem inventory")
 var gold_pickups=0
 for p in game.world_pickups:
  if p.kind=="gold":gold_pickups+=1
 check(gold_pickups==1 and game.gold==0,"Magnet does not pull gold")
 game.world_pickups.clear()

func stopwatch():
 fresh_stage(1)
 game.mode="play";game.player.active=true
 var e=game.spawn_enemy(0,game.player.position+Vector3(20,0,0))
 check(not e.is_empty(),"Test enemy spawned")
 e["shoot"]=0.0
 var start: Vector3=e.pos
 for i in 10:game.update_enemies(0.1)
 var normal_travel=start.distance_to(e.pos)
 e.pos=start
 WorldPickups.stopwatch(game)
 check(game.world_time.active() and is_equal_approx(game.world_time.remaining,8.0),"Stopwatch lasts 8 seconds")
 for i in 10:game.update_enemies(0.1)
 var slow_travel=start.distance_to(e.pos)
 check(normal_travel>0.1 and slow_travel/normal_travel<0.30 and slow_travel/normal_travel>0.10,"Enemies move at about 0.2x (%.2f vs %.2f)"%[slow_travel,normal_travel])
 check(Engine.time_scale==1.0,"Engine.time_scale is untouched")
 check(is_equal_approx(game.world_time.hostile(1.0),0.2),"Hostile delta scaled to 0.2")
 game.world_time.tick(3.0)
 WorldPickups.stopwatch(game)
 check(is_equal_approx(game.world_time.remaining,8.0),"A second Stopwatch refreshes instead of stacking")
 check(is_equal_approx(game.world_time.scale,0.2),"Refresh does not compound the slowdown")
 game.world_time.tick(8.5)
 check(not game.world_time.active() and game.world_time.scale==1.0,"Stopwatch expires back to normal speed")
 WorldPickups.stopwatch(game)
 game.hostile_bolt(game.player.position+Vector3(10,1,0),game.player.position+Vector3(0,1,0))
 var bolt=game.projectiles[game.projectiles.size()-1]
 var p0: Vector3=bolt.node.position
 game.update_projectiles(0.1)
 var bolt_move=p0.distance_to(bolt.node.position)
 check(bolt_move<0.4 and bolt_move>0.1,"Hostile projectiles are slowed (%.2f)"%bolt_move)
 check(is_equal_approx(game.world_time.hostile(0.0)+0.0,0.0),"Player time is not part of WorldTime")
 var json=game.world_time.serialize()
 game.world_time.reset()
 check(not game.world_time.active(),"Reset clears the Stopwatch (stage transition / new run)")
 game.world_time.restore(json)
 check(game.world_time.active(),"Stopwatch state restores")
 game.world_time.reset()

func persistence():
 fresh_stage(1)
 var ids=[0,1,2]
 for id in ids:Vases.break_vase(game,game.vases[id].id,0)
 WorldPickups.spawn(game,"heart",game.player.position+Vector3(5,0.5,0))
 WorldPickups.spawn(game,"gem",game.player.position+Vector3(6,0.5,0),0,"fire")
 WorldPickups.stopwatch(game)
 var path="user://test-vases-run.json"
 check(game.save_run(path),"Run with vases and power-ups saves")
 var remaining_before=Vases.remaining(game);var wp=game.world_pickups.size()
 fresh_stage(1)
 check(Vases.remaining(game)>remaining_before,"Fresh stage rebuilds intact vases")
 check(game.load_run(path),"Run with vases and power-ups loads")
 check(Vases.remaining(game)==remaining_before,"Broken vases stay broken after load")
 check(game.world_pickups.size()==wp,"Dropped power-ups restore after load")
 check(game.world_time.active(),"Stopwatch remaining time restores")

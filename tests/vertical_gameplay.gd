extends SceneTree
var checks=0
var failures=[]
func check(ok: bool,label: String):
 checks+=1
 if ok:print("PASS: "+label)
 else:failures.append(label);push_error(label)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.next_run_seed=42;game.map_seed_override=9;game.begin_run();game.mode="pause";game.player.active=false
 check(game.terrain_version==4 and game.map_layout.terrain_version==4,"New runs use version-4 terrain")
 var levels={}
 for region in game.map_layout.regions:levels[region.height]=true
 check(levels.size()==4 and levels.keys().max()-levels.keys().min()==36,"Four substantial elevation bands span 36 metres")
 var digest=hash(str(game.map_layout.regions)+str(game.map_layout.ramps)+str(game.map_layout.pois)+str(game.map_layout.portal)+str(game.map_layout.elite));var spawn=game.player.position
 check(game.save_run("user://vertical-v4.json") and game.load_run("user://vertical-v4.json"),"Version-4 checkpoint loads")
 game.mode="pause";game.player.active=false
 check(digest==hash(str(game.map_layout.regions)+str(game.map_layout.ramps)+str(game.map_layout.pois)+str(game.map_layout.portal)+str(game.map_layout.elite)) and game.player.position.distance_to(spawn)<0.01,"New checkpoint preserves geometry and position")
 var future=JSON.parse_string(FileAccess.get_file_as_string("user://vertical-v4.json"));future.terrain_version=999
 var future_file=FileAccess.open("user://vertical-future.json",FileAccess.WRITE);future_file.store_string(JSON.stringify(future));future_file.close()
 check(not game.load_run("user://vertical-future.json") and game.terrain_version==4 and game.player.position.distance_to(spawn)<0.01,"Unsupported future terrain is rejected without moving the player")
 game.terrain_version=3;game.build_stage();game.player.active=false
 var old_digest=hash(str(game.map_layout.regions)+str(game.map_layout.ramps)+str(game.map_layout.pois)+str(game.map_layout.portal)+str(game.map_layout.elite));var old_spawn=game.player.position
 check(game.map_layout.regions.all(func(r):return r.height in [0.0,6.0,12.0]),"Legacy version-3 generator retains original palette")
 check(game.save_run("user://vertical-v3.json"),"Legacy-shaped checkpoint writes")
 game.begin_run();game.mode="pause";game.player.active=false
 check(game.terrain_version==4,"Starting another run resets legacy terrain selection")
 check(game.load_run("user://vertical-v3.json"),"Existing terrain-version-3 checkpoint loads")
 game.mode="pause";game.player.active=false
 check(game.terrain_version==3 and old_digest==hash(str(game.map_layout.regions)+str(game.map_layout.ramps)+str(game.map_layout.pois)+str(game.map_layout.portal)+str(game.map_layout.elite)) and game.player.position.distance_to(old_spawn)<0.01,"Old checkpoint retains exact legacy geometry and position")
 var configuration=ForestMap.SETTINGS;var old_extra=configuration.extra_connections;configuration.extra_connections=4;ForestMap.cache.clear()
 var retained=ForestMap.layout(9)
 check(old_digest==hash(str(retained.regions)+str(retained.ramps)+str(retained.pois)+str(retained.portal)+str(retained.elite)),"Tuning new connection settings cannot alter legacy checkpoint terrain")
 configuration.extra_connections=old_extra
 game.begin_run();game.mode="pause";game.player.active=false
 await physics_frame;await physics_frame
 var verified=0
 for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
  var sample={}
  for index in game.map_layout.planes.size():
   var p=Vector3(-95+(index%96)*2,0,-95+int(index/96)*2)
   if maxf(absf(p.x),absf(p.z))>78:continue
   p.y=game.terrain_height(p.x,p.z)+0.65
   var landing=p+direction*4;landing.y=game.terrain_height(landing.x,landing.z)+0.65
   if landing.y-p.y<23:continue
   var valid=true
   for point in [p,p-direction*3,landing,landing+direction*4]:
    if ForestMap.normal(9,point.x,point.z).y<0.999 or game.forest_navigation.blocked.has(ForestMap.index(point.x,point.z)):valid=false
   if valid:sample={"low":p,"high":landing+direction*4};break
  if sample.is_empty():continue
  game.player.position=sample.high-Vector3.UP*0.65;game.player.position.y=game.terrain_height(game.player.position.x,game.player.position.z);game.forest_navigation.refresh(game.player.position);game.enemies.clear()
  var enemy=game.spawn_enemy(0,sample.low);enemy.cooldown=999;var climbed=false
  for tick in 1800:
   EnemySimulation.step(game,enemy,1.0/60)
   if not enemy.get("climb",{}).is_empty():climbed=true
   if enemy.pos.distance_to(game.player.position+Vector3.UP*0.65)<2:break
  check(climbed and enemy.pos.distance_to(game.player.position+Vector3.UP*0.65)<3,"Enemy climbs a 24m+ natural cliff: "+str(direction));verified+=1
 check(verified>0,"Tall-cliff climb fixture exercised")
 var upper=Vector3.ZERO
 for region in game.map_layout.regions:
  if region.height==36:
   upper=Vector3(region.anchor.x,36,region.anchor.y);break
 game.enemies.clear();game.player.position=upper;game.health=100;game.invulnerability=0;game.settings.invincible=false
 var guardian=game.spawn_enemy(8,upper+Vector3(6,0,0));Encounters.initialize(game,guardian,"chunkus");guardian.ability_clock=0;guardian.cooldown=999
 Encounters.step(game,guardian,0.01)
 check(absf(guardian.target.y-36.1)<0.01,"Boss telegraph aligns to the highest plateau")
 Encounters.step(game,guardian,1.51)
 check(game.health<100,"Boss area attack damages a player on high ground")
 var near_cliff={}
 for index in game.map_layout.planes.size():
  if not near_cliff.is_empty():break
  var point=Vector3(-95+(index%96)*2,0,-95+int(index/96)*2)
  if maxf(absf(point.x),absf(point.z))>78:continue
  point.y=game.terrain_height(point.x,point.z)
  for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
   var ahead=point+direction*1.7;var behind=point-direction*0.4
   if game.terrain_height(ahead.x,ahead.z)<point.y+10 or absf(game.terrain_height(behind.x,behind.z)-point.y)>0.1:continue
   if game.forest_navigation.blocked.has(ForestMap.index(point.x,point.z)):continue
   near_cliff={"player":point,"enemy":behind+Vector3.UP*0.65};break
 check(not near_cliff.is_empty(),"Near-target cliff regression fixture found")
 if not near_cliff.is_empty():
  game.enemies.clear();game.player.position=near_cliff.player;game.forest_navigation.refresh(game.player.position)
  var enemy=game.spawn_enemy(0,near_cliff.enemy);enemy.cooldown=999;var climbed=false
  for tick in 120:
   EnemySimulation.step(game,enemy,1.0/60)
   climbed=climbed or not enemy.get("climb",{}).is_empty()
  check(not climbed and enemy.pos.distance_to(game.player.position+Vector3.UP*0.65)<1,"Terrain probe never climbs the wall behind a nearby target")
 var config=ForestMap.SETTINGS.duplicate();config.elevation_band_weights=PackedFloat32Array([0,1,0])
 var sampler=RandomNumberGenerator.new();sampler.seed=77;var weighted=true
 for i in 100:weighted=weighted and ForestRegions.choose_band(sampler,config)==2
 check(weighted,"Configured non-zero height-band weights are honored")
 game.queue_free();await process_frame;await process_frame
 print("VERTICAL GAMEPLAY: %d checks, %d failures"%[checks,failures.size()]);quit(0 if failures.is_empty() else 1)

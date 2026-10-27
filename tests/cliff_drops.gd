extends SceneTree
var game: Node
var failures=[]
var cases=0
var heights={}
var orientations={}
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.next_run_seed=123;game.settings.invincible=true;game.begin_run();game.mode="pause";game.player.active=false
 for seed_value in [9,23,42]:
  game.map_seed_override=seed_value;game.build_stage();game.player.active=false;await physics_frame;await physics_frame
  for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.BACK,Vector3.FORWARD]:
   for height in [12,24,36]:
    var sample={}
    for index in game.map_layout.planes.size():
     var x=-95+(index%96)*2;var z=-95+int(index/96)*2
     if maxf(absf(x),absf(z))>78:continue
     var high=Vector3(x,game.terrain_height(x,z)+0.65,z);var low=high+direction*6;low.y=game.terrain_height(low.x,low.z)+0.65
     if absf(high.y-low.y-height)>0.1:continue
     var valid=true
     for step in range(0,8):
      var point=low+direction*step
      if absf(game.terrain_height(point.x,point.z)+0.65-low.y)>0.1:valid=false
     for point in [high,high-direction*3,low,low+direction*6]:
      for offset in [Vector3.ZERO,Vector3.RIGHT*1.6,Vector3.LEFT*1.6,Vector3.FORWARD*1.6,Vector3.BACK*1.6]:
       var footprint=point+offset
       if game.forest_navigation.blocked.has(ForestMap.index(footprint.x,footprint.z)) or absf(game.terrain_height(footprint.x,footprint.z)+0.65-point.y)>0.1:valid=false
     if valid:sample={"high":high,"low":low+direction*6};break
    if sample.is_empty():continue
    heights[height]=true;orientations[str(direction)]=true
    for kind in [0,13,8]:
     cases+=1;game.enemies.clear();game.player.position=sample.low-Vector3.UP*0.65;game.player.position.y=game.terrain_height(game.player.position.x,game.player.position.z);game.forest_navigation.refresh(game.player.position);game.health=10000;game.invulnerability=999
     var e=game.spawn_enemy(kind,sample.high);e.cooldown=999;e.ability_clock=999
     var fell=false;var air_frames=0;var last_y=e.pos.y;var smooth=true
     for tick in 1000:
      if kind==0:EnemySimulation.step(game,e,1.0/60)
      else:Encounters.step(game,e,1.0/60)
      if e.get("drop",{}).get("phase","")=="fall":fell=true;air_frames+=1
      if absf(e.pos.y-last_y)>0.7:smooth=false
      last_y=e.pos.y
      if air_frames==5:game.hit(e,1,0)
     if not fell or air_frames<8 or not smooth or not e.get("drop",{}).is_empty() or e.pos.distance_to(game.player.position+Vector3.UP*0.65)>3:failures.append({"seed":seed_value,"kind":kind,"height":height,"direction":str(direction),"fell":fell,"air_frames":air_frames,"smooth":smooth,"end":str(e.pos)})
 if heights.size()<3 or orientations.size()<4:failures.append("Insufficient cliff coverage")
 var ramp_drop=false
 for index in game.map_layout.planes.size():
  if ramp_drop:break
  var x=-95+(index%96)*2;var z=-95+int(index/96)*2
  if maxf(absf(x),absf(z))>80 or ForestMap.normal(42,x,z).y<0.999:continue
  for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
   var high=Vector3(x,game.terrain_height(x,z)+0.65,z);var low=high+direction*3;low.y=game.terrain_height(low.x,low.z)+0.65
   var normal=ForestMap.normal(42,low.x,low.z)
   if high.y-low.y<2 or normal.y>0.999 or normal.y<0.8 or game.forest_navigation.blocked.has(ForestMap.index(low.x,low.z)):continue
   game.enemies.clear();game.player.position=low+direction*4;game.player.position.y=game.terrain_height(game.player.position.x,game.player.position.z);game.forest_navigation.refresh(game.player.position)
   var e=game.spawn_enemy(0,high);e.cooldown=999;var falling=false
   for tick in 1000:
    EnemySimulation.step(game,e,1.0/60)
    if e.get("drop",{}).get("phase","")=="fall":falling=true
    if falling and e.get("drop",{}).is_empty():
     if ForestMap.normal(42,e.pos.x,e.pos.z).y<0.999:ramp_drop=true
     break
   if ramp_drop:break
 if not ramp_drop:failures.append("No verified ramp landing")
 cases+=1
 print("CLIFF DROP RESULT: ",JSON.stringify({"cases":cases,"heights":heights.keys(),"orientations":orientations.size(),"ramp_landing":ramp_drop,"failures":failures}))
 game.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)

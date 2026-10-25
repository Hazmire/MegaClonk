extends SceneTree
var game: Node
var failures=[]
var first_failures=[]
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.mode="pause";game.player.active=false
 var start=Time.get_ticks_msec();var total_rays=0
 for seed_value in 100:
  game.run_seed=seed_value;game.stage=1;game.variants.initialize(seed_value);game.build_stage();game.player.active=false
  await physics_frame;await physics_frame
  var data=game.map_layout;var reasons=[]
  if not data.first_attempt_valid or not data.decoration_first_attempt_valid:first_failures.append({"run_seed":seed_value,"map_seed":data.seed,"reason":"First attempt needed repair"})
  var space=game.get_world_3d().direct_space_state
  var points=data.pois.duplicate();points.append(data.portal);points.append(Vector3.ZERO)
  for ramp in data.ramps:
   for t in [0.05,0.5,0.95]:
    var p=ramp.rect.get_center()
    if ramp.axis==0:p.x=ramp.rect.position.x+ramp.length*t
    else:p.y=ramp.rect.position.y+ramp.length*t
    points.append(Vector3(p.x,ForestMap.height(data.seed,p.x,p.y),p.y))
  for point in points:
   var query=PhysicsRayQueryParameters3D.create(point+Vector3.UP*3,point-Vector3.UP*3,1)
   var hit=space.intersect_ray(query);total_rays+=1
   if hit.is_empty():reasons.append("Missing collision at "+str(point))
   elif absf(hit.position.y-point.y)>0.03:reasons.append("Collision-height mismatch "+str(point))
   if not game.forest_navigation.reachable(point):reasons.append("Navigation unreachable "+str(point))
  var path=game.forest_navigation.server_path(Vector3.ZERO,data.portal)
  if path.is_empty() or path[-1].distance_to(data.portal)>1:reasons.append("Godot navigation path missing")
  var connected=0;var expected=game.forest_navigation.edges.size()-game.forest_navigation.blocked.size()
  for cost in game.forest_navigation.distances:
   if cost>=0:connected+=1
  if connected!=expected:reasons.append("Decorated navigation pockets %d/%d"%[connected,expected])
  for axis in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
   var p=axis*94;p.y=game.terrain_height(p.x,p.z)+1
   var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(p,p+axis*5,1));total_rays+=1
   if hit.is_empty():reasons.append("Missing perimeter collision")
  if not reasons.is_empty():failures.append({"seed":seed_value,"reasons":reasons})
  if seed_value%20==0:print("PHYSICS SEED ",seed_value," ",reasons)
 var report={"seeds":100,"first_attempt_passed":100-first_failures.size(),"first_attempt_failures":first_failures,"repaired_count":first_failures.size(),"final_passed":100-failures.size(),"failed":failures,"collision_rays":total_rays,"milliseconds":Time.get_ticks_msec()-start}
 DirAccess.make_dir_recursive_absolute("res://builds")
 var file=FileAccess.open("res://builds/forest-physics-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close();print(JSON.stringify(report))
 game.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)

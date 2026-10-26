extends SceneTree
var game: Node
var failures=[]
var first_failures=[]
var placement_records=[]
var interactions=0
func _initialize():call_deferred("run")
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.mode="pause";game.player.active=false;game.set_physics_process(false)
 var start=Time.get_ticks_msec();var total_rays=0
 for seed_value in 200:
  game.stats=Catalog.base_stats();game.items.clear();game.chests_opened=0
  game.run_seed=seed_value;game.map_seed_override=seed_value;game.stage=1;game.variants.initialize(seed_value);game.build_stage();game.player.active=false
  await physics_frame;await physics_frame
  var data=game.map_layout;var reasons=[]
  if not data.first_attempt_valid or not data.decoration_first_attempt_valid:first_failures.append({"run_seed":seed_value,"map_seed":data.seed,"reason":"First attempt needed repair"})
  var space=game.get_world_3d().direct_space_state
  var points=data.pois.duplicate();points.append(data.portal);points.append(data.spawn);points.append(data.elite)
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
  var path=game.forest_navigation.server_path(data.spawn,data.portal)
  if path.is_empty() or path[-1].distance_to(data.portal)>1:reasons.append("Godot navigation path missing: end=%s target=%s start=%s closest=%s"%[str(path[-1]) if not path.is_empty() else "empty",str(data.portal),str(data.spawn),str(NavigationServer3D.map_get_closest_point(game.forest_navigation.navigation_map,data.portal))])
  var connected=0;var expected=game.forest_navigation.edges.size()-game.forest_navigation.blocked.size()
  for cost in game.forest_navigation.distances:
   if cost>=0:connected+=1
  if connected!=expected:reasons.append("Decorated navigation pockets %d/%d"%[connected,expected])
  for axis in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
   var p=axis*94;p.y=game.terrain_height(p.x,p.z)+1
   var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(p,p+axis*5,1));total_rays+=1
   if hit.is_empty():reasons.append("Missing perimeter collision")
  var placed=data.pois+[data.portal,data.elite,data.spawn]
  for i in placed.size():
   var p=placed[i]
   if ForestMap.is_ramp(data,Vector2(p.x,p.z),4):reasons.append("Object blocks ramp")
   for j in range(i+1,placed.size()):
    if Vector2(p.x-placed[j].x,p.z-placed[j].z).length()<9:reasons.append("Overlapping objects")
   for entries in game.obstacles.values():
    for obstacle in entries:
     if Vector2(p.x-obstacle.pos.x,p.z-obstacle.pos.z).length()<obstacle.radius+2:reasons.append("Object overlaps scenery")
  placement_records.append({"run_seed":seed_value,"map_seed":data.seed,"objects":data.get("placements",[]),"candidates":data.get("placement_candidates",0)})
  var shop={};var chest={};var shrine={};var statue={}
  for object in game.interactables:
   if object.kind=="Shop":shop=object
   elif object.kind=="Chest":chest=object
   elif object.kind=="Charge Shrine":shrine=object
   elif object.kind=="Elite Statue":statue=object
  if shop.is_empty() or chest.is_empty() or shrine.is_empty() or statue.is_empty():reasons.append("Required interaction missing")
  else:
   game.sandbox=true;game.gold=1000
   game.player.position=shop.node.position;game.frontend.shop(shop)
   if shop.offers.is_empty() or not game.buy_shop(shop,int(shop.offers[0]),ShopSystem.price(int(shop.offers[0]))):reasons.append("Shop purchase failed")
   interactions+=1;game.mode="pause";game.player.active=false
   game.player.position=chest.node.position;var old_count=game.items.size()
   await process_frame
   Input.action_press("interact");game.update_interactions(0.01);Input.action_release("interact")
   if not chest.used or game.items.size()!=old_count+1:reasons.append("Chest cannot be opened")
   interactions+=1;game.mode="pause";game.player.active=false;await process_frame
   game.player.position=shrine.node.position
   Input.action_press("interact");game.update_interactions(0.01);Input.action_release("interact");game.update_interactions(12)
   if not shrine.used:reasons.append("Charge shrine cannot complete")
   interactions+=1;game.mode="pause";game.player.active=false;await process_frame
   game.player.position=statue.node.position
   if not game.activate_elite_statue(statue):reasons.append("Elite statue cannot activate")
   interactions+=1
   game.player.position=data.portal
   if not game.activate_portal():reasons.append("Boss portal cannot activate")
   interactions+=1;game.mode="pause";game.player.active=false
  if not reasons.is_empty():failures.append({"seed":seed_value,"reasons":reasons})
  if seed_value%20==0:print("PHYSICS SEED ",seed_value," ",reasons)
 var report={"seeds":200,"first_attempt_passed":200-first_failures.size(),"first_attempt_failures":first_failures,"repaired_count":first_failures.size(),"final_passed":200-failures.size(),"failed":failures,"collision_rays":total_rays,"milliseconds":Time.get_ticks_msec()-start,"interaction_checks":interactions}
 DirAccess.make_dir_recursive_absolute("res://builds")
 var file=FileAccess.open("res://builds/forest-physics-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report.merged({"placement_records":placement_records}),"  "));file.close();print(JSON.stringify(report))
 game.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)

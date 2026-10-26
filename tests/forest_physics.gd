extends SceneTree
var game: Node
var failures=[]
var first_failures=[]
var placement_records=[]
var interactions=0
var traversal_checks=0
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
  # Cover the whole perimeter at walking/jumping heights, including where
  # neighboring plateaus have different floors. Local-floor rays missed gaps.
  for coordinate in range(-88,89,8):
   for axis in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
    var p=axis*94
    if axis.x!=0:p.z=coordinate
    else:p.x=coordinate
    for height in [1,13,25,37,43]:
     p.y=height
     var hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(p,p+axis*5,1));total_rays+=1
     if hit.is_empty():reasons.append("Perimeter gap at "+str(p))
  reasons.append_array(test_enemy_traversal(data));traversal_checks+=2
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
 var report={"seeds":200,"first_attempt_passed":200-first_failures.size(),"first_attempt_failures":first_failures,"repaired_count":first_failures.size(),"final_passed":200-failures.size(),"failed":failures,"collision_rays":total_rays,"milliseconds":Time.get_ticks_msec()-start,"interaction_checks":interactions,"enemy_traversal_checks":traversal_checks}
 DirAccess.make_dir_recursive_absolute("res://builds")
 var file=FileAccess.open("res://builds/forest-physics-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report.merged({"placement_records":placement_records}),"  "));file.close();print(JSON.stringify(report))
 game.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)

func test_enemy_traversal(data: Dictionary) -> Array:
 var sample={}
 for index in data.planes.size():
  if not sample.is_empty():break
  var high=Vector3(-95+(index%96)*2,0,-95+int(index/96)*2)
  if maxf(absf(high.x),absf(high.z))>78:continue
  high.y=game.terrain_height(high.x,high.z)+0.65
  for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
   var low=high+direction*6;low.y=game.terrain_height(low.x,low.z)+0.65
   if high.y-low.y<11:continue
   var clear=true
   for point in [high,high-direction*2,low,low+direction*2,low+direction*4]:
    var expected=high.y if point==high or point==high-direction*2 else low.y
    for offset in [Vector3.ZERO,Vector3.RIGHT*0.7,Vector3.LEFT*0.7,Vector3.FORWARD*0.7,Vector3.BACK*0.7]:
     var foot=point+offset
     if game.forest_navigation.blocked.has(ForestMap.index(foot.x,foot.z)) or absf(game.terrain_height(foot.x,foot.z)+0.65-expected)>0.1:clear=false
   if clear:sample={"high":high,"low":low,"up_target":high-direction*2,"down_target":low+direction*4};break
 if sample.is_empty():return ["No clear cliff traversal fixture"]
 var errors=[]
 for climbing in [true,false]:
  var start=sample.low if climbing else sample.high
  var target=sample.up_target if climbing else sample.down_target
  game.player.position=target-Vector3.UP*0.65;game.forest_navigation.refresh(game.player.position);game.enemies.clear()
  var enemy=game.spawn_enemy(0,start);enemy.cooldown=999;var exercised=false
  for tick in 1800:
   EnemySimulation.step(game,enemy,1.0/60)
   exercised=exercised or not enemy.get("climb" if climbing else "drop",{}).is_empty()
   if enemy.pos.distance_to(target)<2 and enemy.get("climb",{}).is_empty() and enemy.get("drop",{}).is_empty():break
  if not exercised or enemy.pos.distance_to(target)>=2 or not enemy.get("climb",{}).is_empty() or not enemy.get("drop",{}).is_empty():errors.append("Enemy "+("climb" if climbing else "drop")+" failed")
 game.enemies.clear()
 return errors

extends SceneTree
var failures=[]
var checks=0
func check(value: bool,message: String):
 checks+=1
 if value:print("PASS: "+message)
 else:failures.append(message);push_error(message)
func _initialize():call_deferred("run")
func run():
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.settings.focus_pause=false;game.settings.visual_intensity=1;game.settings.reduced=false;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause"
 var seed_results=[];var above=0;var below=0;var near_boundary=0;var cliff_routes=0;var valleys=0;var high_plateaus=0
 for seed_value in 20:
  game.run_seed=seed_value;game.map_seed_override=seed_value;game.stage=1;game.build_stage();game.player.position=game.map_layout.spawn;game.player.active=false;await process_frame
  var wind=game.portal_wind;var field=wind.guidance;var path=field.route(game.player.position);var graph_goal=game.forest_navigation.goal
  var valid=path.size()>1 and path[-1].distance_to(game.portal.global_position)<0.1
  for i in range(path.size()-2):
   var a=game.forest_navigation.nearest_cell(path[i]);var b=game.forest_navigation.nearest_cell(path[i+1])
   if not b in game.forest_navigation.edges[a] or field.costs[b]>=field.costs[a]:valid=false
  check(valid,"Portal wind follows a descending-cost traversable route for seed "+str(seed_value))
  check(field.goal==game.forest_navigation.nearest_cell(game.portal.position) and graph_goal==game.forest_navigation.goal,"Portal flow field targets actual portal without changing enemy navigation: "+str(seed_value))
  var delta=game.portal.position.y-game.player.position.y
  if delta>6:above+=1
  if delta< -6:below+=1
  if maxf(absf(game.portal.position.x),absf(game.portal.position.z))>72:near_boundary+=1
  var blocked_line=false;var previous=game.player.position
  for i in range(1,101):
   var p=game.player.position.lerp(game.portal.position,float(i)/100);p.y=game.terrain_height(p.x,p.z)
   if absf(p.y-previous.y)>1.1:blocked_line=true
   previous=p
  if blocked_line:cliff_routes+=1
  var low=INF
  for p in path:low=minf(low,p.y)
  if low<minf(game.player.position.y,game.portal.position.y)-3:valleys+=1
  if game.portal.position.y>=24:high_plateaus+=1
  seed_results.append({"seed":seed_value,"portal":str(game.portal.position),"spawn":str(game.player.position),"waypoints":path.size(),"above":delta>6,"below":delta< -6,"direct_line_crosses_cliff":blocked_line,"valid":valid})
  var counts=[]
  for edge in 4:counts.append(game.prop_batches["natural_boundary_"+str(edge)].multimesh.visible_instance_count)
  check(counts.all(func(n):return n>90 and n<512),"Imported boundary rocks stay within instance budgets: "+str(seed_value))
 check(above>0 and below>0 and cliff_routes>0,"Sample covers portal above/below player and routes obstructed by direct cliffs")
 var moving=game.portal_wind;var start=game.player.position+Vector3.UP*1.2;moving.positions[0]=start;moving.ages[0]=0;moving.altitudes[0]=1.2;moving.velocities[0]=Vector3.ZERO
 var start_cell=game.forest_navigation.nearest_cell(start);var original_cost=moving.guidance.costs[start_cell]
 for i in 60:moving.simulate(1.0/30)
 var end_cell=game.forest_navigation.nearest_cell(moving.positions[0])
 check(moving.guidance.costs[end_cell]<original_cost,"Actual red particle simulation advances portal-ward along the shared field")
 check(valleys>0 and high_plateaus>0 and near_boundary>0,"Sample includes valley routes, high-plateau portals and boundary portals")
 var field=game.portal_wind.guidance;var old_goal=field.goal;game.portal.position=game.map_layout.spawn;game.portal_wind.simulate(0.5)
 check(field.destination.distance_to(game.portal.position)<0.01 and field.goal==game.forest_navigation.nearest_cell(game.portal.position),"Moving the live portal refreshes guidance rather than using cached map coordinates")
 var wind=game.portal_wind;game.player.position=game.map_layout.portal+Vector3(70,0,0);wind.simulate(0.1);var far=wind.proximity;game.player.position=game.portal.position+Vector3(3,0,0)
 for i in 60:wind.simulate(1.0/30)
 check(wind.proximity>far and wind.direction.is_finite(),"Guidance density and brightness scale smoothly with real proximity")
 game.portal_state="summoned";wind.simulate(0.05)
 check(wind.surge>1 and wind.vortex.visible,"Portal activation intensifies its attached vortex")
 game.portal_state="exit"
 for i in 60:wind.simulate(1.0/30)
 check(wind.factor==0 and not wind.stream.visible and not wind.vortex.visible and wind.ambient.emitting,"Completed portal fades guidance/vortex while ambient wind continues")
 for stage_value in [1,2,3]:
  game.stage=stage_value;game.build_stage();var sky=game.world.get_child(0).environment.sky.sky_material
  check(sky.get_shader_parameter("panorama")== (ArtResetWorld.DAY if stage_value==1 else ArtResetWorld.NIGHT),"Stage loads supplied HDR panorama: "+str(stage_value))
  check(game.portal.has_node("PortalAsset") and game.portal.get_node("PortalAsset").find_children("*","MeshInstance3D",true,false).size()==2,"Portal uses both supplied FBX mesh components")
 var fx=game.combat_fx.supplied;var nodes=fx.get_child_count()
 check(game.combat_fx.supplied_burst("shatter",game.player.position,2),"Supplied native shatter scene plays as a bounded boss effect")
 check(game.combat_fx.supplied_burst("fire",game.player.position,1),"Supplied aura shader powers weapon/bug fire effects")
 check(game.combat_fx.supplied_burst("debris",game.player.position,1),"Supplied rock geometry powers debris effects")
 for i in 120:game.combat_fx.tick(1.0/30,true)
 check(fx.active.is_empty() and fx.get_child_count()==nodes,"Native effects finish and return to their original prewarmed pool")
 DirAccess.make_dir_recursive_absolute("res://builds")
 var report={"seeds":20,"above":above,"below":below,"near_boundary":near_boundary,"direct_cliff_routes":cliff_routes,"valley_routes":valleys,"high_plateau_portals":high_plateaus,"cases":seed_results,"failures":failures}
 var file=FileAccess.open("res://builds/art-reset-guidance.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 print("ART RESET WORLD: %d checks, %d failures; above=%d below=%d boundary=%d cliff=%d"%[checks,failures.size(),above,below,near_boundary,cliff_routes]);game.queue_free();await process_frame;await process_frame;quit(0 if failures.is_empty() else 1)

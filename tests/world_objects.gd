extends SceneTree
var failures=[]
func _initialize():call_deferred("run")
func run():
 ForestMap.generation_version=4;ForestMap.object_version=1
 var records=[];var free_seeds=0;var retries=[];var signatures={};var began=Time.get_ticks_msec()
 for seed in 200:
  var data=ForestMap.layout(seed);var counts={};var errors=[];var elevations={}
  for object in data.placements:
   counts[object.kind]=int(counts.get(object.kind,0))+1
   if object.kind in ["Chest","Shop"]:elevations[str(object.position[1])]=true
  for minimum in [["Chest",15],["Shop",3],["Elite Statue",2],["Boss Statue",1],["Charge Shrine",2],["Risk Shrine",2],["Stat Shrine",2],["Boss Portal",1]]:
   if counts.get(minimum[0],0)<minimum[1]:errors.append("Missing "+minimum[0])
  if int(data.get("placement_attempts",1))>1:retries.append({"seed":seed,"attempts":data.placement_attempts})
  var free=int(counts.get("Free Chest",0))
  if free>0:free_seeds+=1
  if free<0 or free>5:errors.append("Invalid free chest count")
  var positions=data.pois+[data.portal,data.spawn,data.elite]
  for i in positions.size():
   var p: Vector3=positions[i]
   if not p.is_finite() or ForestMap.is_ramp(data,Vector2(p.x,p.z),4):errors.append("Invalid/blocked ramp position")
   for j in range(i+1,positions.size()):
    if Vector2(p.x-positions[j].x,p.z-positions[j].z).length()<9:errors.append("Overlapping world objects")
  if not data.first_attempt_valid or elevations.size()<2:errors.append("Disconnected or nonvertical distribution")
  var signature=hash(str(data.placements));signatures[signature]=true
  if signature!=hash(str(ForestMap.layout(seed).placements)):errors.append("Nondeterministic placement")
  records.append({"seed":seed,"counts":counts,"elevations":elevations.keys(),"positions":data.placements,"errors":errors})
  if not errors.is_empty():failures.append({"seed":seed,"errors":errors})
  if seed%50==0:print("WORLD OBJECT SEED ",seed," ",counts)
 var game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.sandbox=true;game.next_run_seed=923;game.map_seed_override=9;game.begin_run();game.set_physics_process(false);game.player.active=false;game.mode="pause"
 var statues=[]
 for object in game.interactables:
  if object.kind=="Elite Statue":statues.append(object)
 var activated=0
 for statue in statues:
  if game.activate_elite_statue(statue):
   activated+=1
   for e in game.enemies.duplicate():
    if e.get("elite",false):e.hp=0;game.kill_enemy(game.enemies.find(e))
 if activated<2 or game.drop_chests.size()!=6:failures.append({"seed":"runtime","errors":["Both elite encounters must activate and drop six independent chests"]})
 game.queue_free();await process_frame;await process_frame
 var result={"seeds":200,"failures":failures,"unique_placements":signatures.size(),"free_chest_seeds":free_seeds,"placement_retries":retries,"ms":Time.get_ticks_msec()-began,"minimum_chests":15,"minimum_shops":3,"minimum_elites":2,"minimum_boss_statues":1,"actual_elite_encounters_activated":activated}
 DirAccess.make_dir_recursive_absolute("res://builds")
 var file=FileAccess.open("res://builds/world-object-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(result.merged({"records":records}),"  "));file.close()
 print("WORLD OBJECTS: "+JSON.stringify(result));quit(0 if failures.is_empty() and signatures.size()==200 and free_seeds>0 else 1)

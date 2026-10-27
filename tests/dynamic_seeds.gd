extends SceneTree
func _initialize():call_deferred("run")
func run():
 var sides={};var elevations={};var centers={};var counts={};var ramps={};var layouts={};var errors=[];var records=[]
 for seed_value in 100:
  var data=ForestMap.layout(seed_value);var p=data.spawn;var region=data.regions[data.spawn_region];var r: Rect2=region.rect
  var side=("N" if r.position.y==-96 else "")+("S" if r.end.y==96 else "")+("W" if r.position.x==-96 else "")+("E" if r.end.x==96 else "")
  sides[side]=sides.get(side,0)+1;elevations[str(p.y)]=elevations.get(str(p.y),0)+1
  var center=ForestMap.height(seed_value,0,0);centers[str(center)]=centers.get(str(center),0)+1;counts[str(data.regions.size())]=true;ramps[str(data.ramps.size())]=true
  var checksum=hash(str(data.regions)+str(data.ramps)+str(data.spawn));layouts[checksum]=true
  if data.elite.distance_to(data.portal)<16:errors.append("Elite statue overlaps portal interaction zone")
  if Vector2(p.x,p.z).length()<24:errors.append("Central spawn "+str(seed_value))
  if ForestMap.normal(seed_value,p.x,p.z).dot(Vector3.UP)<0.999:errors.append("Sloped spawn")
  if not data.first_attempt_valid:errors.append("Repaired terrain "+str(seed_value))
  for point in data.pois+[p,data.portal,data.elite]:
   if not ForestMap.reachable(seed_value,Vector2(point.x,point.z)):errors.append("Unreachable POI")
  records.append({"seed":seed_value,"spawn":[p.x,p.y,p.z],"side":side,"regions":data.regions.size(),"ramps":data.ramps.size(),"center_height":center,"drafts":data.generation_attempts})
  if seed_value%10==0:await process_frame
 if sides.size()<4 or elevations.size()<3 or centers.size()<3 or counts.size()<4 or ramps.size()<4 or layouts.size()!=100:errors.append("Insufficient variety")
 var report={"seeds":100,"sides":sides,"spawn_elevations":elevations,"center_elevations":centers,"region_counts":counts.keys(),"ramp_counts":ramps.keys(),"unique_layouts":layouts.size(),"errors":errors,"records":records}
 DirAccess.make_dir_recursive_absolute("res://builds");var file=FileAccess.open("res://builds/dynamic-seeds.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 report.erase("records");print(JSON.stringify(report));quit(0 if errors.is_empty() else 1)

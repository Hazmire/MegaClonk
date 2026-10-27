extends SceneTree
var failed=[]
var first_failures=[]
var count=0
var checksums={}
var records=[]
func _initialize():call_deferred("run")
func run():
 var start=Time.get_ticks_msec()
 for seed_value in 200:
  var data=ForestMap.layout(seed_value);var errors=[]
  if not data.first_attempt_valid:first_failures.append({"seed":seed_value,"reason":data.failure_reason})
  var edges=ForestMap.graph(data);var queue=PackedInt32Array([ForestMap.index(0,0)]);var seen={queue[0]:true};var head=0
  while head<queue.size():
   var at=queue[head];head+=1
   for n in edges[at]:
    if not seen.has(n):seen[n]=true;queue.append(n)
  if seen.size()!=edges.size():errors.append("Disconnected walkable cells: %d/%d"%[seen.size(),edges.size()])
  var flat=0
  var bands={};var distribution={};var elevated_area=0.0
  for region in data.regions:
   bands[region.height]=true;distribution[str(region.height)]=float(distribution.get(str(region.height),0))+region.rect.get_area()

  if bands.size()!=4 or bands.keys().max()-bands.keys().min()<36:errors.append("Insufficient verticality")
  for i in data.planes.size():
   var plane=data.planes[i]
   if ForestMap.plane_height(plane,-95+(i%96)*2,-95+int(i/96)*2)>0.01:elevated_area+=4
   if absf(plane.x)+absf(plane.z)<0.0001:flat+=1
  if float(flat)/data.planes.size()<0.75:errors.append("Insufficient flat ground")
  for ramp in data.ramps:
   if ramp.width<12 or absf(ramp.h1-ramp.h0)/ramp.length>tan(deg_to_rad(28)):errors.append("Invalid ramp geometry")
  for p in data.pois+[data.portal]:
   if ForestMap.normal(seed_value,p.x,p.z).dot(Vector3.UP)<0.999:errors.append("Objective on slope")
   if not seen.has(ForestMap.index(p.x,p.z)):errors.append("Objective unreachable")
  records.append({"seed":seed_value,"bands":bands.size(),"elevation_range":bands.keys().max()-bands.keys().min(),"elevated_percent":elevated_area/36864*100,"plateaus":data.regions.size(),"ramps":data.ramps.size(),"height_area":distribution,"flat_percent":float(flat)/data.planes.size()*100,"spawn":[data.spawn.x,data.spawn.y,data.spawn.z],"drafts":data.generation_attempts})
  var digest=hash(str(data.regions)+str(data.ramps)+str(data.pois))
  ForestMap.cache.clear()
  var again=ForestMap.layout(seed_value)
  if digest!=hash(str(again.regions)+str(again.ramps)+str(again.pois)):errors.append("Nondeterministic layout")
  checksums[digest]=true
  if not errors.is_empty():failed.append({"seed":seed_value,"errors":errors})
  count+=1
  if seed_value%20==0:await process_frame
 var report={"seeds":count,"first_attempt_passed":count-first_failures.size(),"first_attempt_failures":first_failures,"repaired_count":first_failures.size(),"final_passed":count-failed.size(),"failed":failed,"unique_layouts":checksums.size(),"ms":Time.get_ticks_msec()-start}
 DirAccess.make_dir_recursive_absolute("res://builds")
 var file=FileAccess.open("res://builds/terrace-seed-report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report.merged({"records":records}),"  "));file.close()
 print(JSON.stringify(report));quit(0 if failed.is_empty() and first_failures.is_empty() else 1)

class_name ForestMap
extends RefCounted
# Full coverage staggered partitions with variable region counts. Ramps are carved
# across shared boundaries, never bridges above a second traversable floor.
const SETTINGS=preload("res://assets/config/forest.tres")
const CELL=2.0
const HALF=96.0
const SIDE=96
static var cache: Dictionary={}
static func layout(seed_value: int) -> Dictionary:
 if cache.has(seed_value):return cache[seed_value]
 var rng=RandomNumberGenerator.new();rng.seed=seed_value
 var draft=draft_regions(rng)
 var regions: Array=draft.regions;var ramps: Array=draft.ramps
 # Objectives/spawn are selected from verified flat interiors before scenery.
 var peripheral=[]
 for region in regions:
  var r: Rect2=region.rect
  if r.position.x==-96 or r.position.y==-96 or r.end.x==96 or r.end.y==96:peripheral.append(region.id)
 var spawn_region=peripheral[rng.randi_range(0,peripheral.size()-1)]
 var spawn2: Vector2=regions[spawn_region].rect.get_center()
 var portal_region=spawn_region;var farthest=0.0
 for region in regions:
  var distance=region.rect.get_center().distance_to(spawn2)
  if distance>farthest:farthest=distance;portal_region=region.id
 var portal2: Vector2=regions[portal_region].rect.get_center()
 var pois=[]
 for i in 12:
  var region=regions[(i+spawn_region+1)%regions.size()]
  var center: Vector2=region.rect.get_center()
  var offset=Vector2(-4,0) if i<regions.size() else Vector2(4,0)
  var point=center+offset
  pois.append(Vector3(point.x,region.height,point.y))
 var elite_region=(spawn_region+int(regions.size()/2))%regions.size()
 var elite2: Vector2=regions[elite_region].rect.get_center()
 var data={"seed":seed_value,"regions":regions,"ramps":ramps,"pois":pois,
  "spawn":Vector3(spawn2.x,regions[spawn_region].height,spawn2.y),"spawn_region":spawn_region,
  "elite":Vector3(elite2.x,regions[elite_region].height,elite2.y),
  "portal":Vector3(portal2.x,regions[portal_region].height,portal2.y),"generation_attempts":draft.attempts}
 # Cell plane uses the center to choose its region; edge queries use that
 # SAME plane, avoiding heightmap interpolation across vertical cliff faces.
 var planes=[]
 for z in SIDE:
  for x in SIDE:
   var p=Vector2(-96+x*2+1,-96+z*2+1)
   var region=0
   for candidate in regions:
    if candidate.rect.has_point(p):region=candidate.id;break
   var plane=Vector3(0,regions[region].height,0) # y = plane.x*x + plane.y + plane.z*z
   for ramp in ramps:
    if ramp.rect.has_point(p):
     var slope=(ramp.h1-ramp.h0)/ramp.length
     if ramp.axis==0:plane=Vector3(slope,ramp.h0-slope*ramp.rect.position.x,0)
     else:plane=Vector3(0,ramp.h0-slope*ramp.rect.position.y,slope)
     break
   planes.append(plane)
 data.planes=planes
 var links=graph(data);var pending=PackedInt32Array([index(0,0)]);var reached={pending[0]:true};var head=0
 while head<pending.size():
  var at=pending[head];head+=1
  for n in links[at]:
   if not reached.has(n):reached[n]=true;pending.append(n)
 data.first_attempt_valid=reached.size()==SIDE*SIDE;data.repaired=false;data.failure_reason=""
 if not data.first_attempt_valid:
  # Explicit, recorded safe fallback before creating collision. No failed first
  # attempt is reported as successful by the seed tests.
  data.failure_reason="Disconnected terrain cells";data.repaired=true
  for region in regions:region.height=0.0
  for ramp in ramps:ramp.h0=0.0;ramp.h1=0.0
  for i in planes.size():planes[i]=Vector3.ZERO
  for i in pois.size():pois[i].y=0.0
  data.portal.y=0.0;data.spawn.y=0.0;data.elite.y=0.0
  push_warning("Repaired forest seed %s: %s"%[seed_value,data.failure_reason])
 if cache.size()>=4:cache.erase(cache.keys()[0])
 cache[seed_value]=data;return data
# Independently partition each seeded row. Different row/column counts and cuts
# create T junctions and irregular adjacency graphs, rather than a rotated 3x3 grid.
static func partition(rng: RandomNumberGenerator,count: int) -> Array:
 var widths=[];var remaining=96-count*22
 for i in count:widths.append(22)
 for i in remaining:widths[rng.randi_range(0,count-1)]+=1
 var cuts=[-96.0];var x=-96.0
 for width in widths:x+=width*2;cuts.append(x)
 return cuts
static func draft_regions(rng: RandomNumberGenerator) -> Dictionary:
 for attempt in 64:
  var regions=[];var candidates=[]
  var rows=partition(rng,rng.randi_range(2,4))
  for row in rows.size()-1:
   var columns=partition(rng,rng.randi_range(2,4))
   for col in columns.size()-1:
    regions.append({"id":regions.size(),"rect":Rect2(columns[col],rows[row],columns[col+1]-columns[col],rows[row+1]-rows[row]),"height":float(rng.randi_range(0,2)*SETTINGS.elevation_step)})
  # Ensure a mixed elevation palette without imposing any spatial relationship.
  var high=rng.randi_range(0,regions.size()-1);regions[high].height=SETTINGS.elevation_step*2
  regions[(high+1)%regions.size()].height=0.0
  for a in regions.size():
   for b in range(a+1,regions.size()):
    var ra: Rect2=regions[a].rect;var rb: Rect2=regions[b].rect
    var axis=-1;var boundary=0.0;var lo=0.0;var hi=0.0
    if ra.end.x==rb.position.x or rb.end.x==ra.position.x:
     axis=0;boundary=maxf(ra.position.x,rb.position.x);lo=maxf(ra.position.y,rb.position.y);hi=minf(ra.end.y,rb.end.y)
    elif ra.end.y==rb.position.y or rb.end.y==ra.position.y:
     axis=1;boundary=maxf(ra.position.y,rb.position.y);lo=maxf(ra.position.x,rb.position.x);hi=minf(ra.end.x,rb.end.x)
    if axis<0 or hi-lo<20:continue
    var first=a;var second=b
    if (axis==0 and ra.position.x>rb.position.x) or (axis==1 and ra.position.y>rb.position.y):first=b;second=a
    for center in range(int(lo+8),int(hi-6),2):
     var p=Vector2(boundary,center) if axis==0 else Vector2(center,boundary)
     var size=Vector2(28,12) if axis==0 else Vector2(12,28)
     candidates.append({"from":first,"to":second,"axis":axis,"rect":Rect2(p-size/2,size),"h0":regions[first].height,"h1":regions[second].height,"length":28.0,"width":12.0})
  for i in range(candidates.size()-1,0,-1):
   var j=rng.randi_range(0,i);var temp=candidates[i];candidates[i]=candidates[j];candidates[j]=temp
  var parents=range(regions.size());var ramps=[];var used={}
  for loops in [false,true]:
   for ramp in candidates:
    var a=ramp.from;var b=ramp.to
    while parents[a]!=a:a=parents[a]
    while parents[b]!=b:b=parents[b]
    if not loops and a==b:continue
    if loops and (used.has(str(ramp.from)+":"+str(ramp.to)) or rng.randf()>0.35):continue
    var clear=true
    for selected in ramps:
     if selected.rect.grow(1).intersects(ramp.rect.grow(1)):clear=false;break
    if not clear:continue
    ramp.backbone=not loops;ramps.append(ramp);parents[a]=b;used[str(ramp.from)+":"+str(ramp.to)]=true
    if loops and ramps.size()>=regions.size()+SETTINGS.extra_connections:break
   if not loops and ramps.size()!=regions.size()-1:break
  if ramps.size()>=regions.size()-1:return {"regions":regions,"ramps":ramps,"attempts":attempt+1}
 assert(false,"Unable to construct connected region graph")
 return {}
static func index(x: float,z: float) -> int:
 return clampi(floori((z+96)/2),0,SIDE-1)*SIDE+clampi(floori((x+96)/2),0,SIDE-1)
static func plane_height(plane: Vector3,x: float,z: float) -> float:return plane.x*x+plane.y+plane.z*z
static func height(seed_value: int,x: float,z: float) -> float:
 var p=layout(seed_value).planes[index(x,z)]
 return plane_height(p,x,z)+maxf(0,maxf(absf(x),absf(z))-96)*3.0
static func normal(seed_value: int,x: float,z: float) -> Vector3:
 var p=layout(seed_value).planes[index(x,z)];return Vector3(-p.x,1,-p.z).normalized()
static func is_ramp(data: Dictionary,p: Vector2,margin: float=0) -> bool:
 for ramp in data.ramps:
  if ramp.rect.grow(margin).has_point(p):return true
 return false
static func protected(data: Dictionary,p: Vector2,margin: float=0) -> bool:
 if p.distance_to(Vector2(data.spawn.x,data.spawn.z))<12+margin or p.distance_to(Vector2(data.elite.x,data.elite.z))<10+margin or p.distance_to(Vector2(data.portal.x,data.portal.z))<10+margin:return true
 if is_ramp(data,p,4+margin):return true
 for pos in data.pois:
  if p.distance_to(Vector2(pos.x,pos.z))<5+margin:return true
 # Wide cross-shaped approach lanes on every plateau connect all ramp mouths.
 var center=Vector2.ZERO
 for region in data.regions:
  if region.rect.has_point(p):center=region.rect.get_center();break
 return absf(p.x-center.x)<10+margin or absf(p.y-center.y)<10+margin
static func adjacent(data: Dictionary,a: int,b: int) -> bool:
 var ax=a%SIDE;var az=a/SIDE;var bx=b%SIDE;var bz=b/SIDE
 if absi(ax-bx)+absi(az-bz)!=1:return false
 var pa: Vector3=data.planes[a];var pb: Vector3=data.planes[b]
 var x=-96+(ax+bx+1);var z=-96+(az+bz+1)
 var delta=Vector2(0,1) if ax!=bx else Vector2(1,0)
 for sign_value in [-1,1]:
  var ex=x+delta.x*sign_value;var ez=z+delta.y*sign_value
  if absf(plane_height(pa,ex,ez)-plane_height(pb,ex,ez))>0.01:return false
 return true
static func graph(data: Dictionary,blocked: Dictionary={}) -> Array:
 var result=[]
 for i in SIDE*SIDE:
  var edges=[]
  if not blocked.has(i):
   for n in [i-1,i+1,i-SIDE,i+SIDE]:
    if n>=0 and n<SIDE*SIDE and not blocked.has(n) and adjacent(data,i,n):edges.append(n)
  result.append(edges)
 return result
static func reachable(seed_value: int,target: Vector2) -> bool:
 var data=layout(seed_value)
 if not data.has("graph"):data.graph=graph(data)
 var goal=index(target.x,target.y);var pending=[index(0,0)];var seen={pending[0]:true};var head=0
 while head<pending.size():
  var at=pending[head];head+=1
  if at==goal:return true
  for n in data.graph[at]:
   if not seen.has(n):seen[n]=true;pending.append(n)
 return false
static func top(data: Dictionary,i: int) -> PackedVector3Array:
 var x=-96+(i%SIDE)*2;var z=-96+int(i/SIDE)*2;var p: Vector3=data.planes[i]
 return PackedVector3Array([Vector3(x,plane_height(p,x,z),z),Vector3(x+2,plane_height(p,x+2,z),z),Vector3(x+2,plane_height(p,x+2,z+2),z+2),Vector3(x,plane_height(p,x,z+2),z+2)])
static func geometry(data: Dictionary) -> ArrayMesh:
 var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in SIDE*SIDE:
  var corners=top(data,i);var sloped=absf(data.planes[i].x)+absf(data.planes[i].z)>0.001
  var color=Color("526b3c").srgb_to_linear() if sloped else Color("4d713f").lightened(float(data.planes[i].y)/160).srgb_to_linear()
  for j in [0,1,2,0,2,3]:tool.set_color(color);tool.add_vertex(corners[j])
  var x=i%SIDE;var z=int(i/SIDE)
  for side in 4:
   var n=[i-SIDE,i+1,i+SIDE,i-1][side]
   var pair=[[0,1],[1,2],[2,3],[3,0]][side]
   var a=corners[pair[0]];var b=corners[pair[1]]
   var boundary=(side==0 and z==0) or (side==1 and x==SIDE-1) or (side==2 and z==SIDE-1) or (side==3 and x==0)
   var lo_a=a;var lo_b=b
   if boundary:
    # Continuous visible perimeter wall, 24m above each local surface.
    lo_a.y+=24;lo_b.y+=24;a.y=-4;b.y=-4
   elif n>=0 and n<SIDE*SIDE:
    lo_a.y=plane_height(data.planes[n],a.x,a.z);lo_b.y=plane_height(data.planes[n],b.x,b.z)
    if maxf(a.y-lo_a.y,b.y-lo_b.y)<=0.01:continue
   else:continue
   for triangle in [[a,lo_b,b],[a,lo_a,lo_b]]:
    if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).length_squared()>0.00001:
     for v in triangle:tool.set_color(Color("77715e").srgb_to_linear());tool.add_vertex(v)
 tool.generate_normals();return tool.commit()

class_name ForestMap
extends RefCounted
# Full coverage terraces: nine seeded broad rectangular regions. Ramps are carved
# across shared boundaries, never bridges above a second traversable floor.
const SETTINGS=preload("res://assets/config/forest.tres")
const CELL=2.0
const HALF=96.0
const SIDE=96
static var cache: Dictionary={}
static func layout(seed_value: int) -> Dictionary:
 if cache.has(seed_value):return cache[seed_value]
 var rng=RandomNumberGenerator.new();rng.seed=seed_value
 var regions=[];var ramps=[]
 var cuts_x=[-96.0,float(rng.randi_range(-9,-8)*4),float(rng.randi_range(8,9)*4),96.0]
 var cuts_z=[-96.0,float(rng.randi_range(-9,-8)*4),float(rng.randi_range(8,9)*4),96.0]
 for z in 3:
  for x in 3:
   var index=z*3+x
   regions.append({"id":index,"rect":Rect2(cuts_x[x],cuts_z[z],cuts_x[x+1]-cuts_x[x],cuts_z[z+1]-cuts_z[z]),"height":0.0 if index==4 else float(rng.randi_range(0,2)*SETTINGS.elevation_step)})
 var elevated=[0,1,2,3,5,6,7,8]
 var first=rng.randi_range(0,7);regions[elevated[first]].height=SETTINGS.elevation_step;regions[elevated[(first+3)%8]].height=SETTINGS.elevation_step*2
 for z in 3:
  for x in 3:
   var a=z*3+x
   for axis in [0,1]:
    if (axis==0 and x==2) or (axis==1 and z==2):continue
    var b=a+(1 if axis==0 else 3)
    var offset=0.0
    var span=regions[a].rect.size.y if axis==0 else regions[a].rect.size.x
    var width=16.0 if span>=44 and rng.randf()<0.5 else SETTINGS.minimum_ramp_width
    var offset_cells=mini(1,maxi(0,floori((span/2-14-width/2)/2)))
    offset=rng.randi_range(-offset_cells,offset_cells)*2.0
    var length=maxf(SETTINGS.preferred_ramp_length,ceilf(absf(regions[a].height-regions[b].height)/tan(deg_to_rad(SETTINGS.maximum_ramp_slope))/2)*2)
    var center=Vector2(cuts_x[x+1],roundf(regions[a].rect.get_center().y/2)*2+offset) if axis==0 else Vector2(roundf(regions[a].rect.get_center().x/2)*2+offset,cuts_z[z+1])
    var rect=Rect2(center-Vector2(length,width)/2,Vector2(length,width)) if axis==0 else Rect2(center-Vector2(width,length)/2,Vector2(width,length))
    ramps.append({"from":a,"to":b,"axis":axis,"rect":rect,"h0":regions[a].height,"h1":regions[b].height,"length":length,"width":width})
 # Random spanning backbone first, then optional loop connections.
 var parents=range(9);var ordered=ramps.duplicate();ramps=[]
 for i in range(ordered.size()-1,0,-1):
  var j=rng.randi_range(0,i);var swap=ordered[i];ordered[i]=ordered[j];ordered[j]=swap
 var extra=[]
 for ramp in ordered:
  var a=ramp.from;var b=ramp.to
  while parents[a]!=a:a=parents[a]
  while parents[b]!=b:b=parents[b]
  if a!=b:parents[a]=b;ramp.backbone=true;ramps.append(ramp)
  else:ramp.backbone=false;extra.append(ramp)
 for i in extra.size():
  if i<SETTINGS.extra_connections or rng.randf()<SETTINGS.extra_connection_frequency:ramps.append(extra[i])
 var pois=[]
 # Objectives stay on large flat interiors, outside the maximum ramp cut depth.
 for i in 12:
  var region=[0,1,2,3,5,6,7,8][i%8];var r=regions[region].rect
  var sign_value=-1 if i<8 else 1
  var room=regions[region].rect.size
  var amount=5 if maxf(room.x,room.y)>=52 else 3
  var offset=Vector2(amount*sign_value,0) if room.x>=room.y else Vector2(0,amount*sign_value)
  var p=r.get_center()+offset
  if region==4:p+=Vector2(8,8)
  pois.append(Vector3(p.x,regions[region].height,p.y))
 var data={"seed":seed_value,"regions":regions,"ramps":ramps,"pois":pois,"portal":Vector3(regions[8].rect.get_center().x+8,regions[8].height,regions[8].rect.get_center().y+8),"cuts_x":cuts_x,"cuts_z":cuts_z}
 # Cell plane uses the center to choose its region; edge queries use that
 # SAME plane, avoiding heightmap interpolation across vertical cliff faces.
 var planes=[]
 for z in SIDE:
  for x in SIDE:
   var p=Vector2(-96+x*2+1,-96+z*2+1)
   var region=(0 if p.y<cuts_z[1] else (1 if p.y<cuts_z[2] else 2))*3+(0 if p.x<cuts_x[1] else (1 if p.x<cuts_x[2] else 2))
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
  data.portal.y=0.0
  push_warning("Repaired forest seed %s: %s"%[seed_value,data.failure_reason])
 if cache.size()>=4:cache.erase(cache.keys()[0])
 cache[seed_value]=data;return data
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
 if p.length()<12+margin or p.distance_to(Vector2(data.portal.x,data.portal.z))<10+margin:return true
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
    lo_a.y+=24;lo_b.y+=24
   elif n>=0 and n<SIDE*SIDE:
    lo_a.y=plane_height(data.planes[n],a.x,a.z);lo_b.y=plane_height(data.planes[n],b.x,b.z)
    if maxf(a.y-lo_a.y,b.y-lo_b.y)<=0.01:continue
   else:continue
   for triangle in [[a,lo_b,b],[a,lo_a,lo_b]]:
    if (triangle[1]-triangle[0]).cross(triangle[2]-triangle[0]).length_squared()>0.00001:
     for v in triangle:tool.set_color(Color("77715e").srgb_to_linear());tool.add_vertex(v)
 tool.generate_normals();return tool.commit()

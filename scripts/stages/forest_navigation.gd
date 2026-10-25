class_name ForestNavigation
extends Node3D
var layout: Dictionary
var edges: Array=[]
var blocked: Dictionary={}
var distances=PackedInt32Array()
var goal=-1
var clock=0.0
var navigation_map: RID
var region: NavigationRegion3D
var ready_for_spawning=false
func setup(data: Dictionary, obstacles: Dictionary) -> void:
 layout=data
 for entries in obstacles.values():
  for obstacle in entries:
   var r=obstacle.radius+0.65
   for z in range(floori((obstacle.pos.z-r+96)/2),ceili((obstacle.pos.z+r+96)/2)):
    for x in range(floori((obstacle.pos.x-r+96)/2),ceili((obstacle.pos.x+r+96)/2)):
     var p=Vector2(-95+x*2,-95+z*2)
     if x>=0 and x<ForestMap.SIDE and z>=0 and z<ForestMap.SIDE and p.distance_to(Vector2(obstacle.pos.x,obstacle.pos.z))<r:blocked[z*ForestMap.SIDE+x]=true
 edges=ForestMap.graph(layout,blocked)
 distances.resize(edges.size());distances.fill(-1)
 var vertices=PackedVector3Array();var lookup={};var polygons=[]
 for i in edges.size():
  if blocked.has(i):continue
  var polygon=PackedInt32Array()
  for vertex in ForestMap.top(layout,i):
   var key=Vector3i(roundi(vertex.x*1000),roundi(vertex.y*1000),roundi(vertex.z*1000))
   if not lookup.has(key):lookup[key]=vertices.size();vertices.append(vertex)
   polygon.append(lookup[key])
  # Navigation polygon winding follows the upward collision surface.
  polygons.append(PackedInt32Array([polygon[0],polygon[1],polygon[2],polygon[3]]))
 var nav=NavigationMesh.new();nav.set_vertices(vertices)
 for polygon in polygons:nav.add_polygon(polygon)
 navigation_map=NavigationServer3D.map_create()
 NavigationServer3D.map_set_active(navigation_map,true)
 NavigationServer3D.map_set_use_async_iterations(navigation_map,false)
 region=NavigationRegion3D.new();NavigationServer3D.region_set_use_async_iterations(region.get_rid(),false);region.navigation_mesh=nav;region.use_edge_connections=false
 region.set_navigation_map(navigation_map);add_child(region)
 NavigationServer3D.map_force_update(navigation_map)
 refresh(data.spawn)
 var path=server_path(data.spawn,data.portal)
 ready_for_spawning=not path.is_empty() and path[-1].distance_to(data.portal)<1
 assert(ready_for_spawning,"Native navigation is not ready for this stage")
func nearest_cell(pos: Vector3) -> int:
 var index=ForestMap.index(pos.x,pos.z)
 if not blocked.has(index):return index
 for radius in range(1,7):
  for dz in range(-radius,radius+1):
   for dx in range(-radius,radius+1):
    var x=index%ForestMap.SIDE+dx;var z=int(index/ForestMap.SIDE)+dz
    if x>=0 and x<ForestMap.SIDE and z>=0 and z<ForestMap.SIDE:
     var at=z*ForestMap.SIDE+x
     if not blocked.has(at):return at
 return index
func refresh(target: Vector3) -> void:
 goal=nearest_cell(target);distances.fill(-1)
 var queue=PackedInt32Array([goal]);distances[goal]=0;var head=0
 while head<queue.size():
  var current=queue[head];head+=1
  for n in edges[current]:
   if distances[n]<0:distances[n]=distances[current]+1;queue.append(n)
func tick(delta: float,target: Vector3) -> void:
 clock-=delta
 if clock<=0 and nearest_cell(target)!=goal:refresh(target);clock=0.3
func direction(pos: Vector3,target: Vector3) -> Vector3:
 var at=nearest_cell(pos)
 if at==goal:return Vector3(target.x-pos.x,0,target.z-pos.z).normalized()
 var best=at;var cost=distances[at]
 for next in edges[at]:
  if distances[next]>=0 and (cost<0 or distances[next]<cost):cost=distances[next];best=next
 if best==at:return Vector3.ZERO
 var point=Vector3(-95+(best%ForestMap.SIDE)*2,0,-95+int(best/ForestMap.SIDE)*2)
 return Vector3(point.x-pos.x,0,point.z-pos.z).normalized()
func constrain(from: Vector3,to: Vector3) -> Vector3:
 if absf(to.x)>95.5 or absf(to.z)>95.5:return from
 var a=ForestMap.index(from.x,from.z);var b=ForestMap.index(to.x,to.z)
 if blocked.has(b):return from
 if a!=b and absf(ForestMap.height(layout.seed,from.x,from.z)-ForestMap.height(layout.seed,to.x,to.z))>1.1:return from
 return to
func reachable(pos: Vector3) -> bool:return distances[nearest_cell(pos)]>=0
func server_path(from: Vector3,to: Vector3) -> PackedVector3Array:
 var query=NavigationPathQueryParameters3D.new();query.map=navigation_map;query.start_position=from;query.target_position=to
 # Godot's default 4096-polygon limit is too small for a full 96x96 arena.
 # This is an occasional validation/debug query, never one query per enemy.
 query.path_search_max_polygons=edges.size()*8
 NavigationServer3D.map_force_update(navigation_map)
 var result=NavigationPathQueryResult3D.new();NavigationServer3D.query_path(query,result)
 return result.get_path()

func _exit_tree() -> void:
 if navigation_map.is_valid():
  NavigationServer3D.free_rid(navigation_map);navigation_map=RID()

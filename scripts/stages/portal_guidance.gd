class_name PortalGuidance
extends RefCounted
var game: Node
var costs=PackedInt32Array()
var goal=-1
var destination=Vector3.ZERO
var valid=false
func setup(owner_game: Node) -> void:
 game=owner_game;rebuild()
func rebuild() -> void:
 valid=false
 if not is_instance_valid(game.portal) or not is_instance_valid(game.forest_navigation):return
 destination=game.portal.global_position;var nav=game.forest_navigation;goal=nav.nearest_cell(destination)
 costs.resize(nav.edges.size());costs.fill(-1)
 if nav.blocked.has(goal):return
 var queue=PackedInt32Array([goal]);costs[goal]=0;var head=0
 while head<queue.size():
  var at=queue[head];head+=1
  for next in nav.edges[at]:
   if costs[next]>=0:continue
   costs[next]=costs[at]+1;queue.append(next)
 valid=costs[nav.nearest_cell(game.player.position)]>=0
func point(cell: int) -> Vector3:
 var x=-95+(cell%ForestMap.SIDE)*2;var z=-95+int(cell/ForestMap.SIDE)*2
 return Vector3(x,game.terrain_height(x,z),z)
func next_cell(at: int) -> int:
 if at<0 or at>=costs.size() or costs[at]<0:return -1
 if at==goal:return goal
 var best=-1;var value=costs[at]
 for neighbour in game.forest_navigation.edges[at]:
  if costs[neighbour]>=0 and costs[neighbour]<value:value=costs[neighbour];best=neighbour
 return best
func waypoint(from: Vector3) -> Vector3:
 if not valid or maxf(absf(from.x),absf(from.z))>95.5:return Vector3.INF
 var cell=game.forest_navigation.nearest_cell(from);var next=next_cell(cell)
 if next<0:return Vector3.INF
 return destination if next==goal else point(next)
func route(from: Vector3) -> PackedVector3Array:
 var result=PackedVector3Array()
 if not valid or maxf(absf(from.x),absf(from.z))>95.5:return result
 var at=game.forest_navigation.nearest_cell(from)
 for i in costs.size():
  if at<0:return PackedVector3Array()
  result.append(point(at))
  if at==goal:result.append(destination);return result
  at=next_cell(at)
 return PackedVector3Array()

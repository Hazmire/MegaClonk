class_name EnemyTraversal
extends RefCounted
static func move(game: Node,e: Dictionary,speed: float,delta: float) -> Vector3:
 var nav=game.forest_navigation
 if not e.get("drop",{}).is_empty():return advance_drop(game,e,speed,delta)
 if not e.get("climb",{}).is_empty():
  var climb: Dictionary=e.climb;climb.clock+=delta
  if climb.clock>float(climb.get("time_limit",8)):e.climb={};e.climb_retry=2.0;return e.pos
  var target: Vector3=Vector3(climb.landing[0],climb.landing[1],climb.landing[2])
  var next: Vector3=e.pos
  if climb.phase=="rise":
   next.y=move_toward(next.y,target.y,maxf(3,speed)*delta)
   if absf(next.y-target.y)<0.01:climb.phase="over"
  else:
   next=next.move_toward(target,maxf(2,speed)*delta)
   if next.distance_to(target)<0.02:e.climb={}
  e.move_direction=Vector3(target.x-e.pos.x,0,target.z-e.pos.z).normalized();return next
 e["climb_retry"]=maxf(0,e.get("climb_retry",0)-delta)
 var direction=game.player.position-e.pos;direction.y=0
 var target_distance=direction.length();direction=direction.normalized()
 # A near target must not make the terrain probe look past the player and
 # repeatedly climb a cliff behind them after a successful landing.
 var ahead=e.pos+direction*minf(e.get("radius",0.5)+1.2,target_distance)
 var step_height=game.terrain_height(ahead.x,ahead.z)-game.terrain_height(e.pos.x,e.pos.z)
 if speed>0 and e.climb_retry<=0 and step_height>1.1 and maxf(absf(ahead.x),absf(ahead.z))<92:
  e.climb_retry=0.25
  var query=PhysicsRayQueryParameters3D.create(e.pos+Vector3.UP*0.2,ahead+Vector3.UP*0.2,1)
  var hit=game.get_world_3d().direct_space_state.intersect_ray(query)
  if not hit.is_empty() and absf(hit.normal.y)<0.2 and not hit.collider.has_meta("forest_decoration"):
   var landing: Vector3=hit.position-hit.normal*(e.get("radius",0.5)+0.8)
   landing.y=game.terrain_height(landing.x,landing.z)+0.65
   var valid=landing.y>e.pos.y+1 and landing.y-e.pos.y<=(ForestMap.SETTINGS.maximum_elevation+0.5 if game.terrain_version>=4 else 12.5) and maxf(absf(landing.x),absf(landing.z))<92
   for offset in [Vector3.ZERO,Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
    var point=landing+offset*e.get("radius",0.5)
    if nav.blocked.has(ForestMap.index(point.x,point.z)) or absf(game.terrain_height(point.x,point.z)+0.65-landing.y)>0.1:valid=false
   var clearance=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(landing,landing+Vector3.UP*2,1))
   if valid and clearance.is_empty():
    e.climb={"landing":[landing.x,landing.y,landing.z],"phase":"rise","clock":0.0,"time_limit":maxf(8,(landing.y-e.pos.y)/maxf(3,speed)+5)};return e.pos
 if speed>0 and step_height<-1.1 and game.player.position.y+1<e.pos.y and maxf(absf(ahead.x),absf(ahead.z))<92:
  var landing=Vector3(ahead.x,game.terrain_height(ahead.x,ahead.z),ahead.z)
  var valid=nav.reachable(landing) and not nav.blocked.has(ForestMap.index(ahead.x,ahead.z))
  var ray=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(ahead.x,e.pos.y+1,ahead.z),landing-Vector3.UP,1))
  if valid and not ray.is_empty() and ray.normal.y>0.5 and not ray.collider.has_meta("forest_decoration"):
   e.drop={"phase":"edge","velocity_y":0.0,"clock":0.0,"top":e.pos.y,"direction":[direction.x,0,direction.z]}
   return advance_drop(game,e,speed,delta)
 # Direct pursuit on compatible surfaces; otherwise shared flow routes around
 # colliders, down cliffs, or toward a ramp when no safe climb landing exists.
 if absf(step_height)>1.1 or nav.blocked.has(ForestMap.index(ahead.x,ahead.z)):direction=nav.direction(e.pos,game.player.position)
 e.move_direction=direction
 var next=nav.constrain(e.pos,e.pos+(direction*speed+e.knock)*delta)
 next=game.avoid_props(next,e.get("radius",0.5))
 next.x=clampf(next.x,-94,94);next.z=clampf(next.z,-94,94)
 next.y=game.terrain_height(next.x,next.z)+0.65
 return next

static func advance_drop(game: Node,e: Dictionary,speed: float,delta: float) -> Vector3:
 var state: Dictionary=e.drop;state.clock+=delta
 var direction=Vector3(state.direction[0],0,state.direction[2]);e.move_direction=direction
 var next: Vector3=e.pos+direction*speed*delta
 next.x=clampf(next.x,-94,94);next.z=clampf(next.z,-94,94)
 if state.phase=="edge":
  if game.forest_navigation.blocked.has(ForestMap.index(next.x,next.z)) or state.clock>maxf(3,(e.get("radius",0.5)*2+3)/maxf(0.1,speed)+1):
   e.drop={};return e.pos
  # Keep the whole agent clear of the cliff face before applying gravity.
  var behind=next-direction*(e.get("radius",0.5)+0.1)
  if game.terrain_height(behind.x,behind.z)+0.65<state.top-1:state.phase="fall"
  else:return next
 var obstacle=game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(e.pos+Vector3.UP*0.3,next+Vector3.UP*0.3,1))
 if not obstacle.is_empty():next.x=e.pos.x;next.z=e.pos.z
 state.velocity_y-=24*delta;next.y=e.pos.y+state.velocity_y*delta
 var floor=game.terrain_height(next.x,next.z)+0.65
 if next.y<=floor:
  next.y=floor;e.drop={};e.climb_retry=0.3
 return next

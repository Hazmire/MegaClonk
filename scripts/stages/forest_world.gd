class_name ForestWorld
extends RefCounted
const NATURE="res://assets/quaternius/nature/"
static func spaced(game: Node,p: Vector3,radius: float) -> bool:
 for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
  var other=p+direction*(radius+4)
  if absf(game.terrain_height(other.x,other.z)-p.y)>0.1:return false
 var cell=Vector2i(floori(p.x/8),floori(p.z/8))
 for x in range(cell.x-1,cell.x+2):
  for z in range(cell.y-1,cell.y+2):
   for other in game.obstacles.get(Vector2i(x,z),[]):
    if Vector2(p.x-other.pos.x,p.z-other.pos.z).length()<radius+other.radius+3:return false
 return true
static func build(game: Node) -> void:
 # Load shared animation resources during stage setup, never during horde ticks.
 var started=Time.get_ticks_usec()
 BestiaryFrames.prewarm()
 var data=ForestMap.layout(game.stage_map_seed())
 game.map_layout=data
 var layout_done=Time.get_ticks_usec()
 var terrain=game.mesh_node(ForestMap.geometry(data,false),Color.WHITE,game.world)
 terrain.name="TerraceTerrain"
 terrain.material_override=ForestAtmosphere.floor_material()
 var body=StaticBody3D.new();body.name="TerrainCollision";terrain.add_child(body);var collider=CollisionShape3D.new();var shape=ConcavePolygonShape3D.new();shape.set_faces(ForestMap.geometry(data).get_faces());collider.shape=shape;body.add_child(collider)
 var collision_done=Time.get_ticks_usec()
 # Dedicated generator only. Decoration never consumes combat RNG.
 var rng=RandomNumberGenerator.new();rng.seed=data.seed+1337
 var clusters=[]
 for i in 12:clusters.append(Vector2(rng.randf_range(-86,86),rng.randf_range(-86,86)))
 for i in 750:
  var c=clusters[i%clusters.size()]
  var p=c+Vector2(rng.randfn(0,11),rng.randfn(0,11))
  if maxf(absf(p.x),absf(p.y))>91 or ForestMap.protected(data,p,1):continue
  var height=game.terrain_height(p.x,p.y)
  var position=Vector3(p.x,height,p.y)
  if not spaced(game,position,0.6):continue
  var scale_value=rng.randf_range(0.85,1.2)
  var type=i%3
  var tree=["CommonTree_1","CommonTree_3","CommonTree_5"][type]
  var season=StageThemes.index(game.stage)
  var source=["tree_rt_1","tree_rt_2","tree_rt_3"][type]
  if season==2 or (season==1 and i%3==0):source="dead_tree_rt_"+str(1+i%2)
  var mesh=load("res://assets/grimdark/baked/props/"+source+".res")
  game.prop_instance("mega_"+tree,StageThemes.decor(mesh,game.stage),Color.WHITE,position,Vector3.ONE*scale_value*7.5,true,rng.randf()*TAU)
  game.prop_batches["mega_"+tree].set_meta("grimdark_source",source)
  game.prop_collider(position,0.45*scale_value,4*scale_value)
  if game.prop_batches["mega_"+tree].multimesh.visible_instance_count>=140:break
 for i in 600:
  var p=Vector2(rng.randf_range(-92,92),rng.randf_range(-92,92))
  if ForestMap.is_ramp(data,p,1) or p.distance_to(Vector2(data.spawn.x,data.spawn.z))<12:continue
  if StageThemes.index(game.stage)==2:continue
  var model=["Grass","Plant","Leaf","Bush","lilTree"][i%5]
  var height=0.25 if i%5<3 else 0.8
  var mesh=load("res://assets/grimdark/baked/props/forest_"+model+".res")
  game.prop_instance("mega_"+model,StageThemes.decor(mesh,game.stage),Color.WHITE,Vector3(p.x,game.terrain_height(p.x,p.y),p.y),Vector3.ONE*height*rng.randf_range(0.8,1.2),true,rng.randf()*TAU)

 for i in 40:
  var p=Vector2(rng.randf_range(-90,90),rng.randf_range(-90,90))
  if ForestMap.protected(data,p,3):continue
  var mesh=preload("res://assets/grimdark/baked/props/forest_Rock.res")
  var position=Vector3(p.x,game.terrain_height(p.x,p.y),p.y)
  if not spaced(game,position,1.8):continue
  game.prop_instance("mega_rock",StageThemes.decor(mesh,game.stage,true),Color.WHITE,position,Vector3.ONE*2,true);game.prop_collider(position,1.8,mesh.get_aabb().size.y*2)
 GrimdarkWorld.boundary(game)
 var props_done=Time.get_ticks_usec()
 ForestAtmosphere.add_grass(game,data,rng)
 var grass_done=Time.get_ticks_usec()
 # One navigation surface/flow field, built only after all blockers are known.
 game.forest_navigation=ForestNavigation.new();game.world.add_child(game.forest_navigation)
 game.forest_navigation.setup(data,game.obstacles)
 var free=game.forest_navigation.edges.size()-game.forest_navigation.blocked.size();var reached=0
 for distance in game.forest_navigation.distances:
  if distance>=0:reached+=1
 data.decoration_first_attempt_valid=free==reached;data.decoration_repaired=false
 if free!=reached:
  # Remove blocking decorations and their collision together, then rebuild once.
  # Critical access wins over scenery; record repair rather than hiding it.
  data.decoration_repaired=true
  for child in game.world.get_children():
   if child.has_meta("forest_decoration"):game.world.remove_child(child);child.queue_free()
  for key in game.prop_batches:
   if str(key).begins_with("mega_CommonTree") or key=="mega_rock":game.prop_batches[key].multimesh.visible_instance_count=0
  game.obstacles.clear()
  NavigationServer3D.region_set_map(game.forest_navigation.region.get_rid(),RID())
  game.world.remove_child(game.forest_navigation);game.forest_navigation.queue_free()
  game.forest_navigation=ForestNavigation.new();game.world.add_child(game.forest_navigation);game.forest_navigation.setup(data,{})
  push_warning("Removed obstructing decorations in map seed %s"%data.seed)
 for p in data.pois:
  assert(game.forest_navigation.reachable(p),"Unreachable objective in seed %s"%data.seed)
 assert(game.forest_navigation.reachable(data.portal),"Unreachable portal in seed %s"%data.seed)
 data.world_metrics={"layout_ms":(layout_done-started)/1000.0,"mesh_collision_ms":(collision_done-layout_done)/1000.0,"props_ms":(props_done-collision_done)/1000.0,"grass_setup_ms":(grass_done-props_done)/1000.0,"navigation_ms":(Time.get_ticks_usec()-grass_done)/1000.0,"total_ms":(Time.get_ticks_usec()-started)/1000.0}

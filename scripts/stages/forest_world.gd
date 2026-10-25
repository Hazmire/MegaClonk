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
 BestiaryFrames.prewarm()
 var data=ForestMap.layout(game.stage_map_seed())
 game.map_layout=data
 var terrain=game.mesh_node(ForestMap.geometry(data),Color.WHITE,game.world)
 terrain.name="TerraceTerrain"
 var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=1.0;terrain.material_override=material
 terrain.create_trimesh_collision()
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
  var mesh=ImportedArt.mesh(NATURE+tree+".gltf",7.5,7)
  game.prop_instance("mega_"+tree,mesh,Color.WHITE,position,Vector3.ONE*scale_value,true,rng.randf()*TAU)
  game.prop_collider(position,0.45*scale_value,4*scale_value)
  if game.prop_batches["mega_"+tree].multimesh.visible_instance_count>=140:break
 for i in 600:
  var p=Vector2(rng.randf_range(-92,92),rng.randf_range(-92,92))
  if ForestMap.is_ramp(data,p,1) or p.distance_to(Vector2(data.spawn.x,data.spawn.z))<12:continue
  var model=["Grass_Common_Short","Fern_1","Flower_3_Group","Bush_Common","Bush_Common_Flowers"][i%5]
  var height=0.6 if i%5<3 else 1.0
  game.prop_instance("mega_"+model,ImportedArt.mesh(NATURE+model+".gltf",height,2),Color.WHITE,Vector3(p.x,game.terrain_height(p.x,p.y),p.y),Vector3.ONE*rng.randf_range(0.8,1.2),true,rng.randf()*TAU)
 for i in 40:
  var p=Vector2(rng.randf_range(-90,90),rng.randf_range(-90,90))
  if ForestMap.protected(data,p,3):continue
  var mesh=ImportedArt.mesh(NATURE+"Rock_Medium_1.gltf",2,4)
  var position=Vector3(p.x,game.terrain_height(p.x,p.y),p.y)
  if not spaced(game,position,1.8):continue
  game.prop_instance("mega_rock",mesh,Color.WHITE,position,Vector3.ONE,true);game.prop_collider(position,1.8,mesh.get_aabb().size.y)
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

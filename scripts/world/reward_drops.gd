class_name RewardDrops
extends RefCounted
const SETTINGS=preload("res://assets/config/stage_update.tres")
static var chest_mesh: Mesh
static var materials: Dictionary={}
static func material(_free: bool) -> Material:
 # Keep the supplied crate atlas on each surface; never replace it with flat colour.
 return null
static func mesh() -> Mesh:
 if chest_mesh==null:
  var base=preload("res://assets/grimdark/baked/props/crate.res")
  var result=ArrayMesh.new()
  for surface in base.get_surface_count():
   var arrays=base.surface_get_arrays(surface);var vertices=arrays[Mesh.ARRAY_VERTEX];var normals=arrays[Mesh.ARRAY_NORMAL]
   var scaling=Vector3(1.1/base.get_aabb().size.x,.75,.8/base.get_aabb().size.z)
   for i in vertices.size():vertices[i]*=scaling;normals[i]=(normals[i]/scaling).normalized()
   arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals
   result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
   result.surface_set_material(surface,GrimdarkMaterials.material(base.surface_get_material(surface)))
  chest_mesh=result
 return chest_mesh
static func safe_position(game: Node,p: Vector3) -> Vector3:
 var cell=game.forest_navigation.nearest_cell(p)
 var result=Vector3(-95+(cell%ForestMap.SIDE)*2,0,-95+int(cell/ForestMap.SIDE)*2)
 result.y=game.terrain_height(result.x,result.z)
 if not game.forest_navigation.reachable(result):result=game.map_layout.spawn
 return result+Vector3.UP*0.05
static func spawn_at(game: Node,p: Vector3,uid: String) -> void:
 for drop in game.drop_chests:
  if drop.uid==uid:return
 var pos=safe_position(game,p);var node=game.pool.acquire("reward_chest",mesh(),Color.WHITE,pos)
 node.material_override=material(true);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.basis=Basis(Quaternion(Vector3.UP,ForestMap.normal(game.stage_map_seed(),pos.x,pos.z)))
 game.drop_chests.append({"uid":uid,"node":node,"warned":false})
static func from_enemy(game: Node,e: Dictionary) -> bool:
 if e.get("chest_dropped",false) or not (e.get("elite",false) or int(e.kind) in [8,9,10]):return false
 e.chest_dropped=true
 spawn_at(game,e.pos,str(game.run_seed)+":"+str(game.stage)+":"+str(e.get("crowd_id",game.kills)))
 return true
static func queue_roll(game: Node) -> bool:
 var available=game.available_items()
 var selected=RewardSelector.choose(RewardSelector.items(available),game.rng,Rarity.reward_weights(game.stats.luck))
 if selected.is_empty():return false
 game.reward_queue.append(int(selected.id));GemRewards.roll_chest(game);return true
static func present_next(game: Node) -> bool:
 if game.active_reward>=0 or game.reward_queue.is_empty():return false
 var id=int(game.reward_queue.pop_front());game.active_reward=id;game.apply_item(id);game.frontend.reward(Catalog.ITEMS[id]);return true
static func collect(game: Node) -> void:
 if game.mode!="run":return
 for i in range(game.drop_chests.size()-1,-1,-1):
  var chest=game.drop_chests[i]
  if chest.node.position.distance_to(game.player.position)>SETTINGS.drop_pickup_radius:continue
  if not queue_roll(game):
   if not chest.warned:game.toast("No enabled item rewards available");chest.warned=true
   continue
  game.run_metrics["free_chests"]=int(game.run_metrics.get("free_chests",0))+1;game.run_metrics["chests"]=int(game.run_metrics.get("chests",0))+1
  var position: Vector3=chest.node.position;game.pool.release(chest.node);game.drop_chests.remove_at(i)
  game.combat_fx.burst("sparks_shower",position,0.6);game.play_sound("level")
 present_next(game)
static func serialize(game: Node) -> Array:
 var result=[]
 for chest in game.drop_chests:
  var p: Vector3=chest.node.position;result.append({"uid":chest.uid,"position":[p.x,p.y,p.z]})
 return result
static func restore(game: Node,records: Array) -> void:
 for record in records:
  if not record is Dictionary or not record.get("position") is Array or record.position.size()!=3:continue
  spawn_at(game,Vector3(record.position[0],record.position[1],record.position[2]),str(record.get("uid","restored_"+str(game.drop_chests.size()))))

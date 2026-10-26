class_name XPGems
extends RefCounted
const RED_CHANCE=0.0025
static var geometry: Mesh
static var blue_material: StandardMaterial3D
static var red_material: StandardMaterial3D
static func eligible(enemy: Dictionary) -> bool:
 return enemy.get("ordinary",false) and int(enemy.get("kind",8))<8 and not enemy.has("summon_owner") and not enemy.get("no_rewards",false)
static func mesh() -> Mesh:
 if geometry==null:
  geometry=ModelBuilder.bake([ModelBuilder.part(ModelBuilder.cone(0.19,0.30),Vector3(0,0.15,0),"ffffff"),ModelBuilder.part(ModelBuilder.cone(0.19,0.24),Vector3(0,-0.12,0),"cbd4df",Vector3(PI,0,0))])
 return geometry
static func material(red: bool) -> StandardMaterial3D:
 var result=red_material if red else blue_material
 if result==null:
  result=StandardMaterial3D.new();result.vertex_color_use_as_albedo=true;result.albedo_color=Color("ff3155" if red else "39a9ff");result.metallic=0.15;result.roughness=0.18
  result.emission_enabled=true;result.emission=result.albedo_color;result.emission_energy_multiplier=0.25
  if red:red_material=result
  else:blue_material=result
 return result
static func acquire(game: Node,pos: Vector3,red: bool=false) -> MeshInstance3D:
 var node=game.pool.acquire("xp_red" if red else "xp",mesh(),Color.WHITE,pos)
 node.material_override=material(red);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.visibility_range_end=65;node.visibility_range_end_margin=5
 return node

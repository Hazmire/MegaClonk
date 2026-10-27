class_name ArtResetWorld
extends RefCounted
const DAY=preload("res://assets/art_reset/sky/day.hdr")
const NIGHT=preload("res://assets/art_reset/sky/night.hdr")
const ROCK=preload("res://assets/art_reset/baked/PSX_Rock.res")
const TREE1=preload("res://assets/art_reset/baked/PSX_Tree1.res")
const TREE2=preload("res://assets/art_reset/baked/PSX_Tree2.res")
const TREE3=preload("res://assets/art_reset/baked/PSX_Tree3.res")
const PORTAL=preload("res://assets/art_reset/portal/Portal_01.fbx")
static var skies: Dictionary={}
static func apply_sky(game: Node,environment: Environment) -> void:
 var index=StageThemes.index(game.stage)
 if not skies.has(index):
  var sky=Sky.new();var material=ShaderMaterial.new();material.shader=preload("res://shaders/supplied_panorama.gdshader")
  material.set_shader_parameter("panorama",DAY if index==0 else NIGHT)
  material.set_shader_parameter("tint",[Color("e3ebff"),Color("aa81dc"),Color("ef8291")][index]);material.set_shader_parameter("energy",[0.65,0.8,0.85][index])
  sky.sky_material=material;sky.radiance_size=Sky.RADIANCE_SIZE_32;sky.process_mode=Sky.PROCESS_MODE_QUALITY;skies[index]=sky
 environment.background_mode=Environment.BG_SKY;environment.sky=skies[index]
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_energy=0.75 if index==0 else 0.65
 environment.fog_density=0.005;environment.fog_sky_affect=0.2
 var material=ForestAtmosphere.floor_material()
 material.set_shader_parameter("earth_texture",preload("res://assets/art_reset/forest/PSX_ForestGround_Tex/PSX_Seamless_ForestEarthGround_128px.png"))
 material.set_shader_parameter("grass_texture",preload("res://assets/art_reset/forest/PSX_ForestGround_Tex/PSX_Seamless_WildForestGrass_128px.png"))
static func boundary(game: Node) -> void:
 var rng=RandomNumberGenerator.new();rng.seed=game.stage_map_seed()+42193
 var mesh=StageThemes.decor(ROCK,game.stage,true)
 for edge in 4:
  mesh=StageThemes.decor(ROCK if edge%2==0 else ImportedArt.mesh("res://assets/quaternius/nature/Rock_Medium_1.gltf",1),game.stage,true)
  for i in 36:
   var along=-105+i*6+rng.randf_range(-2,2)
   var p=Vector3(along,0,104+rng.randf_range(0,4))
   p=p.rotated(Vector3.UP,edge*PI/2);var ground=game.terrain_height(clampf(p.x,-95,95),clampf(p.z,-95,95))
   var y=ground-3.0;var layers=rng.randi_range(5,8)
   for layer in layers:
    var height=rng.randf_range(14,22);var width=rng.randf_range(16,24)
    var position=p+Vector3(0,y,0);position+=Vector3(sin(edge*PI/2),0,cos(edge*PI/2))*float(layer)*0.7
    var bounds=mesh.get_aabb();var scale_value=Vector3(width/bounds.size.x,height,width/bounds.size.z)
    var yaw=rng.randf()*TAU;var box=Transform3D(Basis(Vector3.UP,yaw).scaled(scale_value),position)*mesh.get_aabb()
    var outward=Vector3(sin(edge*PI/2),0,cos(edge*PI/2))
    var inside=box.position.z if edge==0 else box.position.x if edge==1 else -box.end.z if edge==2 else -box.end.x
    position+=outward*maxf(0,96.0-inside)
    game.prop_instance("natural_boundary_"+str(edge),mesh,Color.WHITE,position,scale_value,true,yaw)
    game.prop_batches["natural_boundary_"+str(edge)].cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    y+=height*rng.randf_range(0.50,0.65)
 var trunks=preload("res://assets/art_reset/baked/PSX_Treetrunk.res")
 for i in 26:
  var p=Vector2(rng.randf_range(-88,88),rng.randf_range(-88,88))
  if ForestMap.protected(game.map_layout,p,2) or not ForestWorld.spaced(game,Vector3(p.x,game.terrain_height(p.x,p.y),p.y),1):continue
  var position=Vector3(p.x,game.terrain_height(p.x,p.y),p.y);var scale_value=rng.randf_range(0.7,1.2)
  game.prop_instance("psx_deadwood",StageThemes.decor(trunks,game.stage),Color.WHITE,position,Vector3.ONE*scale_value,true,rng.randf()*TAU)
  game.prop_collider(position,0.4*scale_value,0.8*scale_value)
static func portal(game: Node) -> void:
 var visual=PORTAL.instantiate();visual.name="PortalAsset";game.portal.add_child(visual)
 var parts=[];ImportedArt.collect(visual,Transform3D.IDENTITY,parts);var bounds=AABB();var first=true
 for part in parts:
  var box=part.transform*part.mesh.get_aabb();bounds=box if first else bounds.merge(box);first=false
 var factor=4.4/bounds.size.y;visual.scale=Vector3.ONE*factor;visual.position=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)*factor
 for node in visual.find_children("*","MeshInstance3D",true,false):
  var material=ShaderMaterial.new();material.shader=preload("res://shaders/portal_asset.gdshader")
  material.set_shader_parameter("albedo_map",preload("res://assets/art_reset/portal/Textures/Fantasy Portal 3D LowPoly Model_Textures_01.png"));material.set_shader_parameter("emission_map",preload("res://assets/art_reset/portal/Textures/Fantasy Portal 3D LowPoly Model_Textures_Emissive.png"));material.set_shader_parameter("metallic_map",preload("res://assets/art_reset/portal/Textures/Fantasy Portal 3D LowPoly Model_Textures_Metallic.png"));node.material_override=material
  if str(node.name).contains("Hole"):node.name="Ring";game.portal.set_meta("opening_material",material)
static func refresh_portal(game: Node) -> void:
 if not game.portal.has_node("PortalAsset"):return
 for node in game.portal.get_node("PortalAsset").find_children("*","MeshInstance3D",true,false):
  var material=node.material_override as ShaderMaterial
  material.set_shader_parameter("portal_color",Color("77ffe1") if game.portal_state=="exit" else Color("ff3454"))
  material.set_shader_parameter("pulse",0.9 if game.portal_state=="summoned" else 0.55)
static func reset():skies.clear()

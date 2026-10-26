class_name ForestAtmosphere
extends RefCounted
static var ground: ShaderMaterial
static var grass: ShaderMaterial
static func noise_texture() -> Texture2D:
 return preload("res://assets/config/forest_variation.png")
static func floor_material() -> ShaderMaterial:
 if ground==null:
  ground=ShaderMaterial.new();ground.shader=preload("res://shaders/forest_floor.gdshader");ground.set_shader_parameter("variation",noise_texture())
 return ground
static func grass_material() -> ShaderMaterial:
 if grass==null:
  grass=ShaderMaterial.new();grass.shader=preload("res://assets/BinbunGrass/src/shader/grass.gdshader")
  grass.set_shader_parameter("shape_texture",load("res://assets/BinbunGrass/src/texture/basic/grass_basic_02.png"))
  grass.set_shader_parameter("shape_atlas",load("res://assets/BinbunGrass/src/texture/basic/grass_basic_atlas.png"));grass.set_shader_parameter("use_atlas",true)
  grass.set_shader_parameter("noise_texture",noise_texture());grass.set_shader_parameter("wind_texture",noise_texture());grass.set_shader_parameter("color_gradient",load("res://assets/BinbunGrass/src/palette/palette_01.tres"))
  grass.set_shader_parameter("wind_velocity",Vector2(0.7,0.35));grass.set_shader_parameter("billboard",false);grass.set_shader_parameter("alpha_mode",2)
 return grass
static func apply(environment: Environment) -> void:
 var sky=Sky.new();var material=ShaderMaterial.new();material.shader=preload("res://shaders/forest_sky.gdshader")
 sky.sky_material=material;sky.process_mode=Sky.PROCESS_MODE_QUALITY;sky.radiance_size=Sky.RADIANCE_SIZE_128
 environment.background_mode=Environment.BG_SKY;environment.sky=sky
 environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("a5bfd3");environment.ambient_light_energy=0.75
 environment.fog_enabled=true;environment.fog_light_color=Color("516078");environment.fog_density=0.0045;environment.fog_sun_scatter=0.15;environment.fog_sky_affect=0.25
static func add_grass(game: Node,data: Dictionary,rng: RandomNumberGenerator) -> void:
 var mesh=QuadMesh.new();mesh.size=Vector2(0.75,0.65);mesh.center_offset=Vector3(0,0.325,0);mesh.material=grass_material()
 for i in 650:
  var p=Vector2(rng.randf_range(-90,90),rng.randf_range(-90,90))
  if ForestMap.protected(data,p,0):continue
  var chunk=Vector2i(floori(p.x/32),floori(p.y/32));var key="wind_grass_%d_%d"%[chunk.x,chunk.y]
  game.prop_instance(key,mesh,Color.WHITE,Vector3(p.x,game.terrain_height(p.x,p.y),p.y),Vector3.ONE*rng.randf_range(0.8,1.3),true,rng.randf()*TAU)
  var batch=game.prop_batches[key];batch.visibility_range_end=55;batch.visibility_range_end_margin=10;batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func reset() -> void:
 if ground!=null:ground.set_shader_parameter("variation",null)
 if grass!=null:
  for parameter in ["shape_texture","shape_atlas","noise_texture","wind_texture","color_gradient"]:grass.set_shader_parameter(parameter,null)
 ground=null;grass=null

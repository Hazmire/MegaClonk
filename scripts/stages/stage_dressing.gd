class_name StageDressing
extends Resource
# One Calvary Run look per stage (sky, ground, fog, light, fog wall, weather, backdrop rings, footsteps).
# Values come from docs/stage_dressing/stage_dressing.json via tools/build_stage_dressings.gd; nothing here is hard-coded per stage.
const COUNT=4
const PATH="res://assets/stage_dressing/stage_%d.tres"
const RULES_PATH="res://assets/stage_dressing/rules.tres"
@export var stage_number=1
@export var title=""
@export var sky: Texture2D
@export var top: Texture2D
@export var side: Texture2D
@export var low: Texture2D
@export var torn_edge: Texture2D
@export var side_emission: Texture2D
@export var fog_color=Color.WHITE
@export var fog_density=0.005
@export var ambient_color=Color.WHITE
@export var ambient_energy=0.55
@export var sun_color=Color.WHITE
@export var sun_energy=0.7
@export var sun_rotation_deg=Vector3(-38,25,0)
@export var wall_color=Color.WHITE
@export var wall_glow_color=Color.BLACK
@export var wall_glow=0.0
@export var weather="rain"
@export var backdrop_far: Texture2D
@export var backdrop_mid: Texture2D
@export var backdrop_near: Texture2D
@export var footsteps="dirt"
# Prop look (tree/rock/grass variants) that goes with this dressing, until stage-specific props exist: 0 living, 1 withering, 2 dead.
@export var prop_style=0
static var cache: Dictionary={}
static var rules_cache: StageDressingRules
static func rules() -> StageDressingRules:
 if rules_cache==null:rules_cache=load(RULES_PATH)
 return rules_cache
# Stages 1-4 use dressings 1-4; later stages cycle 2 -> 3 -> 4 (stage 5 = Route 9, 6 = Downtown, 7 = Sinkhole, 8 = Route 9 ...).
static func index(stage: int) -> int:
 var s=maxi(1,stage)
 return s-1 if s<=COUNT else 1+posmod(s-2,COUNT-1)
static func for_stage(stage: int) -> StageDressing:
 var i=index(stage)
 if not cache.has(i):cache[i]=load(PATH%(i+1))
 return cache[i]
func backdrop(layer: int) -> Texture2D:return [backdrop_far,backdrop_mid,backdrop_near][layer]
const HALF=96.0 # the arena is ForestMap.SIDE cells of 2 m, centred on the origin
const SEGMENTS=128
const WEATHER_NAME="Weather"
const NODE_NAME="StageDressing"
# Applies this look to a freshly built stage: environment, ground material, torn edge, fog wall and backdrop rings. Everything it adds sits under
# one "StageDressing" node of the world, which build_stage frees with the rest of the previous stage. Never touches terrain mesh, collision or RNG.
func apply(game: Node) -> void:
 var r=rules()
 var env: Environment=game.world.get_child(0).environment
 var sky_material=PanoramaSkyMaterial.new();sky_material.panorama=sky;sky_material.filter=false
 var sky_resource=Sky.new();sky_resource.sky_material=sky_material;sky_resource.radiance_size=Sky.RADIANCE_SIZE_32
 env.background_mode=Environment.BG_SKY;env.sky=sky_resource;env.sky_rotation=Vector3(0,deg_to_rad(r.sky_rotation_deg),0)
 env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=ambient_color;env.ambient_light_energy=ambient_energy
 env.fog_enabled=true;env.fog_light_color=fog_color;env.fog_density=fog_density;env.fog_sky_affect=0.0;env.fog_sun_scatter=0.0
 env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
 for light in game.world.get_children():
  if light is DirectionalLight3D:light.light_color=sun_color;light.light_energy=sun_energy;light.rotation_degrees=sun_rotation_deg;light.sky_mode=DirectionalLight3D.SKY_MODE_LIGHT_ONLY
 var ground=ForestAtmosphere.floor_material()
 ground.set_shader_parameter("top_tex",top);ground.set_shader_parameter("side_tex",side);ground.set_shader_parameter("low_tex",low)
 ground.set_shader_parameter("emission_tex",side_emission if side_emission!=null else side);ground.set_shader_parameter("emission_strength",1.0 if side_emission!=null else 0.0)
 ground.set_shader_parameter("tex_scale",r.triplanar_scale);ground.set_shader_parameter("low_scale",r.low_ground_scale);ground.set_shader_parameter("low_y",lowest_level(game.map_layout))
 ForestAtmosphere.grass_material().set_shader_parameter("color_gradient",grass_gradient())
 var root=Node3D.new();root.name=NODE_NAME;game.world.add_child(root)
 root.add_child(torn_edge_mesh(game,r))
 for layer in r.wall_offsets.size():
  var offset=HALF+r.wall_offsets[layer];var shader_material=veil_material(r,layer);var quad=QuadMesh.new();quad.size=Vector2(offset*2.0,r.wall_height)
  for side_index in 4:
   var node=MeshInstance3D.new();node.mesh=quad;node.material_override=shader_material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.name="FogWall%d_%d"%[layer,side_index]
   root.add_child(node);node.position.y=r.wall_centre_y
   match side_index:
    0:node.position.z=-offset
    1:node.position.z=offset;node.rotation.y=PI
    2:node.position.x=-offset;node.rotation.y=PI/2
    3:node.position.x=offset;node.rotation.y=-PI/2
 for layer in r.ring_layers.size():root.add_child(backdrop_ring(layer,r))
# The y of the lowest flat terrain level (creek / slag / wet street / floodwater), found once per stage from the layout's cell planes.
static func lowest_level(layout: Dictionary) -> float:
 var lowest=1e9
 for plane in layout.planes:
  if absf(plane.x)+absf(plane.z)<=0.001:lowest=minf(lowest,plane.y)
 return lowest if lowest<1e8 else 0.0
# Grass blades take the dressing's ground colour: dark at the root, the texture's average at the tip.
func grass_gradient() -> GradientTexture1D:
 var image=top.get_image();var total=Vector3.ZERO
 for y in image.get_height():
  for x in image.get_width():
   var c=image.get_pixel(x,y);total+=Vector3(c.r,c.g,c.b)
 total/=float(image.get_width()*image.get_height())
 var average=Color(total.x,total.y,total.z)
 var gradient=Gradient.new();gradient.set_color(0,average.darkened(0.45));gradient.set_color(1,average.lightened(0.15))
 var texture=GradientTexture1D.new();texture.gradient=gradient;return texture
func veil_material(r: StageDressingRules,layer: int) -> ShaderMaterial:
 var material=ShaderMaterial.new();material.shader=preload("res://shaders/stage_veil.gdshader")
 material.set_shader_parameter("fog_color",wall_color);material.set_shader_parameter("glow_color",wall_glow_color);material.set_shader_parameter("glow",wall_glow)
 material.set_shader_parameter("density",r.wall_density[layer]);return material
# The ground falls away at the arena's edge into the fog. Render-only skirt under every border cell; collision is unchanged.
func torn_edge_mesh(game: Node,r: StageDressingRules) -> MeshInstance3D:
 var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var cells=int(HALF)
 for side_index in 4:
  for k in cells:
   var t0=-HALF+k*2.0;var t1=t0+2.0
   var p0:Vector3;var p1:Vector3
   match side_index:
    0:p0=Vector3(t0,0,-HALF);p1=Vector3(t1,0,-HALF)
    1:p0=Vector3(t1,0,HALF);p1=Vector3(t0,0,HALF)
    2:p0=Vector3(-HALF,0,t1);p1=Vector3(-HALF,0,t0)
    _:p0=Vector3(HALF,0,t0);p1=Vector3(HALF,0,t1)
   var mid=(p0+p1)*0.5;var h=game.terrain_height(clampf(mid.x,-HALF+1.0,HALF-1.0),clampf(mid.z,-HALF+1.0,HALF-1.0))
   var a=Vector3(p1.x,h,p1.z);var b=Vector3(p0.x,h,p0.z);var c=Vector3(p0.x,h-30.0,p0.z);var d=Vector3(p1.x,h-26.0,p1.z)
   for v in [a,b,c,a,c,d]:surface.add_vertex(v)
 surface.generate_normals()
 var material=StandardMaterial3D.new();material.albedo_texture=torn_edge;material.roughness=1.0;material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 material.uv1_triplanar=true;material.uv1_world_triplanar=true;material.uv1_scale=Vector3.ONE*r.triplanar_scale;material.cull_mode=BaseMaterial3D.CULL_DISABLED
 var node=MeshInstance3D.new();node.name="TornEdge";node.mesh=surface.commit();node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return node
# One open, inward-facing cylinder per layer (CylinderMesh maps only part of the strip). Height = circumference / 16 so the 8:1 strip and its mirror
# stay square; unshaded, no shadows, no collision. Centred on the arena (the origin), never on the player.
func backdrop_ring(layer: int,r: StageDressingRules) -> MeshInstance3D:
 var radius=r.ring_radius[layer]*r.arena_scale;var base_y=r.ring_base_y[layer]*r.arena_scale
 var h=TAU*radius/r.ring_height_divisor
 var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in SEGMENTS:
  var a0=TAU*i/SEGMENTS;var a1=TAU*(i+1)/SEGMENTS;var u0=float(i)/SEGMENTS;var u1=float(i+1)/SEGMENTS
  var p0t=Vector3(cos(a0)*radius,h*0.5,sin(a0)*radius);var p1t=Vector3(cos(a1)*radius,h*0.5,sin(a1)*radius)
  var p0b=Vector3(p0t.x,-h*0.5,p0t.z);var p1b=Vector3(p1t.x,-h*0.5,p1t.z)
  for v in [[p0t,Vector2(u0,0)],[p1t,Vector2(u1,0)],[p1b,Vector2(u1,1)],[p0t,Vector2(u0,0)],[p1b,Vector2(u1,1)],[p0b,Vector2(u0,1)]]:
   surface.set_uv(v[1]);surface.add_vertex(v[0])
 var material=ShaderMaterial.new();material.shader=preload("res://shaders/stage_backdrop.gdshader")
 material.set_shader_parameter("strip",backdrop(layer));material.set_shader_parameter("repeats",Vector2(1,1))
 material.set_shader_parameter("haze",r.ring_haze[layer]);material.set_shader_parameter("haze_color",fog_color)
 var node=MeshInstance3D.new();node.name="Backdrop_"+r.ring_layers[layer];node.mesh=surface.commit();node.material_override=material
 node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.position=Vector3(0,base_y+h*0.5,0)
 return node
# Weather: one GPU particle system that rides on the player, hard-capped by the rules (halved in reduced mode, off with the Weather setting).
func attach_weather(game: Node) -> void:
 var old=game.player.get_node_or_null(WEATHER_NAME)
 if old!=null:game.player.remove_child(old);old.queue_free()
 if not bool(game.settings.get("weather",true)):return
 var r=rules();var kind=weather
 var system=GPUParticles3D.new();system.name=WEATHER_NAME;system.preprocess=6.0;system.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var process_material=ParticleProcessMaterial.new();process_material.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
 var quad=QuadMesh.new();var quad_material=StandardMaterial3D.new();quad_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
 quad_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;quad_material.vertex_color_use_as_albedo=true;quad.material=quad_material
 if kind=="rain" or kind=="blood_rain":
  system.amount=r.rain_count;system.lifetime=2.0;quad_material.billboard_mode=BaseMaterial3D.BILLBOARD_FIXED_Y
  process_material.direction=Vector3(-0.15,-1,0);process_material.spread=2;process_material.initial_velocity_min=22;process_material.initial_velocity_max=26;process_material.gravity=Vector3(0,-9.8,0)
  process_material.color=r.rain_color if kind=="rain" else r.blood_rain_color
  quad.size=Vector2(0.025,0.7);process_material.emission_box_extents=Vector3(30,1,30);system.position=Vector3(0,18,0)
 else:
  system.amount=r.dust_count if kind=="dust" else r.ash_count;system.lifetime=10.0;quad_material.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
  process_material.emission_box_extents=Vector3(26,8,26);process_material.direction=Vector3(0.4,1,0) if kind=="dust" else Vector3(0.3,-1,0);process_material.spread=40
  process_material.initial_velocity_min=0.2;process_material.initial_velocity_max=0.7;process_material.gravity=Vector3(0.1,0.02,0) if kind=="dust" else Vector3(0.2,-0.3,0)
  process_material.color=r.dust_color if kind=="dust" else r.ash_color
  quad.size=Vector2(0.08,0.08);system.position=Vector3(0,3,0)
 if bool(game.settings.get("reduced",false)):system.amount=int(system.amount*r.weather_reduced_fraction)
 system.process_material=process_material;system.draw_pass_1=quad;system.visibility_aabb=AABB(Vector3(-80,-40,-80),Vector3(160,80,160))
 game.player.add_child(system)

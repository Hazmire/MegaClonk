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
# Boundary fence (visual only): style, post_color, wire_color, height, gap, wires, panel, stripes, candles.
@export var fence: Dictionary={}
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
 var low_y=lowest_level(game.map_layout)
 var ground=ForestAtmosphere.floor_material()
 ground.set_shader_parameter("top_tex",top);ground.set_shader_parameter("side_tex",side);ground.set_shader_parameter("low_tex",low)
 ground.set_shader_parameter("emission_tex",side_emission if side_emission!=null else side);ground.set_shader_parameter("emission_strength",1.0 if side_emission!=null else 0.0)
 ground.set_shader_parameter("tex_scale",r.triplanar_scale);ground.set_shader_parameter("low_scale",r.low_ground_scale);ground.set_shader_parameter("low_y",low_y)
 ForestAtmosphere.grass_material().set_shader_parameter("color_gradient",grass_gradient())
 var root=Node3D.new();root.name=NODE_NAME;game.world.add_child(root)
 root.add_child(torn_edge_mesh(game,r))
 root.add_child(outer_ground_mesh(r,low_y))
 for part in fence_parts(game,r):root.add_child(part)
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
 for layer in r.ring_layers.size():root.add_child(backdrop_ring(layer,r,low_y))
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
func backdrop_ring(layer: int,r: StageDressingRules,low_y: float=0.0) -> MeshInstance3D:
 var radius=r.ring_radius[layer]*r.arena_scale;var base_y=r.ring_base_y[layer]*r.arena_scale
 if r.ring_anchor[layer]=="outer_ground":base_y=outer_ground_y(r,low_y)+r.ring_base_y[layer] # bottom edge just under the outer ground
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
static func outer_ground_y(r: StageDressingRules,low_y: float) -> float:return low_y-r.outer_ground_drop*r.arena_scale
# Render-only flat ring of ground from just outside the torn edge to past the far ring, so nothing is black below the horizon.
# No collision, no shadows, one draw call. The square hole keeps it from ever showing through the playable ground.
func outer_ground_mesh(r: StageDressingRules,low_y: float) -> MeshInstance3D:
 var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var y=outer_ground_y(r,low_y);var inner=HALF+r.outer_ground_margin*r.arena_scale;var outer=r.ring_radius[0]*r.arena_scale*r.outer_ground_radius_factor;var segments=r.outer_ground_segments
 for i in segments:
  var a0=TAU*i/segments;var a1=TAU*(i+1)/segments
  var d0=Vector3(cos(a0),0,sin(a0));var d1=Vector3(cos(a1),0,sin(a1))
  var in0=d0*inner/maxf(absf(d0.x),absf(d0.z));var in1=d1*inner/maxf(absf(d1.x),absf(d1.z))
  in0.y=y;in1.y=y
  var o0=d0*outer+Vector3(0,y,0);var o1=d1*outer+Vector3(0,y,0)
  for v in [in0,o0,o1,in0,o1,in1]:surface.add_vertex(v)
 surface.generate_normals()
 var material=StandardMaterial3D.new();material.albedo_texture=low;material.albedo_color=Color(r.outer_ground_tint,r.outer_ground_tint,r.outer_ground_tint);material.roughness=1.0
 material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;material.uv1_triplanar=true;material.uv1_world_triplanar=true;material.uv1_scale=Vector3.ONE*r.outer_ground_texture_scale;material.cull_mode=BaseMaterial3D.CULL_DISABLED
 var node=MeshInstance3D.new();node.name="OuterGround";node.mesh=surface.commit();node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return node
# Boundary fence, visual only (the perimeter wall already blocks the player): posts every `gap` m along the wall, inset by rules.fence_inset,
# each snapped to the terrain under it. Rails/wires/chain-link panels join neighbouring posts only at equal height. Batched into MultiMeshes:
# posts, wires, plus panels (stage 2) and candles (stage 4), so a stage's fence costs two to three draw calls.
const FENCE_STEP_TOLERANCE=0.2
func fence_parts(game: Node,r: StageDressingRules) -> Array:
 var style=fence;var h=float(style.height);var gap=float(style.gap);var wires=int(style.wires)
 var posts=[];var rails=[];var panels=[];var candles=[]
 var inset=r.fence_inset
 var sides=[[Vector3(-HALF,0,-HALF+inset),Vector3(HALF,0,-HALF+inset)],[Vector3(-HALF,0,HALF-inset),Vector3(HALF,0,HALF-inset)],[Vector3(-HALF+inset,0,-HALF),Vector3(-HALF+inset,0,HALF)],[Vector3(HALF-inset,0,-HALF),Vector3(HALF-inset,0,HALF)]]
 for side_points in sides:
  var a: Vector3=side_points[0];var b: Vector3=side_points[1];var length=a.distance_to(b);var direction=(b-a).normalized();var distance=0.5;var previous=Vector3.INF;var k=0
  while distance<length:
   var p=a+direction*distance;var ground=game.terrain_height(clampf(p.x,-HALF+0.5,HALF-0.5),clampf(p.z,-HALF+0.5,HALF-0.5))
   var top=Vector3(p.x,ground+h,p.z)
   posts.append(Transform3D(Basis(Vector3(0,0,1),sin(k*1.7)*0.06),Vector3(p.x,ground+h*0.5,p.z)))
   if previous!=Vector3.INF and absf(previous.y-top.y)<FENCE_STEP_TOLERANCE:
    for w in wires:
     var offset=Vector3(0,-h*(0.15+0.3*w),0);var wa=previous+offset;var wb=top+offset
     var thick=0.22 if style.stripes else 0.03
     var basis=Basis.looking_at((wb-wa).normalized(),Vector3.UP)*Basis.from_scale(Vector3(0.03,thick,wa.distance_to(wb)))
     rails.append([Transform3D(basis,(wa+wb)*0.5),style.post_color if (style.stripes and k%2==0) else style.wire_color])
    if style.panel:
     var middle=(previous+top)*0.5-Vector3(0,h*0.47,0)
     panels.append(Transform3D(Basis.looking_at(direction.cross(Vector3.UP),Vector3.UP)*Basis.from_scale(Vector3(previous.distance_to(top),h*0.9,1.0)),middle))
   previous=top;distance+=gap;k+=1
   if style.candles and k%3==0:candles.append(Transform3D(Basis(),Vector3(p.x,ground+0.1,p.z)-Vector3(direction.z,0,-direction.x)*0.3))
 var out=[]
 out.append(multimesh_node("FencePosts",box_mesh(Vector3(0.14,h,0.14)),posts,[],style.post_color,false))
 var rail_transforms=[];var rail_colors=[]
 for rail in rails:rail_transforms.append(rail[0]);rail_colors.append(rail[1])
 if not rail_transforms.is_empty():out.append(multimesh_node("FenceWires",box_mesh(Vector3.ONE),rail_transforms,rail_colors,Color.WHITE,false))
 if not panels.is_empty():out.append(multimesh_node("FencePanels",chain_link_quad(gap,h),panels,[],Color.WHITE,false))
 if not candles.is_empty():out.append(multimesh_node("FenceCandles",box_mesh(Vector3(0.06,0.2,0.06)),candles,[],Color("FFC060"),true))
 return out
static func box_mesh(size: Vector3) -> BoxMesh:
 var mesh=BoxMesh.new();mesh.size=size;return mesh
static func chain_link_quad(gap: float,h: float) -> QuadMesh:
 var image=Image.create(16,16,false,Image.FORMAT_RGBA8)
 for y in 16:
  for x in 16:image.set_pixel(x,y,Color(0.35,0.35,0.33,1.0 if (x+y)%8==0 or (x-y+16)%8==0 else 0.0))
 var material=StandardMaterial3D.new();material.albedo_texture=ImageTexture.create_from_image(image);material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
 material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR;material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.uv1_scale=Vector3(gap/0.5,h*0.9/0.5,1.0)
 var quad=QuadMesh.new();quad.size=Vector2.ONE;quad.material=material;return quad
func multimesh_node(node_name: String,mesh: Mesh,transforms: Array,colors: Array,color: Color,unshaded: bool) -> MultiMeshInstance3D:
 var multimesh=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D;multimesh.use_colors=not colors.is_empty();multimesh.mesh=mesh;multimesh.instance_count=transforms.size()
 for i in transforms.size():
  multimesh.set_instance_transform(i,transforms[i])
  if not colors.is_empty():multimesh.set_instance_color(i,colors[i])
 if mesh.material==null:
  var material=StandardMaterial3D.new();material.albedo_color=color;material.roughness=1.0;material.vertex_color_use_as_albedo=not colors.is_empty()
  if unshaded:material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
  mesh.material=material
 var node=MultiMeshInstance3D.new();node.name=node_name;node.multimesh=multimesh;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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

class_name PortalWind
extends Node3D
const SETTINGS=preload("res://assets/config/wind.tres")
var game: Node
var guidance=PortalGuidance.new()
var ambient: GPUParticles3D
var stream: MultiMeshInstance3D
var vortex: MultiMeshInstance3D
var positions=PackedVector3Array()
var velocities=PackedVector3Array()
var ages=PackedFloat32Array()
var altitudes=PackedFloat32Array()
var rng=RandomNumberGenerator.new()
var clock=0.0
var refresh_clock=0.0
var elapsed=0.0
var vortex_clock=0.0
var proximity=0.0
var factor=1.0
var surge=0.0
var last_state=""
var direction=Vector3.ZERO
var opening_material: ShaderMaterial
var guide_route=PackedVector3Array()
func material(primary: Color,secondary: Color,emission: float) -> ShaderMaterial:
 var result=ShaderMaterial.new();result.shader=preload("res://shaders/ethereal_wind.gdshader")
 result.set_shader_parameter("noise_texture",ForestAtmosphere.noise_texture());result.set_shader_parameter("primary_color",primary);result.set_shader_parameter("secondary_color",secondary);result.set_shader_parameter("emission",emission);result.set_shader_parameter("hue_variation",0.05);result.set_shader_parameter("noise_scale",Vector2(1,2));result.set_shader_parameter("edge_position",0.0)
 return result
func batch(count: int,mat: Material,parent: Node) -> MultiMeshInstance3D:
 var node=MultiMeshInstance3D.new();parent.add_child(node);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var mesh=QuadMesh.new();mesh.orientation=PlaneMesh.FACE_Y;mesh.size=Vector2.ONE;mesh.material=mat
 var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=mesh;mm.instance_count=count;node.multimesh=mm
 for i in count:mm.set_instance_color(i,Color(1,1,1,0))
 return node
func setup(owner_game: Node) -> void:
 game=owner_game;opening_material=game.portal.get_meta("opening_material",null);rng.seed=game.stage_map_seed()+918273;guidance.setup(game);guide_route=guidance.route(game.player.position);last_state=game.portal_state
 var theme=StageThemes.index(game.stage)
 ambient=GPUParticles3D.new();ambient.name="AmbientWind";ambient.position=game.player.position+Vector3.UP*3;add_child(ambient);ambient.amount=SETTINGS.ambient_count;ambient.lifetime=10;ambient.preprocess=3;ambient.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var process=ParticleProcessMaterial.new();process.direction=Vector3(1,0.025,0.35).normalized();process.spread=12;process.initial_velocity_min=0.6;process.initial_velocity_max=1.2;process.gravity=Vector3.ZERO;process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;process.emission_box_extents=Vector3(16,4,16);process.color=Color(1,1,1,0.25);process.scale_min=0.4;process.scale_max=1.1;ambient.process_material=process
 var mesh=QuadMesh.new();mesh.orientation=PlaneMesh.FACE_Y;mesh.size=Vector2(1.2,0.18);mesh.material=material([Color("9fa99e"),Color("b0a58b"),Color("a0a3a0")][theme],Color("707a85"),0.7);ambient.draw_pass_1=mesh
 var red=material(Color("ff8296") if theme==2 else Color("ff1b39"),Color("7d0523"),2.6 if theme==2 else 2.0)
 stream=batch(SETTINGS.guidance_count,red,self);stream.name="DirectionalRedWisps"
 vortex=batch(SETTINGS.vortex_count,red,game.portal);vortex.name="RedPortalVortex"
 positions.resize(SETTINGS.guidance_count);velocities.resize(SETTINGS.guidance_count);ages.resize(SETTINGS.guidance_count);altitudes.resize(SETTINGS.guidance_count)
 for i in SETTINGS.guidance_count:respawn(i);ages[i]=rng.randf()*SETTINGS.lifetime
func respawn(i: int) -> void:
 var origin=game.player.position;var pos=origin
 for attempt in 8:
  var angle=rng.randf()*TAU;var candidate=origin+Vector3(cos(angle),0,sin(angle))*rng.randf_range(1,SETTINGS.local_radius)
  if i%2==0 and not guide_route.is_empty():candidate=guide_route[rng.randi_range(0,mini(10,guide_route.size()-1))]
  var at=game.forest_navigation.nearest_cell(candidate)
  if at>=guidance.costs.size() or guidance.costs[at]<0:continue
  candidate=guidance.point(at)
  if absf(candidate.y-origin.y)>4:continue
  pos=candidate;break
 altitudes[i]=rng.randf_range(0.8,2.4);pos.y=game.terrain_height(pos.x,pos.z)+altitudes[i];positions[i]=pos;velocities[i]=Vector3.ZERO;ages[i]=0
func relevant() -> bool:
 return is_instance_valid(game.portal) and game.portal_state!="exit" and game.mode not in ["menu","results","play","quests","unlocks","settings"]
func _process(delta: float) -> void:
 if not is_instance_valid(game) or not is_instance_valid(game.player) or not is_instance_valid(game.portal):return
 clock+=delta
 if clock<SETTINGS.simulation_step:return
 var dt=minf(clock,0.1);clock=0;simulate(dt)
func simulate(dt: float) -> void:
 elapsed+=dt;refresh_clock-=dt;surge=maxf(0,surge-dt)
 if opening_material:opening_material.set_shader_parameter("pulse",(0.9 if game.portal_state=="summoned" else 0.55)+sin(elapsed*1.2)*0.08+surge*0.3)
 ambient.position=game.player.position+Vector3.UP*3
 var intensity=clampf(float(game.settings.visual_intensity),0,1)
 ambient.amount_ratio=intensity*(0.35 if game.settings.reduced else 1.0)
 if refresh_clock<=0:
  if guidance.destination.distance_squared_to(game.portal.global_position)>0.01:guidance.rebuild()
  guide_route=guidance.route(game.player.position)
  refresh_clock=SETTINGS.refresh_seconds
 var target=clampf(1-game.player.position.distance_to(game.portal.global_position)/SETTINGS.proximity_distance,0,1)
 proximity=lerpf(proximity,target,1-exp(-dt*3))
 if game.portal_state!=last_state:
  if game.portal_state=="summoned":surge=1.5
  last_state=game.portal_state
 var waypoint=guidance.waypoint(game.player.position)
 var active=relevant() and guidance.valid and waypoint.is_finite()
 factor=move_toward(factor,1 if active else 0,dt*2)
 direction=(waypoint-game.player.position).normalized() if waypoint.is_finite() else Vector3.ZERO
 stream.visible=factor>0.001;vortex.visible=factor>0.001
 if factor<=0 and not active:return
 var wanted=lerpf(16,SETTINGS.guidance_count,proximity*proximity)*factor*intensity*(0.5 if game.settings.reduced else 1.0)
 for i in SETTINGS.guidance_count:
  ages[i]+=dt
  if ages[i]>=SETTINGS.lifetime or positions[i].distance_squared_to(game.player.position)>SETTINGS.local_radius*SETTINGS.local_radius*4:
   if active:respawn(i)
  var p=positions[i];var aim=guidance.waypoint(p)
  if not aim.is_finite():stream.multimesh.set_instance_color(i,Color(1,1,1,0));continue
  var toward=aim-p;toward.y=0
  var desired=toward.normalized()*lerpf(SETTINGS.speed_far,SETTINGS.speed_near,proximity)*(0.85+float(i%7)*0.05)
  velocities[i]=velocities[i].lerp(desired,1-exp(-dt*5))
  var side=Vector3(-velocities[i].z,0,velocities[i].x).normalized()*sin(elapsed*1.3+i)*0.12
  var next=game.forest_navigation.constrain(p,p+(velocities[i]+side)*dt)
  next.y=game.terrain_height(next.x,next.z)+altitudes[i]+sin(elapsed*1.5+i)*0.12;positions[i]=next
  var life=clampf(ages[i]/0.4,0,1)*clampf((SETTINGS.lifetime-ages[i])/0.8,0,1)
  var alpha=clampf(wanted-i,0,1)*life*lerpf(0.55,0.9,proximity)
  var transform=Transform3D(Basis(Vector3.UP,atan2(-velocities[i].z,velocities[i].x)).scaled(Vector3(2.4,1,0.45)),positions[i])
  stream.multimesh.set_instance_transform(i,transform);stream.multimesh.set_instance_color(i,Color(0.5+float(i%11)*0.045,1,1,alpha))
 vortex_clock+=dt*(0.17+surge*0.08)
 for i in SETTINGS.vortex_count:
  var phase=fposmod(vortex_clock+float(i)/SETTINGS.vortex_count,1);var angle=phase*TAU*2.5+i*2.39996
  var radius=lerpf(4.3,0.4,phase);var p=Vector3(cos(angle)*radius,0.3+phase*2.2,sin(angle)*radius)
  var transform=Transform3D(Basis(Vector3.UP,-angle+PI/2).scaled(Vector3(1.7,1,0.22)),p)
  vortex.multimesh.set_instance_transform(i,transform);vortex.multimesh.set_instance_color(i,Color(0.5+float(i%11)*0.045,1,1,sin(phase*PI)*factor*intensity*lerpf(0.25,0.65,proximity)*(1+surge*0.3)))

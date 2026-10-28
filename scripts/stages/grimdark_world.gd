class_name GrimdarkWorld
extends RefCounted
static func apply_sky(game: Node,environment: Environment) -> void:
 var theme=StageThemes.config(game.stage);var season=StageThemes.index(game.stage)
 var sky=Sky.new();var material=ProceduralSkyMaterial.new()
 material.sky_top_color=theme.zenith;material.sky_horizon_color=theme.horizon
 material.ground_bottom_color=theme.fog;material.ground_horizon_color=theme.horizon
 material.sky_energy_multiplier=.55;material.sun_angle_max=1.0;sky.sky_material=material
 sky.radiance_size=Sky.RADIANCE_SIZE_32;environment.sky=sky;environment.background_mode=Environment.BG_SKY
 environment.ambient_light_energy=.62;environment.fog_density=.006
 environment.fog_sky_affect=.35;environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
 RenderingServer.global_shader_parameter_set("psx_fog_color",theme.fog)
 RenderingServer.global_shader_parameter_set("psx_fog_near",[24.0,20.0,16.0][season])
 RenderingServer.global_shader_parameter_set("psx_fog_far",[76.0,66.0,58.0][season])
static func boundary(game: Node) -> void:
 var rng=RandomNumberGenerator.new();rng.seed=game.stage_map_seed()+42193
 var mesh=GrimdarkMaterials.mesh(preload("res://assets/grimdark/baked/props/forest_Cliff.res"),game.stage)
 for edge in 4:
  for i in 36:
   var p=Vector3(-105+i*6+rng.randf_range(-2,2),0,104+rng.randf_range(0,4)).rotated(Vector3.UP,edge*PI/2)
   var ground=game.terrain_height(clampf(p.x,-95,95),clampf(p.z,-95,95));var y=ground-3
   for layer in rng.randi_range(5,8):
    var height=rng.randf_range(14,22);var width=rng.randf_range(16,24)
    var position=p+Vector3(0,y,0);var bounds=mesh.get_aabb()
    var scale_value=Vector3(width/bounds.size.x,height,width/bounds.size.z)
    var yaw=rng.randf()*TAU;var box=Transform3D(Basis(Vector3.UP,yaw).scaled(scale_value),position)*bounds
    var outward=Vector3(sin(edge*PI/2),0,cos(edge*PI/2))
    var inside=box.position.z if edge==0 else box.position.x if edge==1 else -box.end.z if edge==2 else -box.end.x
    position+=outward*maxf(0,96-inside)
    game.prop_instance("natural_boundary_"+str(edge),mesh,Color.WHITE,position,scale_value,true,yaw)
    game.prop_batches["natural_boundary_"+str(edge)].cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
    y+=height*rng.randf_range(.5,.65)

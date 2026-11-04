extends SceneTree
# Stage dressing: each stage applies its look; the arena (terrain, collision, spawns, determinism) is untouched; the border holds.
var checks=0
var failures=[]
var game: Node3D
func check(ok: bool,label: String):
 checks+=1
 if not ok:failures.append(label);push_error("FAIL: "+label)
 else:print("PASS: "+label)
func _initialize():call_deferred("run")
func ring_nodes() -> Array:
 var out=[]
 for n in game.world.get_node("StageDressing").get_children():
  if n.name.begins_with("Backdrop_"):out.append(n)
 return out
func run():
 game=load("res://scenes/main/main.tscn").instantiate();root.add_child(game);await process_frame
 game.progress=Progress.new();game.progress.storage_path="user://test-dressing.json";game.sandbox=true;game.map_seed_override=9
 game.begin_run();game.set_physics_process(false);game.player.active=false;game.settings.invincible=true;game.spawn_clock=999
 var rules=StageDressing.rules()
 # --- data: manifest -> one resource per stage ---
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://docs/stage_dressing/stage_dressing.json"))
 for i in 4:
  var d=StageDressing.for_stage(i+1);var m=manifest.stages[i]
  check(d.title==m.name and d.fog_color==Color(m.fog.color) and is_equal_approx(d.fog_density,float(m.fog.density)) and d.footsteps==m.footsteps and d.weather==m.weather,"Dressing %d matches the manifest (%s)"%[i+1,d.title])
 check(StageDressing.for_stage(3).side_emission!=null and StageDressing.for_stage(1).side_emission==null,"Only stage 3 has a side emission mask")
 # --- each stage applies its dressing ---
 for s in [1,2,3,4]:
  game.stage=s;game.build_stage();await process_frame
  var d=StageDressing.for_stage(s);var env=game.world.get_child(0).environment
  check(env.fog_light_color==d.fog_color and is_equal_approx(env.fog_density,d.fog_density) and env.fog_sky_affect==0.0 and env.tonemap_mode==Environment.TONE_MAPPER_LINEAR,"Stage %d fog and tonemap come from the dressing"%s)
  check(env.sky.sky_material is PanoramaSkyMaterial and env.sky.sky_material.panorama==d.sky and env.sky.sky_material.filter==false and is_equal_approx(env.sky_rotation.y,PI),"Stage %d sky is the filter-off panorama rotated 180 degrees"%s)
  check(env.ambient_light_color==d.ambient_color and is_equal_approx(env.ambient_light_energy,d.ambient_energy),"Stage %d ambient light"%s)
  var sun=null
  for n in game.world.get_children():
   if n is DirectionalLight3D:sun=n
  check(sun!=null and sun.light_color==d.sun_color and is_equal_approx(sun.light_energy,d.sun_energy) and sun.rotation_degrees.is_equal_approx(d.sun_rotation_deg),"Stage %d sun"%s)
  var ground=ForestAtmosphere.floor_material()
  check(ground.get_shader_parameter("top_tex")==d.top and ground.get_shader_parameter("side_tex")==d.side and ground.get_shader_parameter("low_tex")==d.low,"Stage %d ground textures (top/side/low)"%s)
  check(float(ground.get_shader_parameter("emission_strength"))==(1.0 if d.side_emission!=null else 0.0),"Stage %d side emission only where the dressing has a mask"%s)
  check(float(ground.get_shader_parameter("low_y"))<=0.01,"Lowest terrain level is detected (y %.2f)"%float(ground.get_shader_parameter("low_y")))
  check(game.world.get_node("StageDressing").get_node("TornEdge") is MeshInstance3D,"Stage %d has a torn-edge skirt"%s)
  var walls=0
  for n in game.world.get_node("StageDressing").get_children():
   if n.name.begins_with("FogWall"):walls+=1
  check(walls==8,"Stage %d has two veil layers on each of four sides"%s)
  var weather=game.player.get_node_or_null("Weather")
  check(weather is GPUParticles3D and weather.amount<=rules.rain_count and weather.amount>0,"Stage %d weather (%s, %d particles, capped at %d)"%[s,d.weather,weather.amount if weather else 0,rules.rain_count])
  check(game.map_layout.get("terrain_version",0)>=0 and game.world.find_children("natural_boundary*","",true,false).is_empty(),"Stage %d no longer builds the old cliff props"%s)
  # rings
  var rings=ring_nodes();var ok=rings.size()==3
  for ring in rings:
   var m=ring.material_override as ShaderMaterial
   ok=ok and m!=null and m.shader.code.contains("unshaded") and ring.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and ring.get_child_count()==0
   ok=ok and is_equal_approx(ring.position.x,0.0) and is_equal_approx(ring.position.z,0.0) and m.get_shader_parameter("haze_color")==d.fog_color
  check(ok,"Stage %d: three unshaded, shadow-free, collision-free rings centred on the arena"%s)
  var aabb=rings[0].get_aabb() if rings.size()>0 else AABB()
  check(rings.size()==3 and rings[0].get_aabb().size.x>rings[2].get_aabb().size.x and rings[2].get_aabb().size.x/2.0>96.0*1.5,"Stage %d rings nest far>mid>near and the near ring clears the arena corners"%s)
  check(rings.size()==3 and rings[0].mesh.get_surface_count()==1,"Stage %d: 3 ring meshes, one surface each (3 draw calls)"%s)
 # --- outer ground and fence (edge void fix) ---
 for s in [1,2,3,4]:
  game.stage=s;game.build_stage();await process_frame
  var d=StageDressing.for_stage(s);var root_node=game.world.get_node("StageDressing");var low_y=StageDressing.lowest_level(game.map_layout)
  var outer=root_node.get_node("OuterGround") as MeshInstance3D
  var outer_y=StageDressing.outer_ground_y(rules,low_y)
  var aabb=outer.get_aabb()
  check(outer.get_child_count()==0 and outer.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and outer.mesh.get_surface_count()==1,"Stage %d outer ground: no collision, no shadows, one surface"%s)
  check(is_equal_approx(aabb.position.y,outer_y) and outer_y<low_y-rules.outer_ground_drop*rules.arena_scale+0.01 and is_equal_approx(aabb.size.y,0.0),"Stage %d outer ground is flat and %.1f m below the lowest terrain (y %.1f)"%[s,rules.outer_ground_drop*rules.arena_scale,outer_y])
  check(aabb.position.x<=-rules.ring_radius[0]*rules.arena_scale*1.09 and aabb.end.x>=rules.ring_radius[0]*rules.arena_scale*1.09,"Stage %d outer ground reaches 1.1x the far ring"%s)
  var vertices=outer.mesh.get_faces();var inside=false
  for v in vertices:
   if absf(v.x)<StageDressing.HALF+rules.outer_ground_margin*rules.arena_scale-0.01 and absf(v.z)<StageDressing.HALF+rules.outer_ground_margin*rules.arena_scale-0.01:inside=true
  check(not inside,"Stage %d outer ground has a square hole clear of the playable area"%s)
  var rings=ring_nodes()
  var top_y=StageDressing.highest_level(game.map_layout);var grounds=[];var bottoms_ok=true;var line_ok=rings.size()==3;var rise_ok=true
  for layer in rings.size():
   var ring=rings[layer];var h=ring.get_aabb().size.y;var tex=d.backdrop(layer)
   var line_y=ring.position.y-h*0.5+d.backdrop_ground_px[layer]*h/float(tex.get_height());var want=rules.ring_ground_y[layer]*top_y/rules.reference_top
   line_ok=line_ok and absf(line_y-want)<0.1 and is_equal_approx(h,TAU*rules.ring_radius[layer]*rules.arena_scale*float(tex.get_height())/(2.0*float(tex.get_width())))
   bottoms_ok=bottoms_ok and ring.position.y-h*0.5<outer_y
   grounds.append(line_y)
  rise_ok=rings.size()==3 and grounds[0]>grounds[1] and grounds[1]>grounds[2] and grounds[2]>top_y # rings are ordered far, mid, near
  check(line_ok,"Stage %d each ring's ground line is at ground_y (heights scaled by top plateau %.0f / 12) within 0.1 m"%[s,top_y])
  check(bottoms_ok,"Stage %d every ring bottom is below the outer ground (%.1f m)"%[s,outer_y])
  check(rise_ok,"Stage %d ground lines rise near to mid to far and all clear the top plateau (%s over %.0f)"%[s,str(grounds.map(func(v):return snappedf(v,0.1))),top_y])
  var sea=[root_node.get_node("FogSea_Low") as MeshInstance3D,root_node.get_node("FogSea_High") as MeshInstance3D];var sea_ok=true
  for layer in 2:
   var node=sea[layer];sea_ok=sea_ok and node.get_child_count()==0 and node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and node.mesh.get_surface_count()==1 and is_equal_approx(node.position.y,low_y+rules.fog_sea_y[layer])
   for v in node.mesh.get_faces():sea_ok=sea_ok and (absf(v.x)>=StageDressing.HALF-0.001 or absf(v.z)>=StageDressing.HALF-0.001) # no face ever lies inside the arena square
   for tri in range(0,node.mesh.get_faces().size(),3):
    var centre=(node.mesh.get_faces()[tri]+node.mesh.get_faces()[tri+1]+node.mesh.get_faces()[tri+2])/3.0;sea_ok=sea_ok and (absf(centre.x)>StageDressing.HALF or absf(centre.z)>StageDressing.HALF)
  check(sea_ok,"Stage %d fog sea: 2 layers, no collision, no shadows, never inside the arena, at -0.6 / +2.5 m from the lowest terrain"%s)
  check(is_equal_approx(game.world.get_child(0).environment.fog_height,low_y) and is_equal_approx(game.world.get_child(0).environment.fog_height_density,rules.fog_height_density),"Stage %d height fog starts at the lowest terrain level"%s)
  var posts=root_node.get_node("FencePosts") as MultiMeshInstance3D
  var on_ground=posts.multimesh.instance_count>200;var height=float(d.fence.height)
  for post_transform in posts.get_meta("transforms"):
   var origin=post_transform.origin
   on_ground=on_ground and absf(origin.y-height*0.5-game.terrain_height(clampf(origin.x,-95.5,95.5),clampf(origin.z,-95.5,95.5)))<0.01
  check(on_ground,"Stage %d: %d fence posts, each standing on the terrain under it"%[s,posts.multimesh.instance_count])
  var fence_nodes=[]
  for n in root_node.get_children():
   if n.name.begins_with("Fence"):fence_nodes.append(n)
  var collision_free=true
  for n in fence_nodes:collision_free=collision_free and n.get_child_count()==0 and n.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var expected=2+(1 if d.fence.panel else 0)+(1 if d.fence.candles else 0)
  check(collision_free and fence_nodes.size()==expected,"Stage %d fence: %d multimesh draw calls, no collision, no shadows"%[s,fence_nodes.size()])
  # rails and wires only join posts at the same height
  var wires=root_node.get_node("FenceWires") as MultiMeshInstance3D;var level=true
  for t in wires.get_meta("transforms"):
   var half=t.basis.z*0.5 # the wire's local z runs post to post, so its rise is half.y*2
   level=level and absf(half.y)<0.2+0.01 and t.basis.z.length()>1.0
  check(level and wires.multimesh.instance_count>0,"Stage %d wires join only posts at the same height"%s)
 check(StageDressing.for_stage(4).fence.candles and not StageDressing.for_stage(1).fence.candles and StageDressing.for_stage(2).fence.panel and StageDressing.for_stage(3).fence.stripes,"Per-stage fence styles (stage 2 chain-link, 3 striped boards, 4 candles)")
 # --- endless cycle ---
 check([5,6,7,8,9,10].map(func(v):return StageDressing.index(v))==[1,2,3,1,2,3] and StageDressing.index(1)==0 and StageDressing.index(4)==3,"Endless stages cycle dressings 2 -> 3 -> 4")
 # --- footsteps are data ---
 check(StageDressing.for_stage(1).footsteps=="grass" and StageDressing.for_stage(2).footsteps=="dirt","Footsteps come from the dressing")
 # --- props follow the dressing ---
 check(StageThemes.index(1)==0 and StageThemes.index(2)==1 and StageThemes.index(3)==2 and StageThemes.index(4)==2 and StageThemes.index(5)==1,"Props follow the dressing (living, withering, dead, dead)")
 # --- the arena is untouched ---
 game.stage=1;game.build_stage();await process_frame
 var faces_a=ForestMap.geometry(game.map_layout).get_faces();var visible_a=ForestMap.geometry(game.map_layout,false).get_faces()
 var digest_a=str(hash(faces_a))+":"+str(hash(visible_a))+":"+str(hash(game.map_layout.planes))
 game.stage=2;game.map_seed_override=9;game.build_stage();await process_frame
 var layout_two=game.map_layout
 game.stage=1;game.build_stage();await process_frame
 var digest_b=str(hash(ForestMap.geometry(game.map_layout).get_faces()))+":"+str(hash(ForestMap.geometry(game.map_layout,false).get_faces()))+":"+str(hash(game.map_layout.planes))
 check(digest_a==digest_b and faces_a.size()>10000,"Terrain mesh, collision mesh and planes are identical for a fixed seed across dressings")
 check(hash(layout_two.planes)==hash(game.map_layout.planes) and str(layout_two.pois)==str(game.map_layout.pois),"The arena layout is the same under every dressing (same seed)")
 var shape: ConcavePolygonShape3D=game.world.get_node("TerraceTerrain/TerrainCollision").get_child(0).shape
 check(hash(shape.get_faces())==hash(ForestMap.geometry(game.map_layout).get_faces()),"The live collision shape is the generator's collision mesh")
 var state=[game.rng.state,game.spawn_rng.state,game.wrt.rng.state]
 StageDressing.for_stage(3).apply(game);StageDressing.for_stage(3).attach_weather(game)
 check(state==[game.rng.state,game.spawn_rng.state,game.wrt.rng.state],"Applying a dressing never draws from the game, spawn or weapon RNG")
 # spawn points for a fixed seed
 var positions=[]
 for pass_index in 2:
  game.next_run_seed=4242;game.begin_run();game.set_physics_process(false);game.player.active=false;game.enemies.clear()
  game.stage=1+pass_index*2;game.build_stage();game.stage=1;game.build_stage()
  var seq=[];for i in 12:seq.append(game.spawn_enemy(0).pos)
  positions.append(str(seq))
 check(positions[0]==positions[1],"Enemy spawn points for a fixed seed do not depend on the dressing history")
 # --- the border holds from the highest plateau, including with a launch ---
 game.next_run_seed=4242;game.begin_run();game.stage=1;game.build_stage();game.resume();game.set_physics_process(true);game.spawn_clock=999;game.enemies.clear()
 var top=Vector3(0,-1,0)
 for x in range(-88,89,4):
  for z in range(-88,89,4):
   var h=game.terrain_height(x,z)
   if h>top.y+0.01 or (absf(h-top.y)<=0.01 and Vector2(x,z).length()>Vector2(top.x,top.z).length()):top=Vector3(x,h,z)
 var outward=Vector3(top.x,0,top.z).normalized();if outward.length()<0.1:outward=Vector3(1,0,0)
 var worst=0.0
 for launch in [Vector3(0,0,0),Vector3(0,30,0),Vector3(0,60,0)]:
  game.player.position=top+Vector3(0,1,0);game.player.velocity=outward*90.0+launch;game.player.active=true
  for i in 180:
   await physics_frame
   worst=maxf(worst,maxf(absf(game.player.position.x),absf(game.player.position.z)))
 check(worst<=96.6,"The player cannot leave the arena from the highest plateau, even launched at 90 m/s (max %.2f)"%worst)
 # --- imports ---
 var all_ok=true;var bad=[]
 for folder in ["textures","backdrops","skies"]:
  for file in DirAccess.get_files_at("res://assets/stage_dressing/"+folder):
   if file.ends_with(".png"):
    var text=FileAccess.get_file_as_string("res://assets/stage_dressing/%s/%s.import"%[folder,file])
    if not text.contains("mipmaps/generate=false"):all_ok=false;bad.append(file)
 check(all_ok,"Every dressing texture imports without mipmaps %s"%str(bad))
 var shader_ok=true
 for path in ["res://shaders/stage_ground.gdshader","res://shaders/stage_backdrop.gdshader"]:
  var code=FileAccess.get_file_as_string(path)
  for line in code.split("\n"):
   if line.begins_with("uniform sampler2D") and not line.contains("filter_nearest"):shader_ok=false
 check(shader_ok,"Ground and backdrop samplers use nearest filtering")
 check(not FileAccess.file_exists("res://shaders/grimdark_terrain.gdshader") and not FileAccess.get_file_as_string("res://shaders/vendor_psx/psx.gdshaderinc").contains("psx_fog"),"The interim PSX fog is gone")
 # --- settings ---
 game.settings["weather"]=false;StageDressing.for_stage(2).attach_weather(game)
 check(game.player.get_node_or_null("Weather")==null,"The Weather setting turns weather off")
 game.settings["weather"]=true;game.settings["reduced"]=true;StageDressing.for_stage(1).attach_weather(game)
 check(game.player.get_node("Weather").amount==int(rules.rain_count*rules.weather_reduced_fraction),"Reduced mode halves the weather")
 print("STAGE DRESSING: %d checks, %d failures"%[checks,failures.size()])
 quit(1 if failures.size()>0 else 0)

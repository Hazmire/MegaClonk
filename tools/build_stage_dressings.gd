extends SceneTree
# Regenerates assets/stage_dressing/*.tres from docs/stage_dressing/stage_dressing.json (the source of truth).
#   tools/godot.sh --headless --path . --script tools/build_stage_dressings.gd
const DIR="res://docs/stage_dressing/"
const PROP_STYLE=[0,1,2,2]
func tex(path):return load(DIR+path) if path!=null and path!="" else null
func vec(a):return Vector3(a[0],a[1],a[2])
func _initialize():
 var d=JSON.parse_string(FileAccess.get_file_as_string(DIR+"stage_dressing.json"))
 var rules=StageDressingRules.new()
 rules.triplanar_scale=float(d.texture_import.triplanar_world_scale);rules.low_ground_scale=float(d.texture_import.low_ground_scale)
 rules.sky_rotation_deg=float(d.sky.sky_rotation_deg_y)
 var layers=PackedStringArray();var radius=PackedFloat32Array();var base=PackedFloat32Array();var haze=PackedFloat32Array()
 for r in d.backdrop_rings:layers.append(r.layer);radius.append(r.radius_m);base.append(r.base_y_m);haze.append(r.haze)
 rules.ring_layers=layers;rules.ring_radius=radius;rules.ring_base_y=base;rules.ring_haze=haze
 rules.wall_offsets=PackedFloat32Array(d.fog_wall.offsets_from_edge_m);rules.wall_density=PackedFloat32Array(d.fog_wall.density)
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/stage_dressing"))
 var err=ResourceSaver.save(rules,"res://assets/stage_dressing/rules.tres");print("rules ",err)
 for s in d.stages:
  var r=StageDressing.new()
  r.stage_number=int(s.stage);r.title=s.name;r.sky=tex(s.sky)
  r.top=tex(s.ground.top);r.side=tex(s.ground.side);r.low=tex(s.ground.low);r.torn_edge=tex(s.ground.torn_edge);r.side_emission=tex(s.ground.get("side_emission",""))
  r.fog_color=Color(s.fog.color);r.fog_density=float(s.fog.density)
  r.ambient_color=Color(s.ambient.color);r.ambient_energy=float(s.ambient.energy)
  r.sun_color=Color(s.sun.color);r.sun_energy=float(s.sun.energy);r.sun_rotation_deg=vec(s.sun.rotation_deg)
  r.wall_color=Color(s.fog_wall.color);r.wall_glow_color=Color(s.fog_wall.glow_color);r.wall_glow=float(s.fog_wall.glow)
  r.weather=s.weather;r.backdrop_far=tex(s.backdrop.far);r.backdrop_mid=tex(s.backdrop.mid);r.backdrop_near=tex(s.backdrop.near);r.footsteps=s.footsteps
  r.prop_style=PROP_STYLE[int(s.stage)-1]
  print("stage ",s.stage," ",ResourceSaver.save(r,"res://assets/stage_dressing/stage_%d.tres"%int(s.stage)))
 quit()

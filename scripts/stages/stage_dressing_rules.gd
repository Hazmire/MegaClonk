class_name StageDressingRules
extends Resource
# Values shared by every stage dressing. Generated from docs/stage_dressing/stage_dressing.json by tools/build_stage_dressings.gd.
@export var triplanar_scale=0.25
@export var low_ground_scale=0.18
@export var sky_rotation_deg=180.0
@export var ring_layers: PackedStringArray=PackedStringArray(["far","mid","near"])
@export var ring_radius: PackedFloat32Array=PackedFloat32Array([240.0,150.0,90.0])
@export var ring_base_y: PackedFloat32Array=PackedFloat32Array([-12.0,-4.0,0.0])
@export var ring_haze: PackedFloat32Array=PackedFloat32Array([0.55,0.3,0.1])
@export var ring_height_divisor=16.0
# The reference arena is 96 m across; the game's is 192 m. Ring radii and base heights scale by this so the rings stay outside the walls.
@export var arena_scale=2.0
@export var wall_offsets: PackedFloat32Array=PackedFloat32Array([9.0,15.0])
@export var wall_density: PackedFloat32Array=PackedFloat32Array([0.2,0.28])
@export var wall_height=360.0
@export var wall_centre_y=150.0
@export var rain_count=3000
@export var dust_count=900
@export var ash_count=900
@export var rain_color=Color(0.85,0.9,0.86,0.3)
@export var blood_rain_color=Color(0.6,0.05,0.04,0.55)
@export var dust_color=Color(0.85,0.7,0.5,0.6)
@export var ash_color=Color(0.75,0.68,0.64,0.9)
@export var weather_reduced_fraction=0.5

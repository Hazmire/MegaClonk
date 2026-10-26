class_name ForestSettings
extends Resource
@export_range(10,16,2) var minimum_ramp_width=12.0
@export_range(20,30,1) var maximum_ramp_slope=28.0
@export_range(24,40,2) var preferred_ramp_length=28.0
@export_range(2,4,1) var extra_connections=2
@export_range(0,1,0.05) var extra_connection_frequency=0.65

# Version 4 layout controls. Old version-3 checkpoints retain their fixed palette.
@export_range(3,5,1) var elevation_bands=4
@export_range(24,48,2) var maximum_elevation=36.0
@export_range(0.5,0.9,0.05) var elevated_coverage=0.75
@export_range(44,64,2) var minimum_plateau_size=44.0
@export_range(6,10,1) var minimum_regions=7
@export_range(10,16,1) var maximum_regions=12
@export_range(52,96,2) var maximum_ramp_length=80.0
@export_range(0,4,2) var cliff_edge_variation=4.0

# Defaults preserve the current economy (two of each of six optional objects).
@export_range(6,18,1) var minimum_optional_objects=12
@export_range(6,18,1) var maximum_optional_objects=12

# Empty weights retain uniform sampling of non-zero bands. One region per band
# is always reserved. Larger split bias produces more similarly sized plateaus.
@export var elevation_band_weights=PackedFloat32Array()
@export_range(1,4,1) var plateau_size_bias=2

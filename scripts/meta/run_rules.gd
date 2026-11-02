class_name RunRules
extends Resource
@export var base_spawn_rate=2.4
@export var stage_spawn_growth=0.15
@export var late_stage_pressure=2.1
@export var first_rush_pressure=1.8
@export var second_rush_pressure=2.2
@export var rush_seconds=30.0
@export var endless_pressure_seconds=90.0
@export var ghost_base_rate=0.5
@export var ghost_growth_seconds=120.0
@export var ghost_speed_cap=10.0
# Credit-based spawner (Game.spawn_rate): enemies per second earned with nothing killed ("no-kill rate"), growing over the stage clock;
# clearing the field earns up to (1+clear_bonus)x that, as the living count falls under a soft cap that also grows with time.
@export var spawn_start_rate=0.25
@export var spawn_end_rate=3.0
@export var spawn_curve=1.4
@export var soft_cap_start=25.0
@export var soft_cap_end=300.0
@export var clear_bonus=2.0
@export var rush_spawn_mult=1.6
@export var endless_mult_cap=6.0
# Difficulty stat: +hp and +damage 1:1, +speed per point (capped), +spawn count 1:1 (rate and soft cap).
@export var difficulty_speed_per_point=0.25
@export var difficulty_speed_cap=1.6

## Megaclonk — Aura weapon visual.
##
## Parent it to the player at foot level. Set `radius` from the Size stat and
## `pulse_interval` from Attack speed. Connect `pulsed` to your damage tick
## (or call `pulse()` yourself from the weapon code and set pulse_interval to 0).
## On each pulse the sigil flashes lighter green; flash the enemies inside with
## hit_flash.gd using Color(0.6, 1.0, 0.5).
extends Node3D

signal pulsed

@export var radius := 3.0:
	set = set_radius
@export var pulse_interval := 1.0
@export var spin_degrees_per_second := 26.0
@export var pulse_color := Color(0.55, 0.95, 0.45, 0.6)

var _timer := 0.0
var _pulse_mat: StandardMaterial3D


func _ready() -> void:
	var smoke := $Smoke as GPUParticles3D
	smoke.process_material = smoke.process_material.duplicate()
	var pulse := $Pulse as MeshInstance3D
	_pulse_mat = (pulse.get_active_material(0) as StandardMaterial3D).duplicate()
	pulse.material_override = _pulse_mat
	_pulse_mat.albedo_color.a = 0.0
	set_radius(radius)


func set_radius(r: float) -> void:
	radius = r
	if not is_inside_tree():
		return
	$Sigil.scale = Vector3(r, 1.0, r)
	$Pulse.scale = Vector3(r, 1.0, r)
	var pm := ($Smoke as GPUParticles3D).process_material as ParticleProcessMaterial
	pm.emission_ring_radius = r * 0.85
	var light := get_node_or_null("Light") as OmniLight3D
	if light:
		light.omni_range = r + 1.5


func _process(delta: float) -> void:
	$Sigil.rotate_y(deg_to_rad(spin_degrees_per_second) * delta)
	$Pulse.rotation = $Sigil.rotation
	if pulse_interval > 0.0:
		_timer += delta
		if _timer >= pulse_interval:
			_timer -= pulse_interval
			pulse()


func pulse() -> void:
	_pulse_mat.albedo_color = pulse_color
	create_tween().tween_property(_pulse_mat, "albedo_color:a", 0.0, 0.35)
	var light := get_node_or_null("Light") as OmniLight3D
	if light:
		light.light_energy = 3.0
		create_tween().tween_property(light, "light_energy", 0.6, 0.4)
	pulsed.emit()

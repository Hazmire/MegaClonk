## Megaclonk — Scythes projectile: spins flat, flies out, slows, then speeds
## back to its owner and frees itself on catch.
##
##     var s := preload("res://vfx/weapons/effects/scythe_projectile.tscn").instantiate()
##     get_tree().current_scene.add_child(s)
##     s.global_position = hand_position
##     s.launch(player, direction_to_target)
##
## Swap the Blade sprite's texture for the final scythe art.
extends Node3D

signal caught

@export var out_distance := 7.0
@export var speed := 14.0
@export var spin_degrees_per_second := 1080.0
@export var catch_distance := 0.5

var returning := false
var _t := 0.0
var _origin := Vector3.ZERO
var _dir := Vector3.FORWARD
var _owner_node: Node3D


func launch(owner_node: Node3D, direction: Vector3) -> void:
	_owner_node = owner_node
	_origin = global_position
	_dir = Vector3(direction.x, 0.0, direction.z).normalized()
	_t = 0.0
	returning = false


func _process(delta: float) -> void:
	$Spin.rotate_y(deg_to_rad(spin_degrees_per_second) * delta)
	_t += delta
	if not returning:
		var out_time := out_distance / speed * 2.0
		var k := clampf(_t / out_time, 0.0, 1.0)
		global_position = _origin + _dir * out_distance * (1.0 - pow(1.0 - k, 2.0))
		if k >= 1.0:
			returning = true
			_t = 0.0
	else:
		var target := _origin
		if _owner_node and is_instance_valid(_owner_node):
			target = Vector3(_owner_node.global_position.x, _origin.y, _owner_node.global_position.z)
		var v := minf(speed * (0.3 + _t * 1.8), speed * 1.5)
		var to := target - global_position
		if to.length() <= v * delta + catch_distance:
			_catch()
			return
		global_position += to.normalized() * v * delta


func _catch() -> void:
	var dust := get_node_or_null("Dust") as GPUParticles3D
	if dust:
		var gt := dust.global_transform
		remove_child(dust)
		get_tree().current_scene.add_child(dust)
		dust.global_transform = gt
		dust.emitting = false
		get_tree().create_timer(dust.lifetime + 0.2).timeout.connect(dust.queue_free)
	caught.emit()
	queue_free()

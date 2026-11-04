## Megaclonk — simple straight-line projectile used by the Bow arrow,
## Revolver bullet and Firestaff fireball scenes.
##
## Point the node at the target (look_at) and it flies along its -Z axis.
## When it has travelled `max_distance` it emits `arrived` and frees itself.
## Trails listed in `detach_paths` are left behind to fade out naturally
## instead of vanishing with the projectile.
##
## If your weapons already move their own projectiles, you can drop this
## script and just parent the visual nodes to your projectile; call
## `finish()` (or copy its trail-detaching part) when it dies.
extends Node3D

signal arrived(at: Vector3)

@export var speed := 26.0
@export var acceleration := 0.0
@export var max_distance := 18.0
@export var detach_paths: Array[NodePath] = []

var travelled := 0.0
var _done := false


func _process(delta: float) -> void:
	if _done:
		return
	speed += acceleration * delta
	var step := speed * delta
	global_position += -global_transform.basis.z * step
	travelled += step
	if travelled >= max_distance:
		finish()


func finish() -> void:
	if _done:
		return
	_done = true
	arrived.emit(global_position)
	for p in detach_paths:
		var n := get_node_or_null(p)
		if n is GPUParticles3D:
			var gt: Transform3D = n.global_transform
			n.get_parent().remove_child(n)
			get_tree().current_scene.add_child(n)
			n.global_transform = gt
			n.emitting = false
			get_tree().create_timer(n.lifetime + 0.2).timeout.connect(n.queue_free)
	queue_free()

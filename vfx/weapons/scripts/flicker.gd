## Megaclonk — random scale flicker for fire glows.
extends Node3D

@export var amount := 0.14
@export var interval := 0.04

var _t := 0.0
var _base := Vector3.ONE


func _ready() -> void:
	_base = scale


func _process(delta: float) -> void:
	_t += delta
	if _t >= interval:
		_t = 0.0
		scale = _base * (1.0 + randf_range(-amount, amount))

## Megaclonk — one-shot effect player (muzzle flashes, impacts, shotgun blast).
##
## Instance the scene, position/rotate it, and it plays itself and frees itself.
## Children it understands:
##   - GPUParticles3D: restarted. Optional meta "delay" (seconds) to start later.
##   - OmniLight3D: pops to meta "peak" energy, fades over meta "fade" seconds.
##   - MeshInstance3D named "Flash...": scales from meta "scale_from" to
##     "scale_to" while fading out over meta "time" seconds.
extends Node3D

@export var life := 1.0
@export var auto_free := true
@export var play_on_ready := true
@export var flash_time := 0.08


func _ready() -> void:
	for c in get_children():
		if c is MeshInstance3D and String(c.name).begins_with("Flash"):
			c.visible = false
	if play_on_ready:
		play()


func play() -> void:
	for c in get_children():
		if c is GPUParticles3D:
			var delay: float = c.get_meta("delay", 0.0)
			if delay > 0.0:
				c.emitting = false
				get_tree().create_timer(delay).timeout.connect(c.restart)
			else:
				c.restart()
		elif c is OmniLight3D:
			c.light_energy = c.get_meta("peak", 4.0)
			create_tween().tween_property(c, "light_energy", 0.0, c.get_meta("fade", 0.15))
		elif c is MeshInstance3D and String(c.name).begins_with("Flash"):
			_flash(c)
	if auto_free:
		get_tree().create_timer(life).timeout.connect(queue_free)


func _flash(m: MeshInstance3D) -> void:
	var src := m.get_active_material(0) as StandardMaterial3D
	if src == null:
		return
	var mat := src.duplicate() as StandardMaterial3D
	m.material_override = mat
	var base := mat.albedo_color
	var t: float = m.get_meta("time", flash_time)
	var s0: float = m.get_meta("scale_from", 0.6)
	var s1: float = m.get_meta("scale_to", 1.3)
	m.scale = Vector3.ONE * s0
	m.visible = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(m, "scale", Vector3.ONE * s1, t)
	tw.tween_method(func(a: float) -> void: mat.albedo_color = Color(base.r, base.g, base.b, a), base.a, 0.0, t)

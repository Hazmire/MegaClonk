class_name BonkPlayer
extends CharacterBody3D
var stats: Dictionary
var yaw = 0.0
var pitch = -0.35
var zoom = 12.0
var sensitivity = 0.0025
var inverted = false
var jumps = 0
var max_jumps = 1
var fall_velocity = 0.0
var fall_hit = 0.0
var active = false
var can_climb = false
var air_control = 13.0
var avatar: Node3D
var arm: SpringArm3D
var camera: Camera3D
func _ready() -> void:
 collision_layer = 2
 collision_mask = 1
 floor_max_angle = deg_to_rad(48)
 floor_snap_length = 0.5
 var shape = CollisionShape3D.new()
 var capsule = CapsuleShape3D.new()
 capsule.radius = 0.4
 capsule.height = 1.6
 shape.shape = capsule
 shape.position.y = 0.8
 add_child(shape)
 arm = SpringArm3D.new()
 arm.position.y = 1.8
 arm.spring_length = zoom
 arm.collision_mask = 1
 arm.add_excluded_object(get_rid())
 add_child(arm)
 camera = Camera3D.new()
 camera.fov = 76
 arm.add_child(camera)
func _unhandled_input(event: InputEvent) -> void:
 if not active: return
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  yaw -= event.relative.x * sensitivity
  pitch = clampf(pitch - event.relative.y * sensitivity * (-1 if inverted else 1), -1.15, 0.3)
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = maxf(4, zoom - 1)
  if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(20, zoom + 1)
func _physics_process(delta: float) -> void:
 if not active: return
 arm.rotation = Vector3(pitch, yaw, 0)
 arm.spring_length = lerpf(arm.spring_length, zoom, 10 * delta)
 var input = Input.get_vector("left", "right", "forward", "back")
 var direction = Basis(Vector3.UP, yaw) * Vector3(input.x, 0, input.y)
 var speed = 9.0 * stats.speed * (1.4 if Input.is_action_pressed("sprint") else 1.0)
 var acceleration = 35.0 if is_on_floor() else air_control
 velocity.x = move_toward(velocity.x, direction.x * speed, acceleration * delta)
 velocity.z = move_toward(velocity.z, direction.z * speed, acceleration * delta)
 if is_on_floor():
  if fall_velocity < -24: fall_hit += (-fall_velocity - 24) * 1.5
  jumps = 0
  fall_velocity = 0
 else:
  velocity.y -= 25.0 * delta
  fall_velocity = minf(fall_velocity, velocity.y)
 if Input.is_action_just_pressed("jump") and (is_on_floor() or jumps < max_jumps):
  velocity.y = 10.5 * sqrt(stats.jump)
  jumps += 1
 if can_climb and is_on_wall() and Input.is_action_pressed("sprint"):
  velocity.y = 6.0
 move_and_slide()
 if direction.length_squared() > 0.1:
  avatar.rotation.y = lerp_angle(avatar.rotation.y, atan2(direction.x, direction.z), 12 * delta)
 avatar.position.y = sin(Time.get_ticks_msec() * 0.018) * minf(Vector2(velocity.x, velocity.z).length() * 0.008, 0.09)

 # Procedural locomotion: limbs swing, lean in air, recoil on impacts.
 for limb in avatar.get_children():
  if limb.has_meta("side"):
   var stride = minf(Vector2(velocity.x,velocity.z).length()/9,1)
   limb.rotation.x = sin(Time.get_ticks_msec()*0.018)*stride*float(limb.get_meta("side"))*0.6
 avatar.rotation.x = lerpf(avatar.rotation.x, -0.12 if not is_on_floor() else 0.0,delta*8)

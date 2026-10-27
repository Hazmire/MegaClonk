class_name BonkPlayer
extends CharacterBody3D
const RULES=preload("res://assets/config/abilities.tres")

@export var ground_acceleration = 55.0
@export var ground_friction = 45.0
@export var air_control = 9.0
@export var slide_initiation_speed = 7.0
@export var slide_friction = 3.0
@export var slide_steering = 2.8
@export var slope_acceleration = 26.0
@export var max_slide_speed = 23.0
@export var crouch_speed = 3.8
@export var jump_impulse = 10.0
@export var standing_height = 1.8
@export var crouched_height = 0.95
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
var can_glide=false
var movement_multiplier=1.0
var jump_multiplier=1.0
var posture = "standing"
var avatar: Node3D
var arm: SpringArm3D
var camera: Camera3D
var collider: CollisionShape3D
var hurt_time = 0.0
var dead = false
var crowd_world: Node
var last_facing = 0.0

func _ready() -> void:
 collision_layer = 2
 collision_mask = 1
 floor_max_angle = deg_to_rad(48)
 floor_snap_length = 0.4
 collider = CollisionShape3D.new()
 var capsule = CapsuleShape3D.new()
 capsule.radius = 0.34
 capsule.height = standing_height
 collider.shape = capsule
 collider.position.y = standing_height / 2
 add_child(collider)
 arm = SpringArm3D.new()
 arm.position.y = 1.55
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
func can_stand() -> bool:
 var shape = BoxShape3D.new()
 shape.size = Vector3(0.64, standing_height-crouched_height-0.04, 0.64)
 var query = PhysicsShapeQueryParameters3D.new()
 query.shape = shape
 query.transform = Transform3D(Basis.IDENTITY, global_position+Vector3.UP*(standing_height+crouched_height)/2)
 query.collision_mask = collision_mask
 query.exclude = [get_rid()]
 return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()
func set_posture(value: String) -> void:
 posture = value
 var height = standing_height if posture=="standing" else crouched_height
 collider.shape.height = height
 collider.position.y = height/2
func slide_velocity(horizontal: Vector3, normal: Vector3, direction: Vector3, delta: float) -> Vector3:
 # Tangential gravity is the only source of slide acceleration. No entry boost.
 var tangent_gravity = (Vector3.DOWN*slope_acceleration).slide(normal)
 horizontal += Vector3(tangent_gravity.x,0,tangent_gravity.z)*delta
 horizontal = horizontal.move_toward(Vector3.ZERO,slide_friction*stats.get("slide_friction",1.0)*delta)
 if direction.length_squared()>0.01 and horizontal.length()>0.1:
  var magnitude = horizontal.length()
  var steered = horizontal.normalized().lerp(direction,clampf(slide_steering*delta,0,1)).normalized()
  horizontal = steered*magnitude
 return horizontal.limit_length(max_slide_speed*stats.speed*stats.get("slide_speed",1.0))
func _physics_process(delta: float) -> void:
 if not active: return
 arm.rotation = Vector3(pitch, yaw, 0)
 arm.spring_length = lerpf(arm.spring_length,zoom,10*delta)
 arm.position.y = lerpf(arm.position.y,1.55 if posture=="standing" else 1.0,delta*12)
 var input = Input.get_vector("left","right","forward","back")
 var direction = Basis(Vector3.UP,yaw)*Vector3(input.x,0,input.y)
 var horizontal = Vector3(velocity.x,0,velocity.z)
 var low = Input.is_action_pressed("crouch")
 if low and posture=="standing":
  set_posture("sliding" if is_on_floor() and horizontal.length()>=slide_initiation_speed else "crouching")
 if not low and posture!="standing" and can_stand(): set_posture("standing")
 if posture=="sliding" and is_on_floor():
  horizontal=slide_velocity(horizontal,get_floor_normal(),direction,delta)
  if horizontal.length()<crouch_speed: set_posture("crouching")
 elif is_on_floor():
  var target = direction*(crouch_speed if posture!="standing" else 8.0)*stats.speed*movement_multiplier
  # Preserve excess landing momentum; friction bleeds it away instead of snapping.
  if horizontal.length()>target.length()+0.5:
   horizontal=horizontal.move_toward(Vector3.ZERO,(ground_friction if input.length()<0.01 else slide_friction*2)*delta)
   if direction.length_squared()>0.1: horizontal=horizontal.lerp(direction*horizontal.length(),delta*2)
  else: horizontal=horizontal.move_toward(target,(ground_acceleration if input.length()>0 else ground_friction)*delta)
 else:
  horizontal=air_velocity(horizontal,direction,delta)
 velocity.x=horizontal.x
 velocity.z=horizontal.z
 max_jumps=1+int(stats.get("air_jumps",0))+(2 if stats.get("legacy_air",false) else 0)
 if is_on_floor():
  if fall_velocity < -24: fall_hit+=(-fall_velocity-24)*1.5
  jumps=0
  fall_velocity=0
 else:
  var gliding=can_glide and velocity.y<0 and Input.is_action_pressed("jump")
  velocity.y-=34*(RULES.glide_gravity_multiplier/maxf(1,stats.get("glide",1)) if gliding else 1.0)*delta
  if can_glide and velocity.y<0 and Input.is_action_pressed("jump"): velocity.y=maxf(velocity.y,-maxf(0.8,RULES.glide_terminal_speed/maxf(1,stats.get("glide",1))))
  fall_velocity=minf(fall_velocity,velocity.y)
 var wall_jump=can_climb and is_on_wall() and maxf(absf(position.x),absf(position.z))<73
 if Input.is_action_just_pressed("jump") and (is_on_floor() or jumps<max_jumps or wall_jump):
  velocity.y=jump_impulse*sqrt(stats.jump*jump_multiplier)
  jumps+=1
  if wall_jump:velocity+=get_wall_normal()*6
 if can_climb and is_on_wall() and Input.is_action_pressed("forward") and not low and not Input.is_action_just_pressed("jump") and maxf(absf(position.x),absf(position.z))<73: velocity.y=8*stats.speed*movement_multiplier*RULES.climb_speed_ratio*stats.get("climb",1)
 if is_instance_valid(crowd_world):velocity=crowd_world.crowd.player_velocity(crowd_world,velocity,delta)
 move_and_slide()
 hurt_time=maxf(0,hurt_time-delta)
 if not is_instance_valid(avatar): return
 if avatar.has_method("set_damage_flash"):avatar.set_damage_flash(hurt_time>0)
 var previous=avatar.rotation.y
 if direction.length_squared()>0.1: avatar.rotation.y=lerp_angle(previous,atan2(direction.x,direction.z),12*delta)
 var animation="idle"
 if dead: animation="death"
 elif not is_on_floor(): animation="jump" if velocity.y>0 else ("glide" if can_glide and Input.is_action_pressed("jump") else "fall")
 elif posture=="sliding": animation="slide"
 elif posture=="crouching": animation="crouch"
 elif horizontal.length()>0.5: animation="run"
 elif absf(angle_difference(last_facing,avatar.rotation.y))>0.01: animation="turn"
 if animation in ["idle","run"] and horizontal.length()<3 and absf(angle_difference(previous,avatar.rotation.y))>0.04: animation="turn"
 last_facing=avatar.rotation.y
 if avatar.has_method("animate"): avatar.animate(animation,horizontal.length(),delta)

func air_velocity(horizontal: Vector3, direction: Vector3, delta: float) -> Vector3:
 if direction.length_squared()<0.01: return horizontal
 # Steering may redirect carried slide speed; it cannot mint extra kinetic energy.
 var speed_limit=maxf(horizontal.length(),8.0*stats.speed*movement_multiplier)
 var along=horizontal.dot(direction)
 horizontal+=direction*minf(air_control*delta,maxf(0,8*stats.speed*movement_multiplier-along))
 return horizontal.limit_length(speed_limit)

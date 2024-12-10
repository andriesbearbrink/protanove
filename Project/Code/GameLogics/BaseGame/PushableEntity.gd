class_name PushableEntity
extends CharacterBody2D

@export var health: int = 100
@export var mass: float = 1.0
@export var base_acceleration: float = 100.0
@export var base_max_speed: float = 300.0
@export var base_friction: float = 3.0

var acceleration: float
var max_speed: float
var friction: float
var impulse_velocity: Vector2 = Vector2.ZERO
const IMPULSE_DECAY: float = 1
@export var max_impulse_speed: float = 500.0
const IMPULSE_STRENGTH_FACTOR: float = 0.01

var movement_direction: Vector2 = Vector2.ZERO

var acceleration_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var friction_multiplier: float = 1.0

func _init():
	add_to_group("PushableEntity")

func _ready():
	update_movement_properties()

func update_movement_properties():
	acceleration = base_acceleration * acceleration_multiplier
	max_speed = base_max_speed * speed_multiplier
	friction = base_friction * friction_multiplier

func _physics_process(delta):
	# Apply acceleration based on movement direction
	if movement_direction != Vector2.ZERO:
		velocity += movement_direction * acceleration * delta
	
	# Apply friction
	if movement_direction == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# Limit velocity to max_speed
	velocity = velocity.limit_length(max_speed)
	
	# Apply impulse velocity
	impulse_velocity = impulse_velocity.move_toward(Vector2.ZERO, friction * delta)
	impulse_velocity = impulse_velocity.limit_length(max_impulse_speed)
	
	# Combine velocities
	velocity += impulse_velocity
	
	# Move the entity
	move_and_slide()

	# Rotate to face the direction of movement (if moving)
	if velocity.length() > 0.1:
		rotation = velocity.angle()

func set_movement_direction(direction: Vector2):
	movement_direction = direction.normalized()

func apply_central_impulse(impulse: Vector2):
	var applied_impulse = (impulse / mass) * IMPULSE_STRENGTH_FACTOR
	impulse_velocity += applied_impulse

func reset_color():
	modulate = Color.WHITE

func take_damage(amount: int):
	print("PushableEntity: Taking damage: ", amount)
	health -= amount

func increase_acceleration(percentage: float):
	acceleration_multiplier += percentage
	update_movement_properties()
	print("PushableEntity: Acceleration multiplier increased to: ", acceleration_multiplier)

func increase_max_speed(percentage: float):
	speed_multiplier += percentage
	update_movement_properties()
	print("PushableEntity: Speed multiplier increased to: ", speed_multiplier)

func modify_friction(multiplier: float):
	friction_multiplier *= multiplier
	update_movement_properties()
	print("PushableEntity: Friction multiplier set to: ", friction_multiplier)
	
func apply_knockback(force: Vector2) -> void:
	print("PushableEntity: Applying knockback force: ", force)
	apply_central_impulse(force / mass)  # Adjust knockback based on mass

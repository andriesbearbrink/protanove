class_name MovementComponent
extends Node

var parent: CharacterBody2D
var velocity: Vector2 = Vector2.ZERO
var acceleration: float = 100.0
var max_speed: float = 300.0
var friction: float = 0.01

func _init(parent_node: CharacterBody2D):
	parent = parent_node

func apply_movement(input_vector: Vector2, delta: float):
	if input_vector != Vector2.ZERO:
		velocity += input_vector * acceleration * delta
		velocity = velocity.limit_length(max_speed)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)
	
	parent.velocity = velocity
	parent.move_and_slide()

func set_movement_params(new_acceleration: float, new_max_speed: float, new_friction: float):
	acceleration = new_acceleration
	max_speed = new_max_speed
	friction = new_friction

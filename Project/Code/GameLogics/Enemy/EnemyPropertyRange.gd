class_name EnemyPropertyRange
extends Resource

@export var min_value: float
@export var max_value: float
@export var base_weight: float = 1.0  # For weighted random selection
var current_weight: float

func _init(min_val: float = 0.0, max_val: float = 1.0, weight: float = 1.0):
	min_value = min_val
	max_value = max_val
	base_weight = weight
	current_weight = weight

func get_random_value() -> float:
	return randf_range(min_value, max_value)

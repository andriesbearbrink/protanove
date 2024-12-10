class_name EnemyPropertyComponent
extends Node

const BehaviorType = preload("res://Code/GameLogics/Enemy/EnemyBehaviorComponent.gd").BehaviorType

# Changed to use direct value ranges instead of EnemyPropertyRange class for simplicity
var properties: Dictionary = {
	"size": Vector2(0.8, 1.2),
	"acceleration": Vector2(80.0, 120.0),
	"top_speed": Vector2(150.0, 250.0),
	"health": Vector2(50.0, 150.0),
	"shooting_chance": Vector2(0.0, 1.0)
}

var behavior_weights: Dictionary = {
	BehaviorType.CHASE: 1.0,
	BehaviorType.CIRCLE: 0.5,
	BehaviorType.ZIGZAG: 0.3,
	BehaviorType.SHOOT_AND_RETREAT: 0.2
}

# Add difficulty scaling
var current_difficulty_multiplier: float = 1.0

func modify_ranges(new_ranges: Dictionary):
	for property in new_ranges:
		if property in properties:
			properties[property] = new_ranges[property]

func modify_behavior_weight(behavior: int, weight: float):
	if behavior in behavior_weights:
		behavior_weights[behavior] = weight

func generate_properties() -> Dictionary:
	var generated = {}
	for prop_name in properties:
		var range = properties[prop_name]
		generated[prop_name] = randf_range(range.x, range.y) * current_difficulty_multiplier
	return generated

func select_random_behavior() -> int:
	var total_weight = 0.0
	for weight in behavior_weights.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_sum = 0.0
	
	for behavior in behavior_weights:
		current_sum += behavior_weights[behavior]
		if random_value <= current_sum:
			return behavior
	
	return BehaviorType.CHASE  # Default fallback

func set_difficulty_multiplier(multiplier: float):
	current_difficulty_multiplier = multiplier

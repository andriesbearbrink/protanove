extends Node

class_name EnemyMasterController

signal difficulty_changed(new_difficulty: float)

# Add the behavior type enum reference
const BehaviorType = preload("res://Code/GameLogics/Enemy/EnemyBehaviorComponent.gd").BehaviorType

# Structure to hold time-based modifications
class TimeModifier extends RefCounted:
	var time: float
	var type: String  # "range", "scalar", or "behavior"
	var property: Variant  # Changed to Variant to handle both String and int (for behavior types)
	var value: Variant

	func _init(t: float, typ: String, prop: Variant, val: Variant):
		time = t
		type = typ
		property = prop
		value = val

# Use Array instead of typed array since we're storing custom objects
var time_modifiers: Array = []
var enemy_creation_system: Node
var enemy_system: Node

func _ready():
	reset_to_base_values()
	await get_tree().process_frame
	setup_connections()
	setup_difficulty_progression()

func setup_connections():
	enemy_creation_system = get_node_or_null("/root/MainGame/SimpleEnemyCreationSystem")
	enemy_system = get_node_or_null("/root/MainGame/EnemySystem")
	
	if not enemy_creation_system:
		push_warning("EnemyMasterController: Could not find EnemyCreationSystem")
	if not enemy_system:
		push_warning("EnemyMasterController: Could not find EnemySystem")

func add_time_modifier(time: float, property: String, new_value):
	if new_value is Vector2:
		add_range_modifier(time, property, new_value)
	else:
		add_scalar_modifier(time, property, new_value)

func add_range_modifier(time: float, property: String, new_range: Vector2):
	var modifier = TimeModifier.new(time, "range", property, new_range)
	time_modifiers.append(modifier)
	time_modifiers.sort_custom(func(a, b): return a.time < b.time)

func add_scalar_modifier(time: float, property: String, multiplier: float):
	var modifier = TimeModifier.new(time, "scalar", property, multiplier)
	time_modifiers.append(modifier)
	time_modifiers.sort_custom(func(a, b): return a.time < b.time)

func add_behavior_modifier(time: float, behavior_type: int, weight: float):
	var modifier = TimeModifier.new(time, "behavior", behavior_type, weight)
	time_modifiers.append(modifier)
	time_modifiers.sort_custom(func(a, b): return a.time < b.time)

# Initial easy ranges for enemy properties
const BASE_RANGES = {
	"spawn_rate": Vector2(2.0, 3.0),     # Slower initial spawns (2-3 seconds between)
	"size": Vector2(0.5, 3),           # Fairly consistent size to start
	"speed": Vector2(10.0, 150.0),      # Slower initial speed
	"health": Vector2(30.0, 50.0),       # Lower initial health
	"shooting_chance": Vector2(0.0, 0.0)  # No shooting at start
}

# Initial behavior weights (now using enum values)
const BASE_BEHAVIOR_WEIGHTS = {
	BehaviorType.CHASE: 1.0,               # Primary behavior at start
	BehaviorType.CIRCLE: 0.0,              # Disabled initially
	BehaviorType.ZIGZAG: 0.0,             # Disabled initially
	BehaviorType.SHOOT_AND_RETREAT: 0.0    # Disabled initially
}

# Base gun properties (for when shooting is enabled)
const BASE_GUN_PROPERTIES = {
	"damage": Vector2(5.0, 10.0),      # Lower initial damage
	"fire_rate": Vector2(1.0, 1.5),    # Slower fire rate
	"bullet_speed": Vector2(80.0, 120.0), # Slower bullets
	"spread_angle": Vector2(10.0, 20.0)   # Less accurate
}

# Progressive difficulty stages (updated to use enum values for behaviors)
const DIFFICULTY_STAGES = [
	{
		"time": 60.0,
		"changes": {
			"spawn_rate": 0.8,       # Slightly faster spawning
			"speed": Vector2(120.0, 170.0),
			"health": Vector2(40.0, 60.0)
		}
	},
	{
		"time": 120.0, 
		"changes": {
			"spawn_rate": 0.7,
			"speed": Vector2(140.0, 190.0),
			"health": Vector2(50.0, 70.0),
			BehaviorType.CIRCLE: 0.2  # Introduce circle behavior
		}
	},
	{
		"time": 180.0, 
		"changes": {
			"spawn_rate": 0.6,
			"speed": Vector2(160.0, 210.0),
			"health": Vector2(60.0, 80.0),
			"shooting_chance": Vector2(0.0, 0.1),  # Introduce rare shooting
			BehaviorType.ZIGZAG: 0.2  # Introduce zigzag behavior
		}
	},
	{
		"time": 240.0,  
		"changes": {
			"spawn_rate": 0.5,
			"speed": Vector2(180.0, 230.0),
			"health": Vector2(70.0, 90.0),
			"shooting_chance": Vector2(0.0, 0.1),
			BehaviorType.SHOOT_AND_RETREAT: 0.2  # Introduce shoot and retreat behavior
		}
	},
	{
		"time": 300.0,  
		"changes": {
			"spawn_rate": 0.4,
			"speed": Vector2(200.0, 250.0),
			"health": Vector2(80.0, 100.0),
			"shooting_chance": Vector2(0.0, 0.1),  # More consistent shooting
			BehaviorType.CIRCLE: 1,
			BehaviorType.ZIGZAG: 1,
			BehaviorType.SHOOT_AND_RETREAT: 1
		}
	}
]

var current_ranges = {}
var current_behavior_weights = {}
var current_gun_properties = {}
var current_difficulty: float = 1.0
var current_stage: int = -1

var perk_system: Node

func reset_to_base_values():
	current_ranges = BASE_RANGES.duplicate(true)
	current_behavior_weights = BASE_BEHAVIOR_WEIGHTS.duplicate()
	current_gun_properties = BASE_GUN_PROPERTIES.duplicate(true)

func setup_difficulty_progression():
	for stage in DIFFICULTY_STAGES:
		for property_name in stage.changes:
			var change = stage.changes[property_name]
			if change is Vector2:
				add_time_modifier(stage.time, property_name, change)
			elif property_name is int:  # Behavior type
				add_behavior_modifier(stage.time, property_name, change)
			else:
				add_scalar_modifier(stage.time, property_name, change)

func _process(delta):
	var game_time = Time.get_ticks_msec() / 1000.0
	check_difficulty_stage(game_time)
	apply_current_stage_settings()

func check_difficulty_stage(current_time: float):
	for i in range(DIFFICULTY_STAGES.size()):
		if current_time >= DIFFICULTY_STAGES[i].time and i > current_stage:
			current_stage = i
			apply_stage_changes(DIFFICULTY_STAGES[i].changes)
			print("Advancing to difficulty stage ", i + 1)

func apply_stage_changes(changes: Dictionary):
	for property_name in changes:
		var change = changes[property_name]
		if change is Vector2:
			current_ranges[property_name] = change
		elif property_name is int:  # Behavior type
			current_behavior_weights[property_name] = change
		else:
			apply_scalar_change(property_name, change)

	# Update all connected systems
	if enemy_creation_system:
		enemy_creation_system.property_component.modify_ranges(current_ranges)
		for behavior in current_behavior_weights:
			enemy_creation_system.property_component.modify_behavior_weight(
				behavior, 
				current_behavior_weights[behavior]
			)

func apply_scalar_change(property: String, value: float):
	match property:
		"spawn_rate":
			if enemy_creation_system:
				enemy_creation_system.modify_spawn_rate(value)

func apply_current_stage_settings():
	if enemy_creation_system:
		enemy_creation_system.property_component.modify_ranges(current_ranges)
		for behavior in current_behavior_weights:
			enemy_creation_system.property_component.modify_behavior_weight(
				behavior, 
				current_behavior_weights[behavior]
			)

# Helper methods for getting current settings
func get_current_speed_range() -> Vector2:
	return current_ranges["speed"]

func get_current_health_range() -> Vector2:
	return current_ranges["health"]

func get_current_shooting_chance() -> Vector2:
	return current_ranges["shooting_chance"]

func get_current_spawn_rate() -> float:
	return enemy_creation_system.spawn_interval if enemy_creation_system else 1.0

func get_current_enemy_properties() -> Dictionary:
	return {
		"ranges": current_ranges.duplicate(true),
		"behavior_weights": current_behavior_weights.duplicate(),
		"gun_properties": current_gun_properties.duplicate(true)
	}

# Debug method to print current settings
func print_current_settings():
	print("Current Enemy Settings:")
	print("Stage: ", current_stage + 1)
	print("Speed Range: ", get_current_speed_range())
	print("Health Range: ", get_current_health_range())
	print("Shooting Chance: ", get_current_shooting_chance())
	print("Spawn Rate: ", get_current_spawn_rate())
	print("Behavior Weights: ", current_behavior_weights)

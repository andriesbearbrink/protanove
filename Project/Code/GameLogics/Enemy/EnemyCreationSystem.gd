extends Node

class_name SimpleEnemyCreationSystem

var enemy_system: Node
var property_component: EnemyPropertyComponent
var difficulty_controller: EnemyMasterController
var has_spawned_test_enemies: bool = false

func _ready():
	enemy_system = get_node("/root/MainGame/EnemySystem")
	setup_components()
	connect_to_difficulty_controller()
	print("EnemyCreationSystem: Initialized")

func setup_components():
	property_component = EnemyPropertyComponent.new()
	add_child(property_component)

func connect_to_difficulty_controller():
	await get_tree().process_frame
	difficulty_controller = get_node_or_null("/root/MainGame/EnemyMasterController")
	if difficulty_controller:
		var initial_properties = difficulty_controller.get_current_enemy_properties()
		property_component.modify_ranges(initial_properties.ranges)
		difficulty_controller.connect("difficulty_changed", Callable(self, "_on_difficulty_changed"))

func _on_difficulty_changed(new_difficulty: float):
	property_component.set_difficulty_multiplier(new_difficulty)

func start_spawning():
	if not has_spawned_test_enemies:
		spawn_test_enemies()
		has_spawned_test_enemies = true

func spawn_test_enemies():
	print("\nSpawning test enemies - one of each behavior type")
	
	var viewport_size = get_viewport().get_visible_rect().size
	var center = viewport_size / 2
	var spawn_radius = min(viewport_size.x, viewport_size.y) * 0.4

	var behavior_configs = [
		{
			"type": EnemyBehaviorComponent.BehaviorType.CHASE,
			"properties": {
				"size": 1.5,
				"acceleration": 200.0,  # Increased for more responsive movement
				"top_speed": 400.0,
				"health": 100.0,
				"shooting_chance": 0.0,
				"linear_damp": 1.0  # Add damping to control movement
			},
			"behavior_params": {
				"min_distance": 0.0
			},
			"color": Color(1.0, 0.2, 0.2)
		},
		{
			"type": EnemyBehaviorComponent.BehaviorType.CIRCLE,
			"properties": {
				"size": 0.8,
				"acceleration": 200.0,  # High acceleration for orbital movement
				"top_speed": 300.0,
				"health": 75.0,
				"shooting_chance": 0.0,
				"linear_damp": 3.0  # Higher damping for smoother orbiting
			},
			"behavior_params": {
				"orbit_distance": 250.0,
				"clockwise": true,
				"min_distance": 0.0
			},
			"color": Color(0.2, 1.0, 0.2)
		},
		{
			"type": EnemyBehaviorComponent.BehaviorType.ZIGZAG,
			"properties": {
				"size": 1.0,
				"acceleration": 220.0,  # High acceleration for sharp zigzags
				"top_speed": 350.0,
				"health": 50.0,
				"shooting_chance": 0.0,
				"linear_damp": 2.0
			},
			"behavior_params": {
				"frequency": 2.0,
				"amplitude": 3.0,  # Increased for more pronounced zigzag
				"min_distance": 0.0
			},
			"color": Color(1.0, 1.0, 0.2)
		},
		{
			"type": EnemyBehaviorComponent.BehaviorType.SHOOT_AND_RETREAT,
			"properties": {
				"size": 1.2,
				"acceleration": 200.0,
				"top_speed": 250.0,
				"health": 125.0,
				"shooting_chance": 1.0,
				"linear_damp": 1.5
			},
			"behavior_params": {
				"preferred_distance": 450.0,
				"min_distance": 100.0
			},
			"color": Color(0.2, 0.2, 1.0)
		}
	]

	for i in range(behavior_configs.size()):
		var config = behavior_configs[i]
		var angle = (2 * PI * i) / behavior_configs.size()
		var spawn_position = center + Vector2(cos(angle), sin(angle)) * spawn_radius
		
		print("\nSpawning enemy with behavior: ", get_behavior_name(config.type))
		print("Position: ", spawn_position)
		print("Properties: ", config.properties)
		print("Behavior params: ", config.behavior_params)
		print("Color: ", config.color)
		
		# Add the color to the properties so it can be applied to the enemy
		config.properties["color"] = config.color
		
		enemy_system.spawn_enemy("rigid", spawn_position, {
			"properties": config.properties,
			"behavior_type": config.type,
			"behavior_params": config.behavior_params
		})

func get_behavior_name(behavior_type: int) -> String:
	match behavior_type:
		EnemyBehaviorComponent.BehaviorType.CHASE: return "CHASE"
		EnemyBehaviorComponent.BehaviorType.CIRCLE: return "CIRCLE"
		EnemyBehaviorComponent.BehaviorType.ZIGZAG: return "ZIGZAG"
		EnemyBehaviorComponent.BehaviorType.SHOOT_AND_RETREAT: return "SHOOT_AND_RETREAT"
		_: return "UNKNOWN"

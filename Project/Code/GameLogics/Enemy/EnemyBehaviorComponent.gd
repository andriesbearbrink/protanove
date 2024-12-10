class_name EnemyBehaviorComponent
extends Node

enum BehaviorType {
	CHASE,
	CIRCLE,
	ZIGZAG,
	SHOOT_AND_RETREAT
}

var current_behavior: BehaviorType
var target: Node2D
var movement_params: Dictionary = {}
var debug_timer: float = 0.0
var DEBUG_INTERVAL: float = 1.0

var debug_lines: Array = []  # Store last few debug messages
const MAX_DEBUG_LINES = 5

# Add some common parameters
var min_distance: float = 50.0  # Minimum distance to maintain from other entities
var avoidance_weight: float = 0.5  # How strongly to avoid other entities
var last_direction: Vector2 = Vector2.ZERO

func _init(behavior: BehaviorType, params: Dictionary = {}):
	current_behavior = behavior
	movement_params = params
	print("EnemyBehaviorComponent initialized with behavior: ", BehaviorType.keys()[behavior])
	print("Behavior params: ", movement_params)

func update_movement(enemy: Node2D, delta: float) -> Vector2:
	if not target:
		return Vector2.ZERO
		
	debug_timer += delta
	if debug_timer >= DEBUG_INTERVAL:
		debug_timer = 0.0
		print_debug_info(enemy)
	
	# Get base movement direction based on behavior
	var base_direction: Vector2
	match current_behavior:
		BehaviorType.CHASE:
			base_direction = chase_behavior(enemy, delta)
		BehaviorType.CIRCLE:
			base_direction = circle_behavior(enemy, delta)
		BehaviorType.ZIGZAG:
			base_direction = zigzag_behavior(enemy, delta)
		BehaviorType.SHOOT_AND_RETREAT:
			base_direction = shoot_and_retreat_behavior(enemy, delta)
		_:
			base_direction = Vector2.ZERO
	
	# Add collision avoidance
	var avoidance = calculate_avoidance(enemy)
	var final_direction = (base_direction + avoidance * avoidance_weight).normalized()
	
	# Smooth the direction change
	last_direction = last_direction.lerp(final_direction, delta * 5.0)
	return last_direction

func calculate_avoidance(enemy: Node2D) -> Vector2:
	var avoidance = Vector2.ZERO
	
	# Avoid other enemies
	for other in enemy.get_tree().get_nodes_in_group("enemy"):
		if other != enemy:
			var to_other = enemy.global_position - other.global_position
			var distance = to_other.length()
			if distance < min_distance:
				avoidance += to_other.normalized() * (1.0 - distance/min_distance)
	
	# Avoid player more strongly
	if target:
		var to_player = enemy.global_position - target.global_position
		var distance = to_player.length()
		if distance < min_distance * 1.5:  # Larger minimum distance for player
			avoidance += to_player.normalized() * (1.0 - distance/(min_distance * 1.5)) * 2.0
	
	return avoidance

func chase_behavior(enemy: Node2D, delta: float) -> Vector2:
	if not target:
		return Vector2.ZERO
	
	# Simple but aggressive chase with increased minimum distance
	var to_target = target.global_position - enemy.global_position
	var distance = to_target.length()
	
	if distance < min_distance * 2:  # Keep some distance even when chasing
		return -to_target.normalized()
	return to_target.normalized()

func circle_behavior(enemy: Node2D, delta: float) -> Vector2:
	if not target:
		return Vector2.ZERO
	
	var to_target = target.global_position - enemy.global_position
	var distance = to_target.length()
	var orbit_distance = movement_params.get("orbit_distance", 200.0)
	var clockwise = movement_params.get("clockwise", true)
	
	# Get tangent vector for orbital motion
	var tangent = to_target.rotated(PI/2 if clockwise else -PI/2).normalized()
	
	# Strong radial adjustment
	var radial = to_target.normalized() * (distance - orbit_distance) * 2.0
	
	# Combine tangential and radial movement
	return (tangent + radial.normalized()).normalized()

func zigzag_behavior(enemy: Node2D, delta: float) -> Vector2:
	if not target:
		return Vector2.ZERO
	
	var base_direction = (target.global_position - enemy.global_position).normalized()
	var time = Time.get_ticks_msec() / 1000.0
	var frequency = movement_params.get("frequency", 4.0)
	var amplitude = movement_params.get("amplitude", 1.0)
	
	# Create side-to-side movement
	var perpendicular = base_direction.rotated(PI/2)
	var zigzag = base_direction + perpendicular * sin(time * frequency) * amplitude * 3.0
	
	# Add distance maintenance
	var distance = enemy.global_position.distance_to(target.global_position)
	if distance < min_distance * 2:
		zigzag += -base_direction * 2.0
	
	return zigzag.normalized()

func shoot_and_retreat_behavior(enemy: Node2D, delta: float) -> Vector2:
	if not target:
		return Vector2.ZERO
	
	var to_target = target.global_position - enemy.global_position
	var distance = to_target.length()
	var preferred_distance = movement_params.get("preferred_distance", 300.0)
	
	# Calculate strafe direction that changes periodically
	var time = Time.get_ticks_msec() / 1000.0
	var strafe_direction = to_target.rotated(PI/2 * sign(sin(time * 0.5)))
	
	if distance < preferred_distance * 0.8:
		# Retreat while strafing when too close
		return (-to_target + strafe_direction * 0.5).normalized() * 1.5
	elif distance > preferred_distance * 1.2:
		# Approach while strafing when too far
		return (to_target + strafe_direction * 0.3).normalized()
	else:
		# Strafe when at good distance
		return strafe_direction.normalized()

func get_behavior_name() -> String:
	return BehaviorType.keys()[current_behavior]

func print_debug_info(enemy: Node2D):
	var behavior_name = BehaviorType.keys()[current_behavior]
	var enemy_pos = enemy.global_position
	var target_pos = target.global_position if target else Vector2.ZERO
	var distance = target_pos.distance_to(enemy_pos) if target else 0.0
	var color = enemy.get_node("MeshInstance2D").material.get_shader_parameter("shape_0_color")
	
	var debug_msg = []
	debug_msg.append("\nBehavior Debug [%s] (Color: %s):" % [behavior_name, color])
	debug_msg.append("- Target Present: %s" % (target != null))
	debug_msg.append("- Position: %s" % enemy_pos)
	debug_msg.append("- Distance to target: %.1f" % distance)
	debug_msg.append("- Movement Direction: %s (%.2f)" % [last_direction, last_direction.length()])
	
	match current_behavior:
		BehaviorType.CHASE:
			debug_msg.append("- Chase Status: %s" % 
				("Maintaining Distance" if distance < min_distance * 2 else "Pursuing"))
			
		BehaviorType.CIRCLE:
			var orbit_distance = movement_params.get("orbit_distance", 200.0)
			debug_msg.append("- Orbit Distance (Current/Target): %.1f/%.1f" % [distance, orbit_distance])
			debug_msg.append("- Orbit Direction: %s" % ("Clockwise" if movement_params.get("clockwise", true) else "Counter-Clockwise"))
		
		BehaviorType.ZIGZAG:
			var phase = sin(Time.get_ticks_msec() / 1000.0 * movement_params.get("frequency", 4.0))
			debug_msg.append("- Zigzag Phase: %.2f" % phase)
			debug_msg.append("- Frequency: %.1f, Amplitude: %.1f" % [movement_params.get("frequency", 4.0), movement_params.get("amplitude", 1.0)])
		
		BehaviorType.SHOOT_AND_RETREAT:
			var preferred_distance = movement_params.get("preferred_distance", 300.0)
			var status = "Retreating" if distance < preferred_distance * 0.8 else "Approaching" if distance > preferred_distance * 1.2 else "Strafing"
			debug_msg.append("- Preferred Distance: %.1f (Current: %.1f)" % [preferred_distance, distance])
			debug_msg.append("- Status: %s" % status)
	
	# Store and print debug lines
	debug_lines = debug_msg
	for line in debug_msg:
		print(line)

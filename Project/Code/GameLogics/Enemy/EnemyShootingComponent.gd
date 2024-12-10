class_name EnemyShootingComponent
extends Node

enum ShootingPattern {
	SINGLE,
	BURST,
	SPREAD,
	CIRCLE
}

# Shooting properties
var pattern: ShootingPattern = ShootingPattern.SINGLE
var base_damage: float = 10.0
var base_speed: float = 200.0
var fire_rate: float = 1.0
var spread_angle: float = 30.0
var bullet_size: Vector2 = Vector2(2, 2)
var spawn_offset: float = 25.0

# Pattern-specific properties
var burst_count: int = 1
var burst_delay: float = 0.5
var spread_count: int = 1

# State
var can_fire: bool = true
var parent_enemy: Node2D
var bullet_system: Node
var burst_timer: Timer
var fire_timer: Timer
var burst_shots_remaining: int = 0

func _ready():
	print("Setting up shooting component...")
	parent_enemy = get_parent()
	bullet_system = get_node("/root/MainGame/BulletSystem")
	if bullet_system:
		print("Found bullet system")
	else:
		push_error("Bullet system not found!")
	setup_timers()

func setup_timers():
	fire_timer = Timer.new()
	fire_timer.one_shot = true
	fire_timer.connect("timeout", Callable(self, "_on_fire_timer_timeout"))
	add_child(fire_timer)
	
	burst_timer = Timer.new()
	burst_timer.one_shot = true
	burst_timer.connect("timeout", Callable(self, "_on_burst_timer_timeout"))
	add_child(burst_timer)

func execute_pattern(target_pos: Vector2):
	if not can_fire:
		return
	
	print("Executing shooting pattern: ", ShootingPattern.keys()[pattern])
		
	match pattern:
		ShootingPattern.SINGLE:
			shoot_single(target_pos)
		ShootingPattern.BURST:
			start_burst(target_pos)
		ShootingPattern.SPREAD:
			shoot_spread(target_pos)
		ShootingPattern.CIRCLE:
			shoot_circle()
	
	can_fire = false
	fire_timer.start(1.0 / fire_rate)

func create_bullet_properties(direction: Vector2) -> Dictionary:
	if not parent_enemy or not parent_enemy.get_node("MeshInstance2D"):
		push_error("Missing required nodes for bullet properties!")
		return {}

	var bullet_color = parent_enemy.get_node("MeshInstance2D").material.get_shader_parameter("shape_0_color")
	return {
		"direction": direction,
		"speed": base_speed,
		"damage": base_damage,
		"size": bullet_size,
		"color": bullet_color,  # Use enemy's color
		"particle_trail_enabled": false,
		"line_trail_enabled": true,
		"line_trail_length": 7,
		"line_trail_width": 3.0,
		"line_trail_color": bullet_color,
		"player_number": 0,
		"from_enemy": true
	}
	
func get_spawn_position(direction: Vector2) -> Vector2:
	return parent_enemy.global_position + direction * spawn_offset

func shoot_single(target_pos: Vector2):
	var direction = (target_pos - parent_enemy.global_position).normalized()
	if bullet_system:
		print("Firing single bullet at target")
		bullet_system.create_bullet(
			get_spawn_position(direction),
			direction,
			create_bullet_properties(direction)
		)

func start_burst(target_pos: Vector2):
	print("Starting burst of ", burst_count, " shots")
	burst_shots_remaining = burst_count
	shoot_burst(target_pos)

func shoot_burst(target_pos: Vector2):
	if burst_shots_remaining > 0:
		shoot_single(target_pos)
		burst_shots_remaining -= 1
		if burst_shots_remaining > 0:
			burst_timer.start(burst_delay)

func shoot_spread(target_pos: Vector2):
	print("Firing spread with ", spread_count, " bullets at ", spread_angle, " degrees")
	var base_direction = (target_pos - parent_enemy.global_position).normalized()
	var half_angle = deg_to_rad(spread_angle / 2)
	
	for i in range(spread_count):
		var t = float(i) / (spread_count - 1)
		var angle = lerp(-half_angle, half_angle, t)
		var direction = base_direction.rotated(angle)
		
		if bullet_system:
			bullet_system.create_bullet(
				get_spawn_position(direction),
				direction,
				create_bullet_properties(direction)
			)

func shoot_circle():
	print("Firing circle pattern")
	for i in range(8):
		var angle = i * PI / 4
		var direction = Vector2.RIGHT.rotated(angle)
		
		if bullet_system:
			bullet_system.create_bullet(
				get_spawn_position(direction),
				direction,
				create_bullet_properties(direction)
			)

func _on_fire_timer_timeout():
	can_fire = true

func _on_burst_timer_timeout():
	if parent_enemy and parent_enemy.player_manager:
		var target = parent_enemy.player_manager.get_closest_player(parent_enemy.global_position)
		if target:
			shoot_burst(target.global_position)

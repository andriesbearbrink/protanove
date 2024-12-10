extends RigidBody2D
class_name RigidEnemy

@export var exp_drop: int = 1
@export var exp_orb_scene: PackedScene

@export var exp_orb_count: int = 5  # Number of orbs to spawn
@export var exp_orb_spread: float = 0.0  # How far orbs spread from death position
@export var exp_orb_min_value: int = 1  # Minimum value per orb
@export var exp_orb_max_value: int = 1  # Maximum value per orb
@export var exp_orb_speed: float = 100.0  # Initial scatter speed for orbs

var last_hit_by_player: int = 0
var enemy_type: String = "rigid"
var player_manager: Node = null
var is_initialized: bool = false
var is_dead: bool = false

# Base stats
var health: int = 50
var max_speed: float = 300.0
var acceleration: float = 150.0
var size_scale: float = 1.0


# Behavior component reference
var behavior_component: EnemyBehaviorComponent = null


# Movement and targeting
var current_target_pos: Vector2 = Vector2.ZERO
var current_direction: Vector2 = Vector2.ZERO
var distance_to_player: float = INF

# Shooting properties
var can_shoot: bool = false
var shooting_probability: float = 0.0
var shooting_component: EnemyShootingComponent

# Performance optimization
var frame_count: int = 0
var update_frequency: int = 60
const DISTANCE_THRESHOLDS = [100, 200, 400, 800]
const UPDATE_FREQUENCIES = [10, 20, 30, 60]

func _ready():
	setup_collision_shape()
	setup_physics_layers()
	setup_collision_monitoring()
	
func _physics_process(delta):
	if not is_initialized or is_dead:
		return

	frame_count += 1
	
	# Update targeting and behavior
	if behavior_component and player_manager:
		var closest_player = player_manager.get_closest_player(global_position)
		if closest_player:
			# Debug print every second
			if frame_count % 60 == 0:
				print("\nEnemy Physics Debug:")
				print("- Type: ", get_behavior_name())
				print("- Position: ", global_position)
				print("- Target Position: ", closest_player.global_position)
				print("- Current Velocity: ", linear_velocity)
				print("- Target Found: ", closest_player != null)
			
			behavior_component.target = closest_player
			# Get movement direction from behavior
			current_direction = behavior_component.update_movement(self, delta)
			
			# Apply the movement using forces
			var movement_force = current_direction * acceleration
			apply_central_force(movement_force)
			if frame_count % 60 == 0:
				print("- Current Direction: ", current_direction)
				print("- Applied Force: ", movement_force)
			
			# Update rotation to face movement direction
			if linear_velocity.length() > 0.1:
				var target_angle = linear_velocity.angle()
				var angle_diff = target_angle - rotation
				angle_diff = fmod(angle_diff + PI, 2*PI) - PI
				angular_velocity = angle_diff * 10
			
			# Limit velocity
			if linear_velocity.length() > max_speed:
				linear_velocity = linear_velocity.normalized() * max_speed
	else:
		if frame_count % 60 == 0:
			print("Enemy Physics Error:")
			print("- Behavior Component: ", behavior_component != null)
			print("- Player Manager: ", player_manager != null)
	
	# Handle shooting if enabled
	if frame_count % update_frequency == 0:
		if can_shoot and shooting_component:
			try_shoot()
		adjust_update_frequency()

func get_behavior_name() -> String:
	if behavior_component:
		return behavior_component.get_behavior_name()
	return "NO_BEHAVIOR"

func setup_collision_shape():
	var shape = CircleShape2D.new()
	shape.radius = 10  # Base radius, will be adjusted by size_scale
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	add_child(collision_shape)

func setup_physics_layers():
	add_to_group("enemy")
	set_collision_layer_value(2, true)  # Enemy layer
	set_collision_mask_value(1, true)   # Player layer
	set_collision_mask_value(2, true)   # Enemy layer
	set_collision_mask_value(3, true)   # Bullet layer

func setup_collision_monitoring():
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func initialize(type: String, start_position: Vector2, p_manager: Node):
	enemy_type = type
	global_position = start_position
	player_manager = p_manager
	
	# Make sure base initialization is done first
	is_initialized = true
	
	if behavior_component:
		print("RigidEnemy: Successfully initialized with behavior: ", behavior_component.get_behavior_name())
		print("RigidEnemy: Initial target: ", player_manager.get_closest_player(global_position))
	else:
		push_error("RigidEnemy: No behavior component found!")

	print("RigidEnemy initialized with type:", type, " at position:", start_position)

func setup_shooting():
	if can_shoot:
		print("Setting up shooting component...")
		shooting_component = EnemyShootingComponent.new()
		add_child(shooting_component)
		
		# Configure based on enemy properties
		shooting_component.base_damage = 10.0
		shooting_component.base_speed = 200.0
		shooting_component.fire_rate = randf_range(0.5, 2.0)
		
		# Randomly select a shooting pattern
		var patterns = EnemyShootingComponent.ShootingPattern.values()
		shooting_component.pattern = patterns[randi() % patterns.size()]
		
		# Modify pattern properties based on the selected pattern
		match shooting_component.pattern:
			EnemyShootingComponent.ShootingPattern.SPREAD:
				shooting_component.spread_count = randi_range(3, 5)
				shooting_component.spread_angle = randf_range(20, 30)
			EnemyShootingComponent.ShootingPattern.BURST:
				shooting_component.burst_count = randi_range(2, 4)
				shooting_component.burst_delay = randf_range(0.1, 0.2)
		
		print("Shooting component configured with pattern: ", EnemyShootingComponent.ShootingPattern.keys()[shooting_component.pattern])

func update_target():
	if player_manager:
		var closest_player = player_manager.get_closest_player(global_position)
		if closest_player:
			current_target_pos = closest_player.global_position
			current_direction = (current_target_pos - global_position).normalized()
			distance_to_player = global_position.distance_to(current_target_pos)

func try_shoot():
	if not can_shoot or not shooting_component:
		return
		
	var SHOOTING_RANGE = 500.0
	update_target()  # Make sure distance_to_player is updated
	
	if distance_to_player < SHOOTING_RANGE:
		var target = player_manager.get_closest_player(global_position)
		if target:
			print("Attempting to shoot at player, distance: ", distance_to_player)
			shooting_component.execute_pattern(target.global_position)

func update_behavior():
	if behavior_component and player_manager:
		var closest_player = player_manager.get_closest_player(global_position)
		if closest_player:
			behavior_component.target = closest_player
			distance_to_player = global_position.distance_to(closest_player.global_position)

func adjust_update_frequency():
	for i in range(DISTANCE_THRESHOLDS.size()):
		if distance_to_player <= DISTANCE_THRESHOLDS[i]:
			update_frequency = UPDATE_FREQUENCIES[i]
			return
	update_frequency = UPDATE_FREQUENCIES[-1]

func _on_shoot_timer_timeout():
	if can_shoot and randf() < shooting_probability:
		attempt_shoot()

func attempt_shoot():
	if player_manager:
		var target = player_manager.get_closest_player(global_position)
		if target:
			var direction = (target.global_position - global_position).normalized()
			# Emit signal or call method to create bullet
			# Implementation depends on your bullet system
			if get_parent() and get_parent().has_method("spawn_enemy_bullet"):
				get_parent().spawn_enemy_bullet(global_position, direction)
				
				

func take_damage(amount: int, player_number: int = 0):
	health -= amount
	if player_number != 0:
		last_hit_by_player = player_number
	
	# Visual feedback
	flash()
	
	# Apply knockback
	if player_manager:
		var source = player_manager.get_player(player_number - 1)
		if source:
			var knockback_dir = (global_position - source.global_position).normalized()
			apply_central_impulse(knockback_dir * 200)  # Adjust force as needed
	
	# Sound effect
	if SoundManager.get_instance():
		SoundManager.get_instance().enemy_sound_system.play_hit_sound(enemy_type, global_position)
	
	if health <= 0:
		die()

func get_health() -> int:
	return health

func apply_knockback(force: Vector2):
	apply_central_impulse(force)

func _on_body_entered(body: Node) -> void:
	if body is PushableEntity:
		# Handle collision damage
		body.take_damage(10)
		
		# Apply knockback to both entities
		var collision_dir = (body.global_position - global_position).normalized()
		body.apply_knockback(collision_dir * 2.5)
		apply_central_impulse(-collision_dir * 70)
		
		# Update last hit player if applicable
		if body is BasePlayer:
			last_hit_by_player = body.player_number
			take_damage(20, last_hit_by_player)

func die():
	if is_dead:
		return
	is_dead = true
	
	if get_parent() and get_parent().has_method("on_enemy_died"):
		get_parent().on_enemy_died(self)
	
	queue_free()

func flash():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

# Utility methods
# Add this function to the RigidEnemy class
func set_base_stats(stats: Dictionary):
	if stats.has("health"): health = stats.health
	if stats.has("max_speed"): max_speed = stats.max_speed
	if stats.has("acceleration"): acceleration = stats.acceleration
	if stats.has("size"): 
		size_scale = stats.size
		scale = Vector2.ONE * size_scale
	if stats.has("shooting_chance"):
		shooting_probability = stats.shooting_chance
		can_shoot = shooting_probability > 0
	if stats.has("linear_damp"):
		linear_damp = stats.linear_damp
	if stats.has("color"):
		var mesh = $MeshInstance2D
		if mesh and mesh.material:
			var material = mesh.material as ShaderMaterial
			if material:
				material = material.duplicate()
				material.set_shader_parameter("shape_0_color", stats.color)
				material.set_shader_parameter("shape_1_color", stats.color.darkened(0.2))
				mesh.material = material
				
	# Set RigidBody2D properties for better physics behavior
	gravity_scale = 0.0  # No gravity
	contact_monitor = true
	max_contacts_reported = 4
	linear_velocity = Vector2.ZERO  # Start stationary

func should_despawn() -> bool:
	return health <= 0

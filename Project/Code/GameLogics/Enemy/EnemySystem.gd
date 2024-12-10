extends Node2D

const MAX_ENEMIES = 1000  # Adjust based on your game's needs
var enemy_pool = []
var active_enemies = []

var EnemyBase = preload("res://Code/GameLogics/Enemy/EnemyBase.gd")
var enemy_scene = preload("res://Code/GameLogics/Enemy/EnemyBase.tscn")
var rigid_enemy_scene = preload("res://Code/GameLogics/Enemy/EnemyRigid.tscn")
var RigidEnemy = preload("res://Code/GameLogics/Enemy/EnemyRigid.gd")
var experience_orb_scene = preload("res://Code/GameLogics/Exp/ExperienceOrb.tscn")

var player_manager: Node

func _ready():
	initialize_enemy_pool()
	
	# Get reference to PlayerManager
	player_manager = get_node("/root/MainGame/PlayerManager")
	if not player_manager:
		push_error("PlayerManager not found. Ensure the path is correct.")

func handle_explosion(explosion_position: Vector2, explosion_radius: float, explosion_force: float):
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			var distance = enemy.global_position.distance_to(explosion_position)
			if distance <= explosion_radius:
				var direction = (enemy.global_position - explosion_position).normalized()
				var force = explosion_force * (1 - distance / explosion_radius)
				if force > 0.01:
					var impulse = direction * force
					enemy.apply_central_impulse(impulse)

func initialize_enemy_pool():
	for i in range(MAX_ENEMIES):
		var enemy = enemy_scene.instantiate()
		enemy.set_physics_process(false)
		enemy_pool.append(enemy)

func spawn_enemy(enemy_type: String, position: Vector2, spawn_data: Dictionary = {}):
	var enemy
	if enemy_type == "rigid":
		enemy = rigid_enemy_scene.instantiate()
	else:
		print("Warning: Unknown enemy type")
		return null

	# Add enemy to scene first
	add_child(enemy)
	
	# Set base properties if provided
	if spawn_data.has("properties"):
		enemy.set_base_stats(spawn_data.properties)
		
		# Setup shooting if enabled
		if spawn_data.properties.get("shooting_chance", 0.0) > 0:
			print("Setting up shooting for enemy with probability: ", spawn_data.properties.shooting_chance)
			enemy.shooting_probability = spawn_data.properties.shooting_chance
			enemy.can_shoot = true
			enemy.setup_shooting()  # This should create the shooting component
			print("Shooting component created: ", enemy.shooting_component != null)

	# Create and attach behavior component
	if spawn_data.has("behavior_type"):
		print("Creating behavior component for ", enemy_type)
		var behavior = EnemyBehaviorComponent.new(
			spawn_data.behavior_type,
			spawn_data.get("behavior_params", {})
		)
		enemy.add_child(behavior)
		enemy.behavior_component = behavior

	# Initialize the enemy last (after all components are set up)
	enemy.initialize(enemy_type, position, player_manager)

	return enemy

func configure_enemy_properties(enemy: Node, properties: Dictionary):
	# Configure size
	if properties.has("size"):
		enemy.scale = Vector2.ONE * properties.size
	
	# Configure movement properties
	if properties.has("acceleration"):
		enemy.acceleration = properties.acceleration
	if properties.has("top_speed"):
		enemy.max_speed = properties.top_speed
	
	# Configure health
	if properties.has("health"):
		enemy.health = properties.health
	
	# Configure shooting behavior if applicable
	if properties.has("shooting_chance") and properties.shooting_chance > 0:
		setup_enemy_shooting(enemy, properties.shooting_chance)

func setup_enemy_shooting(enemy: Node, shooting_chance: float):
	
	enemy.can_shoot = true
	enemy.shooting_probability = shooting_chance
	# Add any other shooting-related setup here

func on_enemy_died(enemy):
	print("EnemySystem: on_enemy_died called for enemy at position ", enemy.global_position)
	
	if SoundManager.get_instance():
		SoundManager.get_instance().enemy_sound_system.play_death_sound("basic", enemy.global_position)
	
	if enemy.last_hit_by_player != 0:
		var exp_value = enemy.exp_drop if "exp_drop" in enemy else 1
		# Get orb spawn properties from the enemy
		var orb_count = enemy.exp_orb_count if "exp_orb_count" in enemy else 1
		var orb_spread = enemy.exp_orb_spread if "exp_orb_spread" in enemy else 50.0
		var orb_speed = enemy.exp_orb_speed if "exp_orb_speed" in enemy else 100.0
		
		spawn_experience_orb(
			enemy.global_position,
			exp_value,
			orb_count,
			orb_spread,
			orb_speed
		)
		add_kill_to_player(enemy.last_hit_by_player)
	
	despawn_enemy(enemy)

func add_kill_to_player(player_number: int):
	if player_manager:
		var player = player_manager.get_player(player_number - 1)
		if player and player.has_method("add_kill"):
			player.add_kill()
			print("Kill added to Player ", player_number)
		else:
			push_error("Failed to add kill to Player ", player_number)
	else:
		push_error("PlayerManager not found. Unable to add kill to player.")

func despawn_enemy(enemy):
	var index = active_enemies.find(enemy)
	if index != -1:
		active_enemies.remove_at(index)

	if enemy in enemy_pool:
		enemy_pool.erase(enemy)

	enemy.queue_free()

func spawn_experience_orb(position: Vector2, exp_value: int, count: int = 1, spread: float = 50.0, speed: float = 100.0):
	if experience_orb_scene:
		for i in range(count):
			var orb = experience_orb_scene.instantiate()
			
			# Calculate random position offset
			var angle = randf() * 2 * PI
			var distance = randf() * spread
			var offset = Vector2(cos(angle), sin(angle)) * distance
			
			# Set orb properties
			orb.global_position = position + offset
			
			# If count > 1, distribute the exp_value across orbs
			var orb_value = exp_value / count
			if orb_value < 1:
				orb_value = 1  # Ensure minimum value of 1
			
			orb.set_exp_value(orb_value)
			
			# Set initial velocity for scattering effect
			var velocity = offset.normalized() * speed
			if orb.has_method("set_initial_velocity"):
				orb.set_initial_velocity(velocity)
			
			call_deferred("add_child", orb)
	else:
		push_error("Experience orb scene not set in EnemySystem")

func get_active_enemies() -> Array:
	return active_enemies

func clear_all_enemies():
	for enemy in active_enemies.duplicate():
		despawn_enemy(enemy)
	enemy_pool.clear()

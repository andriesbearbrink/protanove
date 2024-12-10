class_name RIDBullet
extends RefCounted

var player_number: int = 0
var velocity: Vector2
var position: Vector2
var active: bool
var last_position: Vector2
var player_velocity: Vector2 = Vector2.ZERO
var initial_speed: float
var initial_direction: Vector2

var relative_velocity: Vector2  # Velocity relative to the player

# Visual properties
var size: Vector2 = Vector2(1.0, 1.0)
var color: Color = Color.WHITE

# Particle trail properties
var particle_trail_enabled: bool = true
var particle_trail_lifetime: float = 0.5
var particle_trail_spread: float = 10.0
var particle_trail_color: Color = Color.WHITE

# Line trail properties
var line_trail_enabled: bool = false
var line_trail_length: int = 10
var line_trail_width: float = 2.0
var line_trail_color: Color = Color.WHITE
var last_trail_position: Vector2

# Impact effect properties
var impact_effect_enabled: bool = true
var impact_effect_lifetime: float = 0.3
var impact_effect_size: float = 20.0
var impact_effect_color: Color = Color.WHITE

# Bullet properties
var drag: float
var speed: float
var homing: float  # 0 to 1, where 1 is full homing capability
var distance: float
var penetration: int
var ricochet: int
var damage: int
var penetrates: bool = false  # Whether the bullet can penetrate or not

# Explosion properties
var is_explosive: bool = false
var explosion_size: float = 0.0
var explosion_damage: int = 0
var explosion_force: float = 0.0

# Fragmentation properties
var fragmentation_count: int = 0
var fragmentation_explosive: bool = false
var fragmentation_damage: int = 0
var fragmentation_level: int = 0
var fragmentation_homing: float = 0.0

var target: WeakRef  # For homing functionality
var bullet_system: WeakRef  # WeakRef to avoid circular references



var screen_size: Vector2 = Vector2.ZERO

var frame_count: int = 0

func _init():
	active = false

func reset(pos: Vector2, vel: Vector2, properties: Dictionary):
	player_number = properties.get("player_number", 0)
	player_velocity = properties.get("player_velocity", Vector2.ZERO)
	position = pos
	velocity = vel
	#print("Resetting bullet at position: ", position, " with velocity: ", velocity)
	
	drag = properties.get("drag", 0.02)
	speed = properties.get("speed", velocity.length())  # Get speed from velocity if not provided
	homing = properties.get("homing", 0.0)
	size = properties.get("size", Vector2(1.0, 1.0))
	distance = properties.get("distance", 1000.0)
	penetration = properties.get("penetration", 1)
	ricochet = properties.get("ricochet", 0)
	damage = properties.get("damage", 10)
	color = properties.get("color", Color.WHITE)

	is_explosive = properties.get("is_explosive", false)
	explosion_size = properties.get("explosion_size", 10.0)
	explosion_damage = properties.get("explosion_damage", damage)
	explosion_force = properties.get("explosion_force", 100.0)

	fragmentation_count = properties.get("fragmentation_count", 0)
	fragmentation_explosive = properties.get("fragmentation_explosive", false)
	fragmentation_damage = properties.get("fragmentation_damage", damage / 2)
	fragmentation_level = properties.get("fragmentation_level", 0)
	fragmentation_homing = properties.get("fragmentation_homing", 0.0)
	
	# Set visual properties
	size = properties.get("size", Vector2(1.0, 1.0))
	color = properties.get("color", Color.WHITE)

	# Set particle trail properties
	particle_trail_enabled = properties.get("particle_trail_enabled", true)
	particle_trail_lifetime = properties.get("particle_trail_lifetime", 0.5)
	particle_trail_spread = properties.get("particle_trail_spread", 10.0)
	particle_trail_color = properties.get("particle_trail_color", Color.WHITE)
	last_trail_position = pos

	# Set line trail properties
	line_trail_enabled = properties.get("line_trail_enabled", false)
	line_trail_length = properties.get("line_trail_length", 10)
	line_trail_width = properties.get("line_trail_width", 2.0)
	line_trail_color = properties.get("line_trail_color", Color.WHITE)

	# Set impact effect properties
	impact_effect_enabled = properties.get("impact_effect_enabled", true)
	impact_effect_lifetime = properties.get("impact_effect_lifetime", 0.3)
	impact_effect_size = properties.get("impact_effect_size", 20.0)
	impact_effect_color = properties.get("impact_effect_color", Color.WHITE)
	
	active = true
	target = WeakRef.new()
	frame_count = 0
#	print("Bullet reset complete. Active: ", active, ", Speed: ", speed)
#	print("RIDBullet: Reset with color: ", color)

func set_screen_size(size: Vector2):
	screen_size = size

func update(delta: float, enemies: Array) -> bool:
	position += velocity * delta
	
	frame_count += 1

	if homing > 0 and frame_count % 15 == 0:
		update_homing(delta, enemies)

	# Apply drag less aggressively
	velocity = velocity.lerp(Vector2.ZERO, drag * delta)

	last_position = position
	
	# Check for screen wrapping
	if screen_size != Vector2.ZERO:
		var new_position = position
		if new_position.x < 0:
			new_position.x += screen_size.x
		elif new_position.x > screen_size.x:
			new_position.x -= screen_size.x
		if new_position.y < 0:
			new_position.y += screen_size.y
		elif new_position.y > screen_size.y:
			new_position.y -= screen_size.y
		
		if new_position != position:
			emit_warped(position, new_position)
	
		position = new_position
	
	distance -= velocity.length() * delta

	return distance <= 0

func emit_warped(old_position: Vector2, new_position: Vector2):
	var system = bullet_system.get_ref()
	if system and system.has_method("on_bullet_warped"):
		system.on_bullet_warped(self, old_position, new_position)
		
func update_homing(delta: float, enemies: Array):
	var closest_enemy = find_closest_enemy(enemies)
	if closest_enemy:
	#	print("Homing towards enemy at position: ", closest_enemy.global_position)
		var to_target = (closest_enemy.global_position - position).normalized()
		var current_speed = velocity.length()  # Preserve the current speed
		var homing_strength = homing * delta * 15  # Adjusted for 15-frame interval
		
		# Lerp the direction, not the velocity
		var new_direction = velocity.normalized().lerp(to_target, homing_strength)
		
		# Apply the new direction while maintaining speed
		velocity = new_direction.normalized() * current_speed
	else:
		print("No valid enemy found for homing")
	
func find_closest_enemy(enemies: Array):
	var closest_distance = INF
	var closest_enemy = null
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("is_in_group") and enemy.is_in_group("enemy"):
			var enemy_distance = position.distance_to(enemy.global_position)
			if enemy_distance < closest_distance:
				closest_distance = enemy_distance
				closest_enemy = enemy
		else:
			print("Invalid or non-enemy object in enemies array: ", enemy)
	return closest_enemy

func set_bullet_system(system: Node):
	bullet_system = weakref(system)

func handle_collision(collider) -> bool:

	if collider != null and is_instance_valid(collider):
		if collider.has_method("take_damage") and collider.has_method("get_health"):
			var enemy_health = collider.get_health()
			var damage_dealt = min(damage, enemy_health)

			# Reduce bullet damage by the actual damage dealt
			damage -= damage_dealt
			
			# Apply knockback if the collider is a RigidEnemy or BasePlayer
			if collider is RigidEnemy or collider is BasePlayer:
				var knockback_force = velocity.normalized() * 1  # Adjust force as needed
				if collider.has_method("apply_knockback"):
					collider.apply_knockback(knockback_force)
				elif collider is RigidBody2D:
					collider.apply_central_impulse(knockback_force)

	var should_destroy = damage <= 0 or not penetrates

	if ricochet > 0 and should_destroy:
		# Handle ricochet
		var collision_normal = (collider.global_position - position).normalized()
		velocity = velocity.reflect(collision_normal)
		velocity = velocity.rotated(randf_range(-PI/8, PI/8))  # Add some randomness
		ricochet -= 1
		should_destroy = false
		# Don't reset damage for ricochet, keep the remaining damage
	return should_destroy

func explode():
	var system = bullet_system.get_ref()
	if system and system.has_method("handle_explosion"):
		system.handle_explosion(last_position, explosion_size, explosion_damage, explosion_force)

func fragment():
	var system = bullet_system.get_ref()
	if system and system.has_method("create_fragments"):
		system.create_fragments(last_position, self)

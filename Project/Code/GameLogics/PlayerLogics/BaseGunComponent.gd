extends Node
class_name BaseGunComponent

signal gun_fired(spawn_positions: Array, bullet_properties: Dictionary)

# Base gun properties
@export var base_fire_rate: float = 1.0  # Shots per second
@export var base_bullet_count: int = 1    # Number of bullets per shot
@export var base_spread_angle: float = 45 # Spread angle in degrees

# Base bullet properties
@export var base_bullet_speed: float = 600.0
@export var base_bullet_damage: float = 100.0
@export var base_bullet_size: Vector2 = Vector2(2, 2)

# Current gun properties
var current_fire_rate: float
var current_bullet_count: int
var current_spread_angle: float

# Fire rate tracking
var can_fire: bool = true
var fire_timer: Timer

# Property multipliers
var fire_rate_multiplier: float = 1.0
var bullet_count_multiplier: float = 1.0
var spread_multiplier: float = 1.0
var bullet_speed_multiplier: float = 1.0
var bullet_damage_multiplier: float = 1.0
var bullet_size_multiplier: float = 1.0

func _ready():
	setup_fire_timer()
	reset_to_base_stats()

func setup_fire_timer():
	fire_timer = Timer.new()
	fire_timer.one_shot = true
	fire_timer.connect("timeout", Callable(self, "_on_fire_timer_timeout"))
	add_child(fire_timer)

func reset_to_base_stats():
	current_fire_rate = base_fire_rate
	fire_rate_multiplier = 1.0
	current_bullet_count = base_bullet_count
	current_spread_angle = base_spread_angle
	update_fire_rate()

func try_shoot(spawn_position: Vector2, direction: Vector2, base_properties: Dictionary) -> bool:
	if not can_fire:
		return false

	var final_bullet_count = int(current_bullet_count * bullet_count_multiplier)
	var final_spread = current_spread_angle * spread_multiplier
	
	print("DEBUG: GunComponent: Shooting with:")
	print("  - Bullet count: ", final_bullet_count)
	print("  - Spread angle: ", final_spread)
	print("  - Damage multiplier: ", bullet_damage_multiplier)
	print("  - Speed multiplier: ", bullet_speed_multiplier)
	
	# Apply bullet property multipliers
	var modified_properties = base_properties.duplicate()
	if "speed" in modified_properties:
		modified_properties["speed"] *= bullet_speed_multiplier
	if "damage" in modified_properties:
		modified_properties["damage"] *= bullet_damage_multiplier
	if "size" in modified_properties:
		if modified_properties["size"] is Vector2:
			modified_properties["size"] *= bullet_size_multiplier
	
	# Calculate spread positions
	var spawn_positions = []
	var half_spread = final_spread / 2.0
	
	if final_bullet_count == 1:
		spawn_positions.append({
			"position": spawn_position,
			"direction": direction
		})
	else:
		for i in range(final_bullet_count):
			var angle = deg_to_rad(lerp(-half_spread, half_spread, float(i) / (final_bullet_count - 1)))
			var rotated_direction = direction.rotated(angle)
			spawn_positions.append({
				"position": spawn_position,
				"direction": rotated_direction
			})
	
	emit_signal("gun_fired", spawn_positions, modified_properties)
	can_fire = false
	fire_timer.start()
	return true

func _on_fire_timer_timeout():
	can_fire = true

# Modifier methods
func modify_fire_rate(multiplier: float):
	# Apply multiplier directly
	fire_rate_multiplier *= multiplier
	update_fire_rate()
	print("Gun: Fire rate multiplier updated to: ", fire_rate_multiplier)
	print("Gun: Shots per second: ", base_fire_rate * fire_rate_multiplier)

func update_fire_rate():
	# More shots per second = smaller interval
	var shots_per_second = base_fire_rate * fire_rate_multiplier
	fire_timer.wait_time = 1.0 / shots_per_second
	print("Gun: Timer interval set to: ", fire_timer.wait_time, "s")

func modify_bullet_speed(multiplier: float):
	bullet_speed_multiplier *= multiplier
	print("Gun: Bullet speed multiplier updated to: ", bullet_speed_multiplier)

func modify_bullet_damage(multiplier: float):
	bullet_damage_multiplier *= multiplier
	print("Gun: Bullet damage multiplier updated to: ", bullet_damage_multiplier)

func modify_bullet_size(multiplier: float):
	bullet_size_multiplier *= multiplier
	print("Gun: Bullet size multiplier updated to: ", bullet_size_multiplier)

func modify_bullet_count(multiplier: float):
	bullet_count_multiplier *= multiplier
	print("DEBUG: GunComponent: Bullet count multiplier updated to: ", bullet_count_multiplier)
	print("DEBUG: GunComponent: New bullet count: ", int(base_bullet_count * bullet_count_multiplier))

func modify_spread(multiplier: float):
	spread_multiplier *= multiplier
	print("Gun: Spread multiplier updated to: ", spread_multiplier)
	
func modify_bullet_spread(multiplier: float):
	spread_multiplier *= multiplier
	print("DEBUG: GunComponent: Spread multiplier updated to: ", spread_multiplier)
	print("DEBUG: GunComponent: Current spread angle: ", current_spread_angle * spread_multiplier)

# Reset all multipliers
func reset_multipliers():
	print("DEBUG: GunComponent: Resetting all multipliers")
	print("DEBUG: GunComponent: Previous values:")
	print("  - Fire rate: ", fire_rate_multiplier)
	print("  - Bullet count: ", bullet_count_multiplier)
	print("  - Bullet speed: ", bullet_speed_multiplier)
	print("  - Bullet damage: ", bullet_damage_multiplier)
	print("  - Bullet size: ", bullet_size_multiplier)
	
	fire_rate_multiplier = 1.0
	bullet_count_multiplier = 1.0
	spread_multiplier = 1.0
	bullet_speed_multiplier = 1.0
	bullet_damage_multiplier = 1.0
	bullet_size_multiplier = 1.0
	update_fire_rate()
	
	print("DEBUG: GunComponent: All multipliers reset to 1.0")

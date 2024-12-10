extends Node
class_name BaseWeaponComponent

signal weapon_fired(spawn_position: Vector2, bullet_properties: Dictionary)

@export var fire_rate: float = 1
@export var bullet_speed: float = 200.0
@export var bullet_damage: float = 25.0
@export var bullet_size: Vector2 = Vector2(2, 2)
@export var bullet_color: Color = Color.WHITE

var player: Node  # Reference to the player node
var can_fire: bool = true
var fire_timer: Timer

# Upgrade-related variables
var damage_multiplier: float = 1.0
var size_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var penetrates: bool = false  # New variable for penetration
var ricochet: int = 0
var homing: float = 0.0

# Special bullet properties
var is_explosive: bool = false
var explosion_size: float = 50.0
var explosion_damage: float = 0.0
var explosion_force: float = 0.1

# Fragmentation properties
var fragmentation_count: int = 0
var fragmentation_damage: float = 0.0
var fragmentation_level: int = 0
var fragmentation_explosive: bool = false
var fragmentation_homing: float = 0.0

# Explosion modifiers
var explosion_size_multiplier: float = 1.0
var explosion_damage_multiplier: float = 1.0
var explosion_force_multiplier: float = 1.0

# Bullet physics properties
var bullet_drag: float = 0.02

func _ready():
	setup_fire_timer()

func initialize(player_node: Node):
	player = player_node

func setup_fire_timer():
	fire_timer = Timer.new()
	fire_timer.one_shot = true
	fire_timer.connect("timeout", Callable(self, "_on_fire_timer_timeout"))
	add_child(fire_timer)

func try_shoot(direction: Vector2):
	if can_fire:
		shoot(direction)
		can_fire = false
		fire_timer.start(fire_rate)

func shoot(direction: Vector2):
	var spawn_position = player.bullet_spawn.global_position
	var bullet_properties = {
		"direction": direction.normalized(),
		"speed": bullet_speed * speed_multiplier,
		"damage": bullet_damage * damage_multiplier,
		"size": bullet_size * size_multiplier,
		"color": player.player_color,
		"ricochet": ricochet,
		"penetrates": penetrates,
		"homing": homing,
		"is_explosive": is_explosive,
		"explosion_size": explosion_size,
		"explosion_damage": explosion_damage,
		"explosion_force": explosion_force,
		"fragmentation_count": fragmentation_count,
		"fragmentation_damage": fragmentation_damage,
		"player_velocity": player.velocity if player else Vector2.ZERO,
		"player_number": player.player_number if player else 0,  # Add this line
		"particle_trail_color": player.player_color,  # Use player color for trail
		"line_trail_color": player.player_color  # Use player color for line trail

	}
	
	print("Creating bullet with player color: ", player.player_color)  # Add this debug print
	print("Creating bullet with player_number: ", bullet_properties.player_number)  # Debug print
	emit_signal("weapon_fired", spawn_position, bullet_properties)

# Update the get_bullet_properties method to include all new properties
func get_bullet_properties() -> Dictionary:
	return {
		"speed": bullet_speed,
		"damage": bullet_damage * damage_multiplier,
		"size": bullet_size * size_multiplier,
		"color": bullet_color,
		"drag": bullet_drag,
		"ricochet": ricochet,
		"penetrates": penetrates,
		"homing": homing,
		# Add explosion properties
		"is_explosive": is_explosive,
		"explosion_size": explosion_size * explosion_size_multiplier,
		"explosion_damage": explosion_damage * explosion_damage_multiplier,
		"explosion_force": explosion_force * explosion_force_multiplier,
		"fragmentation_count": fragmentation_count,
		"fragmentation_damage": fragmentation_damage,
		"fragmentation_level": fragmentation_level,
		"fragmentation_explosive": fragmentation_explosive,
		"fragmentation_homing": fragmentation_homing,
		"player_velocity": player.velocity if player else Vector2.ZERO,
		"player_number": player.player_number if player else 0,
		"particle_trail_color": player.player_color if player else Color.WHITE,
		"line_trail_color": player.player_color if player else Color.WHITE
	}

func _on_fire_timer_timeout():
	can_fire = true

# Upgrade methods

# Drag modification
func modify_bullet_drag(multiplier: float):
	bullet_drag *= multiplier
	print("Bullet drag modified by ", multiplier, ". New value: ", bullet_drag)

# Explosion modifications
func modify_explosion_size(multiplier: float):
	explosion_size_multiplier *= multiplier
	explosion_size = explosion_size * multiplier
	print("DEBUG: WeaponComponent: Explosion size updated to ", explosion_size)

func modify_explosion_damage(multiplier: float):
	explosion_damage_multiplier *= multiplier
	explosion_damage = explosion_damage * multiplier
	print("DEBUG: WeaponComponent: Explosion damage updated to ", explosion_damage)

func modify_explosion_force(multiplier: float):
	explosion_force_multiplier *= multiplier
	explosion_force = explosion_force * multiplier
	print("DEBUG: WeaponComponent: Explosion force updated to ", explosion_force)

# Explosion setters
func set_explosion_size(size: float):
	explosion_size = size
	print("Explosion size set to: ", explosion_size)

func set_explosion_damage(damage: float):
	explosion_damage = damage
	print("Explosion damage set to: ", explosion_damage)

func set_explosion_force(force: float):
	explosion_force = force
	print("Explosion force set to: ", explosion_force)

# Fragmentation setters
func set_fragmentation_count(count: int):
	fragmentation_count = count
	print("Fragmentation count set to: ", fragmentation_count)

func set_fragmentation_damage(damage: float):
	fragmentation_damage = damage
	print("Fragmentation damage set to: ", fragmentation_damage)

func set_fragmentation_level(level: int):
	fragmentation_level = level
	print("Fragmentation level set to: ", fragmentation_level)

func set_fragmentation_explosive(is_explosive_: bool):
	fragmentation_explosive = is_explosive_
	print("Fragmentation explosive set to: ", fragmentation_explosive)

func set_fragmentation_homing(homing_amount: float):
	fragmentation_homing = homing_amount
	print("Fragmentation homing set to: ", fragmentation_homing)

func increase_damage(percentage: float):
	damage_multiplier += percentage
	print("Weapon damage increased by ", percentage * 100, "%")

func increase_fire_rate(percentage: float):
	fire_rate *= (1 - percentage)
	print("Fire rate increased by ", percentage * 100, "%")

func increase_bullet_size(percentage: float):
	size_multiplier += percentage
	print("Bullet size increased by ", percentage * 100, "%")

func increase_bullet_speed(percentage: float):
	speed_multiplier += percentage
	print("Bullet speed increased by ", percentage * 100, "%")

# New function to set penetration
func set_penetration(can_penetrate: bool):
	penetrates = can_penetrate
	print("Bullet penetration set to: ", penetrates)

func increase_ricochet(amount: int):
	ricochet = min(ricochet + amount, 10)
	print("Bullet ricochet increased by ", amount, ". New value: ", ricochet)

func increase_homing(amount: float):
	homing = min(homing + amount, 1.0)
	print("Bullet homing increased by ", amount, ". New value: ", homing)

# Special bullet property methods
func set_explosive(is_explosive_: bool, size: float, damage: float, force: float):
	is_explosive = is_explosive_
	explosion_size = size
	explosion_damage = damage
	explosion_force = force
	print("DEBUG: WeaponComponent: Set explosive properties:")
	print("  - Size: ", explosion_size)
	print("  - Damage: ", explosion_damage)
	print("  - Force: ", explosion_force)

func set_fragmentation(count: int, damage: float):
	fragmentation_count = count
	fragmentation_damage = damage
	print("Fragmentation set to ", count, " fragments with ", damage, " damage each")

# Update the reset_upgrades method to include all new properties
func reset_upgrades():
	damage_multiplier = 1.0
	size_multiplier = 1.0
	speed_multiplier = 1.0
	bullet_drag = 0.02
	penetrates = false
	ricochet = 0
	homing = 0.0
	
	# Reset explosion properties
	is_explosive = false
	explosion_size = 50.0
	explosion_damage = 0.0
	explosion_force = 0.1
	
	explosion_size_multiplier = 1.0
	explosion_damage_multiplier = 1.0
	explosion_force_multiplier = 1.0
	
	# Reset fragmentation properties
	fragmentation_count = 0
	fragmentation_damage = 0.0
	fragmentation_level = 0
	fragmentation_explosive = false
	fragmentation_homing = 0.0
	
	print("All weapon upgrades reset")

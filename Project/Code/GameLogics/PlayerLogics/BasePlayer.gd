extends PushableEntity
class_name BasePlayer

enum PlayerState { ALIVE, DEAD, RESPAWNING }

var respawn_invulnerable_time: float = 1.0  # Time in seconds for respawn invulnerability
var respawn_push_force: float = 500.0  # Force to push away entities when respawning
var respawn_push_radius: float = 150.0  # Radius of the push effect

signal level_up(new_level: int)

var max_revives: int = 3  # Maximum number of times a player can revive
var revives_remaining: int = 3  # Current number of revives left

@export var player_number: int = 1
@export var max_health: float = 1000.0

var player_state: PlayerState = PlayerState.ALIVE
var player_name: String = "Player"
var player_color: Color = Color.WHITE
var pending_color_update: bool = false
var input_device: String = "keyboard_mouse"
var last_aim_vector: Vector2 = Vector2.RIGHT  # Default aim direction
var last_velocity: Vector2 = Vector2.ZERO
var current_thrust: float = 0.0

@onready var bullet_spawn = %BulletSpawn

var health_component: BaseHealthComponent
var input_component: BaseInputComponent
var weapon_component: BaseWeaponComponent
var perk_component: BasePerkComponent
var visual_component: BaseVisualComponent
var score_component: BaseScoreComponent
var gun_component: BaseGunComponent
var abilities_component: BaseAbilitiesComponent

var components_setup: bool = false

var respawn_timer: Timer
var screen_wrap_system: Node
var bullet_system: Node
var level_system: Node

var movement_speed_multiplier: float = 1.0

var post_process_rect: ColorRect
var base_motion_blur: float = 0.0
var max_motion_blur: float = 0.4
var motion_blur_acceleration: float = 5.0
var motion_blur_deceleration: float = 10.0
var current_motion_blur: float = 0.0

func _ready():
	super._ready()
	add_to_group("player")
	setup_components()
	setup_score_component()
	setup_timers()
	setup_systems()
	setup_collision()
	initialize_components()
	set_input_device(input_device)
	setup_player_sounds()
	print("BasePlayer: Player ", player_number, " ready")
	post_process_rect = get_node("/root/MainGame/CanvasLayer/PostProcessRect")

func setup_components():
	health_component = BaseHealthComponent.new()
	input_component = BaseInputComponent.new()
	weapon_component = BaseWeaponComponent.new()
	perk_component = BasePerkComponent.new()
	visual_component = BaseVisualComponent.new()
	gun_component = BaseGunComponent.new()
	abilities_component = BaseAbilitiesComponent.new()  # Add this line

	
	add_child(gun_component)
	add_child(health_component)
	add_child(input_component)
	add_child(weapon_component)
	add_child(perk_component)
	add_child(visual_component)
	add_child(abilities_component)  # Add this line

func initialize_components():
	health_component.initialize(self)
	input_component.initialize(self)
	weapon_component.initialize(self)
	perk_component.initialize(self)
	visual_component.initialize(self)
	abilities_component.initialize(self)  # Add this line
	
	# Disconnect any existing connections first
	if gun_component.is_connected("gun_fired", Callable(self, "_on_gun_fired")):
		gun_component.disconnect("gun_fired", Callable(self, "_on_gun_fired"))
	
	gun_component.connect("gun_fired", Callable(self, "_on_gun_fired"))
	
	# Connect signals after initialization, but first disconnect any existing connections
	var signals_to_connect = [
		[health_component, "health_changed", "_on_health_changed"],
		[health_component, "player_died", "_on_player_died"],
		[input_component, "movement_input", "_on_movement_input"],
		[input_component, "aim_input", "_on_aim_input"],
		[input_component, "shoot_input", "_on_shoot_input"],
		[weapon_component, "weapon_fired", "_on_weapon_fired"],
		[perk_component, "perk_acquired", "_on_perk_acquired"],
		[visual_component, "appearance_updated", "_on_appearance_updated"],
		[abilities_component, "ability_used", "_on_ability_used"],           # Add these
		[abilities_component, "ability_ready", "_on_ability_ready"],         # three
		[abilities_component, "ability_cooldown_updated", "_on_ability_cooldown_updated"]  # lines
	]
	
	for signal_info in signals_to_connect:
		var component = signal_info[0]
		var signal_name = signal_info[1]
		var method_name = signal_info[2]
		
		if component.is_connected(signal_name, Callable(self, method_name)):
			component.disconnect(signal_name, Callable(self, method_name))
		
		component.connect(signal_name, Callable(self, method_name))
		
func setup_player_sounds():
	if not SoundManager.get_instance():
		return
		
	var sound_system = SoundManager.get_instance().player_sound_system
	
	# Connect gun firing sounds to the gun_component instead of weapon_component
	gun_component.connect("gun_fired", 
		func(_spawn_positions, _bullet_properties): 
			sound_system.play_weapon_sound("shoot"))
	
	# Connect damage sounds
	health_component.connect("health_changed", 
		func(new_health, _max_health): 
			if new_health < health_component.current_health:
				sound_system.play_state_sound("hurt"))
				

func setup_timers():
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.connect("timeout", Callable(self, "_on_respawn_timer_timeout"))
	add_child(respawn_timer)

func setup_systems():
	screen_wrap_system = get_node("/root/MainGame/ScreenWrapSystem")
	bullet_system = get_tree().get_root().get_node("MainGame/BulletSystem")
	level_system = get_node("/root/MainGame/ExpLevelSystem")

func setup_collision():
	set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(3, true)

func _physics_process(delta):
	# Always process physics for movement and sliding
	super._physics_process(delta)
	
	# Only process additional movement effects if not dead
	if player_state != PlayerState.DEAD:
		var velocity_change = (velocity - last_velocity).length()
		var instantaneous_thrust = velocity_change / delta
		
		if SoundManager.get_instance():
			SoundManager.get_instance().player_sound_system.handle_movement(velocity, instantaneous_thrust)
		
		last_velocity = velocity
	
	if screen_wrap_system:
		screen_wrap_system.wrap_object(self)

# Modify the take_damage() function to check for RESPAWNING state
func take_damage(amount: int, player_number: int = -1) -> void:
	if player_state == PlayerState.RESPAWNING:
		return
		
	health_component.take_damage(float(amount))
	
	if SoundManager.get_instance():
		SoundManager.get_instance().player_sound_system.play_state_sound("hurt")
	
	if player_number != -1:
		print("Player ", player_number, " took damage from Player ", player_number)
		
	if post_process_rect and post_process_rect.material:
		var tween = create_tween()
		tween.tween_method(func(v): post_process_rect.material.set_shader_parameter("chromatic_strength", v),
			4.0, 1.0, 1)

# Modify die() to use a tween for smooth deceleration
func die():
	if player_state != PlayerState.ALIVE:
		return
		
	player_state = PlayerState.DEAD
	print("BasePlayer: Player ", player_number, " died")
	
	# Check if player has revives remaining
	if revives_remaining > 0:
		revives_remaining -= 1
		print("BasePlayer: Player ", player_number, " has ", revives_remaining, " revives remaining")
		
		# Store current velocity and create deceleration tween
		var current_total_velocity = velocity + impulse_velocity
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		tween.tween_method(
			func(v): 
				velocity = v
				impulse_velocity = Vector2.ZERO,
			current_total_velocity,
			Vector2.ZERO,
			5.0
		)
		
		# Disable collisions temporarily
		set_collision_mask_value(1, false)
		set_collision_mask_value(3, false)
		
		modulate.a = 0.5
		respawn_timer.start(5.0)
	else:
		# No revives left - enter sustained dead state
		print("BasePlayer: Player ", player_number, " has no revives remaining - entering sustained dead state")
		
		# Make player semi-transparent
		modulate.a = 0.2
		
		# Disable collisions
		set_collision_mask_value(1, false)
		set_collision_mask_value(3, false)
		
		# Disable input processing but keep the node active
		set_process_input(false)
		set_process_unhandled_input(false)
		
		# Disable components but don't remove them
		if input_component:
			input_component.set_process(false)
		if weapon_component:
			weapon_component.set_process(false)
		if abilities_component:
			abilities_component.set_process(false)
			
		# Notify GameStateManager
		GameStateManager.player_died(player_number)

# Add new permanent_death() function to BasePlayer.gd
func permanent_death():
	# Notify GameStateManager
	GameStateManager.player_died(player_number)
	
	# Make player fully transparent
	modulate.a = 0.2
	
	# Disable all collisions
	collision_layer = 0
	collision_mask = 0
	
	# Disable input processing
	set_process_input(false)
	set_process_unhandled_input(false)
	
	# Disable all components
	if input_component:
		input_component.set_process(false)
	if weapon_component:
		weapon_component.set_process(false)
	if abilities_component:
		abilities_component.set_process(false)
	
	# Create final fadeout tween
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 2.0)
	tween.tween_callback(queue_free)


func respawn():
	velocity = Vector2.ZERO
	impulse_velocity = Vector2.ZERO
	if SoundManager.get_instance():
		SoundManager.get_instance().player_sound_system.play_state_sound("die")
		
	player_state = PlayerState.RESPAWNING
	print("BasePlayer: Player ", player_number, " respawning")
	
	# Reset health BEFORE changing state
	health_component.reset_health()
	health_component.current_health = max_health  # Explicitly set to max health
	
	

	
	# Visual effect for respawning state
	modulate.a = 0.5
	
	# Push away nearby entities
	push_away_nearby_entities(position)
	
	# Start invulnerability timer
	get_tree().create_timer(respawn_invulnerable_time).timeout.connect(_on_respawn_complete, CONNECT_ONE_SHOT)

# Keep respawn complete function focused on invulnerability and visuals
func _on_respawn_complete():
	print("BasePlayer: Player ", player_number, " respawn complete")
	player_state = PlayerState.ALIVE
	modulate.a = 1.0  # Restore full opacity
	
	# Re-enable collisions
	
	# Re-enable collisions
	set_collision_mask_value(1, true)
	set_collision_mask_value(3, true)
	
	# Ensure player is still in the player group
	if not is_in_group("player"):
		add_to_group("player")
	
# Add this new function for the push effect
func push_away_nearby_entities(center_pos: Vector2):
	# Push away enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var distance = enemy.global_position.distance_to(center_pos)
		if distance < respawn_push_radius:
			var direction = (enemy.global_position - center_pos).normalized()
			var force = direction * respawn_push_force * (1.0 - distance / respawn_push_radius)
			if enemy is RigidBody2D:
				enemy.apply_central_impulse(force)
			elif enemy.has_method("apply_central_impulse"):
				enemy.apply_central_impulse(force)

func apply_central_impulse(impulse: Vector2):
	if player_state == PlayerState.RESPAWNING:
		return
		
	var applied_impulse = (impulse / mass) * IMPULSE_STRENGTH_FACTOR
	impulse_velocity += applied_impulse

func _on_movement_input(input_vector: Vector2):
	if player_state == PlayerState.ALIVE or player_state == PlayerState.RESPAWNING:
		set_movement_direction(input_vector)
		
		# Calculate thrust based on input
		current_thrust = input_vector.length()
		
		# Update engine sound immediately when thrust is applied
		if SoundManager.get_instance():
			SoundManager.get_instance().player_sound_system.handle_movement(velocity, current_thrust)

func _on_aim_input(aim_vector: Vector2):
	if aim_vector != Vector2.ZERO:
		last_aim_vector = aim_vector
		look_at(global_position + aim_vector)
  
func _on_shoot_input(is_shooting: bool):
	if player_state == PlayerState.ALIVE and is_shooting:
		var bullet_properties = weapon_component.get_bullet_properties()
		gun_component.try_shoot(bullet_spawn.global_position, last_aim_vector, bullet_properties)
	
# Add new method:
func _on_gun_fired(spawn_positions: Array, bullet_properties: Dictionary):
	# Add the player's velocity to the bullet properties
	bullet_properties["player_velocity"] = velocity
	
	for spawn_data in spawn_positions:
		if bullet_system:
			bullet_system.create_bullet(
				spawn_data.position,
				spawn_data.direction,
				bullet_properties
			)
			
func _on_health_changed(new_health: float, max_health: float):
	print("BasePlayer: Health changed. New health:", new_health, "Max health:", max_health)
	if is_instance_valid(visual_component):
		visual_component.update_health_display(new_health, max_health)
	else:
		print("BasePlayer: Visual component is not valid when updating health display")

func _on_player_died():
	die()

func heal(amount: float):
	health_component.heal(amount)

func _on_respawn_timer_timeout():
	respawn()
 
func is_alive() -> bool:
	return player_state == PlayerState.ALIVE

func is_dead() -> bool:
	return player_state == PlayerState.DEAD

func is_respawning() -> bool:
	return player_state == PlayerState.RESPAWNING

func can_select_perks() -> bool:
	return true  # Always allow perk selection regardless of state

func set_player_name(name: String):
	player_name = name

func set_input_device(device: String):
	input_device = device
	print("BasePlayer: Setting input device to ", device)
	if input_component:
		if device == "keyboard_mouse":
			print("BasePlayer: Setting input type to KEYBOARD_MOUSE")
			input_component.set_input_type(BaseInputComponent.InputType.KEYBOARD_MOUSE)
		elif device.begins_with("gamepad"):
			var gamepad_id = int(device.substr(7))
			print("BasePlayer: Setting input type to GAMEPAD with ID ", gamepad_id)
			input_component.set_input_type(BaseInputComponent.InputType.GAMEPAD, gamepad_id)
		print("BasePlayer: Input device set to ", input_device)
	else:
		print("BasePlayer: Input component not initialized when setting input device")

func set_color(color: Color):
	print("BasePlayer: Setting player color to", color)
	player_color = color
	pending_color_update = true
	if is_inside_tree():
		_apply_pending_color()
		
func _apply_pending_color():
	if is_instance_valid(visual_component):
		print("BasePlayer: Applying color", player_color, "to visual component")
		visual_component.set_player_color(player_color)
		pending_color_update = false
	else:
		print("BasePlayer: Visual component is still not valid when applying color")

func _on_perk_acquired(perk_id: String):
	print("Player ", player_number, " acquired perk: ", perk_id)

func _on_appearance_updated():
	# Handle any additional logic needed when appearance is updated
	pass

func setup_score_component():
	score_component = BaseScoreComponent.new()
	if score_component:
		add_child(score_component)
		score_component.initialize(player_number)
		score_component.connect("score_changed", Callable(self, "_on_score_changed"))
	else:
		push_error("Failed to create ScoreComponent")

func _on_score_changed(new_score: int):
	print("Player ", player_number, " score changed. New score: ", new_score)

func collect_exp(amount: int):
	if level_system:
		level_system.add_exp(amount, player_number - 1)
		score_component.add_exp_orb()
		print("BasePlayer: Player ", player_number, " collected ", amount, " exp")

func add_kill():
	score_component.add_kill()
	print("BasePlayer: Player ", player_number, " scored a kill")

func get_score() -> int:
	return score_component.get_score()

func increase_movement_speed(percentage: float):
	movement_speed_multiplier += percentage
	increase_acceleration(percentage)
	increase_max_speed(percentage)
	print("Player ", player_number, " increased movement speed by ", percentage * 100, "%")

# These methods now delegate to the weapon component
func increase_bullet_damage(percentage: float):
	weapon_component.increase_damage(percentage)

func increase_fire_rate(percentage: float):
	weapon_component.increase_fire_rate(percentage)

func increase_bullet_size(percentage: float):
	weapon_component.increase_bullet_size(percentage)

func increase_bullet_speed(percentage: float):
	weapon_component.increase_bullet_speed(percentage)

func increase_bullet_penetration(amount: int):
	weapon_component.increase_penetration(amount)

func increase_bullet_ricochet(amount: int):
	weapon_component.increase_ricochet(amount)

func increase_bullet_homing(amount: float):
	weapon_component.increase_homing(amount)

func set_bullet_penetration(can_penetrate: bool):
	weapon_component.set_penetration(can_penetrate)

func reset():
	player_state = PlayerState.ALIVE
	revives_remaining = max_revives  # Reset revives count
	health_component.reset_health()
	weapon_component.reset_upgrades()
	perk_component.reset_perks()
	visual_component.set_visibility(true)
	position = Vector2(100 * player_number, 100)
	velocity = Vector2.ZERO
	impulse_velocity = Vector2.ZERO
	print("BasePlayer: Player ", player_number, " reset with ", revives_remaining, " revives")
	
func _on_ability_used(ability_name: String):
	if SoundManager.get_instance():
		SoundManager.get_instance().player_sound_system.play_state_sound(ability_name)
	print("Player ", player_number, " used ability: ", ability_name)

func _on_ability_ready(ability_name: String):
	print("Player ", player_number, " ability ready: ", ability_name)

func _on_ability_cooldown_updated(ability_name: String, remaining: float, total: float):
	# You can use this to update UI elements showing cooldown status
	pass

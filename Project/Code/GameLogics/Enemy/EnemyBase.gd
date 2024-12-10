extends PushableEntity

var enemy_type: String = "base"
var player_manager: Node = null
var is_initialized: bool = false
var is_dead: bool = false

var frame_count: int = 0
var target_direction: Vector2 = Vector2.ZERO

var last_hit_by_player: int = -1  # Tracks which player last hit this enemy


@export var exp_drop: int = 1
@export var exp_orb_scene: PackedScene
@onready var ripple_manager = get_node("/root/MainGame/RippleManager")

func _ready():
	
	add_to_group("enemy")
	set_collision_layer_value(2, true)  # Enemy is on layer 2
	set_collision_mask_value(1, true)   # Enemy collides with layer 1 (probably the player)
	set_collision_mask_value(3, true)   # Enemy collides with layer 3 (bullets)
	print("Enemy initialized and added to 'enemy' group")
	 # Find the RippleManager in the scene
	ripple_manager = get_tree().get_first_node_in_group("RippleManager")
	if not ripple_manager:
		push_warning("RippleManager not found in the scene!")

func initialize(type: String, start_position: Vector2, p_manager: Node):
	enemy_type = type
	position = start_position
	player_manager = p_manager
	is_initialized = true
	print("Enemy initialized with type:", type, " at position:", start_position)

func _physics_process(delta):
	if not is_initialized or is_dead:
		return

	super._physics_process(delta)

	frame_count += 1

	if player_manager and frame_count % 15 == 0:
		var closest_player = player_manager.get_closest_player(global_position)
		if closest_player:
			target_direction = (closest_player.global_position - global_position).normalized()
			set_movement_direction(target_direction)

func take_damage(amount: int, player_number: int = -1):
	super.take_damage(amount)
	
	if SoundManager.get_instance():
		SoundManager.get_instance().enemy_sound_system.play_hit_sound(enemy_type, global_position)
	
	last_hit_by_player = player_number  # Store the player number who dealt the damage
	print("Enemy taking damage: ", amount, " from player ", player_number)
	if health <= 0:
		# Add hit sound
		
		die()

func die():
	print("Enemy died")
	is_dead = true
	remove_from_group("enemy")
	drop_exp_orb()
	if get_parent() and get_parent().has_method("on_enemy_died"):
		get_parent().on_enemy_died(self)
	create_death_ripple()
	
	# Add kill to the player's score
	var player_manager = get_node("/root/MainGame/PlayerManager")
	if player_manager and last_hit_by_player != -1:
		var player = player_manager.get_player(last_hit_by_player - 1)
		if player:
			player.add_kill()
			print("Enemy killed by Player ", last_hit_by_player, ". Kill added to score.")
	else:
		print("Enemy died, but no player was credited with the kill.")
	
	queue_free()

func drop_exp_orb():
	if exp_orb_scene:
		var orb = exp_orb_scene.instantiate()
		orb.global_position = global_position
		orb.set_exp_value(exp_drop)
		get_parent().add_child(orb)
		print("Exp orb dropped with value:", exp_drop)
	else:
		print("Error: exp_orb_scene not set for enemy")
		
func _on_body_entered(body: Node) -> void:
	if body is BasePlayer:
		body.take_damage(10)  # Adjust damage amount as needed
		die()

func create_death_ripple():
	if ripple_manager:
		var viewport_size = get_viewport_rect().size
		var ripple_position = global_position / viewport_size
		
		# Add some randomness to the ripple parameters
		var strength = randf_range(1, 1)
		var size = randf_range(125.0, 135.0)
		var duration = randf_range(0.8, 1.2)
		
		ripple_manager.create_ripple(ripple_position, strength, size, duration)
	else:
		push_warning("Cannot create death ripple: RippleManager not found!")

func _exit_tree():
	if not is_dead and get_parent() and get_parent().has_method("on_enemy_died"):
		get_parent().on_enemy_died(self)

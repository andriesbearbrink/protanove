class_name KeyboardMouseInputHandler
extends InputHandler

var player_node: Node2D  # Reference to the player node
var previous_dash_state: bool = false
var previous_aim_state: bool = false

func _init(player: Node2D):
	player_node = player

func get_movement_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

func is_shooting() -> bool:
	return Input.is_action_pressed("shoot")

func get_aim_vector() -> Vector2:
	if player_node:
		return (player_node.get_global_mouse_position() - player_node.global_position).normalized()
	return Vector2.ZERO

# New ability input methods
func is_dashing() -> bool:
	var current_state = Input.is_key_pressed(KEY_SPACE)
	var pressed = current_state and not previous_dash_state
	previous_dash_state = current_state
	return pressed

func is_toggling_aim() -> bool:
	var current_state = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var pressed = current_state and not previous_aim_state
	previous_aim_state = current_state
	return pressed

func get_input_type() -> String:
	return "KeyboardMouseInputHandler"

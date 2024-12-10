class_name GamepadInputHandler
extends InputHandler

var device_id: int = 0
var trigger_threshold: float = 0.5  # Adjust this value as needed
var previous_dash_state: bool = false
var previous_aim_state: bool = false

func _init(id: int):
	device_id = id
	print("GamepadInputHandler: Initialized with device_id ", device_id)

func get_movement_vector() -> Vector2:
	var vector = Vector2(
		Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(device_id, JOY_AXIS_LEFT_Y)
	)
	if vector.length() > 0.1:  # Add a small deadzone
		return vector
	return Vector2.ZERO

func is_shooting() -> bool:
	return Input.get_joy_axis(device_id, JOY_AXIS_TRIGGER_RIGHT) > trigger_threshold

func get_aim_vector() -> Vector2:
	var vector = Vector2(
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)
	)
	if vector.length() > 0.1:  # Add a small deadzone
		return vector
	return Vector2.ZERO

# New ability input methods
func is_dashing() -> bool:
	var current_state = Input.is_joy_button_pressed(device_id, JOY_BUTTON_A)
	var pressed = current_state and not previous_dash_state
	previous_dash_state = current_state
	return pressed

func is_toggling_aim() -> bool:
	var current_state = Input.is_joy_button_pressed(device_id, JOY_BUTTON_RIGHT_SHOULDER)
	var pressed = current_state and not previous_aim_state
	previous_aim_state = current_state
	return pressed

func get_input_type() -> String:
	return "GamepadInputHandler (Device: " + str(device_id) + ")"

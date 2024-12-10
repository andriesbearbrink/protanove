extends Node
class_name BaseInputComponent

signal movement_input(input_vector: Vector2)
signal aim_input(aim_vector: Vector2)
signal shoot_input(is_shooting: bool)

enum InputType { KEYBOARD_MOUSE, GAMEPAD }

@export var input_type: InputType = InputType.KEYBOARD_MOUSE
@export var gamepad_id: int = 0
@export var movement_deadzone: float = 0.1
@export var aim_deadzone: float = 0.1

var input_handler: InputHandler
var player: Node

func initialize(player_node: Node):
	player = player_node
	setup_input_handler(player.input_device)
	print("BaseInputComponent: Initialized for player ", player.player_number)

func setup_input_handler(device: String):
	if device == "keyboard_mouse":
		input_handler = KeyboardMouseInputHandler.new(player)
		print("BaseInputComponent: Set up keyboard/mouse input handler")
	elif device.begins_with("gamepad"):
		var device_id = int(device.substr(7))
		input_handler = GamepadInputHandler.new(device_id)
		print("BaseInputComponent: Set up gamepad input handler with ID ", device_id)
	else:
		print("BaseInputComponent: Unknown input device type: ", device)

func _process(delta):
	if input_handler:
		var movement = input_handler.get_movement_vector()
		var aim = input_handler.get_aim_vector()
		var shooting = input_handler.is_shooting()
		
		if movement.length() > movement_deadzone:
			emit_signal("movement_input", movement)
		else:
			emit_signal("movement_input", Vector2.ZERO)
		
		if aim.length() > aim_deadzone:
			emit_signal("aim_input", aim)
		
		emit_signal("shoot_input", shooting)

	#	if movement.length() > 0.1 or aim.length() > 0.1 or shooting:
		#	print("BaseInputComponent: Input detected")
		#	print("Movement: ", movement)
		#	print("Aim: ", aim)
		#	print("Shooting: ", shooting)

func set_input_type(new_input_type: InputType, new_gamepad_id: int = 0):
	input_type = new_input_type
	gamepad_id = new_gamepad_id
	setup_input_handler("keyboard_mouse" if input_type == InputType.KEYBOARD_MOUSE else "gamepad" + str(gamepad_id))
	print("BaseInputComponent: Input type set to: ", InputType.keys()[input_type], " with gamepad ID: ", gamepad_id)

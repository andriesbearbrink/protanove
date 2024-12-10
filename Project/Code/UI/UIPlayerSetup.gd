extends Control

@export var max_players = 4
@export var player_slot_scene: PackedScene

var player_slots = []
var active_players = 0
var ready_players = 0
var assigned_devices = {}

@onready var player_slots_container = $VBoxContainer/PlayerSlotsContainer

func _ready():
	for i in range(max_players):
		var slot = player_slot_scene.instantiate()
		slot.set_player_index(i)
		player_slots.append(slot)
		player_slots_container.add_child(slot)
		slot.connect("player_ready", Callable(self, "_on_player_ready"))
		slot.connect("player_unready", Callable(self, "_on_player_unready"))
		slot.connect("player_start", Callable(self, "_on_player_start"))
	
	set_process_input(true)

func _input(event):
	if event.is_pressed():
		var device = get_event_device(event)
		if device != "unknown":
			if is_activation_input(event):
				handle_activation(device)
			elif is_deactivation_input(event):
				handle_deactivation(device)

func _on_player_ready(player_index):
	active_players += 1
	print("Player ", player_index + 1, " is ready. Active players: ", active_players)

func _on_player_unready(player_index):
	active_players -= 1
	if player_slots[player_index].is_ready:
		ready_players -= 1
	print("Player ", player_index + 1, " is not ready. Active players: ", active_players)

func _on_player_start(player_index):
	if player_slots[player_index].is_ready:
		ready_players += 1
		print("Player ", player_index + 1, " is ready to start. Ready players: ", ready_players)
		if ready_players == active_players and active_players > 0:
			start_game()
	else:
		ready_players -= 1
		print("Player ", player_index + 1, " is not ready to start. Ready players: ", ready_players)

func start_game():
	var player_data = []
	for slot in player_slots:
		var data = slot.get_player_data()
		if not data.is_empty():
			player_data.append(data)
	
	if not player_data.is_empty():
		if Global.has_method("set_player_data"):
			Global.set_player_data(player_data)
		else:
			print("Global script does not have set_player_data method")
		
		print("Changing to MainGame scene")
		var result = get_tree().change_scene_to_file("res://Code/GameLogics/BaseGame/MainGame.tscn")
		if result != OK:
			print("Failed to change scene. Error code: ", result)
	else:
		print("No active players. Cannot start the game.")

func is_activation_input(event):
	return (event is InputEventKey and event.keycode == KEY_SPACE) or \
		   (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_A)

func is_deactivation_input(event):
	return (event is InputEventKey and event.keycode == KEY_ESCAPE) or \
		   (event is InputEventJoypadButton and event.button_index == JOY_BUTTON_B)

func handle_activation(device):
	if device not in assigned_devices:
		for slot in player_slots:
			if not slot.is_active:
				slot.activate(device)
				assigned_devices[device] = slot
				print("Assigned device ", device, " to player ", slot.player_index + 1)
				return
	else:
		print("Device ", device, " is already assigned to player ", assigned_devices[device].player_index + 1)

func handle_deactivation(device):
	if device in assigned_devices:
		var slot = assigned_devices[device]
		slot.deactivate()
		assigned_devices.erase(device)
		print("Deactivated device ", device, " for player ", slot.player_index + 1)

func get_event_device(event):
	if event is InputEventKey:
		return "keyboard_mouse"
	elif event is InputEventJoypadButton:
		return "gamepad" + str(event.device)
	return "unknown"

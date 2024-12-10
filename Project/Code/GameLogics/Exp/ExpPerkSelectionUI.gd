extends Control

class_name ExpPerkSelectionUI

signal perk_selected(player_index: int, perk: Dictionary)
signal all_players_selected

@export var perk_button_scene: PackedScene
@export var perk_system: PerkSystem
@export var player_manager: PlayerManager

var player_containers: Array[Control] = []
var players_selected: Array = []
var current_focus: Array[Vector2] = []

const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080

var inactive_containers = []

func _ready():
	custom_minimum_size = Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	size = Vector2(SCREEN_WIDTH, SCREEN_HEIGHT)
	position = Vector2.ZERO
	
	# Make the existing ColorRect more transparent
	var main_bg = get_node_or_null("ColorRect")
	if main_bg:
		main_bg.color = Color(1, 1, 0.4, 0.15)  # Very transparent yellow
	
	set_process_input(true)
	visible = false
	print("ExpPerkSelectionUI: _ready called")
	print("ExpPerkSelectionUI script loaded")


func show_perk_selection():
	print("ExpPerkSelectionUI: Showing perk selection")
	print("ExpPerkSelectionUI: Total player count: ", player_manager.get_player_count())
	players_selected.clear()
	inactive_containers.clear()
	for container in player_containers:
		container.queue_free()
	player_containers.clear()
	current_focus.clear()
	for i in range(player_manager.get_player_count()):
		var player = player_manager.get_player(i)
		if player:
			show_player_perks(i)
			current_focus.append(Vector2.ZERO)  # Start with first perk focused
		else:
			print("ExpPerkSelectionUI: Player at index ", i, " not found")
	visible = true
	update_focus_visuals()



func show_player_perks(player_index: int):
	print("ExpPerkSelectionUI: Showing perks for player ", player_index + 1)
	var container = Control.new()
	add_child(container)
	player_containers.append(container)
	
	var player = player_manager.get_player(player_index)
	if player == null:
		print("Error: Player ", player_index + 1, " not found")
		return

	var player_color = player.player_color
	var player_name = player.player_name
	var player_score = player.get_score()  # Get the player's score
	
	# Add a visual indicator for player state, but don't exclude them
	if player.is_dead():
		player_name += " (Dead)"
	elif player.is_respawning():
		player_name += " (Respawning)"
	
	print("Player ", player_index + 1, " color: ", player_color, ", name: ", player_name, ", score: ", player_score)
	
	var player_count = player_manager.get_player_count()
	var container_width = SCREEN_WIDTH / player_count
	var start_x = container_width * player_index
	
	# Set container size and position
	container.set_position(Vector2(start_x, 0))
	container.set_size(Vector2(container_width, SCREEN_HEIGHT))
	
	# Add background with glass-like transparency
	var background = ColorRect.new()
	var transparent_color = player_color
	transparent_color.a = 0.15  # Very transparent
	background.color = transparent_color
	background.set_size(Vector2(container_width, SCREEN_HEIGHT))
	container.add_child(background)
	
	# Add player name and score label
	var label = Label.new()
	label.text = player_name + "\nScore: " + str(player_score) + "\nKills: " + str(player.score_component.get_kills()) 
	label.add_theme_color_override("font_color", player_color.darkened(0.2))
	label.add_theme_font_size_override("font_size", 20)
	label.set_position(Vector2(0, 20))
	label.set_size(Vector2(container_width, 100))  # Increased height to accommodate two lines
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(label)
	
	var perks = perk_system.get_random_perks(3, player.perk_component.acquired_perks.keys())
	
	for i in range(perks.size()):
		var button = perk_button_scene.instantiate()
		button.setup(perks[i])
		button.set_position(Vector2(20, 140 + i * 160))  # Adjusted Y position to account for larger label
		button.set_size(Vector2(container_width - 40, 140))
		button.add_theme_color_override("font_color", player_color.darkened(0.5))
		button.add_theme_color_override("font_hover_color", player_color.darkened(0.7))
		container.add_child(button)
	
	print("ExpPerkSelectionUI: Added ", perks.size(), " perk buttons for player ", player_index)
	
	# Ensure current_focus is updated
	if player_index >= current_focus.size():
		current_focus.append(Vector2.ZERO)
	else:
		current_focus[player_index] = Vector2.ZERO

func _input(event):
	if not visible:
		return

	for i in range(player_manager.get_player_count()):
		if i not in players_selected:
			handle_player_input(i, event)

func handle_player_input(player_index: int, event: InputEvent):
	if player_index in players_selected or player_index in inactive_containers or player_index >= player_containers.size():
		return

	var player = player_manager.get_player(player_index)
	if not player:
		return

	var input_device = player.input_device
	var container = player_containers[player_index]
	
	if input_device == "keyboard_mouse":
		if event is InputEventKey and event.pressed:
			match event.keycode:
				KEY_W:
					move_focus(player_index, Vector2.UP)
				KEY_S:
					move_focus(player_index, Vector2.DOWN)
				KEY_E:
					select_focused_perk(player_index)
					
	elif input_device.begins_with("gamepad"):
		var device_id = int(input_device.substr(7))
		if event.device == device_id:
			if event is InputEventJoypadButton:
				handle_gamepad_button(player_index, event, container)

func handle_gamepad_button(player_index: int, event: InputEventJoypadButton, container: Control):
	if event.pressed:
		match event.button_index: 
			JOY_BUTTON_DPAD_UP:
				move_focus(player_index, Vector2.UP)
			JOY_BUTTON_DPAD_DOWN:
				move_focus(player_index, Vector2.DOWN)
			JOY_BUTTON_Y:
				select_focused_perk(player_index)

func move_focus(player_index: int, direction: Vector2):
	if player_index >= current_focus.size() or player_index >= player_containers.size():
		return

	var new_focus = current_focus[player_index] + direction
	new_focus.y = wrapi(new_focus.y, 0, 3)  # Wrap around for 3 perks
	new_focus.x = 0  # Only one column of perks
	current_focus[player_index] = new_focus
	update_focus_visuals()
	
func select_focused_perk(player_index: int):
	if player_index >= player_containers.size() or player_index >= current_focus.size():
		print("ExpPerkSelectionUI: Invalid player index ", player_index)
		return
	
	if player_index in players_selected:
		print("ExpPerkSelectionUI: Player ", player_index + 1, " has already selected a perk")
		return

	var container = player_containers[player_index]
	if not container.visible:
		print("ExpPerkSelectionUI: Container for player ", player_index + 1, " is not visible")
		return

	var focus = current_focus[player_index]
	var button_index = focus.y + 2  # +2 to skip background and label
	if button_index < container.get_child_count():
		var button = container.get_child(button_index)
		if button is ExpPerkButton:
			handle_perk_selected(player_index, button.perk)
			button.set_selected(true)
	else:
		print("ExpPerkSelectionUI: Invalid button index for player ", player_index + 1)

func update_focus_visuals():
	for i in range(player_containers.size()):
		if i in inactive_containers:
			continue
		var container = player_containers[i]
		var perk_buttons = container.get_children().filter(func(child): return child is ExpPerkButton)
		for j in range(perk_buttons.size()):
			var button = perk_buttons[j]
			if button is ExpPerkButton:
				var is_focused = (j == current_focus[i].y)
				button.set_focused(is_focused)
				if is_focused:
					var player = player_manager.get_player(i)
					if player:
						button.show_focus_indicator(player.player_color)
					else:
						print("Error: Player ", i + 1, " not found")
				else:
					button.hide_focus_indicator()

func handle_perk_selected(player_index: int, perk: Dictionary):
	print("DEBUG TRACE: ExpPerkSelectionUI.handle_perk_selected called")
	print("DEBUG TRACE: Player Index:", player_index)
	print("DEBUG TRACE: Perk:", perk.name)
	
	if player_index in players_selected:
		print("DEBUG TRACE: Player already selected a perk!")
		return

	emit_signal("perk_selected", player_index, perk)
	print("ExpPerkSelectionUI: perk_selected signal emitted for player ", player_index + 1, ": ", perk.name)
	players_selected.append(player_index)
	clear_player_perks(player_index)
	
	if check_all_players_selected():
		print("ExpPerkSelectionUI: All players have selected perks")
		emit_signal("all_players_selected")
		print("ExpPerkSelectionUI: all_players_selected signal emitted")
		hide_perk_selection()

func check_all_players_selected() -> bool:
	var all_selected = players_selected.size() == player_manager.get_player_count()
	print("ExpPerkSelectionUI: check_all_players_selected returning ", all_selected)
	print("ExpPerkSelectionUI: players_selected: ", players_selected.size(), ", total players: ", player_manager.get_player_count())
	return all_selected

func clear_player_perks(player_index: int):
	print("ExpPerkSelectionUI: Clearing perks for player ", player_index + 1)
	if player_index < player_containers.size():
		for child in player_containers[player_index].get_children():
			child.queue_free()
		player_containers[player_index].visible = false
		inactive_containers.append(player_index)

func hide_perk_selection():
	print("ExpPerkSelectionUI: Hiding perk selection UI")
	visible = false
	for container in player_containers:
		container.queue_free()
	player_containers.clear()
	current_focus.clear()
	players_selected.clear()

func get_player_index_for_button(button: ExpPerkButton) -> int:
	for i in range(player_containers.size()):
		if player_containers[i].is_ancestor_of(button):
			return i
	return -1

extends Control

signal resume_game

@onready var debug_menu = preload("res://Code/Debug/DebugMenu.tscn")

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Add debug button
	var debug_button = Button.new()
	debug_button.text = "Debug Menu"
	debug_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	$VBoxContainer.add_child(debug_button)
	debug_button.connect("pressed", _on_debug_button_pressed)

func _on_debug_button_pressed():
	# Remove any existing debug menu
	var existing_menu = get_tree().root.get_node_or_null("DebugMenu")
	if existing_menu:
		existing_menu.queue_free()
	
	# Create and add new debug menu
	var debug_instance = debug_menu.instantiate()
	get_tree().root.add_child(debug_instance)
	debug_instance.show()  # Make sure it's visible
	
	# Hide pause menu but maintain pause state
	hide()
	get_tree().paused = true
	
	# Disable process mode for game nodes
	for node in get_tree().get_nodes_in_group("game"):
		node.process_mode = Node.PROCESS_MODE_DISABLED

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_unpause()
		else:
			_pause()

func _pause():
	print("Attempting pause")
	show()
	for node in get_tree().get_nodes_in_group("game"):
		node.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = true
	print("Pause state:", get_tree().paused)

func _unpause():
	print("Attempting unpause")
	hide()
	for node in get_tree().get_nodes_in_group("game"):
		node.process_mode = Node.PROCESS_MODE_INHERIT
	get_tree().paused = false
	print("Pause state:", get_tree().paused)

func _on_resume_button_pressed():
	_unpause()

func _on_main_menu_button_pressed():
	_unpause()
	get_tree().change_scene_to_file("res://Code/UI/MainMenu.tscn")

func _on_exit_button_pressed():
	get_tree().quit()

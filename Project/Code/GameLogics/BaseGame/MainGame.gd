extends Node

@onready var player_manager = $PlayerManager
@onready var enemy_creation_system = $SimpleEnemyCreationSystem
@onready var level_system = $ExpLevelSystem
@onready var perk_system = $ExpPerkSystem
@onready var perk_selection_ui = $CanvasLayer/ExpPerkSelectionUI
@onready var pause_menu = $CanvasLayer/UiPauseMenu
@onready var enemy_master_controller = $EnemyMasterController
@onready var base_theme = preload("res://Sounds/music/main_theme_base.ogg")
@onready var ambient_theme = preload("res://Sounds/music/main_theme_ambient.ogg")

var is_perk_selection_active = false

func _ready():
	# Add post-processing ColorRect as last child of CanvasLayer
	var post_process_rect = ColorRect.new()
	post_process_rect.set_anchors_preset(Control.PRESET_FULL_RECT)  # Make it cover full screen
	post_process_rect.material = ShaderMaterial.new()
	post_process_rect.material.shader = load("res://Code/GameLogics/BaseGame/Post-Processing.gdshader")
	$CanvasLayer.add_child(post_process_rect)
	# Ensure it's drawn last
	post_process_rect.show_behind_parent = false
	# Optional: store reference if needed
	post_process_rect.name = "PostProcessRect"
	post_process_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	start_game_music()
	print("MainGame: Scene loaded")
	
	  
	
	if level_system:
		level_system.connect("level_up", func(player_index, new_level): _on_level_up(player_index, new_level))
		print("MainGame: Connected level_up signal")
	else:
		push_error("MainGame: LevelSystem not found")
		
	if not has_node("EnemyMasterController"):
		var controller = EnemyMasterController.new()
		add_child(controller)
		controller.name = "EnemyMasterController"
	
	if perk_selection_ui:
		perk_selection_ui.connect("perk_selected", Callable(self, "_on_perk_selected"))
		perk_selection_ui.connect("all_players_selected", Callable(self, "_on_all_players_selected"))
		print("MainGame: Connected perk_selected and all_players_selected signals")
	else:
		push_error("MainGame: PerkSelectionUI not found")
	
	if pause_menu:
		pause_menu.connect("resume_game", Callable(self, "_on_resume_game"))
	else:
		push_error("MainGame: PauseMenu not found")
		
	# Set process mode for UI elements
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	perk_selection_ui.process_mode = Node.PROCESS_MODE_ALWAYS
		
	# Set up pause handling
	if $CanvasLayer/UiPauseMenu:
		$CanvasLayer/UiPauseMenu.hide()
		# Make sure sound system keeps running during pause
		var sound_manager = get_node_or_null("/root/GameSound")
		if sound_manager:
			sound_manager.process_mode = Node.PROCESS_MODE_ALWAYS

	# Ensure proper process modes for nodes that should run during pause
	$CanvasLayer.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ensure correct process modes
	process_mode = Node.PROCESS_MODE_PAUSABLE
	
	start_game()
	print("MainGame: Game setup complete")
	
	 # Connect to GameStateManager's game over signal
	GameStateManager.connect("game_over", Callable(self, "_on_game_over"))
	
func start_game_music():
	if SoundManager.get_instance():
		var music_system = SoundManager.get_instance().music_system
		# Start the main theme with a 2-second crossfade
		music_system.play_track_set("main_theme", 2.0)
		
		# After a short delay, start fading in the ambient layer
		await get_tree().create_timer(3.0).timeout
		music_system.trigger_layer("ambient", 4.0)  # 4-second fade in for ambientssswa


func handle_perk_selection_input(event):
	if perk_selection_ui:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("MainGame: Mouse click detected during perk selection")
			if perk_selection_ui.get_global_rect().has_point(event.global_position):
				perk_selection_ui.handle_click(event.global_position)
		elif event is InputEventJoypadButton or event is InputEventKey:
			perk_selection_ui.handle_input(event)

func start_game():
	setup_players(Global.player_data)
	if enemy_creation_system:
		enemy_creation_system.start_spawning()
	else:
		push_error("SimpleEnemyCreationSystem not found. Make sure it's added to the scene.")

func setup_players(player_data):
	print("MainGame: Starting player setup")
	if player_manager:
		player_manager.clear_players()  # Clear any existing players
		var center = get_viewport().get_visible_rect().size / 2
		var player_count = player_data.size()
		
		for i in range(player_count):
			var data = player_data[i]
			print("MainGame: Setting up player ", i+1, " with data: ", data)
			
			# Calculate position offset based on player count
			var angle = 2 * PI * i / player_count
			var offset = Vector2(cos(angle), sin(angle)) * 50  # 50 is the distance from center
			var start_position = center + offset
			
			var player = player_manager.create_player(data, start_position)
			if player:
				GameStateManager.player_joined(i+1)
				print("MainGame: Player ", i+1, " created successfully at position ", start_position)
			else:
				print("MainGame: Failed to create player ", i+1)
	else:
		print("MainGame: PlayerManager not found. Unable to create players.")
	print("MainGame: Player setup completed")

func _on_level_up(player_index: int, new_level: int):
	print("MainGame: _on_level_up called with player_index: ", player_index, " and new_level: ", new_level)
	print("MainGame: is_perk_selection_active before: ", is_perk_selection_active)
	print("MainGame: perk_selection_ui exists: ", perk_selection_ui != null)
	
	if player_manager.get_selectable_player_count() > 0:
		get_tree().paused = true
		if perk_selection_ui:
			is_perk_selection_active = true
			perk_selection_ui.show_perk_selection()
		else:
			push_error("MainGame: PerkSelectionUI not found. Make sure it's added to the scene.")
	else:
		print("MainGame: No selectable players, skipping perk selection")

	print("MainGame: is_perk_selection_active after: ", is_perk_selection_active)
	print("MainGame: Tree paused: ", get_tree().paused)

func _on_perk_selected(player_index: int, perk: Dictionary):
	print("DEBUG TRACE: MainGame._on_perk_selected called")
	print("DEBUG TRACE: Player Index:", player_index)
	print("DEBUG TRACE: Perk:", perk.name)
	var player = player_manager.get_player(player_index)
	if player:
		call_deferred("_apply_perk_deferred", player, perk)
		
func _apply_perk_deferred(player, perk):
	print("DEBUG TRACE: _apply_perk_deferred called")
	print("DEBUG TRACE: Player number:", player.player_number)
	print("DEBUG TRACE: Perk name:", perk.name)
	if player.perk_component:
		player.perk_component.add_perk(perk.id)
		perk_system.apply_perk(perk, player)

func _on_all_players_selected():
	print("MainGame: All players have selected perks")
	get_tree().paused = false
	is_perk_selection_active = false
	# Remove the line that calls hide_perk_selection() as it's now handled in the UI script

func resume_game():
	get_tree().paused = false
	is_perk_selection_active = false
	
@onready var game_over_ui = preload("res://Code/UI/UIGameOver.tscn")

func _on_game_over():
	print("MainGame: Game Over triggered")
	get_tree().paused = true
	
	# Hide pause menu if it's showing
	if pause_menu:
		pause_menu.hide()
	
	# Show game over UI
	var ui = game_over_ui.instantiate()
	$CanvasLayer.add_child(ui)
	ui.show_game_over()

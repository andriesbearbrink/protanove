extends Control

@onready var stats_container = $StatsContainer
@onready var main_menu_button = $ButtonsContainer/MainMenuButton
@onready var exit_button = $ButtonsContainer/ExitButton

const PLAYER_STATS_SCENE = preload("res://Code/UI/UIGameOverStats.tscn")

func _ready():
	if main_menu_button:
		main_menu_button.pressed.connect(_on_main_menu_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)

func show_game_over():
	var player_manager = get_node("/root/MainGame/PlayerManager")
	if not player_manager:
		print("GameOverUI: PlayerManager not found")
		return
		
	# Sort players by score
	var players = player_manager.players.duplicate()
	players.sort_custom(func(a, b): return a.get_score() > b.get_score())
	
	# Clear any existing stats first
	for child in stats_container.get_children():
		child.queue_free()
	
	# Create stats display for each player
	for player in players:
		print("GameOverUI: Creating stats for player ", player.player_number)
		var stats_display = PLAYER_STATS_SCENE.instantiate()
		stats_container.add_child(stats_display)
		
		# Set player info
		stats_display.set_player_info({
			"name": player.player_name,
			"color": player.player_color,
			"score": player.get_score(),
			"kills": player.score_component.get_kills(),
			"orbs_collected": player.score_component.get_exp_orbs_collected()
		})

func _on_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Code/UI/MainMenu.tscn")

func _on_exit_pressed():
	get_tree().quit()

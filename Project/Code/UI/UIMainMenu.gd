extends Control

@onready var start_game_button = $VBoxContainer/StartGameButton
@onready var options_button = $VBoxContainer/OptionsButton
@onready var profiles_button = $VBoxContainer/ProfilesButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var loading_progress_bar = $LoadingProgressBar

var current_button_index = 0
var buttons = []

func _ready():
	start_game_button.connect("pressed", Callable(self, "_on_start_game_pressed"))
	options_button.connect("pressed", Callable(self, "_on_options_pressed"))
	profiles_button.connect("pressed", Callable(self, "_on_profiles_pressed"))
	quit_button.connect("pressed", Callable(self, "_on_quit_pressed"))
	start_game_button.grab_focus()


func update_focus():
	buttons[current_button_index].grab_focus()
	
func _on_start_game_pressed():
	get_tree().change_scene_to_file("res://Code/UI/PlayerSetup.tscn")

func _on_options_pressed():
	print("Options menu not implemented yet")

func _on_profiles_pressed():
	get_tree().change_scene_to_file("res://Code/UI/ProfileManagementMenu.tscn")

func _on_quit_pressed():
	get_tree().quit()

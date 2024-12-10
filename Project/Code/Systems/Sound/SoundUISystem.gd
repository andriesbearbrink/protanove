extends Node

class_name UISoundSystem

# UI sound categories
enum UISound {
	HOVER,
	CLICK,
	CONFIRM,
	BACK,
	ERROR,
	SUCCESS,
	NOTIFICATION,
	LEVEL_UP,
	ACHIEVEMENT
}

# Sound assets
var ui_sounds = {
	UISound.HOVER: preload("res://Sounds/player/gun1.ogg"),
	UISound.CLICK: preload("res://Sounds/player/gun1.ogg"),
	UISound.CONFIRM: preload("res://Sounds/player/gun1.ogg"),
	UISound.BACK: preload("res://Sounds/player/gun1.ogg"),
	UISound.ERROR: preload("res://Sounds/player/gun1.ogg"),
	UISound.SUCCESS: preload("res://Sounds/player/gun1.ogg"),
	UISound.NOTIFICATION: preload("res://Sounds/player/gun1.ogg"),
	UISound.LEVEL_UP: preload("res://Sounds/player/gun1.ogg"),
	UISound.ACHIEVEMENT: preload("res://Sounds/player/gun1.ogg")
}

# Volume settings for different sound types
const VOLUME_SETTINGS = {
	UISound.HOVER: -15.0,
	UISound.CLICK: -10.0,
	UISound.CONFIRM: -5.0,
	UISound.BACK: -8.0,
	UISound.ERROR: -8.0,
	UISound.SUCCESS: -5.0,
	UISound.NOTIFICATION: -8.0,
	UISound.LEVEL_UP: -3.0,
	UISound.ACHIEVEMENT: -5.0
}

# Dedicated players for different UI sound types
var players: Dictionary = {}
var cached_streams: Dictionary = {}

func _ready():
	setup_players()
	cache_sound_streams()
	connect_to_ui_signals()

func setup_players():
	# Create dedicated players for each UI sound type
	for sound_type in UISound.values():
		var player = AudioStreamPlayer.new()
		player.bus = "UI"
		add_child(player)
		players[sound_type] = player

func cache_sound_streams():
	for sound_type in ui_sounds:
		cached_streams[sound_type] = ui_sounds[sound_type]

func connect_to_ui_signals():
	# Connect to common UI signals
	get_tree().get_root().connect("gui_focus_changed", Callable(self, "_on_focus_changed"))

func play_ui_sound(sound_type: UISound, override: bool = true) -> void:
	if not sound_type in players:
		return
		
	var player = players[sound_type]
	var stream = cached_streams[sound_type]
	
	if not stream:
		return
		
	# If override is true, stop current sound and play new one
	if override and player.playing:
		player.stop()
		
	player.stream = stream
	player.volume_db = VOLUME_SETTINGS[sound_type]
	player.play()

# Convenience methods for common UI sounds
func play_hover():
	play_ui_sound(UISound.HOVER, false)  # Don't override hover sounds

func play_click():
	play_ui_sound(UISound.CLICK)

func play_confirm():
	play_ui_sound(UISound.CONFIRM)

func play_back():
	play_ui_sound(UISound.BACK)

func play_error():
	play_ui_sound(UISound.ERROR)

func play_success():
	play_ui_sound(UISound.SUCCESS)

func play_notification():
	play_ui_sound(UISound.NOTIFICATION)

func play_level_up():
	play_ui_sound(UISound.LEVEL_UP)

func play_achievement():
	play_ui_sound(UISound.ACHIEVEMENT)

# Signal handlers
func _on_focus_changed(control: Control):
	if control and control.is_visible_in_tree():
		play_hover()

# Automatic UI sound handling
func _notification(what: int):
	match what:
		NOTIFICATION_WM_MOUSE_ENTER:
			play_hover()

# Button auto-connection script
func connect_button(button: BaseButton):
	if not button.pressed.is_connected(play_click):
		button.pressed.connect(play_click)
	if not button.mouse_entered.is_connected(play_hover):
		button.mouse_entered.connect(play_hover)

# Batch connect all buttons in a node
func connect_all_buttons(node: Node):
	for child in node.get_children():
		if child is BaseButton:
			connect_button(child)
		if child.get_child_count() > 0:
			connect_all_buttons(child)

# System control
func pause():
	for player in players.values():
		player.stream_paused = true

func resume():
	for player in players.values():
		player.stream_paused = false

# Auto-connect UI elements in a scene
func auto_connect_ui(root_node: Node):
	# Connect all buttons
	connect_all_buttons(root_node)
	
	# Connect other UI elements as needed
	for child in root_node.get_children():
		if child is PopupPanel:
			child.about_to_show.connect(func(): play_ui_sound(UISound.NOTIFICATION))
		elif child is AcceptDialog:
			child.confirmed.connect(func(): play_ui_sound(UISound.CONFIRM))

extends Node

class_name SoundManager

# Change: Now the static instance will be accessed through "GameSound" autoload node
static func get_instance() -> SoundManager:
	return Engine.get_main_loop().root.get_node_or_null("/root/GameSound") as SoundManager

# Components
var music_system: MusicSystem
var player_sound_system: PlayerSoundSystem
var enemy_sound_system: EnemySoundSystem
var ui_sound_system: UISoundSystem

# Bus indices (cached for performance)
var master_bus_idx: int
var music_bus_idx: int
var sfx_bus_idx: int
var ui_bus_idx: int

func _init():
	_initialize_bus_indices()

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS  # Make sure sound manager runs while paused
	_setup_components()

func _initialize_bus_indices():
	master_bus_idx = AudioServer.get_bus_index("Master")
	music_bus_idx = AudioServer.get_bus_index("Music")
	sfx_bus_idx = AudioServer.get_bus_index("SFX")
	ui_bus_idx = AudioServer.get_bus_index("UI")

func _setup_components():
	music_system = MusicSystem.new()
	player_sound_system = PlayerSoundSystem.new()
	enemy_sound_system = EnemySoundSystem.new()
	ui_sound_system = UISoundSystem.new()
	
	# Set all sound systems to ignore pause
	music_system.process_mode = Node.PROCESS_MODE_ALWAYS
	player_sound_system.process_mode = Node.PROCESS_MODE_ALWAYS
	enemy_sound_system.process_mode = Node.PROCESS_MODE_ALWAYS
	ui_sound_system.process_mode = Node.PROCESS_MODE_ALWAYS
	
	add_child(music_system)
	add_child(player_sound_system)
	add_child(enemy_sound_system)
	add_child(ui_sound_system)


# Volume control methods
func set_master_volume(value: float):
	AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(value))

func set_music_volume(value: float):
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(value))

func set_sfx_volume(value: float):
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(value))

func set_ui_volume(value: float):
	AudioServer.set_bus_volume_db(ui_bus_idx, linear_to_db(value))

# Global sound control
func pause_all_sound():
	music_system.pause()
	player_sound_system.pause()
	enemy_sound_system.pause()
	ui_sound_system.pause()

func resume_all_sound():
	music_system.resume()
	player_sound_system.resume()
	enemy_sound_system.resume()
	ui_sound_system.resume()

func _on_game_paused():
	# Optional: Implement pause behavior (lower volume, filter effects, etc.)
	pass

func _on_game_resumed():
	# Optional: Restore normal sound state
	pass

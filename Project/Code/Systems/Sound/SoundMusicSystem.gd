extends Node

class_name MusicSystem

# Track layers
class MusicLayer:
	var player: AudioStreamPlayer
	var volume_db: float = 0.0
	var current_tween: Tween
	
	func _init(stream: AudioStream, bus: String = "Music"):
		player = AudioStreamPlayer.new()
		player.stream = stream
		player.bus = bus
	
	func fade_in(duration: float = 1.0):
		if current_tween:
			current_tween.kill()
		player.volume_db = -80.0
		current_tween = player.create_tween()
		current_tween.tween_property(player, "volume_db", volume_db, duration)
	
	func fade_out(duration: float = 1.0):
		if current_tween:
			current_tween.kill()
		current_tween = player.create_tween()
		current_tween.tween_property(player, "volume_db", -80.0, duration)

# Music tracks organized by state/area
var music_tracks: Dictionary = {
	"main_theme": {
		"base": preload("res://Sounds/music/main_theme_base.ogg"),
		"ambient": preload("res://Sounds/music/main_theme_ambient.ogg"),
		"tension": preload("res://Sounds/music/main_theme_tense.ogg")
	}
}

# Active layers
var active_layers: Dictionary = {}
var current_track_set: String = ""

func _ready():
	setup_music_layers()

func setup_music_layers():
	# Pre-create layers for all tracks
	for track_set in music_tracks:
		active_layers[track_set] = {}
		for layer_name in music_tracks[track_set]:
			var layer = MusicLayer.new(music_tracks[track_set][layer_name])
			active_layers[track_set][layer_name] = layer
			add_child(layer.player)
			layer.player.volume_db = -80.0  # Start silent

func play_track_set(track_set: String, crossfade_duration: float = 2.0):
	if track_set == current_track_set:
		return
		
	# Fade out current track set
	if current_track_set != "":
		for layer in active_layers[current_track_set].values():
			layer.fade_out(crossfade_duration)
			
	# Start new track set
	current_track_set = track_set
	for layer in active_layers[track_set].values():
		layer.player.play()
		# Only fade in base layer initially
		if layer == active_layers[track_set]["base"]:
			layer.fade_in(crossfade_duration)
		else:
			layer.player.volume_db = -80.0

func trigger_layer(layer_name: String, fade_duration: float = 1.0):
	if current_track_set == "":
		return
		
	if layer_name in active_layers[current_track_set]:
		active_layers[current_track_set][layer_name].fade_in(fade_duration)

func remove_layer(layer_name: String, fade_duration: float = 1.0):
	if current_track_set == "":
		return
		
	if layer_name in active_layers[current_track_set]:
		active_layers[current_track_set][layer_name].fade_out(fade_duration)

# Event-based layer control
func handle_intensity_change(intensity: float):
	if current_track_set == "":
		return
		
	# Example: Fade in action layer based on intensity
	if "action" in active_layers[current_track_set]:
		var action_layer = active_layers[current_track_set]["action"]
		action_layer.volume_db = -40 + (intensity * 40)  # Scale volume with intensity
		if intensity > 0.3:  # Threshold for action layer
			action_layer.fade_in()
		else:
			action_layer.fade_out()

func pause():
	for track_set in active_layers.values():
		for layer in track_set.values():
			layer.player.stream_paused = true

func resume():
	for track_set in active_layers.values():
		for layer in track_set.values():
			layer.player.stream_paused = false

# Utility method to ensure all music files are properly loaded
func validate_music_files() -> bool:
	var all_valid = true
	for track_set in music_tracks:
		for layer_name in music_tracks[track_set]:
			if not music_tracks[track_set][layer_name]:
				push_error("Missing music file: " + track_set + "/" + layer_name)
				all_valid = false
	return all_valid

extends Node

class_name EnemySoundSystem

enum Priority { LOW, MEDIUM, HIGH }

# Sound pool with distance-based volume control
class SpatialSoundPool:
	var players: Array[AudioStreamPlayer2D] = []
	var active_count: int = 0
	var min_interval: float
	var max_distance: float
	
	func _init(size: int, interval: float, distance: float):
		min_interval = interval
		max_distance = distance
		for i in range(size):
			var player = AudioStreamPlayer2D.new()
			player.bus = "SFX"
			player.max_distance = distance
			players.append(player)

# Configuration for different enemy types
const ENEMY_CONFIG = {
	"basic": {
		"pool_size": 5,
		"interval": 0.1,
		"max_distance": 800.0
	},
	"rigid": {  # Add configuration for rigid enemies
		"pool_size": 5,
		"interval": 0.1,
		"max_distance": 800.0
	}
}

# Sound assets preloading
var enemy_sounds = {
	"basic": {
		"attack": [
			preload("res://Sounds/player/gun1.ogg"),
			preload("res://Sounds/player/gun1.ogg")
		],
		"hit": [
			preload("res://Sounds/enemies/enemyhit.ogg")
		],
		"death": preload("res://Sounds/enemies/enemyhurt.ogg")
	},
	"rigid": {
		"attack": [
			preload("res://Sounds/player/gun1.ogg"),
			preload("res://Sounds/player/gun1.ogg")
		],
		"hit": [
			preload("res://Sounds/enemies/enemyhit.ogg")
		],
		"death": preload("res://Sounds/enemies/enemyhurt.ogg")
	}
}

# Sound pools for each enemy type
var sound_pools: Dictionary = {}
var last_played_times: Dictionary = {}
var cached_streams: Dictionary = {}

# Camera reference for distance culling
var camera: Camera2D

func _ready():
	setup_sound_pools()
	cache_sound_streams()
	setup_camera_reference()

func setup_sound_pools():
	for enemy_type in ENEMY_CONFIG:
		var config = ENEMY_CONFIG[enemy_type]
		var pool = SpatialSoundPool.new(
			config.pool_size,
			config.interval,
			config.max_distance
		)
		for player in pool.players:
			add_child(player)
			player.finished.connect(
				func(): _on_sound_finished(enemy_type, player)
			)
		sound_pools[enemy_type] = pool

func cache_sound_streams():
	for enemy_type in enemy_sounds:
		cached_streams[enemy_type] = {}
		for sound_name in enemy_sounds[enemy_type]:
			cached_streams[enemy_type][sound_name] = enemy_sounds[enemy_type][sound_name]

func setup_camera_reference():
	# Wait for the scene to be ready
	await get_tree().create_timer(0.1).timeout
	camera = get_viewport().get_camera_2d()
	if not camera:
		push_warning("EnemySoundSystem: No Camera2D found in scene")

func play_enemy_sound(enemy_type: String, sound_name: String, position: Vector2, 
					 priority: Priority = Priority.MEDIUM, volume_db: float = 0.0) -> bool:
	if not can_play_sound(enemy_type, sound_name, position):
		return false
		
	if not sound_pools.has(enemy_type):
		push_warning("Unknown enemy type: " + enemy_type)
		return false
		
	var pool = sound_pools[enemy_type]
	
	# Get player based on priority
	var player = get_available_player(pool, priority)
	if not player:
		return false
		
	# Set up the sound
	var stream = get_sound_stream(enemy_type, sound_name)
	if not stream:
		return false
		
	# Calculate distance-based volume
	var final_volume = calculate_distance_volume(position, volume_db)
	
	# Add slight variations
	var pitch_scale = 1.0 + randf_range(-0.1, 0.1)
	
	# Update player and play sound
	player.stream = stream
	player.volume_db = final_volume
	player.pitch_scale = pitch_scale
	player.position = position
	player.play()
	
	# Update tracking
	var current_time = Time.get_ticks_msec() / 1000.0
	last_played_times[enemy_type + "_" + sound_name] = current_time
	pool.active_count += 1
	
	return true

func get_available_player(pool: SpatialSoundPool, priority: Priority) -> AudioStreamPlayer2D:
	# First try to find an inactive player
	for player in pool.players:
		if not player.playing:
			return player
	
	# If no free players, handle based on priority
	match priority:
		Priority.LOW:
			return null
		Priority.MEDIUM:
			# Try to find a distant sound to override
			for player in pool.players:
				var distance = player.position.distance_to(camera.position)
				if distance > pool.max_distance * 0.8:  # 80% of max distance
					return player
			return null
		Priority.HIGH:
			# Take the oldest playing sound
			return pool.players[0]
	
	return null

func calculate_distance_volume(position: Vector2, base_volume: float) -> float:
	if not camera:
		return base_volume
		
	var distance = position.distance_to(camera.position)
	var max_distance = ENEMY_CONFIG["basic"].max_distance  # Use basic enemy distance as default
	
	# Linear falloff with distance
	var distance_factor = clamp(1.0 - (distance / max_distance), 0.0, 1.0)
	return base_volume - (1.0 - distance_factor) * 40  # 40 dB falloff at max distance

func can_play_sound(enemy_type: String, sound_name: String, position: Vector2) -> bool:
	if not camera:
		return true
		
	# Check distance culling
	var distance = position.distance_to(camera.position)
	if distance > ENEMY_CONFIG[enemy_type].max_distance:
		return false
		
	# Check rate limiting
	var current_time = Time.get_ticks_msec() / 1000.0
	var sound_key = enemy_type + "_" + sound_name
	if sound_key in last_played_times:
		var elapsed = current_time - last_played_times[sound_key]
		return elapsed >= ENEMY_CONFIG[enemy_type].interval
		
	return true

func get_sound_stream(enemy_type: String, sound_name: String) -> AudioStream:
	if enemy_type in cached_streams and sound_name in cached_streams[enemy_type]:
		var stream = cached_streams[enemy_type][sound_name]
		if stream is Array:
			return stream[randi() % stream.size()]
		return stream
	return null

func _on_sound_finished(enemy_type: String, player: AudioStreamPlayer2D):
	var pool = sound_pools[enemy_type]
	pool.active_count = max(0, pool.active_count - 1)

# Convenience methods for common enemy actions
func play_spawn_sound(enemy_type: String, position: Vector2):
	play_enemy_sound(enemy_type, "spawn", position, Priority.HIGH)

func play_attack_sound(enemy_type: String, position: Vector2):
	play_enemy_sound(enemy_type, "attack", position, Priority.MEDIUM)

func play_hit_sound(enemy_type: String, position: Vector2):
	#print("DEBUG: play_hit_sound called in EnemySoundSystem")
	#print("DEBUG: enemy_type =", enemy_type)
	#print("DEBUG: position =", position)
	
	# Debug sound pool access
	if not sound_pools.has(enemy_type):
		#print("DEBUG: No sound pool found for enemy type:", enemy_type)
		return false
		
	var pool = sound_pools[enemy_type]
	#print("DEBUG: Found sound pool for enemy type:", enemy_type)
	
	# Debug sound stream
	var stream = get_sound_stream(enemy_type, "hit")
	#if stream:
		#print("DEBUG: Found hit sound stream")
	#else:
		#print("DEBUG: No hit sound stream found!")
	
	return play_enemy_sound(enemy_type, "hit", position, Priority.LOW)

func play_death_sound(enemy_type: String, position: Vector2):
	play_enemy_sound(enemy_type, "death", position, Priority.HIGH)

func play_boss_phase_change(position: Vector2):
	play_enemy_sound("boss", "phase_change", position, Priority.HIGH)

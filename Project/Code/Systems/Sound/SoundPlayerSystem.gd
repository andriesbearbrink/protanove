extends Node

class_name PlayerSoundSystem

# Sound Categories
enum SoundCategory { MOVEMENT, WEAPON, STATE }
enum Priority { LOW, MEDIUM, HIGH }

# Add weapon bus index tracker
var weapon_bus_idx: int = -1

var engine_player: AudioStreamPlayer
var engine_sound_active: bool = false

const ENGINE_MIN_VOLUME: float = -40.0  # Near silent
const ENGINE_MAX_VOLUME: float = 0   # Full volume
const THRUST_NORMALIZATION_FACTOR: float = 12.0  # Base value to normalize against

# Add fade speed constants
const VOLUME_FADE_IN_SPEED: float = 0.1   # Speed when volume is increasing
const VOLUME_FADE_OUT_SPEED: float = 0.01  # Slower speed when volume is decreasing

const ENGINE_MIN_PITCH: float = 0.7
const ENGINE_MAX_PITCH: float = 1.3
const ENGINE_BASE_PITCH: float = 1.0

# Sound pools for different categories
class SoundPool:
	var players: Array[AudioStreamPlayer] = []
	var active_count: int = 0
	var last_played_time: float = 0.0
	var min_interval: float
	
	func _init(size: int, interval: float):
		min_interval = interval
		for i in range(size):
			var player = AudioStreamPlayer.new()
			player.bus = "SFX"
			players.append(player)

# Pool configuration
const POOL_CONFIG = {
	SoundCategory.MOVEMENT: {"size": 3, "interval": 0.1},
	SoundCategory.WEAPON: {"size": 5, "interval": 0.05},
	SoundCategory.STATE: {"size": 2, "interval": 0.2}
}

# Sound assets
var movement_sounds = {
	"engine": [
		preload("res://Sounds/player/enginecrystal.ogg")
	],
	"dash": preload("res://Sounds/enemies/braap.ogg")
}

var weapon_sounds = {
	"shoot": [
		preload("res://Sounds/player/gun3.ogg"),
	]
}

var state_sounds = {
	"hurt": preload("res://Sounds/player/moan.ogg"),
	"die": preload("res://Sounds/enemies/braap.ogg")
}

# Sound pools
var sound_pools: Dictionary = {}

# Cache for audio streams to avoid dictionary lookups
var cached_streams: Dictionary = {}

# Cooldown tracking
var sound_cooldowns: Dictionary = {}

func _ready():
	setup_sound_pools()
	cache_sound_streams()
	setup_weapon_effects()
	setup_engine_sound()
	check_audio_settings()  # Add this line to check audio settings

	
func setup_engine_sound():
	engine_player = AudioStreamPlayer.new()
	engine_player.bus = "SFX"
	engine_player.stream = preload("res://Sounds/player/enginecrystal.ogg")
	engine_player.volume_db = ENGINE_MIN_VOLUME
	engine_player.pitch_scale = ENGINE_BASE_PITCH
	
	print("Engine sound setup - Initial volume:", engine_player.volume_db)

	
	add_child(engine_player)
	# Start playing immediately but at minimum volume
	engine_player.play()
	print("Engine sound started playing")

	
func setup_weapon_effects():
	# Create a new bus for weapons
	weapon_bus_idx = AudioServer.get_bus_count()
	AudioServer.add_bus()
	AudioServer.set_bus_name(weapon_bus_idx, "Weapons")
	AudioServer.set_bus_send(weapon_bus_idx, "SFX")  # Route to SFX bus
	
	# Add reverb
	var reverb = AudioEffectReverb.new()
	reverb.room_size = 0.5
	reverb.damping = 0.2
	reverb.spread = 0.8
	reverb.wet = 0.15  # Reverb mix
	AudioServer.add_bus_effect(weapon_bus_idx, reverb, 0)
	
	# Add EQ with correct band setup
	var eq = AudioEffectEQ6.new()
	# Configure each band properly
	for i in range(6):
		if i == 0:  # Low frequencies
			eq.set_band_gain_db(i, -5.0)
		elif i == 5:  # High frequencies
			eq.set_band_gain_db(i, 3.0)
		else:
			eq.set_band_gain_db(i, 0.0)
	AudioServer.add_bus_effect(weapon_bus_idx, eq, 1)
	
	# Add limiter
	var limiter = AudioEffectLimiter.new()
	limiter.threshold_db = -3.0
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(weapon_bus_idx, limiter, 2)
	
	# Add subtle distortion
	var dist = AudioEffectDistortion.new()
	dist.drive = 0.1
	dist.keep_hf_hz = 4000.0
	AudioServer.add_bus_effect(weapon_bus_idx, dist, 3)
	
	print("Weapon effects bus setup complete")

# Modify the setup_sound_pools method
func setup_sound_pools():
	for category in POOL_CONFIG:
		var config = POOL_CONFIG[category]
		var pool = SoundPool.new(config.size, config.interval)
		for player in pool.players:
			add_child(player)
			# Route weapon sounds to the weapon bus
			if category == SoundCategory.WEAPON:
				player.bus = "Weapons"
			else:
				player.bus = "SFX"
			player.finished.connect(
				func(): _on_sound_finished(category, player)
			)
		sound_pools[category] = pool

func cache_sound_streams():
	# Cache individual sounds
	for sound_name in state_sounds:
		cached_streams[sound_name] = state_sounds[sound_name]
	
	# Cache arrays of sound variations
	for sound_name in movement_sounds:
		if movement_sounds[sound_name] is Array:
			cached_streams[sound_name] = movement_sounds[sound_name]
		else:
			cached_streams[sound_name] = movement_sounds[sound_name]
	
	for sound_name in weapon_sounds:
		if weapon_sounds[sound_name] is Array:
			cached_streams[sound_name] = weapon_sounds[sound_name]
		else:
			cached_streams[sound_name] = weapon_sounds[sound_name]

# Modify the play_sound method to include more dynamic variations
func play_sound(category: SoundCategory, sound_name: String, priority: Priority = Priority.MEDIUM, volume_db: float = 0.0, pitch_scale: float = 1.0) -> bool:
	if not can_play_sound(category, sound_name):
		return false
	
	var pool = sound_pools[category]
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if current_time - pool.last_played_time < pool.min_interval:
		return false
	
	var player = get_player_for_priority(pool, priority)
	if not player:
		return false
	
	var stream = get_sound_stream(sound_name)
	if not stream:
		return false
	
	# Enhanced variations for weapon sounds
	var final_volume = volume_db
	var final_pitch = pitch_scale
	
	if category == SoundCategory.WEAPON:
		# More dramatic variations for weapons
		final_volume += randf_range(-2.0, 2.0)
		final_pitch += randf_range(-0.15, 0.15)
		
		# Dynamically adjust effect parameters for variety
		if weapon_bus_idx != -1:
			var reverb = AudioServer.get_bus_effect(weapon_bus_idx, 0) as AudioEffectReverb
			if reverb:
				reverb.room_size = randf_range(0.4, 0.6)
				reverb.wet = randf_range(0.1, 0.2)
	else:
		# Subtle variations for other sounds
		final_volume += randf_range(-1.0, 1.0)
		final_pitch += randf_range(-0.05, 0.05)
	
	player.stream = stream
	player.volume_db = final_volume
	player.pitch_scale = final_pitch
	player.play()
	
	pool.last_played_time = current_time
	pool.active_count += 1
	sound_cooldowns[sound_name] = current_time
	
	return true
	
# Add methods to dynamically adjust effects
func set_weapon_reverb(amount: float):
	if weapon_bus_idx != -1:
		var reverb = AudioServer.get_bus_effect(weapon_bus_idx, 0) as AudioEffectReverb
		if reverb:
			reverb.wet = clamp(amount, 0.0, 1.0)

func set_weapon_distortion(amount: float):
	if weapon_bus_idx != -1:
		var dist = AudioServer.get_bus_effect(weapon_bus_idx, 3) as AudioEffectDistortion
		if dist:
			dist.drive = clamp(amount, 0.0, 1.0)

# Convenience methods for different sound categories
# Add pitch parameter to play_movement_sound
func play_movement_sound(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> bool:
	return play_sound(SoundCategory.MOVEMENT, sound_name, Priority.LOW, volume_db, pitch)

func play_weapon_sound(sound_name: String, volume_db: float = 0.0) -> bool:
	return play_sound(SoundCategory.WEAPON, sound_name, Priority.HIGH, volume_db)

func play_state_sound(sound_name: String, volume_db: float = 0.0) -> bool:
	return play_sound(SoundCategory.STATE, sound_name, Priority.MEDIUM, volume_db)

# Helper methods
func get_sound_stream(sound_name: String) -> AudioStream:
	if sound_name in cached_streams:
		var stream = cached_streams[sound_name]
		if stream is Array:
			return stream[randi() % stream.size()]
		return stream
	return null

func get_player_for_priority(pool: SoundPool, priority: Priority) -> AudioStreamPlayer:
	# First try to get an available player
	for player in pool.players:
		if not player.playing:
			return player
	
	# If no players available, handle based on priority
	match priority:
		Priority.LOW:
			return null
		Priority.MEDIUM:
			# Try to steal from a low priority sound
			for player in pool.players:
				if player.volume_db < -10:  # Assuming lower volume = lower priority
					return player
			return null
		Priority.HIGH:
			# Take the oldest playing sound
			return pool.players[0]
	
	return null

func can_play_sound(category: SoundCategory, sound_name: String) -> bool:
	if not sound_pools.has(category):
		return false
	
	var current_time = Time.get_ticks_msec() / 1000.0
	if sound_name in sound_cooldowns:
		var elapsed = current_time - sound_cooldowns[sound_name]
		var cooldown = POOL_CONFIG[category].interval
		return elapsed >= cooldown
	
	return true

func _on_sound_finished(category: SoundCategory, player: AudioStreamPlayer):
	var pool = sound_pools[category]
	pool.active_count = max(0, pool.active_count - 1)

# Movement sound handling
func handle_movement(velocity: Vector2, thrust: float) -> void:
	if not engine_player.playing:
		engine_player.play()
	
	var thrust_magnitude = abs(thrust)
	var normalized_thrust = clamp(thrust_magnitude / THRUST_NORMALIZATION_FACTOR, 0.0, 1.0)
	
	var target_volume = lerp(ENGINE_MIN_VOLUME, ENGINE_MAX_VOLUME, normalized_thrust)
	
	# Choose fade speed based on whether we're increasing or decreasing volume
	var fade_speed = VOLUME_FADE_IN_SPEED
	if target_volume < engine_player.volume_db:
		fade_speed = VOLUME_FADE_OUT_SPEED  # Use slower fade when volume is decreasing
	
	var speed = velocity.length()
	var normalized_speed = clamp(speed / 300.0, 0.0, 1.0)
	var target_pitch = lerp(ENGINE_MIN_PITCH, ENGINE_MAX_PITCH, normalized_speed)
	
	# Apply volume change with appropriate fade speed
	engine_player.volume_db = lerpf(engine_player.volume_db, target_volume, fade_speed)
	engine_player.pitch_scale = lerpf(engine_player.pitch_scale, target_pitch, 0.1)


# Modify handle_weapon_action to use more dynamic variations
func handle_weapon_action(action: String, weapon_type: String = ""):
	match action:
		"shoot":
			var base_volume = -500.0
			var base_pitch = 1.0
			
			# Alternate between different pitch ranges
			if randf() > 0.5:
				base_pitch = randf_range(0.95, 10.05)
			else:
				base_pitch = randf_range(0.85, 0.95)
			
			play_sound(SoundCategory.WEAPON, "shoot", Priority.HIGH, base_volume, base_pitch)

# State change sound handling
func handle_state_change(new_state: String, data: Dictionary = {}):
	match new_state:
		"hurt":
			play_state_sound("hurt", -200.0)
		"heal":
			play_state_sound("heal", -5.0)
		"levelup":
			play_state_sound("levelup", 0.0) 
		"die":
			play_state_sound("die", 0.0)
			
# Add a debug method to check audio bus settings
func check_audio_settings():
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	if sfx_bus_idx >= 0:
		print("SFX Bus Settings:")
		print("- Volume:", AudioServer.get_bus_volume_db(sfx_bus_idx))
		print("- Muted:", AudioServer.is_bus_mute(sfx_bus_idx))
	else:
		print("SFX bus not found!")

# System control
func pause():
	for pool in sound_pools.values():
		for player in pool.players:
			player.stream_paused = true
	engine_player.stream_paused = true

func resume():
	for pool in sound_pools.values():
		for player in pool.players:
			player.stream_paused = false
	engine_player.stream_paused = false

# Clean up
func _exit_tree():
	for pool in sound_pools.values():
		for player in pool.players:
			player.queue_free()
	if is_instance_valid(engine_player):
		engine_player.queue_free()

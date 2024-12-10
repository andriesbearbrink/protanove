extends Area2D

class_name ExperienceOrb

@export var exp_value: int = 1
@export var base_move_speed: float = 20.0  # Renamed from move_speed
@export var max_move_speed: float = 200.0  # Maximum movement speed when close
@export var attraction_distance: float = 50.0
@export var initial_speed: float = 20.0
@export var deceleration: float = 4.0
@export var lifetime: float = 3.0
@export var fade_duration: float = 5.0
@export var base_throb_speed: float = 2.0
@export var base_throb_intensity: float = 0.1
@export var phase_shift_speed: float = 30.0  # How fast the phase shifts during fade


var target: Node2D = null
var velocity: Vector2 = Vector2.ZERO
var is_scattered: bool = true
var time_alive: float = 0.0
var is_fading: bool = false
@onready var mesh_instance = $MeshInstance2D

var original_shape_colors: Array[Color] = []
var shader_material: ShaderMaterial

func _process(delta):
	time_alive += delta
	
	if time_alive >= lifetime:
		is_fading = true
		var fade_progress = (time_alive - lifetime) / fade_duration
		if fade_progress >= 1.0:
			queue_free()
			return
			
		# Update colors for fading
		for i in range(5):
			var original_color = original_shape_colors[i]
			var faded_color = Color(
				original_color.r,
				original_color.g,
				original_color.b,
				original_color.a * (1.0 - fade_progress)
			)
			shader_material.set_shader_parameter("shape_" + str(i) + "_color", faded_color)
			
		# Instead of changing speed, shift the phase during fade
		var phase_shift = fade_progress * phase_shift_speed
		shader_material.set_shader_parameter("phase_shift", phase_shift * fade_progress)
		
		# Optionally increase intensity slightly during fade
		var current_intensity = base_throb_intensity * (1.0 + fade_progress * 0.9)
		shader_material.set_shader_parameter("throb_intensity", current_intensity)

func _physics_process(delta):
	var player_manager = get_node_or_null("/root/MainGame/PlayerManager")
	var should_attract = false
	var attraction_velocity = Vector2.ZERO
	
	# First check if we should be attracted to a player
	if player_manager:
		var closest_player = player_manager.get_closest_player(global_position)
		if closest_player:
			var distance = global_position.distance_to(closest_player.global_position)
			if distance < attraction_distance:
				if target == null:
					target = closest_player
				
				if target and target.is_inside_tree():
					var direction = (target.global_position - global_position).normalized()
					var distance_factor = 1.0 - (distance / attraction_distance)
					var current_speed = lerp(base_move_speed, max_move_speed, distance_factor)
					
					if is_fading:
						var fade_progress = (time_alive - lifetime) / fade_duration
						current_speed *= 1.0 + fade_progress
					
					attraction_velocity = direction * current_speed
					should_attract = true
	
	# Apply scattering movement, but allow attraction to override
	if is_scattered:
		position += velocity * delta
		
		if velocity.length() > 0:
			var decel_amount = deceleration * delta
			if velocity.length() > decel_amount:
				velocity = velocity.normalized() * (velocity.length() - decel_amount)
			else:
				velocity = Vector2.ZERO
				is_scattered = false
	
	# If we should attract, add attraction velocity to current movement
	if should_attract:
		# Blend between scatter and attraction based on distance
		var blend_factor = 1  # Adjust this to control how quickly attraction takes over
		position += attraction_velocity * delta * blend_factor

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	shader_material = mesh_instance.material.duplicate() as ShaderMaterial
	mesh_instance.material = shader_material
	
	# Set constant throb speed and initial intensity
	shader_material.set_shader_parameter("throb_speed", base_throb_speed)
	shader_material.set_shader_parameter("throb_intensity", base_throb_intensity)
	shader_material.set_shader_parameter("phase_shift", 0.0)
	
	# Store original colors
	for i in range(5):
		var color = shader_material.get_shader_parameter("shape_" + str(i) + "_color")
		original_shape_colors.append(color)
	
	var random_angle = randf_range(0, 2 * PI)
	velocity = Vector2(cos(random_angle), sin(random_angle)) * initial_speed

func set_exp_value(value: int):
	exp_value = value
	
	# Scale the orb size based on value
	var base_scale = 1.0
	var scale_multiplier = 1.0 + log(float(value)) * 0.1
	scale = Vector2.ONE * base_scale * scale_multiplier
	
	# Adjust lifetime based on value (optional)
	lifetime += log(float(value))

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Create a quick fade out effect when collected
		var tween = create_tween()
		for i in range(5):
			var original_color = original_shape_colors[i]
			tween.parallel().tween_method(
				func(alpha: float):
					var color = original_color
					color.a = alpha
					shader_material.set_shader_parameter("shape_" + str(i) + "_color", color),
				original_color.a,
				0.0,
				0.1
			)
		tween.tween_callback(func():
			print("ExperienceOrb: Player collected exp ", exp_value)
			body.collect_exp(exp_value)
			queue_free()
		)
		
func set_initial_velocity(vel: Vector2):
	velocity = vel
	is_scattered = true

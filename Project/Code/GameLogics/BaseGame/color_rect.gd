extends ColorRect

@export var dot_spacing: float = 50.0:
	set(value):
		dot_spacing = value
		material.set_shader_parameter("dot_spacing", value)

@export var dot_color: Color = Color(1, 1, 1, 0.5):
	set(value):
		dot_color = value
		material.set_shader_parameter("dot_color", value)

@export_range(0.0, 2.0) var rotation_speed: float = 0.5:
	set(value):
		rotation_speed = value
		material.set_shader_parameter("speed", value)

@export var player_influence: float = 100.0:
	set(value):
		player_influence = value
		material.set_shader_parameter("player_influence", value)

var player1: Node2D
var player2: Node2D

func _ready():
	# Ensure the ColorRect covers the entire viewport
	anchor_right = 1
	anchor_bottom = 1
	
	# Load and set the shader
	material = ShaderMaterial.new()
	material.shader = load("res://path_to_your_shader.gdshader")
	
	# Set initial shader parameters
	material.set_shader_parameter("color1", Color(0.1, 0.1, 0.3))
	material.set_shader_parameter("color2", Color(0.3, 0.1, 0.5))
	material.set_shader_parameter("color3", Color(0.5, 0.1, 0.3))
	material.set_shader_parameter("color4", Color(0.3, 0.1, 0.1))
	
	# Apply exported variables
	self.dot_spacing = dot_spacing
	self.dot_color = dot_color
	self.rotation_speed = rotation_speed
	self.player_influence = player_influence
	
	# Set up the scaling
	set_scaling()
	get_tree().root.size_changed.connect(set_scaling)
	
	# Find player nodes (adjust paths as needed)
	player1 = get_node("/root/Main/Player1")
	player2 = get_node("/root/Main/Player2")

func set_scaling():
	# Ensure the ColorRect always covers the entire viewport
	size = get_viewport_rect().size

func _process(delta):
	if player1 and player2:
		update_player_positions()

func update_player_positions():
	var viewport_size = get_viewport_rect().size
	var p1_pos = player1.global_position / viewport_size
	var p2_pos = player2.global_position / viewport_size
	material.set_shader_parameter("player1_pos", p1_pos)
	material.set_shader_parameter("player2_pos", p2_pos)

func set_gradient_colors(col1: Color, col2: Color, col3: Color, col4: Color):
	material.set_shader_parameter("color1", col1)
	material.set_shader_parameter("color2", col2)
	material.set_shader_parameter("color3", col3)
	material.set_shader_parameter("color4", col4)

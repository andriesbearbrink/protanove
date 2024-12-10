extends Node

class Ripple:
	var center: Vector2
	var strength: float
	var size: float
	var time: float
	var duration: float

	func _init(c: Vector2, s: float, sz: float, d: float):
		center = c
		strength = s
		size = sz
		time = 0.0
		duration = d

var ripples: Array[Ripple] = []
var background_shader: ShaderMaterial

@export var background_node_path: NodePath

func _ready():
	if not background_node_path.is_empty():
		var background_node = get_node(background_node_path)
		if background_node and background_node.material is ShaderMaterial:
			background_shader = background_node.material
		else:
			push_error("Background node does not have a ShaderMaterial")
	else:
		push_error("Background node path not set in RippleManager")

func _process(delta):
	if not background_shader:
		return

	var i = ripples.size() - 1
	while i >= 0:
		var ripple = ripples[i]
		ripple.time += delta
		
		if ripple.time >= ripple.duration:
			ripples.remove_at(i)
		else:
			var t = ripple.time / ripple.duration
			var current_strength = ripple.strength * (1.0 - t)
			background_shader.set_shader_parameter("ripple_center", ripple.center)
			background_shader.set_shader_parameter("ripple_strength", current_strength)
			background_shader.set_shader_parameter("ripple_size", ripple.size)
			background_shader.set_shader_parameter("ripple_time", ripple.time)
		
		i -= 1

func create_ripple(position: Vector2, strength: float = 0.5, size: float = 30.0, duration: float = 1.0):
	if background_shader:
		var ripple = Ripple.new(position, strength, size, duration)
		ripples.append(ripple)
	else:
		push_warning("Cannot create ripple: background shader not set")

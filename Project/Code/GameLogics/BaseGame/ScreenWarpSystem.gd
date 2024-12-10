extends Node2D

class_name ScreenWrapSystem

var screen_size: Vector2
var wrap_margin: float = 10.0

signal object_warped(object: Node2D, old_position: Vector2, new_position: Vector2)

func _ready():
	screen_size = get_viewport_rect().size

func wrap_position(pos: Vector2) -> Vector2:
	var new_pos = pos
	var warped = false
	
	if pos.x < -wrap_margin:
		new_pos.x = screen_size.x + wrap_margin
		warped = true
	elif pos.x > screen_size.x + wrap_margin:
		new_pos.x = -wrap_margin
		warped = true
	
	if pos.y < -wrap_margin:
		new_pos.y = screen_size.y + wrap_margin
		warped = true
	elif pos.y > screen_size.y + wrap_margin:
		new_pos.y = -wrap_margin
		warped = true
	
	if warped:
		emit_signal("object_warped", null, pos, new_pos)
	
	return new_pos

func wrap_object(obj: Node2D):
	var old_pos = obj.global_position
	var new_pos = wrap_position(old_pos)
	if old_pos != new_pos:
		obj.global_position = new_pos
		emit_signal("object_warped", obj, old_pos, new_pos)

func update_screen_size():
	screen_size = get_viewport_rect().size

class_name InputHandler
extends Resource

func get_movement_vector() -> Vector2:
	return Vector2.ZERO

func is_shooting() -> bool:
	return false

func get_aim_vector() -> Vector2:
	return Vector2.ZERO

# New methods for abilities
func is_dashing() -> bool:
	return false

func is_toggling_aim() -> bool:
	return false

func get_ability_input(ability_name: String) -> bool:
	match ability_name:
		"dash":
			return is_dashing()
		"aim_sight":
			return is_toggling_aim()
	return false

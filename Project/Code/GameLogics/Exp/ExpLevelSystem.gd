extends Node

signal level_up(new_level: int)

@export var base_exp_required: int = 20  # Reduced from 100 to 5 for quicker testing
@export var exp_growth_rate: float = 1.4  # Slightly reduced from 1.5 for slower scaling
@export var player_manager: PlayerManager

var current_level: int = 1
var current_exp: int = 0
var exp_to_next_level: int

func _ready():
	exp_to_next_level = calculate_exp_for_level(current_level + 1)

func add_exp(amount: int, player_index: int):
	current_exp += amount
	print("Added %d exp. Current exp: %d/%d" % [amount, current_exp, exp_to_next_level])
	while current_exp >= exp_to_next_level:
		increase_level(player_index)

func increase_level(player_index: int):
	current_level += 1
	current_exp -= exp_to_next_level
	exp_to_next_level = calculate_exp_for_level(current_level + 1)
	print("Level up! New level: %d. Exp to next level: %d" % [current_level, exp_to_next_level])
	print("ExpLevelSystem: Emitting level_up signal with player_index: ", player_index, " and current_level: ", current_level)
	emit_signal("level_up", player_index, current_level)

func calculate_exp_for_level(level: int) -> int:
	var player_count = 1  # Default to 1 player
	
	# Get player count only if player_manager is valid
	if player_manager != null:
		player_count = player_manager.get_player_count()
	
	var scaled_base_exp = base_exp_required * player_count
	return int(scaled_base_exp * pow(exp_growth_rate, level - 1))

func get_current_level() -> int:
	return current_level

func get_current_exp() -> int:
	return current_exp

func get_exp_to_next_level() -> int:
	return exp_to_next_level

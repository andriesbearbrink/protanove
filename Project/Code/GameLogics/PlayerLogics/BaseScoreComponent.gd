extends Node
class_name BaseScoreComponent

signal score_changed(new_score: int)

var score: int = 0
var kills: int = 0
var exp_orbs_collected: int = 0

var player_number: int = 0  # Add this to identify which player this component belongs to

func initialize(player_num: int):
	player_number = player_num

func add_kill():
	kills += 1
	increase_score(1)
	print("SS-Player ", player_number, " scored a kill. Total kills: ", kills)

func add_exp_orb():
	exp_orbs_collected += 1
	increase_score(1)
	print("SS-Player ", player_number, " collected an exp orb. Total orbs: ", exp_orbs_collected)

func increase_score(amount: int):
	score += amount
	emit_signal("score_changed", score)
	print("SS-Player ", player_number, " score increased by ", amount, ". Total score: ", score)

func get_score() -> int:
	return score

func get_kills() -> int:
	return kills

func get_exp_orbs_collected() -> int:
	return exp_orbs_collected

func reset():
	score = 0
	kills = 0
	exp_orbs_collected = 0
	emit_signal("score_changed", score)
	print("SS-Player ", player_number, " score reset. Total score: ", score)

# PlayerProfile.gd
class_name PlayerProfile
extends Resource

@export var name: String = "Player"
@export var color: Color = Color.WHITE
@export var input_device: String = "keyboard"
@export var stats: Dictionary = {
	"games_played": 0,
	"total_score": 0,
	"high_score": 0
}

func update_stats(score: int):
	stats["games_played"] += 1
	stats["total_score"] += score
	if score > stats["high_score"]:
		stats["high_score"] = score

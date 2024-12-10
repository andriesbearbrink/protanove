extends Node
class_name BaseHealthComponent

signal health_changed(new_health, max_health)
signal player_died

@export var max_health: float = 1000.0
@export var current_health: float = max_health

var is_invulnerable: bool = false
var invulnerability_timer: Timer

var player: Node  # Reference to the player node

func _ready():
	setup_invulnerability_timer()

func setup_invulnerability_timer():
	invulnerability_timer = Timer.new()
	invulnerability_timer.one_shot = true
	invulnerability_timer.connect("timeout", Callable(self, "_on_invulnerability_timer_timeout"))
	add_child(invulnerability_timer)

func initialize(player_node: Node):
	player = player_node

func take_damage(amount: float, player_number: int = -1) -> void:
	if is_invulnerable:
		return

	current_health = max(current_health - amount, 0)
	emit_signal("health_changed", current_health, max_health)
	
	print("Player took ", amount, " damage from Player ", player_number if player_number != -1 else "unknown")
	
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	emit_signal("health_changed", current_health, max_health)
	
	print("Player healed ", amount, ". Current health: ", current_health)

func die() -> void:
	emit_signal("player_died")
	print("Player died")

func reset_health() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)

func set_max_health(new_max_health: float) -> void:
	max_health = new_max_health
	current_health = min(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

func get_health_percentage() -> float:
	return current_health / max_health

func set_invulnerable(duration: float) -> void:
	is_invulnerable = true
	invulnerability_timer.start(duration)

func _on_invulnerability_timer_timeout() -> void:
	is_invulnerable = false

# Optional: Method to apply a health modifier (could be used for temporary max health boosts)
func apply_health_modifier(modifier: float, duration: float = 0.0) -> void:
	var old_max_health = max_health
	max_health *= modifier
	current_health = (current_health / old_max_health) * max_health
	emit_signal("health_changed", current_health, max_health)
	
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		max_health = old_max_health
		current_health = min(current_health, max_health)
		emit_signal("health_changed", current_health, max_health)

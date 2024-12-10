extends Node
class_name BaseAbility

var player: Node
var is_on_cooldown: bool = false
var cooldown: float = 1.0
var cooldown_remaining: float = 0.0
var cooldown_timer: Timer

func _ready():
	setup_cooldown_timer()

func initialize(player_node: Node):
	player = player_node

func setup_cooldown_timer():
	cooldown_timer = Timer.new()
	cooldown_timer.one_shot = true
	cooldown_timer.connect("timeout", Callable(self, "_on_cooldown_finished"))
	add_child(cooldown_timer)

func can_use() -> bool:
	return not is_on_cooldown

func use():
	if can_use():
		perform_ability()
		start_cooldown()

func perform_ability():
	# Override in child classes
	pass

func start_cooldown():
	is_on_cooldown = true
	cooldown_remaining = cooldown
	cooldown_timer.start(cooldown)

func _process(delta):
	if is_on_cooldown:
		cooldown_remaining = max(0.0, cooldown_timer.time_left)

func _on_cooldown_finished():
	is_on_cooldown = false
	cooldown_remaining = 0.0

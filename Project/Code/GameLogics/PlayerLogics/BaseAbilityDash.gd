extends BaseAbility
class_name DashAbility

@export var dash_speed: float = 500.0
@export var dash_duration: float = 0.5
@export var dash_cooldown: float = 1.0 

var is_dashing: bool = false
var dash_direction: Vector2
var dash_timer: Timer
var original_speed: float

func _ready():
	super._ready()
	cooldown = dash_cooldown
	setup_dash_timer()

func setup_dash_timer():
	dash_timer = Timer.new()
	dash_timer.one_shot = true
	dash_timer.connect("timeout", Callable(self, "_on_dash_finished"))
	add_child(dash_timer)

func perform_ability():
	if not player or not player is BasePlayer:
		return

	is_dashing = true
	original_speed = player.max_speed
	
	# Use the input direction from the input component instead of velocity
	if player.input_component and player.input_component.input_handler:
		var input_direction = player.input_component.input_handler.get_movement_vector()
		if input_direction.length() > 0.1:
			dash_direction = input_direction.normalized()
		else:
			# If no input direction, use the direction the player is facing
			dash_direction = Vector2.RIGHT.rotated(player.rotation)
	else:
		dash_direction = Vector2.RIGHT.rotated(player.rotation)
	
	# Apply the dash
	player.velocity = dash_direction * dash_speed
	dash_timer.start(dash_duration)


func _physics_process(delta):
	if is_dashing:
		player.velocity = dash_direction * dash_speed

func _on_dash_finished():
	is_dashing = false
	if player:
		player.velocity = dash_direction * ( original_speed * 0.5 )

extends BaseAbility
class_name AimSightAbility

var aim_line: Line2D
var max_length: float = 200.0
var is_active: bool = false
var start_width: float = 2.0  # Starting width of the line

func _ready():
	super._ready()
	setup_aim_line()

func setup_aim_line():
	aim_line = Line2D.new()
	aim_line.width = start_width
	aim_line.default_color = Color(1, 1, 1, 0.2)
	aim_line.top_level = true  # Make the line independent of parent transforms
	aim_line.width_curve = create_width_curve()  # Add the width curve
	
	if player:
		player.add_child(aim_line)
	else:
		add_child(aim_line)

func create_width_curve() -> Curve:
	var curve = Curve.new()
	curve.add_point(Vector2(1, 0))  # End at zero width
	curve.add_point(Vector2(0, 1))  # Start at full width
	return curve

func perform_ability():
	is_active = !is_active
	aim_line.visible = is_active

func _process(delta):
	if is_active and player:
		update_aim_line()

func update_aim_line():
	# Always use the player's last_aim_vector for consistency
	var aim_direction = player.last_aim_vector
	
	# Update the line points in global coordinates
	aim_line.clear_points()
	aim_line.add_point(player.bullet_spawn.global_position)  # Start from bullet spawn point
	aim_line.add_point(player.bullet_spawn.global_position + aim_direction * max_length)
	
	# Update the line color based on player's color
	aim_line.default_color = player.player_color
	aim_line.default_color.a = 0.1

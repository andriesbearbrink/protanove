extends ColorRect

var player_manager: Node

func _ready():
	# Get reference to player manager
	player_manager = get_node("/root/MainGame/PlayerManager")
	if not player_manager:
		push_error("ColorRect: Could not find PlayerManager")
		return

func _process(_delta):
	if not player_manager:
		return
		
	var viewport_size = get_viewport_rect().size
	
	# Get player positions and normalize them to UV space (0-1)
	var players = player_manager.players
	var player1_pos = Vector2.ZERO
	var player2_pos = Vector2.ZERO
	
	if players.size() > 0 and is_instance_valid(players[0]):
		player1_pos = players[0].global_position / viewport_size
		
	if players.size() > 1 and is_instance_valid(players[1]):
		player2_pos = players[1].global_position / viewport_size
	
	# Update shader parameters
	material.set_shader_parameter("player1_pos", player1_pos)
	material.set_shader_parameter("player2_pos", player2_pos)

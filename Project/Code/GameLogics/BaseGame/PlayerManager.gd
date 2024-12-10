extends Node
class_name PlayerManager

@export var player_scene: PackedScene

var players = []

func clear_players():
	print("PlayerManager: Clearing ", players.size(), " players")
	for player in players:
		if is_instance_valid(player):
			print("PlayerManager: Removing player: ", player.name)
			player.queue_free()
	players.clear()
	print("PlayerManager: All players cleared")

func get_player(index: int) -> BasePlayer:
	if index < 0 or index >= players.size():
		print("[PlayerManager] Error: Invalid player index ", index, ". Valid range: 0 to ", players.size() - 1)
		return null
	
	var player = players[index]
	if is_instance_valid(player):
		print("[PlayerManager] Returning player: ", player.name, " (index: ", index, ")")
		return player
	else:
		print("[PlayerManager] Error: Player at index ", index, " is no longer valid.")
		return null

func get_player_count(include_dead: bool = true) -> int:
	if include_dead:
		return players.size()
	else:
		return players.filter(func(player): return player.is_alive()).size()
		
func get_alive_player_count() -> int:
	return players.filter(func(player): return player.is_alive()).size()

func get_selectable_player_count() -> int:
	return players.filter(func(player): return player.can_select_perks()).size()

# Update this method to use 1-based indexing
func create_player(player_data, start_position: Vector2):
	if player_scene and player_data is Dictionary:
		var player = player_scene.instantiate()
		var player_number = players.size()
		players.append(player)
		
		print("PlayerManager: Creating player with data:", player_data)
		
		if "profile" in player_data and player_data["profile"] is PlayerProfile:
			player.set_player_name(player_data["profile"].name)
		if "input_device" in player_data:
			player.set_input_device(player_data["input_device"])
		
		player.player_number = player_number + 1
		add_child(player)
		
		player.initialize_components()
		
		# Set color after player is added to the scene and components are initialized
		if "color" in player_data:
			print("PlayerManager: Setting player color to", player_data["color"])
			player.set_color(player_data["color"])
		
		# Set the player's position to the provided start position
		player.position = start_position
		
		return player
	else:
		print("PlayerManager: Invalid player data or player scene not set. Unable to create player.")
		return null

# Remove any other methods that might be creating players unintentionally
func get_closest_player(position: Vector2) -> Node2D:
	var closest_player = null
	var closest_distance = INF
	
	for player in players:
		if is_instance_valid(player) and player.is_alive():
			var distance = position.distance_to(player.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_player = player
	
	return closest_player

func reset_all_players():
	for player in players:
		player.reset()

func remove_all_players():
	for player in players:
		player.queue_free()
	players.clear()

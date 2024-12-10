extends Node

signal game_over

var player_alive = {}
var game_is_over = false

func player_joined(player_number):
	player_alive[player_number] = true
	print("GameStateManager: Player ", player_number, " joined")
	game_is_over = false  # Reset game over state when new player joins

func player_died(player_number):
	if player_number in player_alive:
		player_alive[player_number] = false
		print("GameStateManager: Player ", player_number, " died")
		check_game_over()

func check_game_over():
	if game_is_over:
		return
		
	# Get PlayerManager node directly from MainGame
	var player_manager = get_node_or_null("/root/MainGame/PlayerManager")
	if not player_manager:
		print("GameStateManager: Could not find PlayerManager")
		return
		
	print("GameStateManager: Checking game over condition")
	var all_players_down = true
	
	for player in player_manager.players:
		if is_instance_valid(player):
			print("GameStateManager: Checking player ", player.player_number)
			print("GameStateManager: - State: ", player.player_state)
			print("GameStateManager: - Revives remaining: ", player.revives_remaining)
			
			# Player is still in play if they're alive or have revives left
			if player.player_state == player.PlayerState.ALIVE or player.revives_remaining > 0:
				all_players_down = false
				print("GameStateManager: Player ", player.player_number, " still in play")
				break
			else:
				print("GameStateManager: Player ", player.player_number, " is down")
	
	if all_players_down and player_manager.players.size() > 0:
		game_is_over = true
		print("GameStateManager: All players down - Game Over")
		emit_signal("game_over")
	else:
		print("GameStateManager: Game continues - Some players still in play")

func reset():
	game_is_over = false
	player_alive.clear()

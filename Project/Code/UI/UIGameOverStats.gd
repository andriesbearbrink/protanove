# GameOverPlayerStats.gd
extends PanelContainer

@onready var player_name_label = $VBoxContainer/PlayerName
@onready var stats_grid = $VBoxContainer/StatsGrid

func set_player_info(info: Dictionary):
	# Set player name with their color
	player_name_label.text = info.name
	player_name_label.add_theme_color_override("font_color", info.color)
	
	# Update stats grid
	var stats = [
		["Score", str(info.score)],
		["Kills", str(info.kills)],
		["Orbs Collected", str(info.orbs_collected)]
	]
	
	for stat in stats:
		# Add label for stat name
		var name_label = Label.new()
		name_label.text = stat[0]
		name_label.add_theme_color_override("font_color", info.color.lightened(0.2))
		stats_grid.add_child(name_label)
		
		# Add label for stat value
		var value_label = Label.new()
		value_label.text = stat[1]
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_grid.add_child(value_label)

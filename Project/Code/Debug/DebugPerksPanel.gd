extends Control
class_name PerksDebugPanel

var perk_list: ItemList
var perk_info: VBoxContainer
var active_perks: ItemList
var selected_player_label: Label
var player_selector: SpinBox
var perk_database: PerkDatabase

func _ready():
	setup_ui()
	setup_perk_database()
	load_perks()
	update_player_perks()

func setup_ui():
	# Add padding to the entire panel
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	margin_container.add_theme_constant_override("margin_top", 20)
	margin_container.add_theme_constant_override("margin_bottom", 20)
	add_child(margin_container)
	margin_container.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Main layout
	var hbox = HBoxContainer.new()
	margin_container.add_child(hbox)
	hbox.custom_minimum_size = Vector2(0, 600)  # Set minimum height
	hbox.add_theme_constant_override("separation", 20)  # Space between columns
	
	# Left side (Available Perks)
	var left_side = VBoxContainer.new()
	hbox.add_child(left_side)
	left_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_side.custom_minimum_size = Vector2(400, 0)  # Give more width to perk list
	left_side.add_theme_constant_override("separation", 10)  # Space between elements
	
	var perks_label = Label.new()
	perks_label.text = "Available Perks"
	perks_label.add_theme_font_size_override("font_size", 16)  # Larger font
	left_side.add_child(perks_label)
	
	perk_list = ItemList.new()
	left_side.add_child(perk_list)
	perk_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	perk_list.custom_minimum_size = Vector2(0, 500)  # Ensure good height for list
	perk_list.connect("item_selected", _on_perk_selected)
	
	# Middle (Perk Info and Controls)
	var middle = VBoxContainer.new()
	hbox.add_child(middle)
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.custom_minimum_size = Vector2(300, 0)  # Fixed width for info panel
	middle.add_theme_constant_override("separation", 15)  # Space between elements
	
	selected_player_label = Label.new()
	middle.add_child(selected_player_label)
	selected_player_label.add_theme_font_size_override("font_size", 16)
	
	var player_select_hbox = HBoxContainer.new()
	middle.add_child(player_select_hbox)
	player_select_hbox.add_theme_constant_override("separation", 10)
	
	var player_label = Label.new()
	player_label.text = "Player: "
	player_select_hbox.add_child(player_label)
	
	player_selector = SpinBox.new()
	player_selector.min_value = 1
	player_selector.max_value = 4
	player_selector.value = 1
	player_select_hbox.add_child(player_selector)
	player_selector.connect("value_changed", _on_player_changed)
	
	# Add a Panel behind perk info for better visibility
	var info_panel = PanelContainer.new()
	middle.add_child(info_panel)
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	perk_info = VBoxContainer.new()
	info_panel.add_child(perk_info)
	perk_info.add_theme_constant_override("separation", 10)
	
	var button_container = HBoxContainer.new()
	middle.add_child(button_container)
	button_container.add_theme_constant_override("separation", 10)
	
	var add_button = Button.new()
	add_button.text = "Add Perk"
	add_button.custom_minimum_size = Vector2(100, 40)  # Larger buttons
	button_container.add_child(add_button)
	add_button.connect("pressed", _on_add_perk_pressed)
	
	var reset_button = Button.new()
	reset_button.text = "Reset Perks"
	reset_button.custom_minimum_size = Vector2(100, 40)  # Larger buttons
	button_container.add_child(reset_button)
	reset_button.connect("pressed", _on_reset_perks_pressed)
	
	# Right side (Active Perks)
	var right_side = VBoxContainer.new()
	hbox.add_child(right_side)
	right_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_side.custom_minimum_size = Vector2(300, 0)  # Fixed width for active perks
	right_side.add_theme_constant_override("separation", 10)
	
	var active_label = Label.new()
	active_label.text = "Active Perks"
	active_label.add_theme_font_size_override("font_size", 16)
	right_side.add_child(active_label)
	
	active_perks = ItemList.new()
	right_side.add_child(active_perks)
	active_perks.size_flags_vertical = Control.SIZE_EXPAND_FILL
	active_perks.custom_minimum_size = Vector2(0, 500)  # Ensure good height for list
	active_perks.connect("item_selected", _on_active_perk_selected)

func setup_perk_database():
	perk_database = PerkDatabase.new()

func load_perks():
	perk_list.clear()
	for perk in perk_database.get_all_perks():
		perk_list.add_item(perk.name)
		perk_list.set_item_metadata(perk_list.get_item_count() - 1, perk)

func update_player_perks():
	print("DEBUG: Updating player perks display")
	active_perks.clear()
	var player = get_current_player()
	if player and player.perk_component:
		print("DEBUG: Found player ", player.player_number, " with perks: ", player.perk_component.acquired_perks)
		for perk_id in player.perk_component.acquired_perks:
			var perk = perk_database.get_perk(perk_id)
			if perk:
				var level = player.perk_component.get_perk_level(perk_id)
				print("DEBUG: Adding perk to display - ", perk.name, " (Level ", level, ")")
				active_perks.add_item("%s (Level %d)" % [perk.name, level])
				active_perks.set_item_metadata(active_perks.get_item_count() - 1, perk)
			else:
				print("DEBUG: Failed to find perk with ID: ", perk_id)

func get_current_player() -> BasePlayer:
	var player_manager = get_node("/root/MainGame/PlayerManager")
	if player_manager:
		return player_manager.get_player(int(player_selector.value) - 1)
	return null

func _on_perk_selected(index: int):
	var perk = perk_list.get_item_metadata(index)
	show_perk_info(perk)

func _on_active_perk_selected(index: int):
	var perk = active_perks.get_item_metadata(index)
	show_perk_info(perk)

func show_perk_info(perk: Dictionary):
	# Clear existing info
	for child in perk_info.get_children():
		child.queue_free()
	
	# Add perk information with better formatting
	var title = Label.new()
	title.text = perk.name
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	perk_info.add_child(title)
	
	var desc = Label.new()
	desc.text = perk.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_constant_override("line_spacing", 5)
	perk_info.add_child(desc)
	
	# Add separator
	var sep = HSeparator.new()
	perk_info.add_child(sep)
	
	# Stats container
	var stats = VBoxContainer.new()
	stats.add_theme_constant_override("separation", 5)
	perk_info.add_child(stats)
	
	var rarity = Label.new()
	rarity.text = "Rarity: %.2f" % perk.rarity
	stats.add_child(rarity)
	
	var max_level = Label.new()
	max_level.text = "Max Level: %d" % perk.get('max_level', 1)
	stats.add_child(max_level)
	
	# Show prerequisites if any
	if perk.has("prerequisites") and not perk.prerequisites.is_empty():
		var prereq = Label.new()
		prereq.text = "Prerequisites: " + ", ".join(perk.prerequisites)
		prereq.add_theme_color_override("font_color", Color(0.7, 0.7, 1.0))
		stats.add_child(prereq)
	
	# Show exclusions if any
	if perk.has("exclusions") and not perk.exclusions.is_empty():
		var excl = Label.new()
		excl.text = "Exclusions: " + ", ".join(perk.exclusions)
		excl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.7))
		stats.add_child(excl)

func _on_add_perk_pressed():
	var selected_items = perk_list.get_selected_items()
	if selected_items.is_empty():
		print("DEBUG: No perk selected")
		return
		
	var perk = perk_list.get_item_metadata(selected_items[0])
	print("DEBUG: Attempting to add perk: ", perk.name, " (ID: ", perk.id, ")")
	
	var player = get_current_player()
	if player:
		print("DEBUG: Found player ", player.player_number)
		if player.perk_component:
			print("DEBUG: Found perk component")
			# Log perk details before adding
			print("DEBUG: Current perks: ", player.perk_component.acquired_perks)
			player.perk_component.add_perk(perk.id)
			print("DEBUG: Perks after addition: ", player.perk_component.acquired_perks)
		else:
			print("DEBUG: No perk component found on player")
	else:
		print("DEBUG: No player found")
	
	update_player_perks()

func _on_reset_perks_pressed():
	var player = get_current_player()
	if player:
		print("DEBUG: Resetting perks for player ", player.player_number)
		if player.perk_component:
			print("DEBUG: Perks before reset: ", player.perk_component.acquired_perks)
			player.perk_component.reset_perks()
			print("DEBUG: Perks after reset: ", player.perk_component.acquired_perks)
		else:
			print("DEBUG: No perk component found on player")
	else:
		print("DEBUG: No player found")
	
	update_player_perks()

func _on_player_changed(value: float):
	update_player_perks()
	selected_player_label.text = "Selected Player: %d" % int(value)

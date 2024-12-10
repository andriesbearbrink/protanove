class_name PerkDatabase
extends Resource

var perks: Dictionary = {}

func _init():
	load_perks()

func load_perks():
	var file = FileAccess.open("res://Code/GameLogics/Exp/ExpPerkDatabase.json", FileAccess.READ)
	if file == null:
		push_error("Failed to open perks_database.json")
		return

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		var data = json.get_data()
		for perk in data.perks:
			perks[perk.id] = perk
		print("Loaded ", perks.size(), " perks from database")
	else:
		push_error("JSON Parse Error: ", json.get_error_message(), " in ", file.get_as_text(), " at line ", json.get_error_line())

	# Print out all loaded perks for debugging
	for perk_id in perks:
		print("Loaded perk: ", perk_id, " - ", perks[perk_id].name)

func get_perk(id: String) -> Dictionary:
	return perks.get(id, {})

func get_all_perks() -> Array:
	return perks.values()

func get_available_perks(player_perks: Array) -> Array:
	var available_perks = []
	for perk in perks.values():
		if can_acquire_perk(perk, player_perks):
			available_perks.append(perk)
	return available_perks

func get_random_perks(count: int, player_perks: Array) -> Array:
	var available_perks = get_available_perks(player_perks)
	available_perks.shuffle()
	
	# Sort by rarity (higher rarity = lower chance)
	available_perks.sort_custom(func(a, b): return a.rarity > b.rarity)
	
	return available_perks.slice(0, min(count, available_perks.size()) - 1)
	
func get_perk_level(perk_id: String, player_perks: Array) -> int:
	return player_perks.count(perk_id)

func can_acquire_perk(perk: Dictionary, player_perks: Array) -> bool:
	var current_level = get_perk_level(perk.id, player_perks)
	
	# Check if the perk has reached its maximum level
	if current_level >= perk.get("max_level", 1):
		return false

	# Check prerequisites
	for prereq in perk.get("prerequisites", []):
		if prereq not in player_perks:
			return false

	# Check exclusions
	for exclusion in perk.get("exclusions", []):
		if exclusion in player_perks:
			return false

	return true

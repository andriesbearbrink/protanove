class_name BasePerkComponent
extends Node

signal perk_acquired(perk_id: String)
signal perk_removed(perk_id: String)

var player: Node
var acquired_perks: Dictionary = {}
var perk_database: PerkDatabase
var level_system: Node
var is_initialized: bool = false

func _ready():
	perk_database = PerkDatabase.new()
	level_system = get_node("/root/MainGame/ExpLevelSystem")
	if not level_system:
		push_error("ExpLevelSystem not found. Make sure it's added to the scene and the path is correct.")

func initialize(player_node: Node):
	if is_initialized:
		return
	
	player = player_node
	if level_system:
		level_system.connect("level_up", Callable(self, "_on_level_up"))
	
	is_initialized = true

func add_perk(perk_id: String):
	print("DEBUG: PerkComponent: Adding perk ", perk_id)
	var perk = perk_database.get_perk(perk_id)
	if perk.is_empty():
		print("DEBUG: PerkComponent: Perk ", perk_id, " not found in database")
		return

	if perk_id in acquired_perks:
		acquired_perks[perk_id] += 1
		print("DEBUG: PerkComponent: Increased level of existing perk ", perk_id, " to ", acquired_perks[perk_id])
	else:
		acquired_perks[perk_id] = 1
		print("DEBUG: PerkComponent: Added new perk ", perk_id)

	# Apply effects
	var effects = perk.effect if perk.effect is Array else [perk.effect]
	print("DEBUG: PerkComponent: Applying effects: ", effects)
	for effect in effects:
		if not effect.has_all(["type", "attribute", "value"]):
			print("DEBUG: PerkComponent: Invalid effect format: ", effect)
			continue
		
		apply_effect(effect)
	
	emit_signal("perk_acquired", perk_id)
	print("DEBUG: PerkComponent: Perk application complete. Current perks: ", acquired_perks)
	
func apply_effect(effect: Dictionary):
	print("DEBUG: PerkComponent: Applying effect: ", effect)
	match effect.type:
		"multiply":
			apply_multiply_effect(effect)
		"add":
			apply_add_effect(effect)
		"set":
			apply_set_effect(effect)
		_:
			print("DEBUG: PerkComponent: Unknown effect type: ", effect.type)

func remove_perk(perk_id: String):
	if perk_id in acquired_perks:
		acquired_perks.erase(perk_id)
		remove_perk_effect(perk_id)
		emit_signal("perk_removed", perk_id)
		print("Perk removed: ", perk_id)
	else:
		print("Error: Attempt to remove non-existent perk: ", perk_id)

func has_perk(perk_id: String) -> bool:
	return perk_id in acquired_perks

func get_perk_level(perk_id: String) -> int:
	return acquired_perks.get(perk_id, 0)

func apply_perk_effect(perk_id: String):
	var perk = perk_database.get_perk(perk_id)
	if perk.is_empty():
		return

	var effects = perk.effect if perk.effect is Array else [perk.effect]
	for effect in effects:
		match effect.type:
			"multiply":
				apply_multiply_effect(effect)
			"add":
				apply_add_effect(effect)
			"set":
				apply_set_effect(effect)
			_:
				print("Unknown effect type: ", effect.type)

func apply_multiply_effect(effect):
	var value = effect.value
	match effect.attribute:
		"bullet_damage":
			player.gun_component.modify_bullet_damage(value)
		"fire_rate":
			player.gun_component.modify_fire_rate(value)
		"bullet_size":
			player.gun_component.modify_bullet_size(value)
		"bullet_speed":
			player.gun_component.modify_bullet_speed(value)
		"bullet_count", "bullet_count_multiplier":
			player.gun_component.modify_bullet_count(value)
		"movement_speed":
			player.increase_movement_speed(value - 1)
		"spread", "bullet_spread":
			player.gun_component.modify_bullet_spread(value)
		"friction":
			player.modify_friction(value)
		"acceleration":
			player.increase_acceleration(value - 1)
		"bullet_drag":
			if player.weapon_component:
				player.weapon_component.modify_bullet_drag(value)
		_:
			print("Unknown attribute for multiply effect: ", effect.attribute)

func apply_add_effect(effect):
	var value = effect.value
	match effect.attribute:
		"bullet_homing":
			if player.weapon_component:
				player.weapon_component.increase_homing(value)
		"bullet_ricochet":
			if player.weapon_component:
				player.weapon_component.increase_ricochet(int(value))
		"fragmentation_count":
			if player.weapon_component:
				player.weapon_component.set_fragmentation_count(
					player.weapon_component.fragmentation_count + int(value)
				)
		_:
			print("Unknown attribute for add effect: ", effect.attribute)
			

func apply_set_effect(effect):
	match effect.attribute:
		"bullet_penetration":
			if player.weapon_component:
				player.weapon_component.set_penetration(bool(effect.value))
		"is_explosive":
			if player.weapon_component:
				var size = effect.get("explosion_size", 50.0)
				var damage = effect.get("explosion_damage", 20.0)
				var force = effect.get("explosion_force", 100.0)
				player.weapon_component.set_explosive(true, size, damage, force)
		"fragmentation_count":
			if player.weapon_component:
				player.weapon_component.set_fragmentation_count(int(effect.value))
		"fragmentation_damage":
			if player.weapon_component:
				player.weapon_component.set_fragmentation_damage(int(effect.value))
		"fragmentation_level":
			if player.weapon_component:
				player.weapon_component.set_fragmentation_level(int(effect.value))
		"fragmentation_explosive":
			if player.weapon_component:
				player.weapon_component.set_fragmentation_explosive(bool(effect.value))
		"fragmentation_homing":
			if player.weapon_component:
				player.weapon_component.set_fragmentation_homing(float(effect.value))
		_:
			print("Unknown attribute for set effect: ", effect.attribute)

func remove_perk_effect(perk_id: String):
	# Implement logic to remove perk effects
	# This might involve resetting certain attributes or applying inverse effects
	pass

func get_available_perks() -> Array:
	return perk_database.get_available_perks(acquired_perks.keys())

func get_random_perks(count: int) -> Array:
	return perk_database.get_random_perks(count, acquired_perks.keys())

func reset_perks():
	print("DEBUG: PerkComponent: Starting perk reset")
	print("DEBUG: PerkComponent: Current perks: ", acquired_perks)
	
	# Reset gun component
	if player and player.gun_component:
		print("DEBUG: PerkComponent: Resetting gun component")
		player.gun_component.reset_multipliers()
	
	# Remove all effects
	for perk_id in acquired_perks:
		var perk = perk_database.get_perk(perk_id)
		if not perk.is_empty():
			var effects = perk.effect if perk.effect is Array else [perk.effect]
			print("DEBUG: PerkComponent: Removing effects for perk ", perk_id, ": ", effects)
			for effect in effects:
				remove_effect(effect)
	
	acquired_perks.clear()
	print("DEBUG: PerkComponent: Perk reset complete")
	
func remove_effect(effect: Dictionary):
	print("DEBUG: PerkComponent: Removing effect: ", effect)
	match effect.type:
		"multiply":
			# Invert the multiplier
			var inverse_effect = effect.duplicate()
			inverse_effect.value = 1.0 / effect.value
			apply_multiply_effect(inverse_effect)
		"add":
			# Invert the addition
			var inverse_effect = effect.duplicate()
			inverse_effect.value = -effect.value
			apply_add_effect(inverse_effect)
		"set":
			# Reset to default value (you may need to define default values)
			var reset_effect = effect.duplicate()
			reset_effect.value = false  # or whatever the default should be
			apply_set_effect(reset_effect)
		_:
			print("DEBUG: PerkComponent: Unknown effect type when removing: ", effect.type)

func _on_level_up(player_index: int, new_level: int):
	if player.player_number - 1 == player_index:  # Adjust for 0-based index
		print("Player ", player.player_number, " leveled up to ", new_level)
		# Here you can implement logic for perk selection on level up
		# For example, you could emit a signal to trigger the perk selection UI

# Helper method to get perk info (useful for UI)
func get_perk_info(perk_id: String) -> Dictionary:
	var perk = perk_database.get_perk(perk_id)
	if perk.is_empty():
		return {}
	
	return {
		"name": perk.name,
		"description": perk.description,
		"level": get_perk_level(perk_id),
		"max_level": perk.get("max_level", 1)
	}

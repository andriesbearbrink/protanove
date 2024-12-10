extends Node

class_name PerkSystem

var perk_database: PerkDatabase

func _ready():
	perk_database = PerkDatabase.new()

func get_random_perks(count: int, player_perks: Array) -> Array:
	var available_perks = perk_database.get_available_perks(player_perks)
	available_perks.shuffle()
	
	while available_perks.size() < count:
		available_perks.append_array(available_perks.slice(0, min(count - available_perks.size(), available_perks.size())))
	
	return available_perks.slice(0, count)

func apply_perk(perk: Dictionary, player):
	print("DEBUG TRACE: ExpPerkSystem.apply_perk called")
	print("DEBUG TRACE: Applying perk: ", perk.name, " to player ", player.player_number)
	if not perk.has("effect"):
		push_error("Perk does not have an 'effect' field: ", perk)
		return

	var effects = perk.effect if perk.effect is Array else [perk.effect]
	for effect in effects:
		if not effect.has("type") or not effect.has("attribute") or not effect.has("value"):
			push_error("Invalid effect in perk: ", effect)
			continue
			
		print("DEBUG TRACE: Applying effect: ", effect)

		match effect.type:
			"multiply":
				print("DEBUG TRACE: Applying multiply effect")
				apply_multiply_effect(player, effect)
			"add":
				print("DEBUG TRACE: Applying add effect")
				apply_add_effect(player, effect)
			"set":
				print("DEBUG TRACE: Applying set effect")
				apply_set_effect(player, effect)
			_:
				push_error("Unknown effect type: ", effect.type)

func apply_multiply_effect(player, effect):
	match effect.attribute:
		"bullet_damage":
			player.gun_component.modify_bullet_damage(effect.value)
		"fire_rate":
			player.gun_component.modify_fire_rate(effect.value)
		"bullet_size":
			player.gun_component.modify_bullet_size(effect.value)
		"bullet_speed":
			player.gun_component.modify_bullet_speed(effect.value)
		"movement_speed":
			player.increase_movement_speed(effect.value - 1)
		"bullet_count", "bullet_count_multiplier":
			player.gun_component.modify_bullet_count(effect.value)
		"spread", "bullet_spread":
			player.gun_component.modify_bullet_spread(effect.value)
		"explosion_size":
			if player.weapon_component:
				player.weapon_component.modify_explosion_size(effect.value)
		"explosion_damage":
			if player.weapon_component:
				player.weapon_component.modify_explosion_damage(effect.value)
		"explosion_force":
			if player.weapon_component:
				player.weapon_component.modify_explosion_force(effect.value)
		"friction":
			player.modify_friction(effect.value)
		"acceleration":
			player.increase_acceleration(effect.value - 1)  # Similar to movement_speed
		"bullet_drag":
			if player.weapon_component:
				player.weapon_component.modify_bullet_drag(effect.value)
		_:
			push_error("Unknown attribute for multiply effect: ", effect.attribute)

func apply_add_effect(player, effect):
	match effect.attribute:
		"bullet_homing":
			if player.weapon_component:
				player.weapon_component.increase_homing(effect.value)
		"bullet_ricochet":
			if player.weapon_component:
				player.weapon_component.increase_ricochet(int(effect.value))
		"fragmentation_count":
			if player.weapon_component:
				player.weapon_component.set_fragmentation_count(
					player.weapon_component.fragmentation_count + int(effect.value)
				)
		_:
			push_error("Unknown attribute for add effect: ", effect.attribute)

func apply_set_effect(player, effect):
	match effect.attribute:
		"bullet_penetration":
			if player.weapon_component:
				player.weapon_component.set_penetration(bool(effect.value))
		"is_explosive":
			if player.weapon_component:
				var size = effect.get("explosion_size", 50.0)
				var damage = effect.get("explosion_damage", 20.0)
				var force = effect.get("explosion_force", 100.0)
				player.weapon_component.set_explosive(bool(effect.value), size, damage, force)
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
			push_error("Unknown attribute for set effect: ", effect.attribute)

func get_perk_info(perk_id: String) -> Dictionary:
	return perk_database.get_perk(perk_id)

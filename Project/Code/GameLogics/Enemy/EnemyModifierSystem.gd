class_name EnemyModifierSystem
extends Node

signal property_range_modified(property_name: String, min_mod: float, max_mod: float)
signal behavior_weight_modified(behavior: int, weight_mod: float)

var time_modifiers: Array[Dictionary] = []
var perk_modifiers: Array[Dictionary] = []

func add_time_modifier(time: float, property_name: String, min_mod: float, max_mod: float):
	time_modifiers.append({
		"time": time,
		"property": property_name,
		"min_mod": min_mod,
		"max_mod": max_mod
	})

func add_perk_modifier(perk_name: String, property_name: String, min_mod: float, max_mod: float):
	perk_modifiers.append({
		"perk": perk_name,
		"property": property_name,
		"min_mod": min_mod,
		"max_mod": max_mod
	})

func update_time_modifiers(elapsed_time: float):
	for modifier in time_modifiers:
		if elapsed_time >= modifier.time:
			emit_signal("property_range_modified", 
				modifier.property,
				modifier.min_mod,
				modifier.max_mod)
			time_modifiers.erase(modifier)

func apply_perk_modifier(perk_name: String):
	for modifier in perk_modifiers:
		if modifier.perk == perk_name:
			emit_signal("property_range_modified",
				modifier.property,
				modifier.min_mod,
				modifier.max_mod)

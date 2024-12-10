extends Node
class_name BaseAbilitiesComponent

signal ability_used(ability_name: String)
signal ability_ready(ability_name: String)
signal ability_cooldown_updated(ability_name: String, remaining: float, total: float)

var abilities: Dictionary = {}
var player: BasePlayer

func initialize(player_node: BasePlayer):
	player = player_node
	setup_abilities()

func setup_abilities():
	# Initialize dash ability
	var dash_ability = DashAbility.new()
	dash_ability.initialize(player)
	abilities["dash"] = dash_ability
	add_child(dash_ability)
	
	# Initialize aim sight ability
	var aim_sight = AimSightAbility.new()
	aim_sight.initialize(player)
	abilities["aim_sight"] = aim_sight
	add_child(aim_sight)

func _physics_process(delta):
	# Check for ability inputs
	if player and player.input_component and player.input_component.input_handler:
		for ability_name in abilities:
			if player.input_component.input_handler.get_ability_input(ability_name):
				use_ability(ability_name)
	
	# Update cooldowns
	for ability_name in abilities:
		var ability = abilities[ability_name]
		if ability.is_on_cooldown:
			emit_signal("ability_cooldown_updated", ability_name, 
				ability.cooldown_remaining, ability.cooldown)

func use_ability(ability_name: String) -> bool:
	if not abilities.has(ability_name):
		return false
		
	var ability = abilities[ability_name]
	if ability.can_use():
		ability.use()
		emit_signal("ability_used", ability_name)
		return true
	return false

# Getters for ability states
func get_ability_cooldown(ability_name: String) -> float:
	if abilities.has(ability_name):
		return abilities[ability_name].cooldown_remaining
	return 0.0

func is_ability_ready(ability_name: String) -> bool:
	if abilities.has(ability_name):
		return abilities[ability_name].can_use()
	return false

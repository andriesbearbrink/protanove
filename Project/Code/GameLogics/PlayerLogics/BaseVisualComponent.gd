class_name BaseVisualComponent
extends Node2D

signal appearance_updated

var player: BasePlayer
var player_color: Color = Color.WHITE
@export var health_indicator_alpha: float = 0.8

var mesh_instance: MeshInstance2D
var health_indicator: MeshInstance2D

var health_material: ShaderMaterial

func _ready():
	setup_visuals()

func initialize(player_node: BasePlayer):
	player = player_node
	update_appearance()

func setup_visuals():
	setup_health_indicator()


func setup_health_indicator():
	health_indicator = MeshInstance2D.new()
	var circle_mesh = QuadMesh.new()
	circle_mesh.size = Vector2(19, 19)
	health_indicator.mesh = circle_mesh
	
	health_material = ShaderMaterial.new()
	health_material.shader = load("res://Code/GameLogics/PlayerLogics/CharacterHealth.gdshader")
	health_indicator.material = health_material
	
	# Ensure proper transparency
	health_indicator.texture_filter = TEXTURE_FILTER_NEAREST
	health_indicator.use_parent_material = false
	health_material.render_priority = 1
	
	add_child(health_indicator)
	health_indicator.position = Vector2(0, 0)  # Adjust as needed

func set_player_color(color: Color):
	print("BaseVisualComponent: Setting player color to", color)
	player_color = color
	update_appearance()

func update_appearance():
	print("BaseVisualComponent: Updating appearance with color", player_color)
	if health_material:
		var color_with_alpha = player_color
		color_with_alpha.a = health_indicator_alpha
		health_material.set_shader_parameter("fill_color", color_with_alpha)
	else:
		print("BaseVisualComponent: Health material is null")
	emit_signal("appearance_updated")

func update_health_display(current_health: float, max_health: float):
	print("BaseVisualComponent: Updating health display. Current health:", current_health, "Max health:", max_health)
	var health_percentage = current_health / max_health
	if health_material:
		health_material.set_shader_parameter("fill_percentage", health_percentage)
		print("BaseVisualComponent: Setting health fill percentage to", health_percentage)
	else:
		print("BaseVisualComponent: Health material is null when updating health display")

func update_weapon_visuals(weapon_data: Dictionary):
	# Update weapon visuals based on current weapon data
	# This could involve changing the shape, color, or effects of the weapon
	pass

func set_visibility(is_visible: bool):
	visible = is_visible

func flash(duration: float = 0.1, color: Color = Color.WHITE):
	var original_modulate = modulate
	modulate = color
	await get_tree().create_timer(duration).timeout
	modulate = original_modulate

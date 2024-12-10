# PostProcessManager.gd
extends Node

var viewport_container: SubViewportContainer
var viewport: SubViewport
var post_process_rect: ColorRect

func _ready():
	setup_post_processing()

func setup_post_processing():
	# Create a SubViewportContainer to hold our game viewport
	viewport_container = SubViewportContainer.new()
	viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewport_container.size_flags_horizontal = Control.SIZE_FILL
	viewport_container.size_flags_vertical = Control.SIZE_FILL
	add_child(viewport_container)
	
	# Create a SubViewport that will contain our actual game
	viewport = SubViewport.new()
	viewport.transparent_bg = true
	viewport.handle_input_locally = true
	viewport.size = get_viewport().size
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(viewport)
	
	# Move all existing children to the SubViewport
	var root = get_tree().root
	for child in root.get_children():
		if child != self:
			root.remove_child(child)
			viewport.add_child(child)
	
	# Create the post-processing ColorRect
	post_process_rect = ColorRect.new()
	post_process_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	post_process_rect.material = ShaderMaterial.new()
	post_process_rect.material.shader = load("res://Code/GameLogics/BaseGame/Post-Processing.gdshader")
	add_child(post_process_rect)

func set_motion_blur_strength(strength: float):
	if post_process_rect and post_process_rect.material:
		post_process_rect.material.set_shader_parameter("motion_blur_strength", strength)

func set_chromatic_aberration(strength: float):
	if post_process_rect and post_process_rect.material:
		post_process_rect.material.set_shader_parameter("chromatic_strength", strength)

func set_vignette_strength(strength: float):
	if post_process_rect and post_process_rect.material:
		post_process_rect.material.set_shader_parameter("vignette_strength", strength)

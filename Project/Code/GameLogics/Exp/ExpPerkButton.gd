# ExpPerkButton.gd
class_name ExpPerkButton
extends Button

var perk: Dictionary
var is_focused: bool = false
var is_selected: bool = false
var focus_indicator: ColorRect
var selection_indicator: ColorRect

func setup(p: Dictionary):
	perk = p
	text = perk.name
	tooltip_text = perk.description

func _ready():
	if not is_connected("pressed", _on_pressed):
		connect("pressed", _on_pressed)
	if not is_connected("button_down", _on_button_down):
		connect("button_down", _on_button_down)
	if not is_connected("gui_input", _on_gui_input):
		connect("gui_input", _on_gui_input)
	if not is_connected("mouse_entered", _on_mouse_entered):
		connect("mouse_entered", _on_mouse_entered)
	if not is_connected("toggled", _on_toggled):
		connect("toggled", _on_toggled)
	
	focus_indicator = ColorRect.new()
	focus_indicator.set_anchors_preset(Control.PRESET_FULL_RECT)
	focus_indicator.color = Color.TRANSPARENT
	focus_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(focus_indicator)
	
	selection_indicator = ColorRect.new()
	selection_indicator.set_anchors_preset(Control.PRESET_FULL_RECT)
	selection_indicator.color = Color.TRANSPARENT
	selection_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(selection_indicator)
	
	# Set up the button appearance
	add_theme_font_size_override("font_size", 24)
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	update_visual()

func set_focused(focused: bool):
	is_focused = focused
	update_visual()

func set_selected(selected: bool):
	is_selected = selected
	update_visual()

func update_visual():
	if is_selected:
		modulate = Color(1.5, 1.5, 1.5)  # Brighten when selected
		selection_indicator.color = Color(1, 1, 1, 0.5)  # White overlay for selection, increased opacity
	elif is_focused:
		modulate = Color(1.2, 1.2, 1.2)  # Highlight when focused
		selection_indicator.color = Color.TRANSPARENT
	else:
		modulate = Color(1, 1, 1)  # Normal color
		selection_indicator.color = Color.TRANSPARENT

func show_focus_indicator(color: Color):
	focus_indicator.color = color.lightened(0.5)
	focus_indicator.color.a = 0.7  # Increased alpha for better visibility

func hide_focus_indicator():
	focus_indicator.color = Color.TRANSPARENT

func _on_pressed():
	var perk_selection_ui = get_node("/root/MainGame/CanvasLayer/ExpPerkSelectionUI")
	if perk_selection_ui and perk_selection_ui.has_method("handle_perk_selected"):
		var player_index = perk_selection_ui.get_player_index_for_button(self)
		if player_index != -1:
			perk_selection_ui.handle_perk_selected(player_index, perk)

# Placeholder methods for other signals
func _on_button_down():
	pass

func _on_gui_input(event):
	pass

func _on_mouse_entered():
	pass

func _on_toggled(button_pressed):
	pass

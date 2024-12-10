extends PanelContainer
class_name PlayerSlot

signal player_ready(player_index: int)
signal player_unready(player_index: int)
signal player_start(player_index: int)

@export var player_index: int = 0

var is_active = false
var current_profile: PlayerProfile
var input_device: String = ""
var is_ready = false

@onready var player_label = $VBoxContainer/PlayerLabel
@onready var profile_option = $VBoxContainer/ProfileOption
@onready var color_picker = $VBoxContainer/ColorPickerButton
@onready var input_label = $VBoxContainer/InputLabel
@onready var profile_name_edit = $VBoxContainer/ProfileNameEdit
@onready var new_profile_button = $VBoxContainer/NewProfileButton
@onready var start_button = $VBoxContainer/StartButton
@onready var focus_indicator = $FocusIndicator

var focused_element = 0
var elements = []

func _ready():
	update_player_label()
	update_appearance()
	
	elements = [profile_option, color_picker, new_profile_button, start_button]
	
	# Disable focus for all UI elements
	for element in elements:
		element.focus_mode = Control.FOCUS_NONE
	
	profile_name_edit.focus_mode = Control.FOCUS_NONE
	
	if profile_option:
		profile_option.connect("item_selected", Callable(self, "_on_profile_selected"))
	if color_picker:
		color_picker.connect("color_changed", Callable(self, "_on_color_changed"))
	if new_profile_button:
		new_profile_button.connect("pressed", Callable(self, "_on_new_profile_button_pressed"))
	if start_button:
		start_button.connect("pressed", Callable(self, "_on_start_button_pressed"))

	profile_name_edit.placeholder_text = "Enter new profile name"
	new_profile_button.text = "Create New Profile"
	start_button.text = "Ready"
	start_button.disabled = true
	
	focus_indicator.hide()

func update_player_label():
	if player_label:
		player_label.text = "Player " + str(player_index + 1)

func set_player_index(index: int):
	player_index = index
	update_player_label()

func activate(device: String):
	if not is_active:
		is_active = true
		input_device = device
		input_label.text = "Input: " + input_device + "\nPress B/Esc to deactivate"
		update_appearance()
		load_profiles()
		emit_signal("player_ready", player_index)
		set_process_input(true)
		update_focus()

func deactivate():
	if is_active:
		is_active = false
		input_device = ""
		input_label.text = "Press A/Space to join"
		update_appearance()
		emit_signal("player_unready", player_index)
		set_process_input(false)
		focus_indicator.hide()

func load_profiles():
	profile_option.clear()
	var profiles = ProfileManager.get_all_profiles()
	for i in range(profiles.size()):
		var profile = profiles[i]
		profile_option.add_item(profile.name, i)
	if profile_option.item_count > 0:
		profile_option.select(0)
		_on_profile_selected(0)

func _on_profile_selected(index: int):
	var profile_name = profile_option.get_item_text(index)
	current_profile = ProfileManager.get_profile(profile_name)
	if current_profile:
		color_picker.color = current_profile.color
		update_focus_indicator_color()

func _on_color_changed(color: Color):
	if current_profile:
		current_profile.color = color
		ProfileManager.save_profiles()
		update_focus_indicator_color()

func _on_new_profile_button_pressed():
	var new_profile_name = profile_name_edit.text.strip_edges()
	if new_profile_name.length() > 0:
		var new_profile = ProfileManager.create_new_profile(new_profile_name)
		if new_profile:
			load_profiles()
			select_profile(new_profile.name)
			profile_name_edit.clear()
		else:
			print("Profile with this name already exists")
	else:
		print("Please enter a valid profile name")

func select_profile(profile_name: String):
	for i in range(profile_option.item_count):
		if profile_option.get_item_text(i) == profile_name:
			profile_option.select(i)
			_on_profile_selected(i)
			return
	print("Profile not found in the list: ", profile_name)

func update_appearance():
	modulate = Color.WHITE if is_active else Color(1, 1, 1, 0.5)
	profile_option.disabled = not is_active
	color_picker.disabled = not is_active
	profile_name_edit.editable = is_active
	new_profile_button.disabled = not is_active
	start_button.disabled = not is_active
	input_label.text = "Press A/Space to join" if not is_active else "Input: " + input_device + "\nPress B/Esc to deactivate"

func get_player_data() -> Dictionary:
	if is_active and current_profile:
		return {
			"profile": current_profile,
			"input_device": input_device,
			"color": color_picker.color
		}
	return {}

func _input(event):
	if not is_active:
		return

	if input_device.begins_with("gamepad"):
		handle_gamepad_input(event)
	elif input_device == "keyboard_mouse":
		handle_keyboard_mouse_input(event)

func handle_gamepad_input(event: InputEvent):
	if event is InputEventJoypadButton and event.is_pressed() and event.device == int(input_device.substr(7)):
		match event.button_index:
			JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN:
				change_focus(1 if event.button_index == JOY_BUTTON_DPAD_DOWN else -1)
			JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT:
				emit_signal("focus_changed", 1 if event.button_index == JOY_BUTTON_DPAD_RIGHT else -1, player_index)
			JOY_BUTTON_A:
				activate_focused_element()

func handle_keyboard_mouse_input(event: InputEvent):
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_UP, KEY_DOWN:
				change_focus(1 if event.keycode == KEY_DOWN else -1)
			KEY_LEFT, KEY_RIGHT:
				emit_signal("focus_changed", 1 if event.keycode == KEY_RIGHT else -1, player_index)
			KEY_ENTER, KEY_SPACE:
				activate_focused_element()

func change_focus(direction: int):
	focused_element = (focused_element + direction) % elements.size()
	if focused_element < 0:
		focused_element = elements.size() - 1
	update_focus()

func update_focus():
	for i in range(elements.size()):
		if i == focused_element:
			update_focus_indicator_position(elements[i])
		else:
			elements[i].release_focus()

func activate_focused_element():
	match focused_element:
		0:  # Profile Option
			if profile_option.disabled:
				return
			if profile_option.get_item_count() > 0:
				var next_index = (profile_option.selected + 1) % profile_option.get_item_count()
				profile_option.select(next_index)
				_on_profile_selected(next_index)
		1:  # Color Picker
			if color_picker.disabled:
				return
			# Open the color picker dialog
			color_picker.emit_signal("pressed")
		2:  # New Profile Button
			if new_profile_button.disabled:
				return
			_on_new_profile_button_pressed()
		3:  # Start Button
			if start_button.disabled:
				return
			_on_start_button_pressed()
			
func _on_start_button_pressed():
	is_ready = !is_ready
	start_button.text = "Cancel" if is_ready else "Ready"
	emit_signal("player_start", player_index)

func update_focus_indicator_position(focused_control: Control):
	focus_indicator.show()
	focus_indicator.size = focused_control.size
	focus_indicator.position = focused_control.position

func update_focus_indicator_color():
	if current_profile:
		focus_indicator.modulate = current_profile.color
	else:
		focus_indicator.modulate = Color.WHITE

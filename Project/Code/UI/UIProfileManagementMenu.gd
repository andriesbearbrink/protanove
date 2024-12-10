extends Control

@onready var profile_list = $VBoxContainer/ProfileList
@onready var new_profile_button = $VBoxContainer/Buttons/NewProfileButton
@onready var edit_profile_button = $VBoxContainer/Buttons/EditProfileButton
@onready var delete_profile_button = $VBoxContainer/Buttons/DeleteProfileButton
@onready var back_button = $VBoxContainer/Buttons/BackButton
@onready var edit_container = $VBoxContainer/EditContainer
@onready var profile_name_edit = $VBoxContainer/EditContainer/ProfileNameEdit
@onready var profile_color_picker = $VBoxContainer/EditContainer/ProfileColorPicker
@onready var save_profile_button = $VBoxContainer/EditContainer/SaveProfileButton

var editing_profile: PlayerProfile = null

func _ready():
	load_profiles()
	new_profile_button.connect("pressed", Callable(self, "_on_new_profile_pressed"))
	edit_profile_button.connect("pressed", Callable(self, "_on_edit_profile_pressed"))
	delete_profile_button.connect("pressed", Callable(self, "_on_delete_profile_pressed"))
	back_button.connect("pressed", Callable(self, "_on_back_pressed"))
	save_profile_button.connect("pressed", Callable(self, "_on_save_profile_pressed"))
	profile_list.connect("item_selected", Callable(self, "_on_profile_selected"))
	edit_container.hide()
	update_button_states()

func load_profiles():
	profile_list.clear()
	var profiles = ProfileManager.get_all_profiles()
	for profile in profiles:
		profile_list.add_item(profile.name)
	print("Loaded profiles: ", profiles.size())  # Debug print
	update_button_states()

func update_button_states():
	var is_profile_selected = profile_list.get_selected_items().size() > 0
	edit_profile_button.disabled = !is_profile_selected
	delete_profile_button.disabled = !is_profile_selected

func _on_profile_selected(_index):
	update_button_states()

func _on_new_profile_pressed():
	editing_profile = null
	profile_name_edit.text = ""
	profile_color_picker.color = Color.WHITE
	edit_container.show()

func _on_edit_profile_pressed():
	var selected_items = profile_list.get_selected_items()
	if selected_items.size() > 0:
		var profile_name = profile_list.get_item_text(selected_items[0])
		editing_profile = ProfileManager.get_profile(profile_name)
		if editing_profile:
			profile_name_edit.text = editing_profile.name
			profile_color_picker.color = editing_profile.color
			edit_container.show()

func _on_delete_profile_pressed():
	var selected_items = profile_list.get_selected_items()
	if selected_items.size() > 0:
		var profile_name = profile_list.get_item_text(selected_items[0])
		ProfileManager.delete_profile(profile_name)
		load_profiles()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Code/UI/MainMenu/MainMenu.tscn")

func _on_save_profile_pressed():
	var new_name = profile_name_edit.text.strip_edges()
	if new_name.length() > 0:
		if editing_profile:
			var old_name = editing_profile.name
			editing_profile.name = new_name
			editing_profile.color = profile_color_picker.color
			ProfileManager.update_profile(old_name, editing_profile)
		else:
			var new_profile = ProfileManager.create_new_profile(new_name)
			if new_profile:
				new_profile.color = profile_color_picker.color
				ProfileManager.save_profiles()
		load_profiles()
		edit_container.hide()
	else:
		print("Please enter a valid profile name")

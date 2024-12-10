# ProfileManager.gd
extends Node

var profiles: Dictionary = {}

func _ready():
	load_profiles()
	
func create_new_profile(name: String) -> PlayerProfile: 
	if profiles.has(name):
		return null  # Profile with this name already exists
	
	var new_profile = PlayerProfile.new()
	new_profile.name = name
	profiles[name] = new_profile
	save_profiles()
	return new_profile

func load_profiles():
	var dir = DirAccess.open("user://profiles")
	if dir:
		for file_name in dir.get_files():
			if file_name.ends_with(".tres"):
				var profile = ResourceLoader.load("user://profiles/" + file_name)
				if profile is PlayerProfile:
					profiles[profile.name] = profile
	
	# If no profiles exist, create a default one
	if profiles.is_empty():
		create_new_profile("Player 1")

func save_profiles():
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("profiles"):
		dir.make_dir("profiles")
	
	for profile in profiles.values():
		var err = ResourceSaver.save(profile, "user://profiles/" + profile.name + ".tres")
		if err != OK:
			print("Error saving profile: ", profile.name, " Error code: ", err)

func get_profile(name: String) -> PlayerProfile:
	return profiles.get(name)

func get_all_profiles() -> Array:
	return profiles.values()

func delete_profile(name: String):
	if profiles.has(name):
		profiles.erase(name)
		DirAccess.remove_absolute("user://profiles/" + name + ".tres")
		save_profiles()
		print("Profile deleted: ", name)  # Debug print
	else:
		print("Profile not found: ", name)  # Debug print
		
func update_profile(old_name: String, new_profile: PlayerProfile):
	if profiles.has(old_name):
		profiles.erase(old_name)
		profiles[new_profile.name] = new_profile
		save_profiles()
		return true
	return false

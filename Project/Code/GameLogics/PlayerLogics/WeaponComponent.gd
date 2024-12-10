class_name WeaponComponent
extends Node

signal weapon_fired(bullet_properties: Dictionary)

var parent: Node2D
var fire_rate: float = 0.8
var can_fire: bool = true

var bullet_system: Node2D  # Reference to the RIDBulletSystem

func _init(parent_node: Node2D):
	parent = parent_node
	print("WeaponComponent initialized")

func _ready():
	# Get reference to the bullet system
	bullet_system = get_node("/root/MainGameContainer/MainGame/BulletSystem")  # Adjust this path as needed
	if not bullet_system:
		push_error("BulletSystem not found. Make sure it's added to the scene and the path is correct.")

func set_weapon_params(new_fire_rate: float, new_bullet_speed: float):
	fire_rate = new_fire_rate

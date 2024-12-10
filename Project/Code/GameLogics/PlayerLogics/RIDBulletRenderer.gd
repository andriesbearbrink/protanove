extends Node2D

class_name RIDBulletRenderer

var multimesh: MultiMesh
var multimesh_instance: MultiMeshInstance2D
var bullet_material: ShaderMaterial
var max_bullets: int = 1000  # Adjust based on your needs

func _ready():
	setup_multimesh()
	setup_bullet_material()

func setup_multimesh():
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true  # Add this line to enable color usage
	multimesh.instance_count = max_bullets
	
	var mesh = QuadMesh.new()
	mesh.size = Vector2(1, 1)  # Unit size quad
	multimesh.mesh = mesh
	
	# Initialize all instances with a default transform and color
	for i in range(max_bullets):
		var default_transform = Transform2D()
		default_transform.origin = Vector2(-1000, -1000)  # Move far off-screen
		multimesh.set_instance_transform_2d(i, default_transform)
		multimesh.set_instance_color(i, Color.WHITE)  # Set a default color
	
	multimesh_instance = MultiMeshInstance2D.new()
	multimesh_instance.multimesh = multimesh
	add_child(multimesh_instance)

func setup_bullet_material():
	bullet_material = ShaderMaterial.new()
	bullet_material.shader = load("res://Code/GameLogics/PlayerLogics/bullet.gdshader")
	bullet_material.set_shader_parameter("bullet_color", Color(1.0, 1.0, 1.0, 1.0))
	multimesh_instance.material = bullet_material

func update_bullet_visuals(bullets: Array):
	var visible_count = min(bullets.size(), max_bullets)
	multimesh.visible_instance_count = visible_count
	
	for i in range(visible_count):
		var bullet = bullets[i]
		var transform = Transform2D()
		transform = transform.scaled(bullet.size)
		transform = transform.rotated(bullet.velocity.angle())
		transform.origin = bullet.position
		multimesh.set_instance_transform_2d(i, transform)
		multimesh.set_instance_color(i, bullet.color)
	#	print("RIDBulletRenderer: Setting bullet ", i, " color to ", bullet.color)
	
	# Hide unused instances
	for i in range(visible_count, max_bullets):
		var transform = Transform2D()
		transform.origin = Vector2(-1000, -1000)  # Move far off-screen
		multimesh.set_instance_transform_2d(i, transform)

func set_custom_shader_parameter(param_name: String, value):
	bullet_material.set_shader_parameter(param_name, value)

func set_custom_shader(shader_path: String):
	var new_shader = load(shader_path)
	if new_shader:
		bullet_material.shader = new_shader
	else:
		push_error("Failed to load shader from path: " + shader_path)

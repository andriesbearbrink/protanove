extends Node2D

class_name RIDBulletSystem

var bullet_renderer: RIDBulletRenderer
var bullet_particles: RIDBulletParticles
var bullet_event_system: RIDBulletEventSystem
var bullet_trails: RIDBulletTrails

var screen_wrap_system: Node

var active_bullets: Array = []

var screen_size: Vector2

func _ready():
	bullet_renderer = RIDBulletRenderer.new()
	add_child(bullet_renderer)

	bullet_particles = RIDBulletParticles.new()
	add_child(bullet_particles)

	bullet_event_system = RIDBulletEventSystem.new()
	add_child(bullet_event_system)
	
	bullet_event_system.connect("bullet_fragmentation", Callable(self, "_on_bullet_fragmentation"))

	bullet_trails = RIDBulletTrails.new()
	add_child(bullet_trails)

	screen_wrap_system = get_node("/root/MainGame/ScreenWrapSystem")
	if screen_wrap_system:
		screen_size = screen_wrap_system.screen_size
	else:
		screen_size = get_viewport_rect().size
		push_warning("ScreenWrapSystem not found. Using viewport size for screen wrapping.")

func create_bullet(position: Vector2, direction: Vector2, properties: Dictionary):
	var speed = properties.get("speed", 100.0)
	var base_velocity = direction * speed
	
	# Get the player velocity from properties and add it to the bullet velocity
	var player_velocity = properties.get("player_velocity", Vector2.ZERO)
	var final_velocity = base_velocity
	
	 #for player relative bullets
	 #var final_velocity = base_velocity + player_velocity

	
	var bullet_color = properties.get("color", Color.WHITE)
	#print("RIDBulletSystem: Creating bullet with color: ", bullet_color)
	#print("RIDBulletSystem: Creating particle_trail_color with color: ", properties.get("particle_trail_color", bullet_color))
	#print("RIDBulletSystem: Creating line_trail_color with color: ", properties.get("line_trail_color", bullet_color))
	
	var bullet = RIDBullet.new()
	bullet.reset(position, final_velocity, properties)
	bullet.set_bullet_system(self)
	bullet.set_screen_size(screen_size)
	active_bullets.append(bullet)
	
	if bullet.particle_trail_enabled:
		bullet_particles.create_particle_system(bullet)

func _physics_process(delta):
	var enemies = get_tree().get_nodes_in_group("enemy")
	update_bullets(delta, enemies)
	bullet_particles._process(delta)
	bullet_event_system._process(delta)
	bullet_trails._process(delta)
	
	# Update the MultiMesh renderer
	bullet_renderer.update_bullet_visuals(active_bullets)

func update_bullets(delta: float, enemies: Array):
	var i = active_bullets.size() - 1
	while i >= 0:
		var bullet = active_bullets[i]
		if bullet.update(delta, enemies):
			remove_bullet(bullet)
		else:
			wrap_bullet(bullet)
			if bullet.particle_trail_enabled:
				bullet_particles.update_particle_system(bullet)
			bullet_trails.update_trail(bullet)
			check_collisions(bullet)
		i -= 1

func remove_bullet(bullet):
	active_bullets.erase(bullet)
	bullet_trails.start_trail_fadeout(bullet)
	bullet_particles.remove_particle_system(bullet)  # Add this line

func on_bullet_warped(bullet, old_position: Vector2, new_position: Vector2):
	bullet_event_system.emit_bullet_warped(bullet, old_position, new_position)
	bullet_trails.clear_bullet_trail(bullet)
	bullet_trails.update_trail_after_warp(bullet)

func wrap_bullet(bullet):
	var old_position = bullet.position
	var new_position = bullet.position

	if new_position.x < 0:
		new_position.x += screen_size.x
	elif new_position.x > screen_size.x:
		new_position.x -= screen_size.x

	if new_position.y < 0:
		new_position.y += screen_size.y
	elif new_position.y > screen_size.y:
		new_position.y -= screen_size.y

	if new_position != old_position:
		bullet_event_system.emit_bullet_warped(bullet, old_position, new_position)
		bullet_trails.clear_bullet_trail(bullet)
		bullet_trails.update_trail_after_warp(bullet)
		bullet.position = new_position

func check_collisions(bullet):
	var query = PhysicsShapeQueryParameters2D.new()
	var bullet_shape = CircleShape2D.new()
	bullet_shape.radius = max(bullet.size.x, bullet.size.y) / 2
	query.set_shape(bullet_shape)
	query.transform = Transform2D(0, bullet.position)
	query.collision_mask = 0b11  # Enemy and wall layers

	var space_state = get_world_2d().direct_space_state
	var collisions = space_state.intersect_shape(query)

	for collision in collisions:
		if collision.has("collider") and is_instance_valid(collision["collider"]):
			var collider = collision["collider"]
			#print("RIDBulletSystem: Collision detected with ", collider.name)
			bullet_event_system.handle_collision(bullet, collider)
			if bullet.handle_collision(collider):
				bullet_particles.create_impact_effect(bullet.position, bullet)
				bullet_trails.start_trail_fadeout(bullet)
				remove_bullet(bullet)
				#print("RIDBulletSystem: Bullet removed after collision")
				return

func _on_bullet_fragmentation(bullet, fragments):
	#print("Received fragmentation signal for bullet at position: ", bullet.position)
	for i in range(fragments.size()):
		var fragment = fragments[i]
		#print("Creating fragment ", i, " at position: ", fragment["position"])
		#print("Fragment properties: ", fragment["properties"])
		create_bullet(fragment["position"], fragment["direction"], fragment["properties"])

func handle_explosion(position: Vector2, size: float, damage: int, force: float):
	bullet_event_system.handle_explosion(position, size, damage, force)

func _exit_tree():
	bullet_particles.clean_up()
	# No need to clean up bullets as they are no longer pooled objects

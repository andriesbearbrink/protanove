class_name RIDBulletEventSystem
extends Node2D

signal bullet_collision(bullet, collider)
signal bullet_explosion(position, size, damage, force)
signal bullet_fragmentation(bullet, fragments)
signal bullet_warped(bullet, old_position, new_position)

var explosion_visuals: Array = []
var processed_collisions = {}


class ExplosionVisual:
	var position: Vector2
	var max_radius: float
	var duration: float
	var elapsed_time: float = 0
	var color: Color

	func _init(pos: Vector2, radius: float, dur: float, col: Color = Color.CORAL):
		position = pos
		max_radius = radius
		duration = dur
		color = col

	func update(delta: float) -> bool:
		elapsed_time += delta
		return elapsed_time >= duration

func emit_collision(bullet, collider):
	emit_signal("bullet_collision", bullet, collider)

func emit_explosion(position: Vector2, size: float, damage: int, force: float):
	emit_signal("bullet_explosion", position, size, damage, force)
	create_explosion_visual(position, size, 0.5)  # 0.5 second duration

func emit_fragmentation(bullet, fragments: Array):
	emit_signal("bullet_fragmentation", bullet, fragments)

func emit_bullet_warped(bullet, old_position: Vector2, new_position: Vector2):
	emit_signal("bullet_warped", bullet, old_position, new_position)

func create_explosion_visual(position: Vector2, radius: float, duration: float, color: Color = Color.CORAL):
	var explosion = ExplosionVisual.new(position, radius, duration, color)
	explosion_visuals.append(explosion)

func update_explosion_visuals(delta: float):
	var i = explosion_visuals.size() - 1
	while i >= 0:
		if explosion_visuals[i].update(delta):
			explosion_visuals.remove_at(i)
		i -= 1

func _draw():
	for explosion in explosion_visuals:
		var t = explosion.elapsed_time / explosion.duration
		var radius = explosion.max_radius * t
		var alpha = 1.0 - t
		draw_circle(explosion.position, radius, explosion.color * Color(1, 1, 1, alpha))

func handle_collision(bullet, collider):
	#print("RIDBulletEventSystem: Handling collision between bullet and ", collider.name)
	emit_collision(bullet, collider)
	
	if collider.has_method("take_damage"):
		#print("RIDBulletEventSystem: Calling take_damage on collider with damage: ", bullet.damage, " and player number: ", bullet.player_number)
		collider.take_damage(bullet.damage, bullet.player_number)
	
	if bullet.is_explosive:
		handle_explosion(bullet.position, bullet.explosion_size, bullet.explosion_damage, bullet.explosion_force)
	
	if bullet.fragmentation_count > 0 and bullet.fragmentation_level > 0:
		handle_fragmentation(bullet)
		

func handle_explosion(position: Vector2, size: float, damage: int, force: float):
	emit_explosion(position, size, damage, force)

	# Find all entities within the explosion radius
	var query = PhysicsShapeQueryParameters2D.new()
	var explosion_shape = CircleShape2D.new()
	explosion_shape.radius = size
	query.set_shape(explosion_shape)
	query.transform = Transform2D(0, position)
	query.collision_mask = 0b11  # Enemy and player layers

	var space_state = get_tree().get_root().get_world_2d().direct_space_state
	var collisions = space_state.intersect_shape(query)

	for collision in collisions:
		var collider = collision["collider"]
		if collider.has_method("take_damage") and collider.has_method("apply_central_impulse"):
			var distance = position.distance_to(collider.global_position)
			if distance < size:
				var damage_factor = 1 - (distance / size)
				var actual_damage = int(damage * damage_factor)
				collider.take_damage(actual_damage)

				var direction = (collider.global_position - position).normalized()
				if direction.length() < 0.01:
					direction = Vector2(randf() - 0.5, randf() - 0.5).normalized()

				var impulse = direction * force * damage_factor
				collider.apply_central_impulse(impulse)

func handle_fragmentation(bullet):
	var fragments = []
	#print("Creating fragments for bullet at position: ", bullet.position)
	for i in range(bullet.fragmentation_count):
		var angle = randf() * 2 * PI
		var direction = Vector2(cos(angle), sin(angle))
		
		# Set fragment speed independently (80% of original bullet speed)
		var fragment_speed = 150.0  # Base fragment speed
		
		# Calculate fragment size (minimum 1x1)
		var fragment_size = bullet.size
		
		var fragment_properties = {
			"speed": fragment_speed,
			"velocity": direction * fragment_speed,
			"drag": bullet.drag,
			"size": fragment_size,
			"distance": bullet.distance * 0.5,
			"penetration": max(1, bullet.penetration - 1),
			"ricochet": max(0, bullet.ricochet - 1),
			"damage": bullet.fragmentation_damage,
			"color": bullet.color.lightened(0.2),
			"homing": bullet.fragmentation_homing,
			"is_explosive": bullet.fragmentation_explosive,
			"explosion_size": bullet.explosion_size * 0.5 if bullet.is_explosive else 0,
			"explosion_damage": bullet.explosion_damage * 0.5 if bullet.is_explosive else 0,
			"explosion_force": bullet.explosion_force * 0.5 if bullet.is_explosive else 0,
			"fragmentation_count": bullet.fragmentation_count / 2,
			"fragmentation_explosive": bullet.fragmentation_explosive,
			"fragmentation_damage": bullet.fragmentation_damage * 0.5,
			"fragmentation_level": bullet.fragmentation_level - 1,
			"fragmentation_homing": bullet.fragmentation_homing,
			"particle_trail_enabled": true,  # Disabled by default
			"particle_trail_lifetime": bullet.particle_trail_lifetime * 0.5,
			"particle_trail_color": bullet.particle_trail_color.lightened(0.2),
			"line_trail_enabled": true,
			"line_trail_length": 10,
			"line_trail_width": 2
		}
		fragments.append({"position": bullet.position, "direction": direction, "properties": fragment_properties})
		#print("Fragment ", i, " created with direction: ", direction, " and speed: ", fragment_speed)
	
	#print("Emitting fragmentation signal with ", fragments.size(), " fragments")
	emit_fragmentation(bullet, fragments)

func _process(delta):
	update_explosion_visuals(delta)
	queue_redraw()
	# Clear processed collisions each frame
	processed_collisions.clear()

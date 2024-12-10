class_name RIDBulletParticles
extends Node2D

var particle_systems: Dictionary = {}
var persistent_particle_systems: Array = []
var impact_effects: Array = []

func create_particle_system(bullet):
	var particle_system = GPUParticles2D.new()
	add_child(particle_system)
	
	var particle_material = ParticleProcessMaterial.new()
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	particle_material.particle_flag_disable_z = true
	particle_material.direction = Vector3(0, -1, 0)
	particle_material.spread = 0.0
	particle_material.gravity = Vector3(0, 0, 0)
	particle_material.initial_velocity_min = 1.0
	particle_material.initial_velocity_max = 2.0
	particle_material.orbit_velocity_min = 0.0
	particle_material.orbit_velocity_max = 0.0
	particle_material.damping_min = 0.0
	particle_material.damping_max = 0.0
	particle_material.scale_min = 1.0
	particle_material.scale_max = 3.0
	particle_material.color = bullet.particle_trail_color
	particle_material.color_ramp = create_color_ramp(bullet.particle_trail_color)
	particle_material.scale_curve = create_size_ramp()

	particle_system.process_material = particle_material
	particle_system.amount = 8
	particle_system.lifetime = bullet.particle_trail_lifetime
	particle_system.one_shot = false
	particle_system.explosiveness = 0.0
	particle_system.randomness = 0.1
	particle_system.fixed_fps = 0
	particle_system.local_coords = false
	particle_system.draw_order = GPUParticles2D.DRAW_ORDER_INDEX
	
	particle_systems[bullet] = particle_system

func update_particle_system(bullet):
	if particle_systems.has(bullet):
		var particle_system = particle_systems[bullet]
		particle_system.global_position = bullet.position
		particle_system.rotation = bullet.velocity.angle() + PI
		particle_system.emitting = true

func remove_particle_system(bullet):
	if particle_systems.has(bullet):
		var particle_system = particle_systems[bullet]
		particle_system.emitting = false
		persistent_particle_systems.append({
			"system": particle_system,
			"lifetime": particle_system.lifetime,
			"elapsed": 0.0
		})
		particle_systems.erase(bullet)

func create_impact_effect(position: Vector2, bullet):
	if bullet.impact_effect_enabled:
		var effect = {
			"position": position,
			"color": bullet.impact_effect_color,
			"size": bullet.impact_effect_size,
			"lifetime": bullet.impact_effect_lifetime,
			"max_lifetime": bullet.impact_effect_lifetime
		}
		impact_effects.append(effect)

func update_impact_effects(delta):
	for i in range(impact_effects.size() - 1, -1, -1):
		var effect = impact_effects[i]
		effect.lifetime -= delta
		if effect.lifetime <= 0:
			impact_effects.remove_at(i)

func draw_impact_effects():
	for effect in impact_effects:
		var alpha = effect.lifetime / effect.max_lifetime
		draw_circle(effect.position, effect.size * alpha, effect.color * Color(1, 1, 1, alpha))

func start_persistent_particles(bullet):
	if particle_systems.has(bullet):
		var particle_system = particle_systems[bullet]
		particle_system.emitting = false
		persistent_particle_systems.append({
			"system": particle_system,
			"lifetime": bullet.particle_trail_lifetime + 1,
			"elapsed": 0.0
		})
		particle_systems.erase(bullet)

func update_persistent_particle_systems(delta):
	var i = persistent_particle_systems.size() - 1
	while i >= 0:
		var ps_data = persistent_particle_systems[i]
		ps_data.elapsed += delta
		if ps_data.elapsed >= ps_data.lifetime:
			ps_data.system.queue_free()
			persistent_particle_systems.remove_at(i)
		i -= 1

func create_color_ramp(base_color: Color) -> Gradient:
	var gradient = Gradient.new()
	gradient.set_color(0, base_color)
	var transparent_color = Color(base_color.r, base_color.g, base_color.b, 0)
	gradient.set_color(1, transparent_color)
	return gradient
	
func create_size_ramp() -> CurveTexture:
	var curve = Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	
	var texture = CurveTexture.new()
	texture.curve = curve
	return texture

func _process(delta):
	update_persistent_particle_systems(delta)
	update_impact_effects(delta)
	queue_redraw()

func _draw():
	draw_impact_effects()

func clean_up():
	for particle_system in particle_systems.values():
		particle_system.queue_free()
	for ps_data in persistent_particle_systems:
		ps_data.system.queue_free()
	persistent_particle_systems.clear()
	particle_systems.clear()
	impact_effects.clear()

class_name RIDBulletTrails
extends Node2D

var trail_points: Dictionary = {}
var active_trails: Array = []
var bullet_trails: Array = []

const MAX_TRAIL_POINTS = 20
const MAX_TRAILS = 200
const FADE_DURATION = 2.0  # Time in seconds for the trail to fade out

var background_shader: ShaderMaterial

func _ready():
	var background = get_node("/root/MainGame/ColorRect")  # Adjust this path as needed
	if background and background.material is ShaderMaterial:
		background_shader = background.material
	else:
		push_error("Background shader not found or not a ShaderMaterial")

func update_trail(bullet: RIDBullet):
	if bullet == null:
		return
	
	if not trail_points.has(bullet):
		trail_points[bullet] = []
	
	var points = trail_points[bullet]
	
	# Check for screen wrap
	var last_position = bullet.last_trail_position
	
	var dx = abs(bullet.position.x - last_position.x)
	var dy = abs(bullet.position.y - last_position.y)
	if dx > get_viewport_rect().size.x * 0.5 or dy > get_viewport_rect().size.y * 0.5:
		points.clear()  # Clear the trail if warped
	
	points.push_front(bullet.position)
	bullet.last_trail_position = bullet.position
	
	var trail_length = MAX_TRAIL_POINTS
	if bullet.line_trail_enabled:
		trail_length = bullet.line_trail_length
	
	while points.size() > trail_length:
		points.pop_back()

func start_trail_fadeout(bullet):
	if trail_points.has(bullet):
		var color = Color.WHITE
		if "line_trail_color" in bullet:
			color = bullet.line_trail_color
		
		var width = 1.0
		if "line_trail_width" in bullet:
			width = bullet.line_trail_width
		
		active_trails.append({
			"points": trail_points[bullet],
			"color": color,
			"width": width,
			"fade_speed": 100.0,  # Points to remove per second, adjust as needed
			"time_elapsed": 0.0
		})
		trail_points.erase(bullet)

func update_active_trails(delta):
	var i = active_trails.size() - 1
	while i >= 0:
		var trail = active_trails[i]
		trail.time_elapsed += delta
		
		var points_to_remove = int(trail.time_elapsed * trail.fade_speed)
		
		if points_to_remove > 0:
			trail.points = trail.points.slice(0, -points_to_remove)
			trail.time_elapsed = 0.0  # Reset the timer
		
		if trail.points.size() <= 1:
			active_trails.remove_at(i)
		
		i -= 1

func update_bullet_trails(delta):
	for trail in bullet_trails:
		trail.lifetime -= delta
	
	bullet_trails = bullet_trails.filter(func(trail): return trail.lifetime > 0)
	
	for bullet in trail_points.keys():
		if bullet_trails.size() < MAX_TRAILS:
			bullet_trails.append({
				"position": bullet.position,
				"intensity": 0.4,
				"lifetime": 1  # Adjust this value to control trail duration
			})
		else:
			break

func _process(delta):
	update_active_trails(delta)
	update_bullet_trails(delta)
	queue_redraw()

func _draw():
	for bullet in trail_points.keys():
		var color = Color.WHITE
		if "line_trail_color" in bullet:
			color = bullet.line_trail_color
		
		var width = 1.0
		if "line_trail_width" in bullet:
			width = bullet.line_trail_width
		
		draw_trail(trail_points[bullet], color, width)
	
	for trail in active_trails:
		draw_trail(trail.points, trail.color, trail.width)

func draw_trail(points: Array, color: Color, width: float):
	if points.size() < 2:
		return
	
	for i in range(points.size() - 1):
		var alpha = 0.4 - float(i) / points.size()
		draw_line(points[i], points[i+1], color * Color(1, 1, 1, alpha), width)
 
func clear_bullet_trail(bullet):
	if trail_points.has(bullet):
		trail_points[bullet].clear()

func update_trail_after_warp(bullet):
	if trail_points.has(bullet):
		trail_points[bullet] = [bullet.position]  # Start a new trail from the new position
		bullet.last_trail_position = bullet.position

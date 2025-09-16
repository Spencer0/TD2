extends Node
class_name BuildingManager

signal enter_build_mode(resource: TowerResource)

@export var tilemaplayer: TileMapLayer
@export var placement_validator: PlacementValidator
@export var tower_info_ui: Control
@export var TowerHoverManager: Node2D
var current_resource: TowerResource = null
var overlay_sprite: Sprite2D = null
var ghost_tower: Node2D = null
var overlay_green: Texture2D = null
var overlay_red: Texture2D = null

func _ready() -> void:
	# Create isometric diamond overlay textures
	overlay_green = create_isometric_overlay_texture(Color.GREEN, 0.5)
	overlay_red = create_isometric_overlay_texture(Color.RED, 0.5)
	
	# Prepare a reusable overlay sprite
	overlay_sprite = Sprite2D.new()
	overlay_sprite.z_index = 1000
	overlay_sprite.hide()
	add_child(overlay_sprite)

func create_isometric_overlay_texture(color: Color, alpha: float) -> ImageTexture:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)
	
	# Set the alpha channel for the color
	color.a = alpha
	
	# Draw isometric diamond shape
	# Diamond vertices for 64x32 isometric tile
	var center_x = 32
	var center_y = 16
	
	# Create diamond points
	var points = [
		Vector2i(center_x, 0),      # top
		Vector2i(64, center_y),     # right
		Vector2i(center_x, 32),     # bottom
		Vector2i(0, center_y)       # left
	]
	
	# Fill diamond using scanline algorithm
	for y in range(64):
		for x in range(64):
			if is_point_in_diamond(Vector2i(x, y), points):
				img.set_pixel(x, y, color)
	
	# Add border
	draw_diamond_border(img, points, Color(color.r, color.g, color.b, 1.0))
	
	return ImageTexture.create_from_image(img)

func is_point_in_diamond(point: Vector2i, diamond_points: Array) -> bool:
	# Use cross product method to check if point is inside diamond
	var inside = true
	for i in range(diamond_points.size()):
		var p1 = diamond_points[i]
		var p2 = diamond_points[(i + 1) % diamond_points.size()]
		
		var cross = (p2.x - p1.x) * (point.y - p1.y) - (p2.y - p1.y) * (point.x - p1.x)
		if cross < 0:
			inside = false
			break
	
	return inside

func draw_diamond_border(img: Image, points: Array, border_color: Color) -> void:
	# Draw lines between consecutive points
	for i in range(points.size()):
		var start = points[i]
		var end = points[(i + 1) % points.size()]
		draw_line_on_image(img, start, end, border_color)

func draw_line_on_image(img: Image, start: Vector2i, end: Vector2i, color: Color) -> void:
	# Simple line drawing using Bresenham's algorithm
	var dx = abs(end.x - start.x)
	var dy = abs(end.y - start.y)
	var x_step = 1 if start.x < end.x else -1
	var y_step = 1 if start.y < end.y else -1
	var error = dx - dy
	
	var x = start.x
	var y = start.y
	
	while true:
		if x >= 0 and x < 64 and y >= 0 and y < 64:
			img.set_pixel(x, y, color)
		
		if x == end.x and y == end.y:
			break
			
		var error2 = 2 * error
		if error2 > -dy:
			error -= dy
			x += x_step
		if error2 < dx:
			error += dx
			y += y_step

func enter_build_mode_with(resource: TowerResource) -> void:
	current_resource = resource
	overlay_sprite.show()
	
	# Create ghost tower
	create_ghost_tower()

func create_ghost_tower() -> void:
	if ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null
	
	if current_resource and current_resource.scene:
		ghost_tower = current_resource.scene.instantiate()
		ghost_tower.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent
		ghost_tower.z_index = 999
		
		# Disable collision and functionality for ghost
		disable_ghost_functionality(ghost_tower)
		
		add_child(ghost_tower)
		ghost_tower.hide()

func disable_ghost_functionality(node: Node) -> void:
	# Recursively disable collision and areas
	for child in node.get_children():
		if child is Area2D or child is CollisionShape2D:
			child.set_deferred("monitoring", false)
			child.set_deferred("monitorable", false)
		disable_ghost_functionality(child)

func _unhandled_input(event: InputEvent) -> void:
	if current_resource == null:
		return
		
	if event is InputEventMouseMotion:
		update_placement_preview()
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			attempt_placement()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_build_mode()

func update_placement_preview() -> void:
	var mouse_pos = tilemaplayer.get_local_mouse_position()
	var tile = tilemaplayer.local_to_map(mouse_pos)
	var valid = placement_validator.is_placement_valid(tile, current_resource.size, tilemaplayer)
	
	# Position overlay to snap to the anchor tile
	overlay_sprite.texture = overlay_green if valid else overlay_red
	overlay_sprite.position = tilemaplayer.map_to_local(tile)
	overlay_sprite.position += Vector2(0,16)
	# Scale overlay to match tower size
	overlay_sprite.scale = Vector2(current_resource.size, current_resource.size)
	
	# Update ghost tower position
	if ghost_tower:
		ghost_tower.position = tilemaplayer.map_to_local(tile)
		ghost_tower.position += Vector2(0,16)
		ghost_tower.show()
		ghost_tower.modulate = Color(0, 1, 0, 0.99) if valid else Color(1, 0, 0,0.99)

func attempt_placement() -> void:
	var mouse_pos = tilemaplayer.get_local_mouse_position()
	var tile = tilemaplayer.local_to_map(mouse_pos)
	var valid = placement_validator.is_placement_valid(tile, current_resource.size, tilemaplayer)
	
	if valid:
		place_tower(tile)
		cancel_build_mode()

func place_tower(tile: Vector2i) -> void:
	var tower_instance = current_resource.scene.instantiate()
	print("place tower")
	# Properly set up the tower
	tower_instance.set_resource(current_resource)
	tower_instance.resource = current_resource
	
	# Set position and add to scene with proper Y-sorting
	tower_instance.position = tilemaplayer.map_to_local(tile)
	tower_instance.position += Vector2(0,16)
	tower_instance.y_sort_enabled = true
	tower_instance.connect("tower_clicked", Callable(tower_info_ui, "_on_tower_clicked"))
	tower_instance.add_to_group("towers")
	TowerHoverManager.register_tower(tower_instance)
	
	# Add to proper parent for Y-sorting (not tilemaplayer)
	var game_scene = get_tree().current_scene
	if game_scene.has_node("Towers"):
		game_scene.get_node("Towers").add_child(tower_instance)
	else:
		get_tree().quit()
	
	placement_validator.mark_occupied(tile, current_resource.size)

func cancel_build_mode() -> void:
	overlay_sprite.hide()
	if ghost_tower:
		ghost_tower.queue_free()
		ghost_tower = null
	current_resource = null

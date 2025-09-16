extends Node2D

@onready var attack_range: Area2D = $AttackRange
@onready var range_shape: CollisionShape2D = $AttackRange/RangeShape
@onready var visuals: Node2D = $Visuals
@onready var tween: Tween
@onready var click_enabled_timer: Timer = $ClicksEnabledTimer
@export var resource: TowerResource
signal tower_clicked(tower: Node, resource: TowerResource)

# How can we handle "tower upgrades"?
# When a UI button is clicked, "upgrade" we can call upgrade() here
# This will change the color of of sprites, I will denote "UpgradableSprites" 
# and "Sprites" seperately. 
# The upgradeable sprites should get a strong color change to 
# Level 0 -> default, 1 -> 80% Bronze Color, 2 -> 80% Silver, 3-> 80% Gold overlay on the sprites
# We should also bump the damage by one for upgrade level.
# I would prefer to not store that logic in this class,
# not sure the best class to do so. 
# while we are doing this refactor, let's also extract tower_visuals to its own file
# so come up with a class to hold the upgrade logic? we also probably want upgrades to be 
# different for other tower types in the future, but we don't need to do that now 
# 


# Tower stats 

var damage := 1.0
var fire_rate := 1.0
var projectile_speed := 300.0
var detection_range := 150.0
var firing_height := 96
var display_name = "Tower"

# Internal state
var fire_timer := 0.0
var current_target: CharacterBody2D = null
var enemies_in_range: Array[CharacterBody2D] = []
var tile_position: Vector2i

# Visual feedback state
var is_hovered := false
var hover_tween: Tween
var click_tween: Tween

@export var projectile_scene: PackedScene

func _ready() -> void:
	y_sort_enabled = true
	
	if resource:
		display_name = resource.display_name
		if resource.has_method("get_damage"):
			damage = resource.get_damage()
		if resource.has_method("get_fire_rate"):
			fire_rate = resource.get_fire_rate()
		if resource.has_method("get_range"):
			detection_range = resource.get_range()
	
	# Connect range detection
	attack_range.connect("body_entered", Callable(self, "_on_enemy_entered_range"))
	attack_range.connect("body_exited", Callable(self, "_on_enemy_exited_range"))
	
	setup_detection_range()
	
	# TODO: Is this doing anything
	var tilemap = get_node("../../TileMapLayer") if has_node("../../TileMapLayer") else null
	if tilemap:
		tile_position = tilemap.local_to_map(position)

func setup_detection_range() -> void:
	if range_shape and range_shape.shape is CircleShape2D:
		(range_shape.shape as CircleShape2D).radius = detection_range
	if attack_range:
		attack_range.position = Vector2.ZERO

func set_resource(new_resource: TowerResource) -> void:
	resource = new_resource
	if resource:
		display_name = resource.display_name

func _process(delta: float) -> void:
	fire_timer += delta
	cleanup_invalid_enemies()
	
	if current_target == null or not is_instance_valid(current_target):
		find_new_target()
	
	if can_fire() and current_target != null:
		if is_target_in_range(current_target):
			fire_projectile()
			fire_timer = 0.0
		else:
			current_target = null

func cleanup_invalid_enemies() -> void:
	enemies_in_range = enemies_in_range.filter(func(enemy): return is_instance_valid(enemy))

func find_new_target() -> void:
	if enemies_in_range.is_empty():
		current_target = null
		return
	var closest_enemy: CharacterBody2D = null
	var closest_distance := INF
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			continue
		if is_target_in_range(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_enemy = enemy
	current_target = closest_enemy

func is_target_in_range(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	return global_position.distance_to(target.global_position) <= detection_range

func can_fire() -> bool:
	return fire_timer >= (1.0 / fire_rate) and projectile_scene != null

func fire_projectile() -> void:
	if current_target == null or not is_instance_valid(current_target):
		return
	var projectile = projectile_scene.instantiate()
	var game_scene = get_tree().current_scene
	if game_scene.has_node("Projectiles"):
		game_scene.get_node("Projectiles").add_child(projectile)
	else:
		var projectiles_container = Node2D.new()
		projectiles_container.name = "Projectiles"
		projectiles_container.y_sort_enabled = true
		projectiles_container.z_index = 100
		game_scene.add_child(projectiles_container)
		projectiles_container.add_child(projectile)
	projectile.global_position = global_position + Vector2(0, -firing_height)
	projectile.z_index = z_index + 10
	if projectile.has_method("setup"):
		projectile.setup(current_target, projectile_speed, damage)
	fire_animation()

func fire_animation() -> void:
	if not visuals:
		return
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(visuals, "scale", Vector2(1.1, 0.95), 0.15)
	tween.tween_property(visuals, "scale", Vector2(1.0, 1.05), 0.15)
	tween.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.15)

# ====================
# New public API
# ====================

func set_hovered(state: bool) -> void:
	if state == is_hovered:
		return
	is_hovered = state
	if is_hovered:
		apply_hover_effect()
	else:
		remove_hover_effect()

func click() -> void:
	apply_click_effect()
	emit_signal("tower_clicked", self, self.resource)

# ====================
# Visual effects - Move to tower_visuals.gd
# ====================

func apply_hover_effect():
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(visuals, "modulate", Color(1.2, 1.2, 0.8, 1.0), 0.15)

func remove_hover_effect():
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
	hover_tween = create_tween().set_parallel(true)
	hover_tween.tween_property(visuals, "modulate", Color.WHITE, 0.15)
	hover_tween.tween_property(visuals, "position", Vector2.ZERO, 0.15)

func apply_click_effect():
	if not visuals:
		return
	if click_tween and click_tween.is_valid():
		click_tween.kill()
	click_tween = create_tween()
	click_tween.tween_property(visuals, "modulate", Color.GREEN, 0.1)

func _on_enemy_entered_range(body: Node2D) -> void:
	if body.is_in_group("enemies") and body is CharacterBody2D:
		if not enemies_in_range.has(body):
			enemies_in_range.append(body as CharacterBody2D)

func _on_enemy_exited_range(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemies_in_range.erase(body)
		if body == current_target:
			current_target = null

extends Node2D
class_name Tower
# -------------------------
# Child Nodes
# -------------------------
@onready var attack_range: Area2D = $AttackRange
@onready var range_shape: CollisionShape2D = $AttackRange/RangeShape
@onready var visuals: TowerVisuals = $Visuals
@onready var tween: Tween
@onready var click_enabled_timer: Timer = $ClicksEnabledTimer

# -------------------------
# Exported Data
# -------------------------
@export var resource: TowerResource
@export var upgrade_data: Node2D
@export var projectile_scene: PackedScene

# -------------------------
# Signals
# -------------------------
signal tower_clicked(tower: Node, resource: TowerResource)

# -------------------------
# Stats
# -------------------------
var damage := 1.0
@export var fire_rate := 1.0
var projectile_speed := 300.0
var detection_range := 150.0
var firing_height := 96
var display_name = "Tower"

# Upgrade state
var upgrade_level := 0
@export var upgrade_cost = 100
var max_upgrades = 4

# -------------------------
# Internal State
# -------------------------
var fire_timer := 0.0
var current_target: CharacterBody2D = null
var enemies_in_range: Array[CharacterBody2D] = []
var tile_position: Vector2i
# Prevent clicking and opening up tower details right when placed
# Otherwise the UI will pop up
var can_be_clicked = false
var clickable_timer: Timer

# -------------------------
# Visual Feedback State
# -------------------------
var is_hovered := false
var hover_tween: Tween
var click_tween: Tween

# -------------------------
# Lifecycle
# -------------------------
func _ready() -> void:
	y_sort_enabled = true

	# Load from resource if available
	# only not available for "Ghost" tower placements
	# probably should be
	if resource:
		display_name = resource.display_name

	# Connect range detection
	attack_range.connect("body_entered", Callable(self, "_on_enemy_entered_range"))
	attack_range.connect("body_exited", Callable(self, "_on_enemy_exited_range"))

	setup_detection_range()

	# Ugly timer code
	clickable_timer = Timer.new()
	add_child(clickable_timer)

	clickable_timer.wait_time = 0.3
	clickable_timer.one_shot = true # Ensures the timer runs only once

	clickable_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	clickable_timer.start()
	
	# Store tilemap position if available
	var tilemap = get_node("../../TileMapLayer") if has_node("../../TileMapLayer") else null
	if tilemap:
		tile_position = tilemap.local_to_map(position)

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

# -------------------------
# Detection + Targeting
# -------------------------
func setup_detection_range() -> void:
	if range_shape and range_shape.shape is CircleShape2D:
		(range_shape.shape as CircleShape2D).radius = detection_range
	if attack_range:
		attack_range.position = Vector2.ZERO

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

# -------------------------
# Firing Logic
# -------------------------
func can_fire() -> bool:
	return fire_timer >= (1.0 / fire_rate) and projectile_scene != null

func fire_projectile() -> void:
	if current_target == null or not is_instance_valid(current_target):
		return
	## This code should just be "projectile.shoot(globalPosition)"
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

# -------------------------
# Upgrades
# -------------------------
func upgrade() -> void:
	print('upgrade')
	upgrade_level += 1
	if(upgrade_level >= max_upgrades):
		upgrade_cost = -1
	upgrade_cost = upgrade_cost * 2
	if upgrade_data:
		damage = upgrade_data.get_damage(upgrade_level)
		fire_rate = fire_rate * upgrade_data.get_fire_rate_scaling(upgrade_level)
	if visuals:
		visuals.set_upgrade_level(upgrade_level)

# -------------------------
# UI Feedback
# -------------------------
func set_hovered(state: bool) -> void:
	if(!can_be_clicked):
		return
	if state == is_hovered:
		return
	is_hovered = state
	if is_hovered:
		visuals.apply_hover_effect()
	else:
		visuals.remove_hover_effect()

func click() -> void:
	if(!can_be_clicked):
		return
	visuals.apply_click_effect()
	emit_signal("tower_clicked", self, self.resource)

# -------------------------
# Signals from Area2D
# -------------------------
func _on_enemy_entered_range(body: Node2D) -> void:
	if body.is_in_group("units") and body is CharacterBody2D:
		if not enemies_in_range.has(body):
			enemies_in_range.append(body as CharacterBody2D)

func _on_enemy_exited_range(body: Node2D) -> void:
	if body.is_in_group("units"):
		enemies_in_range.erase(body)
		if body == current_target:
			current_target = null
			
func _on_timer_timeout() -> void:
	can_be_clicked = true

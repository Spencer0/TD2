extends Node2D
class_name UnitVisuals

@onready var sprite: Sprite2D = $Sprite
@onready var death_particles: GPUParticles2D = $DeathParticles
@onready var status_particles: GPUParticles2D = $StatusParticles
@onready var enemy_logic: EnemyLogic = get_parent()

var base_y: float
var time: float = 0.0
var status_overlay_color: Color = Color.WHITE
var active_visual_statuses: Dictionary = {}  # StatusType -> visual data

signal spawn_finished
signal death_finished

func _ready() -> void:
	base_y = sprite.position.y

	# Connect to logic signals
	enemy_logic.connect("spawned", Callable(self, "_on_spawned"))
	enemy_logic.connect("took_damage", Callable(self, "_on_took_damage"))
	enemy_logic.connect("died", Callable(self, "_on_died"))
	enemy_logic.connect("status_applied", Callable(self, "_on_status_applied"))

	# Setup all particles
	_setup_death_particles()

func _process(delta: float) -> void:
	time += delta
	# Idle hover effect
	var base_offset = sin(time * 2.0) * 10.0
	
	# Add status-specific movement modifications
	sprite.position.y = base_y + base_offset
	

	# Update status visuals
	_update_status_visuals(delta)

# ---------------------------
# Signal Handlers
# ---------------------------
func _on_spawned() -> void:
	_play_spawn_effect()

func _on_took_damage() -> void:
	play_hit_feedback()

func _on_died() -> void:
	play_death_effect()

func _on_status_applied(status_type) -> void:
	apply_visual_status_effect(status_type)

# ---------------------------
# SPAWN EFFECT
# ---------------------------
func _play_spawn_effect():
	sprite.modulate.a = 0.0
	sprite.scale = Vector2(0.5, 0.5)

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	tween.tween_callback(func():
		emit_signal("spawn_finished")
		enemy_logic.allow_movement() 
	)

# ---------------------------
# HIT FEEDBACK
# ---------------------------
func play_hit_feedback():
	var tween := create_tween()
	tween.parallel().tween_property(sprite, "scale", Vector2(1.02, 0.98), 0.1)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)

# ---------------------------
# STATUS VISUAL EFFECTS
# ---------------------------
func apply_visual_status_effect(status_type) -> void:
	
	match status_type:
		EnemyLogic.StatusType.SLOW:
			_apply_slow_visuals()
		EnemyLogic.StatusType.POISON:
			_apply_poison_visuals()
		EnemyLogic.StatusType.REVERSE:
			_apply_reverse_visuals()
		EnemyLogic.StatusType.BURN:
			_apply_burn_visuals()
		_:
			print("Unknown status type: ", status_type)

func _apply_slow_visuals() -> void:
	active_visual_statuses[EnemyLogic.StatusType.SLOW] = {
		"color": Color(0.0, 0.0, 1.0, 1.0) * 2, 
	}
	_update_status_color()

func _apply_poison_visuals() -> void:
	active_visual_statuses[EnemyLogic.StatusType.POISON] = {
		"color": Color(0.3, 1.0, 0.3, 1.0), 
	}
	_update_status_color()

func _apply_reverse_visuals() -> void:
	active_visual_statuses[EnemyLogic.StatusType.REVERSE] = {
	}
	_update_status_color()

func _apply_burn_visuals() -> void:
	active_visual_statuses[EnemyLogic.StatusType.BURN] = {
		"color": Color(1.0, 0.4, 0.2,  1.0),  # Orange/red tint
	}
	_update_status_color()

func _update_status_color() -> void:
	# Blend all active status colors
	var final_color = Color.WHITE
	var blend_factor = 0.0
	
	for status_type in active_visual_statuses:
		if enemy_logic.active_statuses.has(status_type):  # Only if still active in logic
			var color = active_visual_statuses[status_type]["color"]
			final_color = final_color.lerp(color, 0.5)
			blend_factor += 0.3
	# If I sprite hide here, I can see it vanish sprite.hide()
	status_overlay_color = final_color
	sprite.modulate = final_color 

func _calculate_status_movement_offset(delta: float) -> float:
	var offset = 0.0
	
	# Slow effect - reduced movement
	if active_visual_statuses.has(EnemyLogic.StatusType.SLOW) and enemy_logic.active_statuses.has(EnemyLogic.StatusType.SLOW):
		offset *= active_visual_statuses[EnemyLogic.StatusType.SLOW].get("movement_modifier", 1.0)
	
	return offset

func _update_status_visuals(delta: float) -> void:
	# Remove visual effects for statuses that are no longer active
	var to_remove = []
	for status_type in active_visual_statuses:
		if not enemy_logic.active_statuses.has(status_type):
			to_remove.append(status_type)
	
	for status_type in to_remove:
		_remove_visual_status_effect(status_type)
	
	for status_type in active_visual_statuses:
		if not enemy_logic.active_statuses.has(status_type):
			continue
		var visual_data = active_visual_statuses[status_type]
		if visual_data.get("spin_effect", false):
			sprite.rotation += delta * 2.0

func _remove_visual_status_effect(status_type) -> void:
	if active_visual_statuses.has(status_type):
		active_visual_statuses.erase(status_type)
		_update_status_color()
# ---------------------------
# DEATH EFFECT
# ---------------------------
func play_death_effect():
	status_particles.emitting = false
	death_particles.emitting = true

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(func():
		emit_signal("death_finished")
		enemy_logic.queue_free()
	)

func _setup_death_particles():
	var mat := ParticleProcessMaterial.new()
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 100.0
	mat.scale_min = 1.5
	mat.scale_max = 3.0
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	mat.emission_ring_inner_radius = 28.0
	mat.emission_ring_radius = 30.0
	mat.gravity = Vector3(0, 400, 0)
	mat.color_ramp = _make_gradient([Color("#7FFF00"), Color("#7FFF00", 0)])
	death_particles.amount = 15
	death_particles.lifetime = 2.5
	death_particles.one_shot = true
	death_particles.explosiveness = 1.0
	mat.direction = Vector3(0, -0.6, 0) 
	mat.spread = 45.0  
	death_particles.process_material = mat
	death_particles.position = Vector2(0, -20)
	death_particles.emitting = false

# HELPERS
# ---------------------------
func _make_gradient(colors: Array) -> GradientTexture2D:
	var grad := Gradient.new()
	for i in colors.size():
		grad.add_point(float(i) / (colors.size() - 1), colors[i])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	return tex

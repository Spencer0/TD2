extends Node2D
class_name EnemyVisuals

@onready var sprite: Sprite2D = $Sprite
@onready var move_particles: GPUParticles2D = $MoveParticles
@onready var death_particles: GPUParticles2D = $DeathParticles
@onready var enemy_logic: EnemyLogic = get_parent()

var base_y: float
var time: float = 0.0

signal spawn_finished
signal death_finished

func _ready() -> void:
	base_y = sprite.position.y

	# Connect to logic signals
	enemy_logic.connect("spawned", Callable(self, "_on_spawned"))
	enemy_logic.connect("took_damage", Callable(self, "_on_took_damage"))
	enemy_logic.connect("died", Callable(self, "_on_died"))

	# Setup all particles
	_setup_move_particles()
	_setup_death_particles()

func _process(delta: float) -> void:
	time += delta
	# Idle hover effect
	var offset = sin(time * 2.0) * 10.0
	sprite.position.y = base_y + offset
	
	# Handle movement particles based on enemy movement
	_update_movement_particles()

# ---------------------------
# Movement Particle Management
# ---------------------------
func _update_movement_particles() -> void:
	# Enable move particles only when enemy is moving
	var is_moving = enemy_logic.can_move and enemy_logic.velocity.length() > 10.0
	move_particles.emitting = is_moving

# ---------------------------
# Signal Handlers
# ---------------------------
func _on_spawned() -> void:
	_play_spawn_effect()

func _on_took_damage() -> void:
	play_hit_feedback()

func _on_died() -> void:
	play_death_effect()

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
	tween.tween_property(sprite, "modulate", Color(1, 0, 0), 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)
	tween.parallel().tween_property(sprite, "scale", Vector2(1.02, 0.98), 0.1)
	tween.tween_property(sprite, "scale", Vector2.ONE, 0.1)

func apply_visual_status_effect(status)
	# How to best handle this given the current status effect implementation. 
	# Also, open to ideas on what I'm doing wrong in my "unit" or enemy code
	# and better ways to model that
	
# ---------------------------
# DEATH EFFECT
# ---------------------------
func play_death_effect():
	move_particles.emitting = false
	death_particles.emitting = true

	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.3)
	tween.tween_callback(func():
		emit_signal("death_finished")
		enemy_logic.queue_free()
	)


func _setup_move_particles():
	var mat := ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, 30, 0)
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 40.0
	mat.scale_min = 0.9
	mat.scale_max = 1.0
	mat.color_ramp = _make_gradient([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	move_particles.amount = 5
	move_particles.lifetime = 0.4
	move_particles.one_shot = false
	move_particles.process_material = mat
	move_particles.emitting = false  # ✅ Start disabled, will be managed by _update_movement_particles()

func _setup_death_particles():
	var mat := ParticleProcessMaterial.new()
	mat.initial_velocity_min = 50.0 # Decrease initial velocity
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
	# Add a slight upward direction, but not enough to dominate gravity.
	mat.direction = Vector3(0, -0.6, 0) 
	mat.spread = 45.0  
	death_particles.process_material = mat
	death_particles.position = Vector2(0, -20)
	death_particles.emitting = false
# ---------------------------
# HELPERS
# ---------------------------
func _make_gradient(colors: Array) -> GradientTexture2D:
	var grad := Gradient.new()
	for i in colors.size():
		grad.add_point(float(i) / (colors.size() - 1), colors[i])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	return tex

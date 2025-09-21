# projectile_visuals.gd
extends Node2D
class_name ProjectileVisuals

@onready var sprite: Sprite2D = $Sprite
@onready var hit_particles: GPUParticles2D = $HitParticles
signal hit_finished

var base_scale: Vector2 = Vector2.ONE
var time: float = 0.0

func _ready() -> void:
	base_scale = sprite.scale
	setup_hit_particles()

func _process(delta: float) -> void:
	# Pulse while traveling
	time += delta
	var scale_offset = sin(time * 8.0) * 0.15
	sprite.scale = base_scale + Vector2.ONE * scale_offset

func update_rotation(angle: float) -> void:
	sprite.rotation = angle

# ---------------------------
# HIT PARTICLE BURST
# ---------------------------
func play_hit_effect(global_pos: Vector2) -> void:
	# Stop sprite pulsing and fade it out quickly
	set_process(false)
	
	# Fade sprite to transparent in 0.1 seconds
	var fade_tween = create_tween()
	fade_tween.tween_property(sprite, "modulate:a", 0.0, 0.01)
	
	# Position and start particles
	hit_particles.global_position = global_pos
	hit_particles.emitting = true
	hit_particles.z_index = global_position.y + 1
	
	# Wait for particle lifetime to finish, then signal cleanup
	await get_tree().create_timer(hit_particles.lifetime).timeout
	emit_signal("hit_finished")

# ---------------------------
# PARTICLE SETUP - SIMPLE APPROACH
# ---------------------------
func setup_hit_particles() -> void:
	var mat := ParticleProcessMaterial.new()
	
	# Set up for radial burst
	mat.initial_velocity_min = 600.0
	mat.initial_velocity_max = 600.0
	mat.scale_min = 0.08
	mat.scale_max = 0.16
	mat.gravity = Vector3.ZERO
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 180.0  # This creates 360° spread
	hit_particles.amount = 4
	hit_particles.lifetime = 0.15
	hit_particles.one_shot = true
	hit_particles.explosiveness = 1.0
	hit_particles.process_material = mat
	hit_particles.emitting = false
	

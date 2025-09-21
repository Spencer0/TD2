# SpecializedUnitVisuals.gd - Inherits from UnitVisuals with overrides
extends UnitVisuals
class_name SpecializedUnitVisuals

@export var additional_sprites: Array[Sprite2D] = []

var rock_timer: float = 0.0
var is_rocking: bool = false


# Override the idle animation method instead of _process
func _update_idle_animation(delta: float) -> void:
	# Override the movement pattern based on config
	match unit_logic.unit_config.animation_type:
		UnitConfig.AnimationType.ROCK:
			_handle_rock_animation(delta)
		UnitConfig.AnimationType.BOB:
			super._update_idle_animation(delta)  # Use parent's bobbing
		UnitConfig.AnimationType.CUSTOM:
			_handle_custom_animation(delta)
	# Always update status visuals
	_update_status_visuals(delta)

func _handle_rock_animation(delta: float) -> void:
	time += delta
	rock_timer += delta
	
	# Base idle position
	
	
	# Check if it's time to rock
	var config = unit_logic.unit_config
	if config and rock_timer >= config.rock_interval and not is_rocking:
		_start_rock_animation()

func _start_rock_animation() -> void:
	is_rocking = true
	rock_timer = 0.0
	
	var config = unit_logic.unit_config
	var rock_angle = deg_to_rad(config.rock_angle if config else 15.0)
	
	var tween = create_tween()
	
	# Rock right
	tween.tween_property(sprite, "rotation", rock_angle, 0.2)
	for additional_sprite in additional_sprites:
		tween.parallel().tween_property(additional_sprite, "rotation", rock_angle, 0.2)
	
	# Rock left
	tween.tween_property(sprite, "rotation", -rock_angle, 0.4)
	for additional_sprite in additional_sprites:
		tween.parallel().tween_property(additional_sprite, "rotation", -rock_angle, 0.4)
	
	# Return to center
	tween.tween_property(sprite, "rotation", 0.0, 0.2)
	for additional_sprite in additional_sprites:
		tween.parallel().tween_property(additional_sprite, "rotation", 0.0, 0.2)
	
	tween.tween_callback(func(): is_rocking = false)

func _handle_custom_animation(delta: float) -> void:
	# Override this in further subclasses for completely custom animations
	super._process(delta)

# Override spawn effect to handle multiple sprites
func _play_spawn_effect():
	sprite.modulate.a = 0.0
	sprite.scale = Vector2(0.5, 0.5)
	
	# Setup additional sprites for spawn effect
	for additional_sprite in additional_sprites:
		additional_sprite.modulate.a = 0.0
		additional_sprite.scale = Vector2(0.5, 0.5)

	var tween := create_tween()
	
	# Main sprite animation
	tween.tween_property(sprite, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(sprite, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Additional sprites with slight delay
	var delay = 0.1
	for additional_sprite in additional_sprites:
		tween.parallel().tween_property(additional_sprite, "modulate:a", 1.0, 0.5).set_delay(delay)
		tween.parallel().tween_property(additional_sprite, "scale", Vector2.ONE, 0.5).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		delay += 0.1
	
	tween.tween_callback(func():
		emit_signal("spawn_finished")
		unit_logic.allow_movement()
	)

# Override status color updates to affect all sprites
func _apply_color_to_sprites(color: Color) -> void:
	# Call parent logic
	super._apply_color_to_sprites(color)
	
	# Apply the same color to additional sprites
	for additional_sprite in additional_sprites:
		additional_sprite.modulate = color

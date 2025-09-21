# SpecializedUnitVisuals.gd - Inherits from UnitVisuals with overrides
extends UnitVisuals
class_name FastUnitVisuals

@export var additional_sprites: Array[Sprite2D] = []

var rock_timer: float = 0.0
var is_rocking: bool = false


# Override spawn effect to handle multiple sprites
##  REFACTOR ME IM IN THREE PLACES ## 
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

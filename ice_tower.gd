extends Tower
class_name IceTower

# Override just the animation method
func fire_animation() -> void:
	if not visuals:
		return
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Sway left and right instead of scaling
	tween.tween_property(visuals, "rotation_degrees", -5.0, 0.15)  # Sway left
	tween.tween_property(visuals, "rotation_degrees", 5.0, 0.15)   # Sway right
	tween.tween_property(visuals, "rotation_degrees", -5.0, 0.15)  # Sway left
	tween.tween_property(visuals, "rotation_degrees", 5.0, 0.15)   # Sway right
	tween.tween_property(visuals, "rotation_degrees", 0.0, 0.15)   # Back to center

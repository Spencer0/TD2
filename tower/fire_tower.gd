extends Tower
class_name FireTower

# Override just the animation method
func fire_animation() -> void:
	if not visuals:
		return
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Jump up and down instead of rotation
	tween.tween_property(visuals, "position:y", visuals.position.y - 15, 0.1)  # Jump up
	tween.tween_property(visuals, "position:y", visuals.position.y, 0.1)       # Land back down
	tween.tween_property(visuals, "position:y", visuals.position.y - 10, 0.08) # Smaller jump
	tween.tween_property(visuals, "position:y", visuals.position.y, 0.08)      # Land back down
	tween.tween_property(visuals, "position:y", visuals.position.y - 5, 0.06)  # Even smaller jump
	tween.tween_property(visuals, "position:y", visuals.position.y, 0.06)      # Final landing

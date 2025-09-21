extends Projectile
class_name FireProjectile

@export var status_type: String = "BURN"  # e.g., "BURN", "POISON" (match enum strings)
@export var status_strength: float = 2.0  # 2 dmg/sec burn damage
@export var status_duration: float = 3.0

func _on_hit_enemy(body: Node) -> void:
	if body.is_in_group("units") and body.has_method("apply_status"):
		body.take_damage(damage as int)
		
		# Apply status if configured
		if status_type != "":
			var type = UnitLogic.StatusType[status_type.to_upper()]  # Convert string to enum
			body.apply_status(type, status_strength, status_duration)
	
	visuals.play_hit_effect(global_position)
	
	set_physics_process(false)
	velocity = Vector2.ZERO
	hitbox.set_deferred("monitoring", false)

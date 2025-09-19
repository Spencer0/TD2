extends Node2D
class_name TowerUpgrade

@export var damage_per_level := [1.0, 2.0, 3.0, 4.0]
@export var fire_rate_per_level := [1.0, 1.1, 1.25, 1.5]

func get_damage(level: int) -> float:
	if level < damage_per_level.size():
		return damage_per_level[level]
	return damage_per_level.back()

func get_fire_rate(level: int) -> float:
	if level < fire_rate_per_level.size():
		return fire_rate_per_level[level]
	return fire_rate_per_level.back()

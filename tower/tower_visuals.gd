# tower_visuals.gd
extends Node2D
class_name TowerVisuals
@export var upgradable_sprites: Array[Sprite2D] = []
@export var normal_sprites: Array[Sprite2D] = []

var upgrade_colors := {  
	1: Color(0.12, 1.0, 0.0) ,
	2: Color(0.0, 0.44, 0.87), 
	3: Color(1.0, 0.3, 1.5) ,       
	4: Color(1.5, 1.2, 0.0),          
}

func set_upgrade_level(level: int) -> void:
	var color = upgrade_colors.get(level, null)
	if !color:
		return
	for sprite in upgradable_sprites:
		if sprite != null:
			sprite.modulate = color * 2

# Hover/click effects can also live here:
func apply_hover_effect():
	modulate = Color(1.2, 1.2, 0.8, 1.0)
	
func remove_hover_effect():
	modulate = Color.WHITE

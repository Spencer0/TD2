extends Node2D
class_name StageSelection

@export var levels: Array[LevelResource] 
@onready var levels_row: HBoxContainer = $Menu/VBoxContainer/LevelsRow

func _ready() -> void:
	for level in levels:
		var level_ui = preload("res://menus/level_select_ui.tscn").instantiate()
		
		var texture_rect = level_ui.get_node("TextureRect") as TextureRect
		
		# Load the pre-resized 256x256 image
		var texture = load(level.menu_image_path_to_texture)
		texture_rect.texture = texture
		
		# Set the custom minimum size to 256x256, overriding any scaling
		texture_rect.custom_minimum_size = Vector2(256, 256)
		
		# Ensure the texture stretches to fill the container
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Remove the dynamic scaling lines as they are no longer needed
		# texture_rect.scale = Vector2(0.3, 0.3)
		
		var label = level_ui.get_node("Label") as Label
		label.text = level.display_name
		
		# connect interactions
		level_ui.mouse_entered.connect(func():
			label.add_theme_color_override("font_color", Color.GREEN))
		level_ui.mouse_exited.connect(func():
			label.add_theme_color_override("font_color", Color.WHITE))
		level_ui.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_start_level(level.main_scene))
				
		levels_row.add_child(level_ui)


func _start_level(scene: PackedScene) -> void:
	# Just switch scenes; no need for manual cleanup since Godot will free the menu tree
	get_tree().change_scene_to_packed(scene)

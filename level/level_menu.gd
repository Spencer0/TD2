extends Control
class_name LevelMenu

@onready var resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton
@onready var exit_button: Button = $PanelContainer/VBoxContainer/ExitButton

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep working while game is paused

	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func open_menu() -> void:
	get_tree().paused = true
	show()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	hide()

func _on_exit_pressed() -> void:
	get_tree().paused = false  # Ensure unpaused before leaving
	get_tree().change_scene_to_file("res://menus/StageSelection.tscn")

extends Area2D

signal tower_hovered(tower)
signal tower_unhovered(tower)
signal tower_clicked(tower)

var is_hovered = false

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event) 

func _on_mouse_entered():
	if not is_hovered:
		is_hovered = true
		tower_hovered.emit(get_parent())

func _on_mouse_exited():
	if is_hovered:
		is_hovered = false
		tower_unhovered.emit(get_parent())

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		print('emit')
		tower_clicked.emit(get_parent())

extends Camera2D

@export var speed: float = 400.0
@export var zoom_step: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.5

func _process(delta: float) -> void:
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		position += input_dir * speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom -= Vector2.ONE * zoom_step
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom += Vector2.ONE * zoom_step

		# Clamp so you don’t zoom forever
		zoom.x = clamp(zoom.x, min_zoom, max_zoom)
		zoom.y = clamp(zoom.y, min_zoom, max_zoom)

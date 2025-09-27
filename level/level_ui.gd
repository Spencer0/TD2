extends CanvasLayer


@onready var menu: LevelMenu = $LevelMenu
@onready var menu_button: Button = $BottomLeft/PanelContainer2/GameStats/MenuButton

func _ready() -> void:
	menu_button.pressed.connect(_on_menu_button_pressed)

func _on_menu_button_pressed() -> void:
	menu.open_menu()

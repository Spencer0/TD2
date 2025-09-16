extends Control
@onready var upgrade_button: Button = $ExpandableInfo/Upgrade
@onready var tower_info_container: PanelContainer = $PanelContainer
@onready var display_label: Label = $PanelContainer/ExpandableInfo/DisplayName
@onready var subviewport: SubViewport = $PanelContainer/ExpandableInfo/TowerStats/SubViewportContainer/SubViewport

@export var tower_resources: Array[TowerResource] = []

var is_expanded: bool = false
var original_size: Vector2
var current_tower: Node = null
var current_resource: TowerResource = null
var just_opened := false

func _ready() -> void:
	close_list()
	
func _on_tower_clicked(tower: Node, resource: TowerResource) -> void:
		current_tower = tower
		current_resource = resource
		expand_list()
		just_opened = true


func expand_list() -> void:
	display_label.text = current_resource.display_name
	tower_info_container.show()
	for child in subviewport.get_children():
		child.queue_free()
	if current_tower.has_node("Visuals"):
		var tower_visuals: Node = current_tower.get_node("Visuals")
		var copy = tower_visuals.duplicate(DUPLICATE_SIGNALS)
		copy.position = Vector2(108, 198)
		subviewport.add_child(copy)
		
func _unhandled_input(event: InputEvent) -> void:
	if just_opened:
		if event is InputEventMouseButton and event.is_released():
			just_opened = false
		return
	if tower_info_container.is_visible():
		if event is InputEventMouseButton and event.is_released():
			if not tower_info_container.get_global_rect().has_point(event.global_position):
				close_list()
	if event.is_action_pressed("ui_cancel"):
		close_list()
		
func close_list() -> void:
	tower_info_container.hide()

extends Control
class_name ExpandableUI

@onready var vbox_container: VBoxContainer = $VBoxContainer
@onready var primary_button: Button = $VBoxContainer/PrimaryButton
@onready var expandable_list: VBoxContainer = $VBoxContainer/ExpandableList

@export var building_manager: BuildingManager
@export var tower_resources: Array[TowerResource] = []

var is_expanded: bool = false
var original_size: Vector2

func _ready() -> void:
	primary_button.text = "Towers"
	primary_button.pressed.connect(_on_primary_button_pressed)
	expandable_list.hide()
	
	# Store original size
	original_size = size
	
	# Set up tower buttons
	setup_tower_buttons()
	
	# Ensure proper sizing
	custom_minimum_size = Vector2(150, 50)

func setup_tower_buttons() -> void:
	# Clear existing buttons
	for child in expandable_list.get_children():
		child.queue_free()
	
	# Create buttons for each tower resource
	for resource in tower_resources:
		var button = Button.new()
		button.text = "%s ($%d)" % [resource.display_name, resource.cost]
		button.custom_minimum_size = Vector2(140, 35)
		
		# Set icon if available
		if resource.icon:
			button.icon = resource.icon
		
		button.pressed.connect(_on_tower_button_pressed.bind(resource))
		expandable_list.add_child(button)

func _on_primary_button_pressed() -> void:
	is_expanded = !is_expanded
	
	if is_expanded:
		expand_list()
	else:
		collapse_list()

func expand_list() -> void:
	expandable_list.show()
	
	# Create smooth expansion animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Calculate target size
	var target_height = primary_button.size.y + expandable_list.get_combined_minimum_size().y + 10
	var target_size = Vector2(original_size.x, target_height)
	
	# Animate size change
	tween.tween_property(self, "size", target_size, 0.3)
	
	# Update button text
	primary_button.text = "Towers ▲"

func collapse_list() -> void:
	# Create smooth collapse animation
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_BACK)
	
	# Animate size change back to original
	tween.tween_property(self, "size", original_size, 0.3)
	
	# Hide list after animation
	tween.tween_callback(expandable_list.hide)
	
	# Update button text
	primary_button.text = "Towers ▼"

func _on_tower_button_pressed(resource: TowerResource) -> void:
	if building_manager:
		building_manager.enter_build_mode_with(resource)
	
	# Collapse the list after selection
	is_expanded = false
	collapse_list()

func add_tower_resource(resource: TowerResource) -> void:
	if not tower_resources.has(resource):
		tower_resources.append(resource)
		setup_tower_buttons()

func remove_tower_resource(resource: TowerResource) -> void:
	tower_resources.erase(resource)
	setup_tower_buttons()

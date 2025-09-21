extends Control

@onready var upgrade_button: Button = $PanelContainer/ExpandableInfo/UpgradeButton
@onready var tower_info_container: PanelContainer = $PanelContainer
@onready var display_label: Label = $PanelContainer/ExpandableInfo/DisplayName
@onready var subviewport: SubViewport = $PanelContainer/ExpandableInfo/TowerStats/SubViewportContainer/SubViewport

@export var tower_resources: Array[TowerResource] = []
@export var level_manager: LevelManager  # NEW: Reference to level manager

var is_expanded: bool = false
var original_size: Vector2
var current_tower: Node = null
var current_resource: TowerResource = null
var just_opened := false

func _ready() -> void:
	close_list()
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	
func _on_tower_clicked(tower: Node, resource: TowerResource) -> void:
	current_tower = tower
	current_resource = resource
	expand_list()
	just_opened = true

func expand_list() -> void:
	display_label.text = current_resource.display_name
	tower_info_container.show()
	
	# Update upgrade button with cost info
	update_upgrade_button()
	
	for child in subviewport.get_children():
		child.queue_free()
	var tower_visuals: Node = current_tower.get_node("Visuals")
	var copy = tower_visuals.duplicate(DUPLICATE_SIGNALS)
	copy.position = Vector2(108, 198)
	copy.modulate = Color.WHITE
	# Destroy all tweens the copy may have, before snapshotting. 
	# The "click" tween (turns it green slightly)
	# is getting snapshotted into my viewport :) 
	subviewport.add_child(copy)

func update_upgrade_button() -> void:
	if not current_tower:
		upgrade_button.disabled = true
		upgrade_button.text = "No Tower"
		return
	
	# Get upgrade cost from tower
	var upgrade_cost = get_upgrade_cost()
	
	if upgrade_cost < 0:
		# Tower is max level
		upgrade_button.disabled = true
		upgrade_button.text = "Max Level"
		return
	
	# Check if we can afford it
	var can_afford = true
	if level_manager:
		can_afford = level_manager.can_afford(upgrade_cost)
	
	upgrade_button.disabled = not can_afford
	upgrade_button.text = "Upgrade ($" + str(upgrade_cost) + ")"
	
	# Optional: Change button color/style based on affordability
	if can_afford:
		upgrade_button.modulate = Color.WHITE
	else:
		upgrade_button.modulate = Color(0.7, 0.7, 0.7)  # Dimmed

func get_upgrade_cost() -> int:
	if not current_tower:
		return -1
	
	# Check if tower has upgrade_cost property
	if "upgrade_cost" in current_tower:
		return current_tower.upgrade_cost
	
	# Fallback: check if tower resource has upgrade costs array
	if current_resource and "upgrade_costs" in current_resource:
		var level = current_tower.upgrade_level if "upgrade_level" in current_tower else 0
		if level < current_resource.upgrade_costs.size():
			return current_resource.upgrade_costs[level]
	
	# Default fallback cost based on level
	var level = current_tower.upgrade_level if "upgrade_level" in current_tower else 0
	var base_cost = current_resource.cost if current_resource else 100
	return base_cost + (level * 50)  # Each upgrade costs base + 50 per level

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
	
func _on_upgrade_button_pressed():
	if not current_tower or not level_manager:
		return
	
	var upgrade_cost = get_upgrade_cost()
	
	if upgrade_cost < 0:
		print("Tower is already at max level!")
		return
	
	# Check affordability and spend money
	if level_manager.spend_money(upgrade_cost):
		current_tower.upgrade()
		# Update the button after upgrade (cost may have changed)
		update_upgrade_button()
		print("Tower upgraded for $", upgrade_cost)
	else:
		print("Cannot afford upgrade: $", upgrade_cost, " (have $", level_manager.current_money, ")")

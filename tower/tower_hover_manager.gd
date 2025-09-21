# TowerHoverManager.gd
# Add this as an Autoload singleton in Project Settings
extends Node

var currently_hovered_towers: Array[Node] = []
var active_hover: Node = null

func register_tower(tower: Node):
	"""Call this when a tower is spawned"""
	var area = tower.get_node("MouseHitBox") # adjust path as needed
	if area:
		area.mouse_entered.connect(_on_tower_hovered.bind(tower))
		area.mouse_exited.connect(_on_tower_unhovered.bind(tower))
		area.tower_clicked.connect(_on_tower_clicked)  # No bind here

func unregister_tower(tower: Node):
	"""Call this when a tower is destroyed"""
	currently_hovered_towers.erase(tower)
	if active_hover == tower:
		active_hover = null
		_update_active_hover()

func _on_tower_hovered(tower: Node):
	if not currently_hovered_towers.has(tower):
		currently_hovered_towers.append(tower)
		_update_active_hover()

func _on_tower_unhovered(tower: Node):
	currently_hovered_towers.erase(tower)
	_update_active_hover()
	
func _on_tower_clicked(tower: Node):
	tower.click()

func _update_active_hover():
	var new_hover = null
	if currently_hovered_towers.size() > 0:
		# Sort by Y position (frontmost first)
		currently_hovered_towers.sort_custom(func(a, b): return a.global_position.y > b.global_position.y)
		new_hover = currently_hovered_towers[0]
	
	if new_hover != active_hover:
		if active_hover and is_instance_valid(active_hover):
			active_hover.set_hovered(false)
		active_hover = new_hover
		if active_hover and is_instance_valid(active_hover):
			active_hover.set_hovered(true)

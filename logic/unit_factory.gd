extends Node
class_name UnitFactory

# -------------------------
# Configuration
# -------------------------
@export var spawn_point: Marker2D
@export var target_points: Array[Marker2D] = []
@export var units_container: Node2D
@export var level_manager: LevelManager

# -------------------------
# Spawning State
# -------------------------
var spawn_queue: Array[UnitConfig] = []
var spawn_timer: Timer
var current_spawn_delay: float = 1.0
var is_spawning: bool = false

# -------------------------
# Signals
# -------------------------
signal spawn_queue_empty()
signal unit_spawned(unit: UnitLogic)

# -------------------------
# Lifecycle
# -------------------------
func _ready() -> void:
	print("UnitFactory ready")
	
	# Validate configuration
	if not spawn_point:
		push_error("UnitFactory: No spawn point assigned!")
	if target_points.is_empty():
		push_error("UnitFactory: No target points assigned!")
	
	# Create and configure spawn timer
	spawn_timer = Timer.new()
	spawn_timer.wait_time = current_spawn_delay
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

# -------------------------
# Public API
# -------------------------
func queue_units(unit_configs: Array[UnitConfig], spawn_delay: float = 1.0) -> void:
	"""Add units to the spawn queue with specified delay between spawns"""
	spawn_queue.append_array(unit_configs)
	current_spawn_delay = spawn_delay
	spawn_timer.wait_time = current_spawn_delay
	
	if not is_spawning and not spawn_queue.is_empty():
		start_spawning()

func start_spawning() -> void:
	"""Begin spawning units from the queue"""
	if spawn_queue.is_empty():
		return
		
	is_spawning = true
	spawn_timer.start()

func stop_spawning() -> void:
	"""Stop spawning (but keep queue intact)"""
	is_spawning = false
	spawn_timer.stop()

func clear_queue() -> void:
	"""Clear all queued units"""
	spawn_queue.clear()
	stop_spawning()

func is_queue_empty() -> bool:
	"""Check if spawn queue is empty"""
	return spawn_queue.is_empty()

# -------------------------
# Target Selection
# -------------------------
func get_random_target() -> Marker2D:
	"""Returns a random target point from the list"""
	if target_points.is_empty():
		push_error("UnitFactory: No target points available!")
		return null
	
	return target_points[randi() % target_points.size()]

# -------------------------
# Spawning Logic
# -------------------------
func _on_spawn_timer_timeout() -> void:
	if spawn_queue.is_empty():
		finish_spawning()
		return
	
	spawn_next_unit()

func spawn_next_unit() -> void:
	if spawn_queue.is_empty():
		return
		
	var config = spawn_queue.pop_front()
	var unit = create_unit(config)
	
	if unit:
		emit_signal("unit_spawned", unit)

func create_unit(config: UnitConfig) -> UnitLogic:
	"""Create and configure a unit from a UnitConfig"""
	if not config or not config.scene:
		push_error("UnitFactory: Invalid config or missing scene")
		return null
	
	# Instantiate the unit
	var unit = config.scene.instantiate()
	
	if not units_container:
		push_error("UnitFactory: No units container assigned!")
		return null
	
	# Get random target point
	var target_point = get_random_target()
	if not target_point:
		push_error("UnitFactory: Could not get valid target point")
		return null
	
	# Add to scene
	units_container.add_child(unit)
	
	# Set spawn position
	unit.global_position = spawn_point.global_position if spawn_point else Vector2.ZERO
	
	# Setup the unit with random target
	var target_pos = target_point.global_position
	unit.setup_enemy(target_pos, config)
	unit.add_to_group("units")
	
	# Connect to level manager for economy/life management
	if level_manager:
		level_manager.register_unit(unit)
	
	print("Spawned unit: %s targeting %s" % [config.unit_name, target_point.name])
	return unit

func finish_spawning() -> void:
	"""Called when spawn queue is empty"""
	is_spawning = false
	spawn_timer.stop()
	emit_signal("spawn_queue_empty")
	print("UnitFactory: Spawn queue empty")

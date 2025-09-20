extends CharacterBody2D
class_name EnemyLogic

signal spawned
signal took_damage
signal died
signal status_applied(status_type)  # Fixed: specific parameter name

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var speed := 100.0
var health := 2
var can_move: bool = false

enum StatusType { SLOW, POISON, REVERSE, BURN }
var active_statuses: Dictionary = {}  # StatusType -> {strength: float, duration: float, timer: Timer}
var base_speed: float = 100.0  # Cache original for resets

## STATUS EFFECT FIELDS ##
var effective_speed: float = 100.0
var is_reversed: bool = false
var status_tick_timer: float = 0.0
var tick_rate: float = 1.0  # Seconds per tick for DoT

func _ready() -> void:
	# Tell visuals to run spawn effect
	base_speed = speed  
	effective_speed = base_speed
	emit_signal("spawned")

func setup_navigation(target_position: Vector2) -> void:
	nav_agent.target_position = target_position

func _process(delta: float) -> void:
	if active_statuses.is_empty():
		return  # Early out if no statuses
	
	status_tick_timer += delta
	if status_tick_timer >= tick_rate:
		status_tick_timer -= tick_rate  # Accumulate for smooth ticks
		tick_statuses()

func _physics_process(delta: float) -> void:  # Fixed: underscore instead of asterisks
	if not can_move:
		return
	if nav_agent.is_navigation_finished():
		queue_free()
		return
	
	var next_path_position = nav_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	
	# Apply reverse
	if is_reversed:
		direction = -direction
	
	velocity = direction * effective_speed
	move_and_slide()

func take_damage(dmg: int) -> void:
	health -= dmg
	emit_signal("took_damage")
	if health <= 0:
		can_move = false
		# Clean up statuses on death
		for type in active_statuses.keys():  # Fixed: use .keys() for safety
			remove_status(type)
		emit_signal("died")

func apply_status(type: StatusType, strength: float, duration: float) -> void:
	if type not in StatusType.values():
		push_error("Invalid status type: " + str(type))
		return
	
	if active_statuses.has(type):
		# Refresh duration (simple stacking)
		var data = active_statuses[type]
		data.duration = duration
		data.strength = max(data.strength, strength)  # Take stronger effect
		data.timer.stop()
		data.timer.start(duration)
	else:
		# New status
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(func(): remove_status(type))
		timer.start()
		
		active_statuses[type] = {
			strength = strength, 
			duration = duration, 
			timer = timer
		}
		
		# Emit signal to visuals with the correct status type
		status_applied.emit(type)  # Fixed: emit the actual status type, not the enum class
	
	update_status_effects()

func remove_status(type: StatusType) -> void:
	if active_statuses.has(type):
		active_statuses[type].timer.queue_free()
		active_statuses.erase(type)
		update_status_effects()

func update_status_effects() -> void:
	
	# Reset to base values
	effective_speed = base_speed
	is_reversed = false
	
	# Apply all active status effects
	for type in active_statuses.keys():
		match type:
			StatusType.SLOW:
				effective_speed *= (1.0 - active_statuses[type].strength)
			StatusType.REVERSE:
				print("Applying REVERSE effect")
				is_reversed = true
			# Poison and Burn don't modify movement, they just tick damage

func tick_statuses() -> void:
	var types_to_check = active_statuses.keys()  # Create a copy to avoid modification during iteration
	for type in types_to_check:
		if not active_statuses.has(type):  # Safety check
			continue
			
		print("Ticking status: ", StatusType.keys()[type])
		match type:
			StatusType.POISON:
				var damage = int(active_statuses[type].strength)
				print("Poison tick damage: ", damage)
				take_damage(damage)
			StatusType.BURN:
				var damage = int(active_statuses[type].strength)
				print("Burn tick damage: ", damage)
				take_damage(damage)

# Called by visuals after spawn tween is done
func allow_movement() -> void:
	can_move = true

# Debug function to check current status
func get_status_info() -> String:
	var info = "Active Statuses: "
	for type in active_statuses.keys():
		info += StatusType.keys()[type] + "(" + str(active_statuses[type].strength) + ") "
	info += "\nEffective Speed: " + str(effective_speed)
	info += "\nIs Reversed: " + str(is_reversed)
	return info

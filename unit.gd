extends CharacterBody2D
class_name EnemyLogic

signal spawned
signal took_damage
signal died
signal status_applied(StatusType)

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
		
func _physics_process(delta: float) -> void:
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
		for type in active_statuses:
			remove_status(type)
		emit_signal("died")
		
func apply_status(type: StatusType, strength: float, duration: float) -> void:
	if type not in StatusType.values():
		push_error("Invalid status type: " + str(type))
		return
	print("status debug #apply_status")
	if active_statuses.has(type):
		print("status debug #active_statuses.has(type)")
		# Refresh duration (simple stacking)
		var data = active_statuses[type]
		data.duration = duration
		data.timer.start(duration)
	else:
		print("status debug #active_statuses.has NOT (type)")
		print(type)
		# New status
		var timer = Timer.new()
		add_child(timer)
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(func(): remove_status(type))
		timer.start()
		
		active_statuses[type] = {strength = strength, duration = duration, timer = timer}
		update_status_effects()
		status_applied.emit(StatusType)  
		
func remove_status(type: StatusType) -> void:
	if active_statuses.has(type):
		print("status debug #remove_status")
		active_statuses[type].timer.queue_free()
		active_statuses.erase(type)
		update_status_effects()

func update_status_effects() -> void:
	print("status debug #update_status_effects")
	# Recalc speed
	effective_speed = base_speed
	if active_statuses.has(StatusType.SLOW):
		print("status debug #StatusType.SLOW")
		effective_speed *= (1.0 - active_statuses[StatusType.SLOW].strength)
	
	# Recalc reverse
	is_reversed = active_statuses.has(StatusType.REVERSE)
	
	# No immediate effects for poison/burn—they tick

func tick_statuses() -> void:
	for type in active_statuses.keys():
		print("status debug #tick_statuses")
		match type:
			StatusType.POISON:
				take_damage(active_statuses[type].strength)  # Assuming int, cast if needed
			StatusType.BURN:
				take_damage(active_statuses[type].strength)

# Called by visuals after spawn tween is done
func allow_movement() -> void:
	can_move = true

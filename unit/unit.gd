extends CharacterBody2D
class_name UnitLogic
signal spawned
signal took_damage
signal died(unit: UnitLogic)
signal reached_target(unit: UnitLogic)
signal status_applied(status_type)

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

# Make these virtual/overridable by using @export or making them protected
var speed: float 
var health 
var unit_name 
var animation
var value: int  
var unit_config : UnitConfig

var can_move: bool = false
var move_timer = Timer.new()


enum StatusType { SLOW, POISON, REVERSE, BURN }
var active_statuses: Dictionary = {}  # StatusType -> {strength: float, duration: float, timer: Timer}

## STATUS EFFECT FIELDS ##
var effective_speed: float 
var is_reversed: bool = false
var status_tick_timer: float = 0.0
var tick_rate: float = 1.0  # Seconds per tick for DoT


# Virtual method that can be overridden
func _ready() -> void:
	add_child(move_timer)
	var visuals = $UnitVisuals
	visuals.set_unit_logic(self)
	move_timer.wait_time = 1.0 
	move_timer.one_shot = true
	move_timer.timeout.connect(_on_move_timer_timeout)
	emit_signal("spawned")

func _on_move_timer_timeout():
	can_move=true

func setup_enemy(target_position: Vector2, new_unit_config: UnitConfig) -> void:
	unit_config = new_unit_config
	speed = unit_config.base_speed
	effective_speed = speed
	health = unit_config.base_health
	animation = unit_config.AnimationType
	unit_name = unit_config.unit_name
	value = unit_config.value
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
		on_reached_destination()
		return
	
	# Get basic pathfinding direction
	var next_path_position = nav_agent.get_next_path_position()
	var desired_direction = (next_path_position - global_position).normalized()
	
	
	# Apply reverse status effect
	if is_reversed:
		desired_direction = -desired_direction
	
	# Move
	velocity = desired_direction * effective_speed
	move_and_slide()


# Virtual method for when unit reaches destination
func on_reached_destination() -> void:
	emit_signal("reached_target", self)
	queue_free()

func take_damage(dmg: int) -> void:
	health -= dmg
	emit_signal("took_damage")
	if health <= 0:
		_on_death()

# Protected death handling - can be extended by subclasses
func _on_death() -> void:
	can_move = false
	# Clean up statuses on death
	for type in active_statuses.keys():
		remove_status(type)
	emit_signal("died", self)

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
		status_applied.emit(type)
	
	update_status_effects()

func remove_status(type: StatusType) -> void:
	if active_statuses.has(type):
		active_statuses[type].timer.queue_free()
		active_statuses.erase(type)
		update_status_effects()

# Virtual method that can be extended for special status behaviors
func update_status_effects() -> void:
	# Reset to base values
	effective_speed = speed
	is_reversed = false
	
	# Apply all active status effects
	for type in active_statuses.keys():
		_apply_status_effect(type)

# Protected method for applying individual status effects
func _apply_status_effect(type: StatusType) -> void:
	match type:
		StatusType.SLOW:
			effective_speed *= (1.0 - active_statuses[type].strength)
		StatusType.REVERSE:
			is_reversed = true
		# Poison and Burn don't modify movement, they just tick damage

func tick_statuses() -> void:
	var types_to_check = active_statuses.keys()  # Create a copy to avoid modification during iteration
	for type in types_to_check:
		if not active_statuses.has(type):  # Safety check
			continue
			
		_tick_status_effect(type)

# Protected method for individual status ticks
func _tick_status_effect(type: StatusType) -> void:
	match type:
		StatusType.POISON:
			var damage = int(active_statuses[type].strength)
			print("Poison tick damage: ", damage)
			take_damage(damage)
		StatusType.BURN:
			var damage = int(active_statuses[type].strength)
			take_damage(damage)

# Called by visuals after spawn tween is done
func allow_movement() -> void:
	can_move = true

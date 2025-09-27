extends Node
class_name WaveManager

# -------------------------
# Configuration
# -------------------------
@export var unit_factory: UnitFactory
@export var level_manager: LevelManager
@export var available_units: Array[UnitConfig] = []
@export var base_units_per_wave: int = 10
@export var difficulty: int = 1  # Corresponds to our level/stage (1-5)

# Wave timing
@export var time_between_waves: float = 5.0
@export var base_spawn_delay: float = 1.0  # Base time between unit spawns
@export var check_interval: float = 1.0   # How often to check if wave is complete

# -------------------------
# Wave State
# -------------------------
var current_wave: int = 0
var max_waves: int = 10
var is_wave_active: bool = false
var is_checking_completion: bool = false

# Timers
var wave_delay_timer: Timer
var completion_check_timer: Timer

# -------------------------
# Signals
# -------------------------
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()

# -------------------------
# Lifecycle
# -------------------------
func _ready() -> void:
	setup_timers()
	max_waves = level_manager.max_waves if level_manager else 10

func setup_timers() -> void:
	# Timer for delay between waves
	wave_delay_timer = Timer.new()
	wave_delay_timer.wait_time = time_between_waves
	wave_delay_timer.one_shot = true
	wave_delay_timer.timeout.connect(_on_wave_delay_timeout)
	add_child(wave_delay_timer)
	
	# Timer to check if wave is complete
	completion_check_timer = Timer.new()
	completion_check_timer.wait_time = check_interval
	completion_check_timer.one_shot = false
	completion_check_timer.timeout.connect(_check_wave_completion)
	add_child(completion_check_timer)
	
	# Connect to factory signals
	if unit_factory:
		unit_factory.spawn_queue_empty.connect(_on_spawn_queue_empty)

# -------------------------
# Public API
# -------------------------
func start_next_wave() -> void:
	if current_wave >= max_waves:
		print("All waves completed!")
		emit_signal("all_waves_completed")
		return
	
	current_wave += 1
	is_wave_active = true
	
	if level_manager:
		level_manager.start_next_wave()
	
	emit_signal("wave_started", current_wave)
	spawn_wave()

func start_wave_with_delay() -> void:
	if not wave_delay_timer.is_stopped():
		return
		
	wave_delay_timer.start()

# -------------------------
# Wave Generation & Spawning
# -------------------------
func spawn_wave() -> void:
	"""Generate and spawn the current wave"""
	if available_units.is_empty():
		push_error("WaveManager: No available units configured!")
		return
	
	var wave_units = generate_wave_units()
	var spawn_delay = calculate_spawn_delay()
	
	print("Starting wave ", current_wave, " with ", wave_units.size(), " units (spawn delay: ", spawn_delay, "s)")
	
	unit_factory.queue_units(wave_units, spawn_delay)
	start_completion_checking()

func generate_wave_units() -> Array[UnitConfig]:
	"""Generate random units for the current wave"""
	var units: Array[UnitConfig] = []
	var unit_count = calculate_wave_size()
	
	for i in range(unit_count):
		var random_unit = available_units[randi() % available_units.size()]
		units.append(random_unit)
	
	return units

func calculate_wave_size() -> int:
	"""Calculate how many units should be in this wave"""
	# More units per wave as difficulty increases
	return base_units_per_wave + (current_wave * difficulty)

func calculate_spawn_delay() -> float:
	"""Calculate delay between unit spawns based on difficulty"""
	# Base delay minus difficulty scaling (max difficulty 5 removes 1 second)
	var delay = base_spawn_delay - (difficulty - 1) * 0.2
	return max(delay, 0.1)  # Minimum 0.1 second delay

# -------------------------
# Wave Completion
# -------------------------
func start_completion_checking() -> void:
	"""Start checking if the wave is complete"""
	if is_checking_completion:
		return
		
	is_checking_completion = true
	completion_check_timer.start()
	print("Started checking wave ", current_wave, " completion...")

func _check_wave_completion() -> void:
	"""Check if current wave is complete (no units left spawning or alive)"""
	if not is_wave_active:
		return
	
	# Check if factory is still spawning
	if unit_factory and not unit_factory.is_queue_empty():
		return
	
	# Check if any units are still alive
	var remaining_units = get_tree().get_nodes_in_group("units")
	if remaining_units.size() > 0:
		return
	
	# Wave is complete!
	complete_current_wave()

func complete_current_wave() -> void:
	"""Mark current wave as complete"""
	is_wave_active = false
	is_checking_completion = false
	completion_check_timer.stop()
	
	print("Wave ", current_wave, " completed!")
	emit_signal("wave_completed", current_wave)
	
	if level_manager:
		level_manager.complete_wave()
	
	# Check if all waves are done
	if current_wave >= max_waves:
		emit_signal("all_waves_completed")
	else:
		# Start next wave with delay
		start_wave_with_delay()

# -------------------------
# Timer Callbacks
# -------------------------
func _on_wave_delay_timeout() -> void:
	"""Called when it's time to start the next wave"""
	start_next_wave()

func _on_spawn_queue_empty() -> void:
	"""Called when unit factory finishes spawning all units in the wave"""
	print("Wave ", current_wave, " finished spawning all units")
	# Completion checking will handle the rest

# -------------------------
# Utility
# -------------------------
func get_wave_progress() -> Dictionary:
	"""Get current wave progress info"""
	return {
		"current_wave": current_wave,
		"max_waves": max_waves,
		"is_active": is_wave_active,
		"units_remaining": get_tree().get_nodes_in_group("units").size(),
		"difficulty": difficulty,
		"current_spawn_delay": calculate_spawn_delay()
	}

func set_difficulty(new_difficulty: int) -> void:
	"""Update difficulty level (1-5)"""
	difficulty = clamp(new_difficulty, 1, 5)
	print("Difficulty set to: ", difficulty)

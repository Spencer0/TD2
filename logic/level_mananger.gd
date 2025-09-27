extends Node
class_name LevelManager

# -------------------------
# Unit Event Handlers
# -------------------------
func _on_unit_died(unit: UnitLogic) -> void:
	var money_reward = unit.value if unit else 10
	add_money(money_reward)
	print("Unit killed! Gained $", money_reward)

func _on_unit_reached_target(unit: UnitLogic) -> void:
	lose_life()
	print("Enemy reached target! Lost a life")

# -------------------------
# Public API for connecting new units
# -------------------------
func register_unit(unit: Node) -> void:
	connect_unit_signals(unit)

# -------------------------
# Signals
# -------------------------
signal stats_updated(money: int, lives: int, current_wave: int)
signal money_spent(amount: int)
signal life_lost()
signal game_over()
signal level_complete()

# -------------------------
# Dependencies
# -------------------------
@export var wave_manager: WaveManager

# -------------------------
# Game State
# -------------------------
@export var starting_money: int = 500
@export var starting_lives: int = 10
@export var max_waves: int = 10

var current_money: int
var current_lives: int
var current_wave: int = 0
var is_level_active: bool = false

# -------------------------
# Lifecycle
# -------------------------
func _ready() -> void:
	current_money = starting_money
	current_lives = starting_lives
	current_wave = 0
	is_level_active = true
	
	# Connect to existing units in scene (if any)
	connect_to_existing_units()
	
	# Connect to wave manager
	if wave_manager:
		print("connection")
		connect_wave_manager_signals()
	
	emit_stats_updated()
	start_first_wave()

# Connect to wave manager signals
func connect_wave_manager_signals() -> void:
	if not wave_manager:
		return
		
	if wave_manager.has_signal("wave_started") and not wave_manager.is_connected("wave_started", Callable(self, "_on_wave_started")):
		wave_manager.connect("wave_started", Callable(self, "_on_wave_started"))
	if wave_manager.has_signal("wave_completed") and not wave_manager.is_connected("wave_completed", Callable(self, "_on_wave_completed")):
		wave_manager.connect("wave_completed", Callable(self, "_on_wave_completed"))
	if wave_manager.has_signal("all_waves_completed") and not wave_manager.is_connected("all_waves_completed", Callable(self, "_on_all_waves_completed")):
		wave_manager.connect("all_waves_completed", Callable(self, "_on_all_waves_completed"))

# Connect to units that might already exist in the scene
func connect_to_existing_units() -> void:
	var units = get_tree().get_nodes_in_group("units")
	for unit in units:
		connect_unit_signals(unit)

# Connect signals for a specific unit
func connect_unit_signals(unit: Node) -> void:
	if unit.has_signal("died") and not unit.is_connected("died", Callable(self, "_on_unit_died")):
		unit.connect("died", Callable(self, "_on_unit_died"))
	if unit.has_signal("reached_target") and not unit.is_connected("reached_target", Callable(self, "_on_unit_reached_target")):
		unit.connect("reached_target", Callable(self, "_on_unit_reached_target"))

# -------------------------
# Money Management
# -------------------------
func can_afford(cost: int) -> bool:
	return current_money >= cost

func spend_money(amount: int) -> bool:
	if not can_afford(amount):
		return false
	
	current_money -= amount
	emit_signal("money_spent", amount)
	emit_stats_updated()
	return true

func add_money(amount: int) -> void:
	current_money += amount
	emit_stats_updated()

# -------------------------
# Life Management
# -------------------------
func lose_life() -> void:
	current_lives -= 1
	emit_signal("life_lost")
	emit_stats_updated()
	
	if current_lives <= 0:
		get_tree().change_scene_to_file("res://menus/StageSelection.tscn")
		emit_signal("game_over")

# -------------------------
# Wave Management
# -------------------------
func start_next_wave() -> void:
	current_wave += 1
	emit_stats_updated()

func complete_wave() -> void:
	# Award bonus money for completing wave
	var wave_bonus = 50 + (current_wave * 10)
	add_money(wave_bonus)
	print("Wave completed! Bonus: $", wave_bonus)

func start_first_wave() -> void:
	"""Public method to start the first wave"""
	if wave_manager and current_wave == 0:
		wave_manager.call_deferred("start_next_wave")

# -------------------------
# Wave Manager Event Handlers  
# -------------------------
func _on_wave_started(wave_number: int) -> void:
	print("Level Manager: Wave ", wave_number, " started")
	# current_wave is updated by start_next_wave() which WaveManager calls

func _on_wave_completed(wave_number: int) -> void:
	print("Level Manager: Wave ", wave_number, " completed")
	# complete_wave() is called by WaveManager which awards bonus

func _on_all_waves_completed() -> void:
	print("Level Manager: All waves completed!")
	is_level_active = false
	emit_signal("level_complete")

# -------------------------
# Helper
# -------------------------
func emit_stats_updated() -> void:
	emit_signal("stats_updated", current_money, current_lives, current_wave)

extends Node
class_name LevelManager


# -------------------------
# Signals
# -------------------------
signal stats_updated(money: int, lives: int, current_wave: int)
signal money_spent(amount: int)
signal life_lost()
signal game_over()
signal level_complete()

# -------------------------
# Game State
# -------------------------
@export var starting_money: int = 500
@export var starting_lives: int = 10
@export var max_waves: int = 10

var current_money: int
var current_lives: int
var current_wave: int = 0


# -------------------------
# Lifecycle
# -------------------------
func _ready() -> void:
	current_money = starting_money
	current_lives = starting_lives
	current_wave = 0
	
	# Connect to existing units in scene (if any)
	connect_to_existing_units()
	
	emit_stats_updated()

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
# Unit Event Handlers
# -------------------------
func _on_unit_died(unit: UnitLogic) -> void:
	var money_reward = unit.value if unit else 10
	add_money(money_reward)

func _on_unit_reached_target(unit: UnitLogic) -> void:
	lose_life()
	print("Enemy reached target! Lost a life")

# -------------------------
# Public API for connecting new units
# -------------------------
func register_unit(unit: Node) -> void:
	connect_unit_signals(unit)

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
		emit_signal("game_over")

# -------------------------
# Wave Management
# -------------------------
func start_next_wave() -> void:
	current_wave += 1
	emit_stats_updated()

func complete_wave() -> void:
	if current_wave >= max_waves:
		emit_signal("level_complete")
	else:
		# Could add delay here or let WaveManager handle timing
		pass

# -------------------------
# Helper
# -------------------------
func emit_stats_updated() -> void:
	emit_signal("stats_updated", current_money, current_lives, current_wave)

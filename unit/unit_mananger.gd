extends Node2D
class_name EnemySpawner

@export var spawn_timer: Timer
@export var target_point: Marker2D
@export var spawn_point: Marker2D
@export var units: Node2D
@export var level_manager: LevelManager 
# List of configs to spawn from
@export var enemy_configs: Array[UnitConfig] = []

var _spawn_index: int = 0

func _ready() -> void:
	if enemy_configs.is_empty():
		push_warning("EnemySpawner has no configs assigned!")
	spawn_timer.timeout.connect(_on_spawn_timeout)

func _on_spawn_timeout() -> void:
	spawn_enemy()

func spawn_enemy() -> void:
	if enemy_configs.is_empty():
		return
	# Pick config based on round-robin
	var config: UnitConfig = enemy_configs[_spawn_index]
	_spawn_index = (_spawn_index + 1) % enemy_configs.size()
	var enemy_scene: PackedScene = config.scene
	var enemy = enemy_scene.instantiate()
	units.add_child(enemy)
	enemy.global_position = spawn_point.global_position
	enemy.setup_enemy(target_point.global_position, config)
	level_manager.register_unit(enemy)
	enemy.add_to_group("units")

extends Node2D


@export var spawn_timer: Timer
@export var target_point: Marker2D
@export var spawn_point: Marker2D
@export var units: Node2D
@export var enemy_scene := preload("res://unit.tscn")

func _ready() -> void:
	spawn_timer.timeout.connect(func(): spawn_enemy())

func spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	units.add_child(enemy)
	enemy.global_position = spawn_point.global_position
	enemy.add_to_group("enemies")
	enemy.call_deferred("setup_navigation", target_point.global_position)

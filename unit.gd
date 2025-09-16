extends CharacterBody2D
class_name EnemyLogic

signal spawned
signal took_damage
signal died

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var speed := 100.0
var health := 2
var can_move: bool = false

func _ready() -> void:
	# Tell visuals to run spawn effect
	emit_signal("spawned")

func setup_navigation(target_position: Vector2) -> void:
	nav_agent.target_position = target_position

func _physics_process(delta: float) -> void:
	if not can_move:
		return

	if nav_agent.is_navigation_finished():
		queue_free()
		return

	var next_path_position = nav_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func take_damage(damage: int) -> void:
	health -= damage
	emit_signal("took_damage")
	if health <= 0:
		can_move = false
		emit_signal("died")

# Called by visuals after spawn tween is done
func allow_movement() -> void:
	can_move = true

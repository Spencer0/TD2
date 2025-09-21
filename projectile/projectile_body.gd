extends CharacterBody2D
class_name Projectile

@onready var hitbox: Area2D = $Area2D
@onready var visuals: ProjectileVisuals = $ProjectileVisuals

var target: CharacterBody2D = null
var speed := 300.0
var damage := 1.0
var lifetime := 3.0

var direction: Vector2
var time_alive := 0.0

func _ready() -> void:
	hitbox.connect("body_entered", Callable(self, "_on_hit_enemy"))
	visuals.hit_finished.connect(Callable(self, "_on_hit_finished"))

func setup(new_target: CharacterBody2D, new_speed: float, new_damage: float) -> void:
	target = new_target
	speed = new_speed
	damage = new_damage
	direction = (target.global_position - global_position).normalized() if target else Vector2.RIGHT
	velocity = direction * speed

func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive > lifetime:
		queue_free()
		return

	move_and_slide()

	if direction != Vector2.ZERO:
		visuals.update_rotation(velocity.angle())

func _on_hit_enemy(body: Node) -> void:
	if body.is_in_group("units"):
		body.take_damage(damage)
		## Add: body.add_status(status: String, strength: Int, duration :Timer) 
		
		visuals.play_hit_effect(global_position)
		
		set_physics_process(false)
		velocity = Vector2.ZERO
		hitbox.set_deferred("monitoring", false) # Prevent double hit

func _on_hit_finished() -> void:
	# Free projectile after hit effect completes
	queue_free()

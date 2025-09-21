extends Resource
class_name UnitConfig

@export var unit_name: String = "Basic Enemy"
@export var base_health: int = 20
@export var base_speed: float = 100.0
@export var value: int = 10
@export var scene: PackedScene 

## Idle animation params
@export var animation_type: AnimationType = AnimationType.BOB
@export var rock_interval: float = 1.5  # Time between rock animations
@export var rock_angle: float = 15.0  # Degrees to rock

enum AnimationType {
	BOB,      # Original up/down motion
	ROCK,     # Side to side rocking
	CUSTOM    # Override in subclass
}

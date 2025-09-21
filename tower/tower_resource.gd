extends Resource
class_name TowerResource

@export var display_name: String
@export var scene: PackedScene # How the sprites are arranged, where custom scripts come into play etc
@export var size: int = 1   # how many tiles wide/high this tower is
@export var cost: int = 100
@export var icon: Texture2D

extends Node2D
@onready var animated_sprite_2d = $"BG 1/AnimatedSprite2D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite_2d.play("Flames")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

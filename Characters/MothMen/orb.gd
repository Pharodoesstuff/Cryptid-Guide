extends Area2D

@export var speed: float = 200.0
var direction: Vector2 = Vector2.DOWN
var closet_ref: Node2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if closet_ref and closet_ref.has_method("add_orb_time_penalty"):
			closet_ref.add_orb_time_penalty()
		queue_free()

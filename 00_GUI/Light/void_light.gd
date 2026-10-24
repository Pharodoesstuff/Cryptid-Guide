extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	visible = false # Start hidden by default

# Called automatically whenever this node leaves the scene tree
func _exit_tree() -> void:
	deactivate()

func activate(_duration: float = 0.0) -> void:
	#EventBus.player_freeze_requested.emit(true)
	visible = true
	animation_player.play("Enclose")
	await animation_player.animation_finished
	EventBus.voidlight_finished.emit()
	#EventBus.player_freeze_requested.emit(false)
	

func deactivate() -> void:
	visible = false
	if is_instance_valid(animation_player):
		animation_player.stop()

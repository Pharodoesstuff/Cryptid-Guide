extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	if PlayerManager.player_spawned == false:
		PlayerManager.set_player_position( global_position )
		PlayerManager.player_spawned = true

func _on_level_loaded() -> void:
	PlayerManager.set_player_position(global_position)

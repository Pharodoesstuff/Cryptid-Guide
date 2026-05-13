extends Sprite2D
@onready var player = get_tree().get_first_node_in_group("player")

func _process( delta ):
	if player:
		material.set("shader_parameter/player_position", player.global_position)

class_name Level extends Node2D

func _ready() -> void:
	self.y_sort_enabled = true
	PlayerManager.set_as_parent(self)
	LevelManager.level_load_started.connect(_free_level)
	
	# Wait for LevelManager to signal that the level is ready
	await LevelManager.level_loaded
	_position_player()

func _free_level() -> void:
	PlayerManager.unparent_player(self)
	queue_free()

func _position_player() -> void:
	var player: Player = PlayerManager.player
	if not is_instance_valid(player):
		return

	var target_name: String = LevelManager.target_transition
	
	# 1. Look for a node matching the target transition name (e.g. "Void")
	if target_name != "":
		var target_node: Node2D = find_child(target_name, true, false) as Node2D
		if is_instance_valid(target_node):
			# Add a positional offset so the player doesn't spawn inside collision or immediately re-trigger the area
			var offset: Vector2 = LevelManager.position_offset
			if offset == Vector2.ZERO:
				offset = Vector2(0, 24) # Default offset down from the entry point
			player.global_position = target_node.global_position + offset
			return

	# 2. Fallback to PlayerSpawn node if no target transition was specified or found
	var spawn_node: Node2D = find_child("PlayerSpawn", true, false) as Node2D
	if is_instance_valid(spawn_node):
		player.global_position = spawn_node.global_position

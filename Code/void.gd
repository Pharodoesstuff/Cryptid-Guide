extends "res://Code/Level Code/level.gd"

func _ready() -> void:
	# 1. Call parent level.gd _ready() so PlayerManager.set_as_parent(self) executes
	super._ready()
	
	# Wait for LevelManager to finish changing scene and unpause the tree
	await LevelManager.level_loaded
	
	# Reference player directly from PlayerManager singleton
	var player: Player = PlayerManager.player
	
	# 2. Position player if target_transition is empty or matches "Cabin"
	if is_instance_valid(player):
		if LevelManager.target_transition == "" or LevelManager.target_transition == "Cabin":
			player.global_position = Vector2(100, 100) # Set to a valid coordinate in your Void scene
	
	# Activate light component
	if is_instance_valid(player) and player.has_node("VoidLight"):
		player.get_node("VoidLight").activate(8.0)

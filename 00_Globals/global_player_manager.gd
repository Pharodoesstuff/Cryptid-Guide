extends Node

const PLAYER = preload("res://Characters/Main Character/Main Character.tscn")

var player : Player
var player_spawned : bool = false
var is_loading_save: bool = false
var used_transitions: Array[String] = []

func _ready() -> void:
	add_player_instance()

func add_player_instance() -> void:
	player = PLAYER.instantiate()
	add_child ( player )
	pass
	
func set_health( hp: int, max_hp: int) -> void:
	player.max_hp = max_hp
	player.hp = hp
	player.update_hp( 0 )

func set_player_position(_new_pos : Vector2) -> void:
	if not is_instance_valid(player):
		add_player_instance()
	player.global_position = _new_pos

# Inside global_player_manager.gd
func set_as_parent(_p : Node2D) -> void:
	if not is_instance_valid(player):
		add_player_instance()
	
	var target_player := player # Hold reference locally
	if target_player.get_parent():
		target_player.get_parent().remove_child(target_player)
	_p.add_child(target_player)
	
func unparent_player(_p : Node2D) -> void:
	if is_instance_valid(player) and player.get_parent() == _p:
		_p.remove_child(player)
	
func load_save_file(save_data: Dictionary) -> void:
	PlayerManager.is_loading_save = true
	
	# Load target level and set player position from save data...
	# e.g., PlayerManager.set_player_position(save_data["player_position"])
	
	await LevelManager.level_loaded
	PlayerManager.is_loading_save = false

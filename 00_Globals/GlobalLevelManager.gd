extends Node

signal level_load_started
signal level_loaded
signal TileMapBoundsChanged( bounds : Array[ Vector2 ] )

var current_tilemap_bounds : Array[ Vector2 ]
var target_transition : String
var position_offset : Vector2

func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()
	
func ChangeTilemapBounds ( bounds : Array [ Vector2 ] ) -> void:
	current_tilemap_bounds = bounds
	TileMapBoundsChanged.emit( bounds )

func load_new_level(
		level_path : String, 
		_target_transition : String,
		_position_offset : Vector2
) -> void:
	get_tree().paused = true
	target_transition = _target_transition
	position_offset = _position_offset
	
	await get_tree().process_frame #lvl transition
	
	level_load_started.emit()
	
	await get_tree().process_frame
	
	# Load resource first so uid:// paths resolve correctly
	var next_scene = load(level_path) as PackedScene
	if is_instance_valid(next_scene):
		get_tree().change_scene_to_packed(next_scene)
	else:
		push_error("Failed to load level path: " + level_path)
	
	await get_tree().process_frame
	
	get_tree().paused = false
	
	await get_tree().process_frame
	
	level_loaded.emit()

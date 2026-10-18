extends Node

const SAVE_PATH = "user://"

signal game_loaded
signal game_saved

var current_save : Dictionary = {
	scene_path = "",
	player = {
		hp = 1,
		max_hp = 1,
		pos_x = 0,
		pos_y = 0
	},
	items = [],
	persistence = [],
	quests = [],
	used_transitions = [] # Added to save file dictionary structure
}

func _ready() -> void:
	_setup_autosave_timer()

func _setup_autosave_timer() -> void:
	var timer := Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = false
	timer.autostart = true
	timer.timeout.connect(autosave_timer)
	add_child(timer)

func save_game() -> void:
	update_player_data()
	var file := FileAccess.open(SAVE_PATH + "Save.sav", FileAccess.WRITE)
	if file:
		var save_json = JSON.stringify(current_save)
		file.store_line(save_json)
		game_saved.emit()
		print("save_game")

func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH + "Save.sav", FileAccess.READ)
	if not file:
		print("Save file not found.")
		return
	var json := JSON.new()
	json.parse(file.get_line())
	var save_dict : Dictionary = json.get_data() as Dictionary
	current_save = save_dict
	
	if current_save.get("scene_path", "").is_empty():
		push_error("save file is missing valid scene")
		return

	# Restore used_transitions BEFORE loading the scene so LvlTrans2._ready() checks valid state
	PlayerManager.used_transitions.clear()
	if "used_transitions" in current_save:
		PlayerManager.used_transitions.assign(current_save["used_transitions"])
	else:
		PlayerManager.used_transitions.clear()

	LevelManager.load_new_level(current_save.scene_path, "", Vector2.ZERO)
	
	PlayerManager.set_player_position(Vector2(current_save.player.pos_x, current_save.player.pos_y))
	PlayerManager.set_health(current_save.player.hp, current_save.player.max_hp)
	
	await LevelManager.level_loaded
	
	game_loaded.emit()

func update_player_data() -> void:
	var p : Player = PlayerManager.player
	if p:
		current_save.player.hp = p.hp
		current_save.player.max_hp = p.max_hp
		current_save.player.pos_x = p.global_position.x
		current_save.player.pos_y = p.global_position.y
	
	if get_tree().current_scene:
		current_save.scene_path = get_tree().current_scene.scene_file_path

	# Save active used transition IDs into dictionary
	current_save["used_transitions"] = PlayerManager.used_transitions

func autosave_timer() -> void:
	save_game()

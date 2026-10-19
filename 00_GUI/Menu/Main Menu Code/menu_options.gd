extends Node2D
const START_LEVEL : String = "res://Background Assets/Cabin/Cabin.tscn"

@onready var create: Button = $CanvasLayer2/GridContainer/Create
@onready var host: Button = $CanvasLayer2/GridContainer/Host
@onready var load_in: Button = $CanvasLayer2/GridContainer/Load_in
@onready var options: Button = $CanvasLayer2/GridContainer/Options
@onready var exit: Button = $CanvasLayer2/Exit



func _ready() -> void:
	get_tree().paused = true
	if is_instance_valid(PlayerManager.player):
		PlayerManager.player.visible = false
		
	create.pressed.connect( _on_create_pressed )
	load_in.pressed.connect( _on_load_pressed )
	exit.pressed.connect( _on_quit_pressed )
	
	LevelManager.level_load_started.connect( exit_menu_screen)
	
	pass
	
# In menu_options.gd
func _on_create_pressed() -> void:
	PlayerManager.player_spawned = false
	PlayerManager.is_loading_save = false
	if is_instance_valid(PlayerManager.player):
		PlayerManager.player.reset_player_state()
	start_game()
	
func _on_host_pressed() -> void:
	pass
func _on_load_pressed() -> void:
	SaveManager.load_game()
	pass
func _on_options_pressed() -> void:
	pass

func _on_quit_pressed() -> void:
	get_tree().quit()


func start_game() -> void:
	LevelManager.load_new_level( START_LEVEL, "", Vector2.ZERO )
	pass

# Inside menu_options.gd
func exit_menu_screen() -> void:
	get_tree().paused = false # <--- Unpause the engine
	if is_instance_valid(PlayerManager.player):
		PlayerManager.player.visible = true	
	self.queue_free()


func _on_load_in_pressed() -> void:
	pass # Replace with function body.

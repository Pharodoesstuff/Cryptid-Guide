extends CanvasLayer

@onready var button_menu: Button = $VBoxContainer/Button_Menu
@onready var button_exit: Button = $VBoxContainer/Button_Exit



var is_paused : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_pause_menu()
	pass # Replace with function body.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("paused"):
		if is_instance_valid(PlayerManager.player) and PlayerManager.player.visible:
			toggle_pause()
			get_viewport().set_input_as_handled()
		
func show_pause_menu() -> void:
	get_tree().paused = true
	visible = true
	is_paused = true
	button_menu.grab_focus()

	
func hide_pause_menu() -> void:
	get_tree().paused = false
	visible = false
	is_paused = false
	

func _on_button_exit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.


func _on_button_menu_pressed() -> void:
	hide_pause_menu()
	
	# Save the player from being freed when the Level scene unloads
	if is_instance_valid(PlayerManager.player) and PlayerManager.player.get_parent():
		PlayerManager.player.get_parent().remove_child(PlayerManager.player)
		PlayerManager.add_child(PlayerManager.player)
		
	get_tree().change_scene_to_file("res://00_GUI/Menu/menu_options.tscn")

func toggle_pause() -> void:
	if is_paused:
		hide_pause_menu()
	else:
		show_pause_menu()
	

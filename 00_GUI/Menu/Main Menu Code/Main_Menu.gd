extends Node


@onready var start: Button = $CanvasLayer/Start

func _ready() -> void:
	get_tree().paused = true
	PlayerManager.player.visible = false
		
	
func _on_start_pressed () ->void : 
	get_tree().change_scene_to_file("res://00_GUI/Menu/menu_options.tscn")
	pass

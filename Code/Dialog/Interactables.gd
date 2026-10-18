class_name Interactable extends Area2D

@export_multiline var dialogue_lines: Array[String] = ["It's an old piece of furniture."]
@export var speaker_name: String = ""

func interact() -> void:
	# Fetches the UI node specifically
	var dialog_system = get_tree().get_first_node_in_group("dialogue_system") as DialogSystemNode
	if dialog_system:
		dialog_system.start_dialogue(dialogue_lines, speaker_name)

extends "res://Interactions/Dialog/Scripts/forced_Dialogue.gd"

func _ready() -> void:
	# Keep standard collision connections from base class
	body_entered.connect(_on_body_entered)
	
	# Listen ONLY for voidlight in this special dialogue script
	EventBus.voidlight_finished.connect(_on_voidlight_finished)

func _on_voidlight_finished() -> void:
	signal_has_fired = true
	if trigger_mode == TriggerType.SIGNAL_ONLY:
		_start_dialogue()

# Override _start_dialogue to emit jersey_devil_hungry when text completes
func _start_dialogue() -> void:
	if has_triggered and trigger_once:
		return
		
	has_triggered = true
	
	# Lock player
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and "can_move" in players[0]:
		players[0].can_move = false
		
	# Spawn dialogue UI
	var dialogue_instance = dialogue_ui_scene.instantiate()
	dialogue_instance.dialogue = dialogue_sequence
	get_tree().current_scene.add_child(dialogue_instance)
	
	if override_position:
		var container = dialogue_instance.get_node_or_null("DialogueContainer")
		if container:
			container.position = custom_position
			
	if trigger_once:
		set_deferred("monitoring", false)
		
	# Wait for player to close dialogue, then trigger Jersey Devil
	await dialogue_instance.tree_exited
	EventBus.jersey_devil_hungry.emit()

# dialogue_trigger.gd (or your Area2D dialogue script)
extends Area2D

enum TriggerType {
	TOUCH_ONLY,
	SIGNAL_ONLY,
	SIGNAL_THEN_TOUCH
}

@export_category("Trigger Conditions")
@export var trigger_mode: TriggerType = TriggerType.TOUCH_ONLY
@export var trigger_once: bool = true
@export var persistence_key: String = "" # e.g., "void_dialogue_seen" or "attic_dialogue_seen"

@export_subgroup("Signal Settings")
@export var signal_emitter: NodePath
@export var signal_name: String = "ambush_completed"

@export_category("Dialogue Setup")
@export var dialogue_sequence: Array[DE]
@export var dialogue_ui_scene: PackedScene = preload("res://00_Globals/dialogue_system.tscn")

@export_subgroup("Positioning")
@export var override_position: bool = false
@export var custom_position: Vector2 = Vector2.ZERO

var signal_has_fired: bool = false
var has_triggered: bool = false

func _ready() -> void:
	# 1. Check if this trigger has already been completed in SaveManager
	if not persistence_key.is_empty() and SaveManager.has_persistence(persistence_key):
		has_triggered = true
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		return # Stop further signal connection/ready setup

	# 2. Connect collision signals
	body_entered.connect(_on_body_entered)
	
	# Connect target signal if configured
	if trigger_mode != TriggerType.TOUCH_ONLY and not signal_emitter.is_empty():
		var emitter_node = get_node_or_null(signal_emitter)
		if emitter_node and emitter_node.has_signal(signal_name):
			emitter_node.connect(signal_name, _on_target_signal_emitted)
		else:
			printerr("DialogueTrigger: Could not find node or signal '", signal_name, "' on ", signal_emitter)

func _on_target_signal_emitted() -> void:
	signal_has_fired = true
	if trigger_mode == TriggerType.SIGNAL_ONLY:
		_start_dialogue()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
		
	match trigger_mode:
		TriggerType.TOUCH_ONLY:
			_start_dialogue()
		TriggerType.SIGNAL_THEN_TOUCH:
			if signal_has_fired:
				_start_dialogue()

func _start_dialogue() -> void:
	if has_triggered and trigger_once:
		return
		
	has_triggered = true
	
	# Save interaction key into SaveManager persistence array
	if not persistence_key.is_empty():
		SaveManager.set_persistence(persistence_key)
	
	# Lock player movement
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and "can_move" in players[0]:
		players[0].can_move = false
		
	# Instantiate dialogue UI
	var dialogue_instance = dialogue_ui_scene.instantiate()
	dialogue_instance.dialogue = dialogue_sequence
	
	get_tree().current_scene.add_child(dialogue_instance)
	
	# Apply optional position override
	if override_position:
		var container = dialogue_instance.get_node_or_null("DialogueContainer")
		if container:
			container.position = custom_position
			
	if trigger_once:
		set_deferred("monitoring", false)

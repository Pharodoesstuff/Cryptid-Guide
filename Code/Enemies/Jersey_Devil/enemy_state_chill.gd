class_name EnemyStateChill extends EnemyState

@export var anim_name : String = "DDevil"
@export var chase_state : EnemyState
@export var wait_time : float = 13.0

@export var override_final_position : bool = false
@export var final_dialogue_position : Vector2 = Vector2(-1, -1)

# Export array of timed dialogue entries
@export var timed_dialogues : Array[TimedDialogue]

# Final dialogue resource spoken after Devil reaches the player
@export var final_dialogue : Resource

# Cabin scene UID to load after final dialogue ends
@export var cabin_level_path : String = "uid://dpxmw1emc12l1"

@export var dialogue_manager_scene : PackedScene = preload("res://00_Globals/dialogue_system.tscn")

var _idle_timer : float = 0.0
var _timer_triggered : bool = false
var _is_approaching_player : bool = false
var _final_sequence_started : bool = false
var _triggered_dialogue_indices : Array[int] = []

func enter() -> void:
	enemy.velocity = Vector2.ZERO
	enemy.UpdateAnimation(anim_name)
	_idle_timer = 0.0
	_timer_triggered = false
	_is_approaching_player = false
	_final_sequence_started = false
	_triggered_dialogue_indices.clear()

func physics(delta: float) -> EnemyState:
	if enemy.is_hungry and PlayerManager.player:
		# Player moves BEFORE timer -> start normal chase
		if PlayerManager.player.velocity.length() > 0.1 and not _timer_triggered:
			EventBus.keepdark.emit() # Destroys detector
			return chase_state
		
		# Player stays still -> tick idle timer & dialogues
		if not _timer_triggered:
			_idle_timer += delta
			_check_timed_dialogues()
			
			if _idle_timer >= wait_time:
				_timer_triggered = true
				_start_stalk_sequence()
		
		# Devil walks up to player during stalk sequence
		elif _is_approaching_player and not _final_sequence_started:
			var player = PlayerManager.player
			if is_instance_valid(player):
				var dist = enemy.global_position.distance_to(player.global_position)
				if dist <= 45.0: # Reached player proximity
					_start_final_dialogue_sequence()

	return null

func _check_timed_dialogues() -> void:
	for i in range(timed_dialogues.size()):
		if i in _triggered_dialogue_indices:
			continue
			
		var entry : TimedDialogue = timed_dialogues[i]
		if entry and _idle_timer >= entry.time:
			_triggered_dialogue_indices.append(i)
			if entry.dialogue:
				var pos = entry.custom_position if entry.override_position else Vector2(-1, -1)
				_play_dialogue_resource(entry.dialogue, pos)

func _start_stalk_sequence() -> void:
	_close_active_dialogues()
	EventBus.player_freeze_requested.emit(true)
	
	# Disable HurtBox so Devil doesn't kill player during cutscene
	var hurtbox_col = enemy.get_node_or_null("HurtBox/CollisionShape2D")
	if hurtbox_col:
		hurtbox_col.set_deferred("disabled", true)
		
	_is_approaching_player = true
	enemy.start_stalking()

func _start_final_dialogue_sequence() -> void:
	_final_sequence_started = true
	_is_approaching_player = false
	enemy.stop_stalking()
	enemy.UpdateAnimation("DDevil_idol")
	_close_active_dialogues()
	
	# Fix: Use Vector2(-1, -1) unless explicitly overridden in Inspector so UI renders on screen
	var target_pos : Vector2 = Vector2(-1, -1)
	if override_final_position:
		target_pos = final_dialogue_position
	
	if final_dialogue:
		var manager_instance = _play_dialogue_resource(final_dialogue, target_pos)
		if is_instance_valid(manager_instance):
			manager_instance.tree_exited.connect(_on_final_dialogue_finished)
		else:
			_on_final_dialogue_finished()
	else:
		_on_final_dialogue_finished()

func _on_final_dialogue_finished() -> void:
	await get_tree().create_timer(1.0).timeout
	
	# Save persistence flag to permanently lock Void transition
	SaveManager.set_persistence("void_cutscene_completed")
	
	# Transition back to Cabin
	LevelManager.load_new_level(cabin_level_path, "Void", Vector2.ZERO)

func _close_active_dialogues() -> void:
	for existing in get_tree().get_nodes_in_group("dialogue_box"):
		if is_instance_valid(existing):
			existing.queue_free()

func _play_dialogue_resource(res: Resource, custom_pos: Vector2 = Vector2(-1, -1)) -> Node:
	if res == null or dialogue_manager_scene == null:
		return null

	_close_active_dialogues()
		
	var de_array : Array[DE] = []
	if res is DE:
		de_array.append(res)
	elif "dialogue" in res:
		de_array = res.dialogue
	elif "dialogue_sequence" in res:
		de_array = res.dialogue_sequence
		
	if de_array.size() > 0:
		var manager_instance = dialogue_manager_scene.instantiate()
		manager_instance.dialogue = de_array
		
		if custom_pos != Vector2(-1, -1):
			var container = manager_instance.get_node_or_null("DialogueContainer")
			if container:
				container.global_position = custom_pos
				
		get_tree().root.add_child(manager_instance)
		return manager_instance
	return null

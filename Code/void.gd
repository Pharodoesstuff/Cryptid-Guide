extends "res://Code/Level Code/level.gd"

@export_category("Scene References")
@export var dialogue_scene: PackedScene = preload("res://Interactions/Dialog/forced_dialogue.tscn")
@export var jersey_devil: Node2D

@export_group("Intro Dialogue")
@export var intro_dialogue: Array[DE] = []
@export var intro_override_pos: bool = false
@export var intro_custom_pos: Vector2 = Vector2.ZERO

@export_group("Success Dialogue")
@export var success_dialogue: Array[DE] = []
@export var success_override_pos: bool = false
@export var success_custom_pos: Vector2 = Vector2.ZERO

@export_group("Final Dialogue")
@export var final_dialogue: Array[DE] = []
@export var final_override_pos: bool = false
@export var final_custom_pos: Vector2 = Vector2.ZERO

@export_group("Timer Dialogues")
@export var timer_dialogues: Array[TimerDialogueStep] = []

@export_category("Timings & Speeds")
@export var challenge_duration: float = 20.0
@export var teleport_delay: float = 3.0
@export var stalk_speed: float = 35.0
@export var void_light_stopping_distance: float = 80.0

@onready var bg: Node2D = $BG

var is_stalking: bool = false

func _ready() -> void:
	super._ready()
	
	# Safe player resolution fallback
	var player: Player = PlayerManager.player
	if not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
			PlayerManager.player = player

	if is_instance_valid(player):
		if LevelManager and ("target_transition" in LevelManager):
			if LevelManager.target_transition == "" or LevelManager.target_transition == "Cabin":
				player.global_position = Vector2(100, 100)
			
	EventBus.off_light.connect(_turn_off)

	if not jersey_devil and has_node("Jersey Devil"):
		jersey_devil = $"Jersey Devil"

	call_deferred("start_void_sequence")

func start_void_sequence() -> void:
	var player: Player = PlayerManager.player
	if not is_instance_valid(player): 
		return

	# 1. Lock movement & play light animation
	EventBus.player_freeze_requested.emit(true)
	
	if player.has_node("VoidLight"):
		var void_light = player.get_node("VoidLight")
		if void_light.has_method("activate"):
			void_light.activate(8.0)
			await EventBus.voidlight_finished
		else:
			await get_tree().create_timer(1.0).timeout
	elif has_node("PointLight2D"):
		$PointLight2D.visible = true
		await get_tree().create_timer(1.0).timeout
	else:
		await get_tree().create_timer(1.0).timeout

	# 2. Intro Dialogue
	await play_dialogue(intro_dialogue, intro_override_pos, intro_custom_pos)

	# 3. Unlock movement & start timer challenge
	EventBus.player_freeze_requested.emit(false)
	var survived = await run_stand_still_challenge(challenge_duration)

	if not survived:
		get_tree().call_group("dialogue_box", "close_dialogue")
		trigger_jersey_devil_aggro(player)
		return

	# 4. Challenge Passed: Lock movement again
	EventBus.player_freeze_requested.emit(true)
	get_tree().call_group("dialogue_box", "close_dialogue")

	# Trigger stalking animation and success dialogue simultaneously
	stalk_player_to_voidlight(player)
	await play_dialogue(success_dialogue, success_override_pos, success_custom_pos)

	while is_stalking:
		await get_tree().process_frame

	# 5. Final Dialogue
	# 5. Play final dialogue
	await play_dialogue(final_dialogue, final_override_pos, final_custom_pos)

	# Safety check in case the scene tree was freed during dialogue wait
	if not is_inside_tree():
		return

	# 6. Teleport delay & trigger existing Cabin transition node
	if teleport_delay > 0.0:
		await get_tree().create_timer(teleport_delay).timeout

	if not is_inside_tree():
		return

	set_player_frozen(false)

	# Trigger the existing transition node already placed in your scene
	var cabin_trans = get_node_or_null("Level transitions/Cabin")
	if is_instance_valid(cabin_trans):
		cabin_trans.monitoring = true
		if cabin_trans.has_method("trigger"):
			cabin_trans.trigger()
		elif cabin_trans.has_method("transition"):
			cabin_trans.transition()

func run_stand_still_challenge(duration: float) -> bool:
	var player: Player = PlayerManager.player
	if not is_instance_valid(player):
		return false

	player.velocity = Vector2.ZERO
	await get_tree().process_frame

	var time_elapsed: float = 0.0
	var triggered_steps: Array[TimerDialogueStep] = []

	while time_elapsed < duration:
		await get_tree().process_frame
		var delta = get_process_delta_time()
		time_elapsed += delta

		if is_player_attempting_movement(player):
			return false

		for step in timer_dialogues:
			if step and step not in triggered_steps:
				if time_elapsed >= step.time:
					triggered_steps.append(step)
					if step.dialogue != null:
						# Close previous dialogue step before spawning new step
						get_tree().call_group("dialogue_box", "close_dialogue")
						spawn_dialogue([step.dialogue], step.override_position, step.custom_position)

	return true

func stalk_player_to_voidlight(player: Player) -> void:
	if not is_instance_valid(jersey_devil) or not is_instance_valid(player):
		return

	is_stalking = true
	var anim_player: AnimationPlayer = jersey_devil.get_node_or_null("AnimationPlayer")

	while is_instance_valid(jersey_devil) and is_instance_valid(player):
		var target_pos = player.global_position
		var to_target = target_pos - jersey_devil.global_position
		var distance = to_target.length()

		if distance <= void_light_stopping_distance:
			break

		var move_dir = to_target.normalized()
		var delta = get_process_delta_time()
		jersey_devil.global_position += move_dir * stalk_speed * delta

		if jersey_devil.has_method("SetDirection"):
			jersey_devil.SetDirection(move_dir)
			jersey_devil.UpdateAnimation("DDevil")
		elif anim_player and anim_player.has_animation("DDevil_side") and anim_player.current_animation != "DDevil_side":
			anim_player.play("DDevil_side")

		await get_tree().process_frame

	if is_instance_valid(jersey_devil):
		if anim_player and anim_player.has_animation("Devil_walk_intro_side"):
			anim_player.play("Devil_walk_intro_side")
			await get_tree().create_timer(1.0).timeout

		if jersey_devil.has_method("set_revealed"):
			jersey_devil.set_revealed(true)

		if anim_player and anim_player.has_animation("Devil_Side_Idol"):
			anim_player.play("Devil_Side_Idol")

	is_stalking = false

func is_player_attempting_movement(player: Player) -> bool:
	var raw_input = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	return raw_input.length_squared() > 0 or player.velocity.length_squared() > 0.1

func spawn_dialogue(dialogue_data: Array, override_pos: bool = false, custom_pos: Vector2 = Vector2.ZERO) -> Node:
	if dialogue_data.is_empty() or not dialogue_scene:
		return null
		
	var diag_inst = dialogue_scene.instantiate()
	
	if "dialogue" in diag_inst:
		diag_inst.dialogue.clear()
		for item in dialogue_data:
			if item != null:
				diag_inst.dialogue.append(item)
	elif "dialogue_sequence" in diag_inst:
		diag_inst.dialogue_sequence.clear()
		for item in dialogue_data:
			if item != null:
				diag_inst.dialogue_sequence.append(item)
	else:
		push_error("Spawned dialogue scene missing required dialogue property!")
		diag_inst.queue_free()
		return null
		
	get_tree().root.add_child(diag_inst)
	
	if override_pos and diag_inst.has_method("set_override_position"):
		diag_inst.set_override_position(custom_pos, false)

	return diag_inst

func play_dialogue(dialogue_data: Array, override_pos: bool = false, custom_pos: Vector2 = Vector2.ZERO) -> void:
	var diag_inst = spawn_dialogue(dialogue_data, override_pos, custom_pos)
	if is_instance_valid(diag_inst):
		await diag_inst.tree_exited

func trigger_jersey_devil_aggro(target: Player) -> void:
	EventBus.jersey_devil_hungry.emit()
	if is_instance_valid(jersey_devil) and jersey_devil.has_method("start_aggro"):
		jersey_devil.start_aggro(target)

func _exit_tree() -> void:
	EventBus.player_freeze_requested.emit(false)
	if is_instance_valid(PlayerManager.player):
		PlayerManager.player.can_move = true

func _turn_off() -> void:
	if is_instance_valid(bg):
		bg.visible = false

func set_player_frozen(frozen: bool) -> void:
	EventBus.player_freeze_requested.emit(frozen)
	var player = PlayerManager.player
	if is_instance_valid(player):
		if "is_frozen" in player:
			player.is_frozen = frozen
		if "can_move" in player:
			player.can_move = not frozen
			

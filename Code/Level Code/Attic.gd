extends "res://Code/Level Code/level.gd"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var powerbox_area: Area2D = $Powerbox
@onready var dover_demon: Node2D = $DoverDemon



var is_interactable: bool = true
var is_player_in_powerbox_range: bool = false

func _ready() -> void:
	super._ready()
	var player = PlayerManager.player
	if is_instance_valid(player):
		player.visible = true
		player.modulate.a = 1.0
		player.set_frozen(false)

	if powerbox_area:
		powerbox_area.body_entered.connect(_on_powerbox_body_entered)
		powerbox_area.body_exited.connect(_on_powerbox_body_exited)
		print("[DEBUG] Powerbox signals connected successfully.")
	else:
		print("[DEBUG ERROR] $Powerbox Area2D node not found!")
	if SaveManager.has_persistence("attic_power_on"):
		_set_power_on_state()
	await get_tree().physics_frame
	_check_initial_powerbox_overlap()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Accept") and not event.is_echo():
		print("[DEBUG] 'Accept' pressed! Range: ", is_player_in_powerbox_range, " | Interactable: ", is_interactable)
		
		if is_interactable and is_player_in_powerbox_range:
			get_viewport().set_input_as_handled()
			interact_with_powerbox()


	

func _on_powerbox_body_entered(body: Node2D) -> void:
	print("[DEBUG] Area entered by: ", body.name)
	if _is_player(body):
		print("[DEBUG] Player entered powerbox range!")
		is_player_in_powerbox_range = true
	else:
		print("[DEBUG] Body entered, but it is NOT recognized as Player.")

func _on_powerbox_body_exited(body: Node2D) -> void:
	print("[DEBUG] Body exited Powerbox: ", body.name)
	if _is_player(body):
		is_player_in_powerbox_range = false

func _check_initial_powerbox_overlap() -> void:
	if not is_instance_valid(powerbox_area):
		return
	for body in powerbox_area.get_overlapping_bodies():
		print("[DEBUG] Overlapping body on start: ", body.name)
		if _is_player(body):
			print("[DEBUG] Player detected in overlap on start!")
			is_player_in_powerbox_range = true
			break

func _is_player(node: Node) -> bool:
	var matches_manager = (node == PlayerManager.player)
	var matches_group = node.is_in_group("player")
	print("[DEBUG] Player Check on '", node.name, "': Manager match = ", matches_manager, " | Group match = ", matches_group)
	return matches_manager or matches_group

func interact_with_powerbox() -> void:
	print("[DEBUG] Starting powerbox interaction!")
	if SaveManager.has_persistence("attic_power_on"):
		print("[DEBUG] Already persistence saved as ON.")
		_set_power_on_state()
		return
		
	is_interactable = false
	
	# Freeze the player so they can't move during the animation
	var player = PlayerManager.player
	if is_instance_valid(player):
		player.set_frozen(true)

	SaveManager.set_persistence("attic_power_on")
	SaveManager.save_game()
	
	if animation_player.has_animation("Power"):
		print("[DEBUG] Playing 'Power' anim...")
		animation_player.play("Power")
		await animation_player.animation_finished
		
	if animation_player.has_animation("Starting..."):
		print("[DEBUG] Playing 'Starting...' anim...")
		animation_player.play("Starting...")
		await animation_player.animation_finished
		EventBus.attic_event_completed.emit()

	_set_power_on_state()
	
	# Unfreeze the player after all animations finish
	if is_instance_valid(player):
		player.set_frozen(false)
		
	is_interactable = true

func _wait_for_animation(anim_name: StringName) -> void:
	while true:
		var finished_anim = await animation_player.animation_finished
		if finished_anim == anim_name:
			break

func _set_power_on_state() -> void:
	if has_node("STOP"):
		$STOP.visible = true
		
	if animation_player.has_animation("STOP"):
		animation_player.play("STOP")

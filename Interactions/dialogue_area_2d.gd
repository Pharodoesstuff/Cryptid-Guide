class_name DialogueArea2d extends Area2D

const DialogueSystemPreload = preload("res://00_Globals/dialogue_system.tscn")

@export var required_player_look_dir: String = ""
@export var activate_instant: bool = false
@export var only_activate_once: bool = false
@export var override_dialogue_position: bool = false
@export var override_position: Vector2
@export var dialogue: Array[DE]

var player_body_in: bool = false
var has_activated_already: bool = false
var desired_dialogue_pos: Vector2

var player_node: CharacterBody2D = null
var active_dialogue_node: Node = null

func _ready() -> void:
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i

func _process(_delta: float) -> void:
	# Stop processing if monitoring has been disabled
	if not monitoring:
		return

	if !player_node:
		for i in get_tree().get_nodes_in_group("player"):
			player_node = i
		return

	if only_activate_once and has_activated_already:
		set_process(false)
		return

	# Block re-triggering while dialogue is actively displayed
	if is_instance_valid(active_dialogue_node):
		return

	if Input.is_action_just_pressed("Accept") and !activate_instant:
		# Guard against calling get_overlapping_bodies() if monitoring is off
		var is_inside = player_body_in or (monitoring and player_node in get_overlapping_bodies())
		if is_inside and _check_look_direction():
			_activate_dialogue()

func _check_look_direction() -> bool:
	if required_player_look_dir == "":
		return true
		
	var player_dir = player_node.look_dir
	# Account for AnimDirection() returning "side" for horizontal directions
	if required_player_look_dir in ["left", "right"] and player_dir == "side":
		return true
		
	return player_dir == required_player_look_dir

func _activate_dialogue() -> void:
	has_activated_already = true
	if player_node:
		player_node.can_move = false
		player_node.velocity = Vector2.ZERO
		
	var new_dialogue = DialogueSystemPreload.instantiate()
	var viewport_rect = get_viewport().get_visible_rect()
	
	# Center the 650px wide dialogue box horizontally
	var box_width: float = 650.0
	var centered_x: float = (viewport_rect.size.x - box_width) / 2.0
	
	if override_dialogue_position:
		desired_dialogue_pos = override_position
	else:
		var camera = get_viewport().get_camera_2d()
		if camera and player_node.global_position.y > camera.get_screen_center_position().y:
			# Top of screen
			desired_dialogue_pos = Vector2(centered_x, 20)
		else:
			# Bottom of screen
			desired_dialogue_pos = Vector2(centered_x, viewport_rect.size.y - 140)

	new_dialogue.offset = desired_dialogue_pos
	new_dialogue.dialogue = dialogue
	active_dialogue_node = new_dialogue
	get_parent().add_child(new_dialogue)

func _on_body_entered(body: Node2D) -> void:
	if only_activate_once and has_activated_already:
		return
	if body.is_in_group("player"):
		player_body_in = true
		if activate_instant and !is_instance_valid(active_dialogue_node):
			_activate_dialogue()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_body_in = false

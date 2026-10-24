extends CanvasLayer

const DialogueButtonPreload = preload("res://Interactions/Dialog/Dialog_button.tscn")

@onready var DialogueLabel: RichTextLabel = $DialogueContainer/HBoxContainer/VBoxContainer/RichTextLabel
@onready var SpeakerSprite: Sprite2D = $DialogueContainer/HBoxContainer/SpeakerParent/Sprite2D if has_node("DialogueContainer/HBoxContainer/SpeakerParent/Sprite2D") else null

@export_category("Position Override")
@export var override_position: bool = false:
	set(value):
		override_position = value
		_update_container_position()

@export var custom_position: Vector2 = Vector2.ZERO:
	set(value):
		custom_position = value
		_update_container_position()

var dialogue: Array = []
var current_dialogue_item: int = 0
var next_item: bool = true

var player_node: CharacterBody2D

func _ready() -> void:
	add_to_group("dialogue_box")
	visible = false
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i
	_update_container_position()

func set_override_position(pos: Vector2, is_world_space: bool = false) -> void:
	override_position = true
	if is_world_space and get_viewport():
		var canvas_transform = get_viewport().get_canvas_transform()
		custom_position = canvas_transform * pos
	else:
		custom_position = pos
	_update_container_position()

func _update_container_position() -> void:
	if not is_inside_tree() or not override_position:
		return
		
	var container = get_node_or_null("DialogueContainer")
	if container:
		container.global_position = custom_position

func _process(_delta: float) -> void:
	if current_dialogue_item >= dialogue.size():
		close_dialogue()
		return

	if next_item:
		next_item = false
		var item = dialogue[current_dialogue_item]
		
		if "override_position" in item and item.override_position:
			var is_world = item.is_world_space if "is_world_space" in item else false
			set_override_position(item.custom_position, is_world)
		
		if item is DialogueFunction:
			visible = !item.hide_dialogue_box
			_function_resource(item)
			
		elif item is DialogueChoice:
			visible = true
			_choice_resource(item)
			
		elif item is DialogueText:
			visible = true
			_text_resource(item)
			
		else:
			printerr("You accidentally added a raw DE resource!")
			current_dialogue_item += 1
			next_item = true

func _function_resource(i: DialogueFunction) -> void:
	var target_node: Node = self if i.target_path.is_empty() else get_node_or_null(i.target_path)
	
	# Fallback: locate Dialogue manager in current level if target_node missing function
	if not target_node or not target_node.has_method(i.function_name):
		var dialogue_node = get_tree().current_scene.get_node_or_null("Dialogue")
		if dialogue_node and dialogue_node.has_method(i.function_name):
			target_node = dialogue_node

	if target_node and target_node.has_method(i.function_name):
		if i.function_arguments.size() == 0:
			target_node.call(i.function_name)
		else:
			target_node.callv(i.function_name, i.function_arguments)

	current_dialogue_item += 1
	next_item = true

func _choice_resource(i: DialogueChoice) -> void:
	DialogueLabel.text = i.text
	DialogueLabel.visible_characters = -1
	var speaker_parent = get_node_or_null("DialogueContainer/HBoxContainer/SpeakerParent")
	
	if i.speaker_img and is_instance_valid(SpeakerSprite):
		if speaker_parent: speaker_parent.visible = true
		SpeakerSprite.texture = i.speaker_img
		SpeakerSprite.hframes = i.speaker_img_Hframes
		SpeakerSprite.frame = min(i.speaker_img_select_frame, i.speaker_img_Hframes - 1)
	else:
		if speaker_parent: speaker_parent.visible = false
		
	var btn_container = get_node_or_null("DialogueContainer/HBoxContainer/VBoxContainer/button_container")
	if btn_container:
		btn_container.visible = true
		for child in btn_container.get_children():
			child.queue_free()
			
		var first_button: Button = null

		for idx in i.choice_text.size():
			var DialogueButtonVar = DialogueButtonPreload.instantiate()
			DialogueButtonVar.text = i.choice_text[idx]
			
			if idx == 0:
				first_button = DialogueButtonVar
			
			var function_resource: DialogueFunction = i.choice_function_call[idx] if idx < i.choice_function_call.size() else null
			if function_resource:
				var target: Node = self if function_resource.target_path.is_empty() else get_node_or_null(function_resource.target_path)
				
				if target and target.has_method(function_resource.function_name):
					DialogueButtonVar.connect("pressed", Callable(target, function_resource.function_name).bindv(function_resource.function_arguments), CONNECT_ONE_SHOT)
					if function_resource.hide_dialogue_box:
						DialogueButtonVar.connect("pressed", hide, CONNECT_ONE_SHOT)
					DialogueButtonVar.connect("pressed", _choice_button_pressed.bind(target, function_resource.wait_for_signal_to_continue), CONNECT_ONE_SHOT)
				else:
					DialogueButtonVar.connect("pressed", _choice_button_pressed.bind(null, ""), CONNECT_ONE_SHOT)
			else:
				DialogueButtonVar.connect("pressed", _choice_button_pressed.bind(null, ""), CONNECT_ONE_SHOT)
				
			btn_container.add_child(DialogueButtonVar)

		if first_button:
			first_button.call_deferred("grab_focus")

func _choice_button_pressed(target_node: Node, wait_for_signal_to_continue: String):
	var btn_container = get_node_or_null("DialogueContainer/HBoxContainer/VBoxContainer/button_container")
	if btn_container:
		btn_container.visible = false
		for child in btn_container.get_children():
			child.queue_free()
			
	if wait_for_signal_to_continue and target_node:
		var signal_name = wait_for_signal_to_continue
		if target_node.has_signal(signal_name):
			var signal_state = { "done": false }
			var callable = func(_args = null): signal_state.done = true
			target_node.connect(signal_name, callable, CONNECT_ONE_SHOT)
			while not signal_state.done:
				if not is_inside_tree(): return
				await get_tree().process_frame

	current_dialogue_item += 1
	next_item = true

func _text_resource(i: DialogueText) -> void:
	var audio_player = get_node_or_null("AudioStreamPlayer")
	if audio_player:
		audio_player.stream = i.text_sound
		audio_player.volume_db = i.text_volume_db

	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		if i.reset_camera_to_player and is_instance_valid(player_node):
			var camera_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
			camera_tween.tween_property(camera, "global_position", player_node.global_position, i.camera_transition_time)
		elif i.camera_position != Vector2(999.999, 999.999):
			var camera_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
			camera_tween.tween_property(camera, "global_position", i.camera_position, i.camera_transition_time)
	
	var speaker_parent = get_node_or_null("DialogueContainer/HBoxContainer/SpeakerParent")
	if speaker_parent:
		speaker_parent.visible = i.speaker_img != null

	if i.speaker_img and is_instance_valid(SpeakerSprite):
		SpeakerSprite.texture = i.speaker_img
		SpeakerSprite.hframes = i.speaker_img_Hframes
		SpeakerSprite.frame = 0
		
	DialogueLabel.visible_characters = 0
	DialogueLabel.text = i.text
	var text_without_square_brackets: String = _text_without_square_brackets(i.text)
	var total_characters: int = text_without_square_brackets.length()
	var character_timer: float = 0.0
	
	if not is_inside_tree(): return
	await get_tree().process_frame
	
	var speed = maxf(i.text_speed, 0.001)
	while DialogueLabel.visible_characters < total_characters:
		if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("Accept"):
			DialogueLabel.visible_characters = total_characters
			get_viewport().set_input_as_handled()
			break 
		
		character_timer += get_process_delta_time()
		if character_timer >= (1.0 / speed):
			character_timer = 0.0
			var curr_idx = DialogueLabel.visible_characters
			if curr_idx < total_characters:
				var character: String = text_without_square_brackets[curr_idx]
				DialogueLabel.visible_characters += 1
				if character != " ":
					if i.text_sound and audio_player:
						audio_player.pitch_scale = randf_range(i.text_volume_pitch_min, i.text_volume_pitch_max)
						audio_player.play()
					if is_instance_valid(SpeakerSprite) and i.speaker_img_Hframes > 1:
						SpeakerSprite.frame = (SpeakerSprite.frame + 1) % i.speaker_img_Hframes
		
		if not is_inside_tree(): return
		await get_tree().process_frame
		
	if is_instance_valid(SpeakerSprite):
		SpeakerSprite.frame = min(i.speaker_img_rest_frame, i.speaker_img_Hframes - 1)
	
	if not is_inside_tree(): return
	await get_tree().process_frame
	
	var wait_timer: float = 0.0

	while true:
		if not is_inside_tree(): return
		await get_tree().process_frame
		
		if Input.is_action_just_pressed("Accept"):
			get_viewport().set_input_as_handled()
			current_dialogue_item += 1
			next_item = true
			break
		
		if i.auto_advance:
			wait_timer += get_process_delta_time()
			if wait_timer >= i.auto_advance_delay:
				current_dialogue_item += 1
				next_item = true
				break

func _text_without_square_brackets(text: String) -> String:
	var result: String = ""
	var inside_bracket: bool = false
	for char_elem in text:
		if char_elem == "[":
			inside_bracket = true
			continue
		if char_elem == "]":
			inside_bracket = false
			continue
		if !inside_bracket:
			result += char_elem
	return result

func close_dialogue() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera and is_instance_valid(player_node):
		var camera_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
		camera_tween.tween_property(camera, "global_position", player_node.global_position, 0.5)

	visible = false
	if has_node("DialogueContainer"):
		$DialogueContainer.visible = false
	if player_node and not player_node.is_frozen:
		player_node.can_move = true
	queue_free()

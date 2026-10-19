extends CanvasLayer

const DialogueButtonPreload = preload("res://Interactions/Dialog/Dialog_button.tscn")

@onready var DialogueLabel: RichTextLabel = $DialogueContainer/HBoxContainer/VBoxContainer/RichTextLabel
@onready var SpeakerSprite: Sprite2D = $DialogueContainer/HBoxContainer/SpeakerParent/Sprite2D

var dialogue: Array[DE]
var current_dialogue_item: int = 0
var next_item: bool = true

var player_node: CharacterBody2D

func _ready() -> void:
	visible = false
	for i in get_tree().get_nodes_in_group("player"):
		player_node = i

func _process(_delta: float) -> void:
	if current_dialogue_item >= dialogue.size():
		if player_node:
			player_node.can_move = true
		queue_free()
		return

	if next_item:
		next_item = false
		var item = dialogue[current_dialogue_item]
		
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
	var target_node = get_node_or_null(i.target_path)
	if target_node and target_node.has_method(i.function_name):
		if i.function_arguments.size() == 0:
			target_node.call(i.function_name)
		else:
			target_node.callv(i.function_name, i.function_arguments)
	
	if i.wait_for_signal_to_continue and target_node:
		var signal_name = i.wait_for_signal_to_continue
		if target_node.has_signal(signal_name):
			var signal_state = { "done": false }
			var callable = func(_args = null): signal_state.done = true
			target_node.connect(signal_name, callable, CONNECT_ONE_SHOT)
			while not signal_state.done:
				if not is_inside_tree(): return
				await get_tree().process_frame
	
	current_dialogue_item += 1
	next_item = true

func _choice_resource(i: DialogueChoice) -> void:
	DialogueLabel.text = i.text
	DialogueLabel.visible_characters = -1
	if i.speaker_img:
		$DialogueContainer/HBoxContainer/SpeakerParent.visible = true
		SpeakerSprite.texture = i.speaker_img
		SpeakerSprite.hframes = i.speaer_img_Hframes
		SpeakerSprite.frame = min(i.speaker_img_select_frame, i.speaer_img_Hframes - 1)
	else:
		$DialogueContainer/HBoxContainer/SpeakerParent.visible = false
		
	$DialogueContainer/HBoxContainer/VBoxContainer/button_container.visible = true
	
	for child in $DialogueContainer/HBoxContainer/VBoxContainer/button_container.get_children():
		child.queue_free()
		
	for idx in i.choice_text.size():
		var DialogueButtonVar = DialogueButtonPreload.instantiate()
		DialogueButtonVar.text = i.choice_text[idx]
		
		var function_resource: DialogueFunction = i.choice_function_call[idx] if idx < i.choice_function_call.size() else null
		if function_resource:
			var target = get_node_or_null(function_resource.target_path)
			if target:
				DialogueButtonVar.connect("pressed", Callable(target, function_resource.function_name).bindv(function_resource.function_arguments), CONNECT_ONE_SHOT)
				if function_resource.hide_dialogue_box:
					DialogueButtonVar.connect("pressed", hide, CONNECT_ONE_SHOT)
				DialogueButtonVar.connect("pressed", _choice_button_pressed.bind(target, function_resource.wait_for_signal_to_continue), CONNECT_ONE_SHOT)
			else:
				DialogueButtonVar.connect("pressed", _choice_button_pressed.bind(null, ""), CONNECT_ONE_SHOT)
		else:
			DialogueButtonVar.connect("pressed", _choice_button_pressed.bind(null, ""), CONNECT_ONE_SHOT)
			
		$DialogueContainer/HBoxContainer/VBoxContainer/button_container.add_child(DialogueButtonVar)

	if $DialogueContainer/HBoxContainer/VBoxContainer/button_container.get_child_count() > 0:
		$DialogueContainer/HBoxContainer/VBoxContainer/button_container.get_child(0).grab_focus()

func _choice_button_pressed(target_node: Node, wait_for_signal_to_continue: String):
	$DialogueContainer/HBoxContainer/VBoxContainer/button_container.visible = false
	for child in $DialogueContainer/HBoxContainer/VBoxContainer/button_container.get_children():
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
	$AudioStreamPlayer.stream = i.text_sound
	$AudioStreamPlayer.volume_db = i.text_volume_db
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera and i.camera_position != Vector2(999.999, 999.999):
		var camera_tween: Tween = create_tween().set_trans(Tween.TRANS_SINE)
		camera_tween.tween_property(camera, "global_position", i.camera_position, i.camera_transition_time)
	
	if !i.speaker_img:
		$DialogueContainer/HBoxContainer/SpeakerParent.visible = false
	else:
		$DialogueContainer/HBoxContainer/SpeakerParent.visible = true
		SpeakerSprite.texture = i.speaker_img
		SpeakerSprite.hframes = i.speaker_img_Hframes
		SpeakerSprite.frame = 0
		
	DialogueLabel.visible_characters = 0
	DialogueLabel.text = i.text
	var text_without_square_brackets: String = _text_without_square_brackets(i.text)
	var total_characters: int = text_without_square_brackets.length()
	var character_timer: float = 0.0
	
	# Wait 1 frame so the keypress that opened the dialogue isn't read as a skip input
	if not is_inside_tree(): return
	await get_tree().process_frame
	
	# Step 1: Type text (Accept or Cancel skips to the end)
	while DialogueLabel.visible_characters < total_characters:
		if Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("Accept"):
			DialogueLabel.visible_characters = total_characters
			get_viewport().set_input_as_handled()
			break 
		
		character_timer += get_process_delta_time()
		if character_timer >= (1.0 / i.text_speed):
			character_timer = 0.0
			var curr_idx = DialogueLabel.visible_characters
			if curr_idx < total_characters:
				var character: String = text_without_square_brackets[curr_idx]
				DialogueLabel.visible_characters += 1
				if character != " ":
					if i.text_sound:
						$AudioStreamPlayer.pitch_scale = randf_range(i.text_volume_pitch_min, i.text_volume_pitch_max)
						$AudioStreamPlayer.play()
					if i.speaker_img_Hframes > 1:
						SpeakerSprite.frame = (SpeakerSprite.frame + 1) % i.speaker_img_Hframes
		
		if not is_inside_tree(): return
		await get_tree().process_frame
		
	SpeakerSprite.frame = min(i.speaker_img_rest_frame, i.speaker_img_Hframes - 1)
	
	if not is_inside_tree(): return
	await get_tree().process_frame
	
	# Step 2: Wait for Accept key press to advance/close
	while true:
		if not is_inside_tree(): return
		await get_tree().process_frame
		if Input.is_action_just_pressed("Accept"):
			get_viewport().set_input_as_handled()
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

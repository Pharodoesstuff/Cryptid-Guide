extends Area2D

@export var final_dialogue : Resource
@export var dialogue_manager_scene : PackedScene = preload("res://00_Globals/dialogue_system.tscn")
@export var override_position : bool = false
@export var custom_position : Vector2 = Vector2(315, 580)

func _ready() -> void:
	EventBus.keepdark.connect(_keep_dark)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy and body.is_stalking:
		# 1. Stop movement and reveal main form
		body.stop_stalking()
		body.set_revealed(true)
		
		# 2. Play dark-to-regular transition animation and WAIT until it finishes
		if body.animation_player.has_animation("Devil_walk_intro_side"):
			body.animation_player.play("Devil_walk_intro_side")
			await body.animation_player.animation_finished
		
		# 3. Play final dialogue line ONLY after the animation has finished
		var pos = custom_position if override_position else Vector2(-1, -1)
		_play_dialogue_resource(final_dialogue, pos)

func _play_dialogue_resource(res: Resource, custom_pos: Vector2 = Vector2(-1, -1)) -> void:
	if res == null or dialogue_manager_scene == null:
		return

	# Clear any active dialogue boxes on screen
	for existing in get_tree().get_nodes_in_group("dialogue_box"):
		if is_instance_valid(existing):
			existing.queue_free()
		
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

func _keep_dark() -> void:
	queue_free()

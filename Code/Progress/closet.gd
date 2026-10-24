extends Area2D
signal ambush_completed
signal ambush_started

@onready var closet_dialogue: Area2D = $"../../Dialogue/Closet Dialogue"
@onready var monsters_node: Node2D = $"../../Monsters"
@onready var cabin_anim_player: AnimationPlayer = $"../../AnimationPlayer"

@export var base_ambush_duration: float = 5.0 # Initial time player must survive (seconds)
@export var hit_penalty_seconds: float = 1.0   # Extra time added per orb hit

var is_unlocked: bool = false
var event_triggered: bool = false
var ambush_time_remaining: float = 0.0
var ambush_active: bool = false
var player_inside: bool = false

# Camera tracking variables
var initial_camera_pos: Vector2 = Vector2.ZERO
var initial_monsters_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if monsters_node:
		monsters_node.visible = false

	# Restore state if loaded from save
	if SaveManager.has_persistence("closet_ambush_cleared"):
		is_unlocked = true
		event_triggered = true

func _process(delta: float) -> void:
	if player_inside and Input.is_action_just_pressed("Accept") and not event_triggered:
		interact()

	if ambush_active:
		# Lock monsters' position relative to the camera as the player moves
		var camera = get_viewport().get_camera_2d()
		if camera:
			var camera_delta = camera.get_screen_center_position() - initial_camera_pos
			monsters_node.global_position = initial_monsters_pos + camera_delta

		# Countdown fight timer
		ambush_time_remaining -= delta
		if ambush_time_remaining <= 0.0:
			end_monster_ambush()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if SaveManager.has_persistence("book_quiz_passed"):
			unlock_closet()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false

func unlock_closet() -> void:
	is_unlocked = true
	if closet_dialogue:
		closet_dialogue.monitoring = false
		closet_dialogue.visible = false
		closet_dialogue.set_process(false)

func interact() -> void:
	if event_triggered:
		return

	if not is_unlocked:
		if closet_dialogue and closet_dialogue.has_method("interact"):
			closet_dialogue.interact()
	else:
		event_triggered = true
		start_monster_ambush()

func start_monster_ambush() -> void:
	monitoring = false
	monsters_node.visible = true
	monsters_node.global_position = Vector2.ZERO
	
	# Start flapping animation on each monster
	for monster in monsters_node.get_children():
		if monster.has_method("play_flapping_anim"):
			monster.play_flapping_anim()
			
	
	# 1. Play Summon animation and wait for completion
	if cabin_anim_player and cabin_anim_player.has_animation("Summon"):
		EventBus.player_freeze_requested.emit(true)
		cabin_anim_player.play("Summon")
		
		await cabin_anim_player.animation_finished
		ambush_started.emit()
		EventBus.player_freeze_requested.emit(false)
	
	# 2. Transition to Fight animation
	if cabin_anim_player and cabin_anim_player.has_animation("Fight"):
		cabin_anim_player.play("Fight")
		
	# Anchor camera center position for camera tracking
	var camera = get_viewport().get_camera_2d()
	if camera:
		initial_camera_pos = camera.get_screen_center_position()
		initial_monsters_pos = monsters_node.global_position
		
	ambush_time_remaining = base_ambush_duration
	ambush_active = true
	
	# Start orb attack loop
	for monster in monsters_node.get_children():
		if monster.has_method("start_attacking"):
			monster.start_attacking(self)

func add_orb_time_penalty() -> void:
	if ambush_active:
		ambush_time_remaining += hit_penalty_seconds
		print("Hit! +", hit_penalty_seconds, "s added. Remaining: ", ambush_time_remaining)

func end_monster_ambush() -> void:
	ambush_active = false
	print("Monsters retreat!")
	
	for monster in monsters_node.get_children():
		if monster.has_method("stop_attacking"):
			monster.stop_attacking()
			
	if cabin_anim_player and cabin_anim_player.has_animation("Finish"):
		cabin_anim_player.play("Finish")
		await cabin_anim_player.animation_finished
	elif cabin_anim_player and cabin_anim_player.has_animation("RESET"):
		cabin_anim_player.play("RESET")
		
	monsters_node.visible = false
	monsters_node.global_position = Vector2.ZERO
	
	# Save persistence key and notify the level script
	SaveManager.set_persistence("closet_ambush_cleared")
	ambush_completed.emit()

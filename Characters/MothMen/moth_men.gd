extends Node2D

@export var orb_scene: PackedScene = preload("res://Characters/MothMen/Orb.tscn")
@export var attack_cooldown: float = 2.5

# Dropdown in the Inspector matching your exact animation names
@export_enum("Moth", "Moth_Diag", "Moth_Side", "Moth_Idol", "Moth_Diag_Idol", "Moth_Side_Idol") var active_animation: String = "Moth"

# Check this box in the Inspector to flip the monster horizontally (e.g., for right-side monsters)
@export var flip_horizontal: bool = false

@onready var local_anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_timer: Timer = Timer.new()

var closet_ref: Node2D

func _ready() -> void:
	add_child(attack_timer)
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	# Flip sprite direction if requested
	if flip_horizontal:
		scale.x = -1

	# Play assigned animation on load
	if local_anim_player and local_anim_player.has_animation(active_animation):
		local_anim_player.play(active_animation)

func start_attacking(closet: Node2D) -> void:
	closet_ref = closet
	
	# Ensure the active flying animation is playing during combat
	if local_anim_player and local_anim_player.has_animation(active_animation):
		local_anim_player.play(active_animation)
		
	attack_timer.start()

func stop_attacking() -> void:
	attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	if not orb_scene:
		return
		
	var orb = orb_scene.instantiate()
	orb.global_position = global_position
	
	if "closet_ref" in orb:
		orb.closet_ref = closet_ref
		
	var player = get_tree().get_first_node_in_group("player")
	if player:
		orb.direction = (player.global_position - global_position).normalized()
		
	# Spawn in the level scene root so camera/monster movement won't affect active orbs
	get_tree().current_scene.add_child(orb)

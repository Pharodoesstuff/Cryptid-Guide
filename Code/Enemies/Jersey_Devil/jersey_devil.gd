class_name Enemy extends CharacterBody2D

signal direction_changed(new_direction: Vector2)

const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var cardinal_direction: Vector2 = Vector2.DOWN
var direction: Vector2 = Vector2.ZERO
var player : Player

@onready var jersey_devil: Sprite2D = $JerseyDevil
@onready var shadow_2: Sprite2D = $Shadow2
@onready var enemy_state_machine: EnemyStateMachine = $EnemyStateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_hungry: bool = false
var is_revealed: bool = false
var is_stalking: bool = false

@export var stalk_speed: float = 100.0

func _ready():
	EventBus.player_freeze_requested.emit(true)
	enemy_state_machine.initialize(self)
	player = PlayerManager.player
	EventBus.jersey_devil_hungry.connect(_on_jersey_devil_hungry)

func _on_jersey_devil_hungry() -> void:
	is_hungry = true
	EventBus.player_freeze_requested.emit(false)

func start_stalking() -> void:
	is_stalking = true

func stop_stalking() -> void:
	is_stalking = false
	velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if is_stalking and player:
		var stalk_dir = global_position.direction_to(player.global_position)
		velocity = stalk_dir * stalk_speed
		if SetDirection(stalk_dir):
			UpdateAnimation("DDevil")

	move_and_slide()
	
func SetDirection(_new_direction: Vector2) -> bool:
	direction = _new_direction
	if direction == Vector2.ZERO:
		return false
	
	var direction_id: int = int(round(
		(direction + cardinal_direction * 0.1).angle() 
		/ TAU * DIR_4.size()
	))
	var new_dir = DIR_4[posmod(direction_id, DIR_4.size())]
	
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	direction_changed.emit(new_dir)
	jersey_devil.scale.x = 1 if cardinal_direction == Vector2.LEFT else -1
	shadow_2.scale.x = 1 if cardinal_direction == Vector2.LEFT else -1
	return true

func set_revealed(revealed: bool) -> void:
	is_revealed = revealed

func UpdateAnimation(anim_prefix: String) -> void:
	if is_revealed and anim_prefix == "DDevil":
		anim_prefix = "Devil"

	if animation_player.has_animation(anim_prefix):
		animation_player.play(anim_prefix)
		return

	var is_vertical: bool = (cardinal_direction == Vector2.DOWN or cardinal_direction == Vector2.UP)
	var target_anim: String = ""

	if anim_prefix == "Devil":
		target_anim = "Devil_Idol" if is_vertical else "Devil_Side_Walk"
	elif anim_prefix == "DDevil":
		target_anim = "DDevil_idol" if is_vertical else "DDevil_side"
	else:
		target_anim = anim_prefix + "_" + AnimDirection()

	if animation_player.has_animation(target_anim):
		animation_player.play(target_anim)
	else:
		push_error("Animation not found: " + target_anim)

func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN or cardinal_direction == Vector2.UP:
		return "idol"
	else:
		return "side"

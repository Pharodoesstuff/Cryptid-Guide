class_name Player extends CharacterBody2D

signal player_damaged(hurt_box: HurtBox)

var invulnerable: bool = false
var hp: int = 6
var max_hp: int = 6
var can_move: bool = true

var cardinal_direction: Vector2 = Vector2.DOWN
const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var direction: Vector2 = Vector2.ZERO

var look_dir: String = "down"

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effect: AnimationPlayer = $Effect
@onready var hitbox: HitBox = $Hitbox
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $"State Machine"

func _ready():
	add_to_group("player")
	PlayerManager.player = self
	state_machine.Initialize(self)
	hitbox.damaged.connect(_take_damage)
	update_hp(99)

func _process(_delta):
	if !can_move:
		direction = Vector2.ZERO
		return

	# Read directional inputs and normalize vector (prevents fast diagonal movement)
	var raw_dir = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	direction = raw_dir.normalized()

func _physics_process(_delta):
	if !can_move:
		velocity = Vector2.ZERO
		animation_player.play("idle_" + AnimDirection())
		return

	# NOTE: If your individual State Machine state scripts already call 
	# move_and_slide(), remove 'move_and_slide()' from this function!
	move_and_slide()

func SetDirection() -> bool:
	if direction == Vector2.ZERO:
		return false
	
	var direction_id: int = int(round((direction + cardinal_direction * 0.1).angle() / TAU * DIR_4.size()))
	var new_dir = DIR_4[posmod(direction_id, DIR_4.size())]
	
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	look_dir = AnimDirection()
	sprite_2d.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func UpdateAnimation(state: String) -> void:
	animation_player.play(state + "_" + AnimDirection())

func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

func _take_damage(hurt_box: HurtBox) -> void:
	if invulnerable:
		return
	update_hp(-hurt_box.damage)
	
	player_damaged.emit(hurt_box)
	if hp <= 0:
		update_hp(99)

func update_hp(delta: int) -> void:
	hp = clampi(hp + delta, 0, max_hp)

func make_invulnerable(_duration: float = 1.0) -> void:
	invulnerable = true
	hitbox.monitoring = false
	
	await get_tree().create_timer(_duration).timeout
	
	invulnerable = false
	hitbox.monitoring = true
	
# Add to player.gd
func reset_player_state() -> void:
	can_move = true
	velocity = Vector2.ZERO
	direction = Vector2.ZERO

class_name Player extends CharacterBody2D

signal player_damaged(hurt_box: HurtBox)

var is_dead: bool = false

var invulnerable: bool = false
var hp: int = 6
var max_hp: int = 6
var can_move: bool = true

var cardinal_direction: Vector2 = Vector2.DOWN
const DIR_4 = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
var direction: Vector2 = Vector2.ZERO

var look_dir: String = "down"

var is_frozen: bool = false

@export var death_scene: PackedScene 
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var effect: AnimationPlayer = $Effect
@onready var hitbox: HitBox = $Hitbox
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $"State Machine"

func _ready():
	EventBus.player_freeze_requested.connect(_on_player_freeze_requested)
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

# In player.gd
func _take_damage(hurt_box: HurtBox) -> void:
	if invulnerable or is_dead: # <--- Ignore damage if already dying
		return
		
	update_hp(-hurt_box.damage)
	player_damaged.emit(hurt_box)
	
	if hp <= 0:
		is_dead = true
		die.call_deferred(hurt_box.death_type) # Call deferred avoids physics query errors

func die(type: String) -> void:
	visible = false
	process_mode = PROCESS_MODE_DISABLED
	
	# 2. Clear PlayerManager reference
	if PlayerManager.player == self:
		PlayerManager.player = null
		EventBus.off_light.emit()


	# 3. Spawn Death Scene
	if death_scene:
		var death_instance = death_scene.instantiate()
		get_parent().add_child(death_instance)
		death_instance.global_position = global_position
		
		if has_node("Camera2D"):
			$Camera2D.reparent(death_instance)
			
		if death_instance.has_method("setup"):
			death_instance.setup(sprite_2d.scale.x, AnimDirection(), type)

	queue_free()

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

func set_frozen(freeze: bool) -> void:
	can_move = !freeze
	if freeze:
		velocity = Vector2.ZERO
		direction = Vector2.ZERO


func _on_player_freeze_requested(frozen: bool) -> void:
	is_frozen = frozen
	can_move = !frozen
	velocity = Vector2.ZERO
	direction = Vector2.ZERO
	
	if frozen:
		# 1. Switch immediately to the correct idle direction
		animation_player.play("idle_" + AnimDirection())
		
		# 2. Pause the state machine so it doesn't overwrite animations
		if state_machine:
			state_machine.set_process(false)
			state_machine.set_physics_process(false)
	else:
		# Re-enable state machine when unfrozen
		if state_machine:
			state_machine.set_process(true)
			state_machine.set_physics_process(true)

class_name Player extends CharacterBody2D

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var speed : float = 150.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var state_machine: PlayerStateMachine = $"State Machine"

func _ready():
	state_machine.Intialize(self)

func _process( _delta ):
	# 1. Capture the input based on your perfect Input Map
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	# 2. Update the facing direction
	SetDirection() 
	print("Current Direction: ", direction)

func _physics_process( _delta ):
	# 3. Apply the movement speed to the character's velocity
	if direction != Vector2.ZERO:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO
		
	# 4. Physically move the character
	move_and_slide()
	
func SetDirection() -> bool:
	var new_dir : Vector2 = cardinal_direction
	if direction == Vector2.ZERO:
		return false
	
	if direction.y == 0:
		new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	elif direction.x == 0:
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN
	
	if new_dir == cardinal_direction:
		return false
		
	cardinal_direction = new_dir
	sprite_2d.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true
	
func UpdateAnimation( state : String ) -> void:
	animation_player.play( state + "_" + AnimDirection())

func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "side"

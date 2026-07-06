class_name PlayerIdleState extends State

# Creates a slot in the Godot Inspector to link the Walk state
@export var walk_state: State

func Enter() -> void:
	# As soon as the player stops and enters this state, play the idle animation
	player.UpdateAnimation("idle")

func Process(_delta: float) -> State:
	# If the player pushes a movement key, switch to the Walk state
	if player.direction != Vector2.ZERO:
		return walk_state
	
	# Returning null tells the State Machine to stay in the Idle state
	return null

class_name PlayerWalkState extends State

# This creates a slot in the Godot Inspector so we can link the Idle state
@export var idle_state: State

func Enter() -> void:
	# As soon as this state becomes active, play the walk animation
	player.UpdateAnimation("walk")

func Process(_delta: float) -> State:
	# If the player has let go of the movement keys, switch to Idle
	if player.direction == Vector2.ZERO:
		return idle_state
	
	# If they are still holding a key, keep updating the walk animation 
	# (so it instantly switches from walk_down to walk_side if they turn)
	player.UpdateAnimation("walk")
	
	# Returning null tells the State Machine to stay in the Walk state
	return null

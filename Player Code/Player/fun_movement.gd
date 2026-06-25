#This code can be used for fight scenes. Why? Because the player is moving like they're iceskating

"""
extends CharacterBody2D

class_name Player
@export var speed: float = 300.0        # Maximum movement speed (pixels/sec)
@export var acceleration: float = 1200.0 # Rate of speed-up (pixels/sec²)
@export var friction: float = 1200.0     # Rate of slow-down (pixels/sec²)

## Movement Logic
#-----------------------------------------------------------------------------

func get_input_direction() -> Vector2:
	# Get_vector is great because it automatically normalizes the diagonal vector.
	return Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

func handle_movement(direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		# Apply acceleration towards the target velocity (input * max_speed)
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		# Apply friction to smoothly slow down to a stop
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func _physics_process(delta: float) -> void:
	var direction: Vector2 = get_input_direction()
	
	handle_movement(direction, delta)

	# The essential CharacterBody2D function
	move_and_slide()

## Scene Transition/Spawn Logic
#-----------------------------------------------------------------------------
"""

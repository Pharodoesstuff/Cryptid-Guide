class_name State extends Node

# All states will share this player reference
var player: Player

# What happens when we enter the state
func Enter() -> void:
	pass

# What happens when we leave the state
func Exit() -> void:
	pass

# Runs every frame (like _process)
func Process(_delta: float) -> State:
	return null

# Runs every physics frame (like _physics_process) - THIS WAS CAUSING YOUR CRASH!
func Physics(_delta: float) -> State:
	return null

# Handles input events
func HandleInput(_event: InputEvent) -> State:
	return null

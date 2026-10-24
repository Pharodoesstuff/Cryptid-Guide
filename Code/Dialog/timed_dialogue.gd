class_name TimerDialogueStep extends Resource

@export var time: float = 0.0
@export var dialogue: DE # Changed from Array[DE] to DE to match void.tscn

@export_group("Positioning")
@export var override_position: bool = false
@export var custom_position: Vector2 = Vector2.ZERO

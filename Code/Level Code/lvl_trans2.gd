extends Area2D

enum TriggerMode {
	AREA_ENTER,      # Triggers when the player walks into the collision area
	BUTTON_PRESS,    # Triggers when the player presses an interact button inside the area
	AUTOMATIC_TIMER  # Triggers automatically after X seconds upon entering the room
}

@export_category("Level Settings")
@export_file("*.tscn") var level_path: String
@export var target_transition: String = ""
@export var position_offset: Vector2 = Vector2.ZERO

@export_category("Trigger Configuration")
@export var trigger_mode: TriggerMode = TriggerMode.AREA_ENTER

## How many interactions/touches required before transitioning
@export var required_interactions: int = 1

## Seconds to wait if Trigger Mode is set to AUTOMATIC_TIMER
@export var timer_delay: float = 3.0

@export_category("One-Shot Settings")
## If true, this transition will deactivate forever after being used once
@export var is_one_shot: bool = false

## Give this a unique name if you want the "one-shot" status to save permanently across room changes
@export var transition_id: String = ""

var current_interactions: int = 0
var is_disabled: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Restore disabled status if tracked globally in PlayerManager
	if is_one_shot and transition_id != "":
		var used_list: Array = PlayerManager.get("used_transitions") if "used_transitions" in PlayerManager else []
		if transition_id in used_list:
			_disable_transition()
			return

	# Handle auto-timer trigger on level load
	if trigger_mode == TriggerMode.AUTOMATIC_TIMER:
		_start_timer_transition()

func _on_body_entered(body: Node2D) -> void:
	if is_disabled:
		return
		
	if _is_player(body):
		if trigger_mode == TriggerMode.AREA_ENTER:
			interact()

## Call this function manually (e.g. from player interaction key) or automatically on area enter
func interact() -> void:
	if is_disabled:
		return

	current_interactions += 1
	
	if current_interactions >= required_interactions:
		_trigger_scene_change()

func _start_timer_transition() -> void:
	await get_tree().create_timer(timer_delay).timeout
	
	# Only execute if this transition node is still alive in the active scene tree
	if is_inside_tree() and not is_disabled:
		_trigger_scene_change()

func _trigger_scene_change() -> void:
	if is_disabled:
		return

	if is_one_shot:
		_disable_transition()
		_save_one_shot_state()

	# Calls your exact LevelManager routine without altering it
	LevelManager.load_new_level(level_path, target_transition, position_offset)

func _disable_transition() -> void:
	is_disabled = true
	# Deferred calls prevent physics locking errors during body_entered signals
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

func _save_one_shot_state() -> void:
	if transition_id != "":
		if transition_id not in PlayerManager.used_transitions:
			PlayerManager.used_transitions.append(transition_id)

func _is_player(body: Node2D) -> bool:
	return body is Player or body.name == "Player" or body.is_in_group("player")

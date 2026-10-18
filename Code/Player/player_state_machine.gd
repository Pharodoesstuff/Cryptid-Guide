class_name PlayerStateMachine extends Node

var states : Array[ State ]
var prev_state : State
var current_state : State

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	if current_state:
		change_State(current_state.Process(delta))

# Fixed: Changed from 'Physics' to '_physics_process' for Godot engine call
func _physics_process(delta: float) -> void:
	if current_state:
		change_State(current_state.Physics(delta))

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		change_State( current_state.HandleInput( event ))

func Initialize( _player : Player) -> void: # Fixed typo
	states = []
	
	for c in get_children():
		if c is State:
			states.append(c)
	
	if states.size() == 0:
		return
		
	states[0].player = _player
	states[0].state_machine = self
	
	for state in states:
		state.init()
		
	change_State( states[0])
	process_mode = Node.PROCESS_MODE_INHERIT

func change_State( new_state : State) -> void:
	if new_state == null || new_state == current_state:
		return
	
	if current_state:
		current_state.Exit()
	
	prev_state = current_state
	current_state = new_state
	current_state.Enter()

class_name PlayerStateMachine extends Node

@export var initial_state: PlayerState

var states: Array[PlayerState]
var current_state: PlayerState

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func _process(delta: float) -> void:
	change_state(current_state.update(delta))

func _physics_process(delta: float) -> void:
	change_state(current_state.physics_update(delta))

func _unhandled_input(event: InputEvent) -> void:
	change_state(current_state.handle_input(event))

func initialize(_player: CharacterBody2D) -> void:
	states = []
	
	for child in get_children():
		if child is PlayerState:
			states.append(child)
	
	if states.size() > 0:
		states[0].player = _player
		change_state(states[0])
		process_mode = Node.PROCESS_MODE_INHERIT

func change_state(new_state: PlayerState) -> void:
	if new_state == null or new_state == current_state:
		return
	
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()

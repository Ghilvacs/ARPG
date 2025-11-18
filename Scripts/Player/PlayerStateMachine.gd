class_name PlayerStateMachine
extends Node

@export var initial_state: PlayerState

var states: Array[PlayerState] = []
var current_state: PlayerState


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:
	if current_state == null:
		return
	change_state(current_state.update(delta))


func _physics_process(delta: float) -> void:
	if current_state == null:
		return
	change_state(current_state.physics_update(delta))


func _unhandled_input(event: InputEvent) -> void:
	if current_state == null:
		return
	change_state(current_state.handle_input(event))


func initialize(_player: CharacterBody2D) -> void:
	states.clear()

	# Collect all PlayerState children and assign the player reference
	for child in get_children():
		if child is PlayerState:
			states.append(child)
			child.player = _player

	if states.is_empty():
		push_error("PlayerStateMachine has no PlayerState children.")
		return

	# Enable processing now that we are set up
	process_mode = Node.PROCESS_MODE_INHERIT

	# Decide the starting state
	var starting_state: PlayerState = initial_state

	# If nothing set in the inspector, fall back to the first state
	if starting_state == null:
		starting_state = states[0]

	# Actually set current_state here
	change_state(starting_state)


func change_state(new_state: PlayerState) -> void:
	if new_state == null or new_state == current_state:
		return

	if current_state:
		current_state.exit()

	current_state = new_state
	current_state.enter()

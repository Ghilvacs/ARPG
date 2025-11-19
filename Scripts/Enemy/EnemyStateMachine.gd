extends Node
class_name EnemyStateMachine

@export var initial_state: EnemyState
@export var enemy: CharacterBody2D:
	set(value):
		enemy = value
		_assign_enemy_to_states()

@export var dead_state: EnemyState

var current_state: EnemyState
var states: Array[EnemyState] = []


func _ready() -> void:
	_collect_states()

	assert(states.size() > 0, "EnemyStateMachine: no EnemyState children found.")

	if initial_state:
		current_state = initial_state
	else:
		current_state = states[0]

	current_state.enter(null)


func _collect_states() -> void:
	states.clear()
	for child in get_children():
		if child is EnemyState:
			var state := child as EnemyState
			state.state_machine = self
			states.append(state)

	_assign_enemy_to_states()


func _assign_enemy_to_states() -> void:
	if enemy == null:
		return
	for state in states:
		state.enemy = enemy


func _process(delta: float) -> void:
	if current_state == null:
		return

	var next_state := current_state.update(delta)
	_change_state(next_state)


func _physics_process(delta: float) -> void:
	if current_state == null:
		return

	var next_state := current_state.physics_update(delta)
	_change_state(next_state)


func _unhandled_input(event: InputEvent) -> void:
	if current_state == null:
		return

	var next_state := current_state.handle_input(event)
	_change_state(next_state)


func _change_state(new_state: EnemyState) -> void:
	if new_state == null or new_state == current_state:
		return

	var prev := current_state
	
	current_state.exit()
	current_state = new_state
	current_state.enter(prev)

extends Node

signal level_load_started
signal level_loaded

var target_transition: String
var position_offset: Vector2
var enemy_states = {}
var item_states = {}

func _ready() -> void:
	pass


func load_new_level(
		level_path: String,
		_target_transition: String,
		_position_offset: Vector2
) -> void:
	
	ScreenFader.fade_out(0.5)
	await get_tree().create_timer(0.5).timeout  # wait for fade
	
	get_tree().paused = true
	target_transition = _target_transition
	position_offset = _position_offset
	
	level_load_started.emit()
	
	await get_tree().process_frame
	await get_tree().change_scene_to_file(level_path)
	
	await get_tree().process_frame
	get_tree().paused = false
	
	get_tree().paused = false
	await get_tree().process_frame
	
	level_loaded.emit()
	ScreenFader.fade_in(0.5)


func record_enemy_state(id: String, alive: bool) -> void:
	enemy_states[id] = alive


func is_enemy_alive(id: String) -> bool:
	return enemy_states.get(id, true)


func record_item_state(id: String, in_place: bool) -> void:
	item_states[id] = in_place


func is_item_in_place(id: String) -> bool:
	return item_states.get(id, true)

extends Node

signal level_load_started
signal level_loaded

var target_transition: String
var position_offset: Vector2

func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()

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
	
	await get_tree().process_frame
	level_load_started.emit()
	
	await get_tree().process_frame
	get_tree().change_scene_to_file(level_path)
	
	await get_tree().process_frame
	get_tree().paused = false
	
	await get_tree().process_frame
	level_loaded.emit()
	ScreenFader.fade_in(0.5)

extends Node

const SAVE_PATH = "user://"

signal game_saved
signal game_loaded

var can_save: bool = false

var current_save: Dictionary = {
	scene_path = "",
	player = {
		hp = 1,
		max_hp = 1,
		pos_x = 0,
		pos_y = 0
	},
	items = [],
	persistence = [],
	quests = []
}


func save_game() -> void:
	update_scene_path()
	update_player_data()
	var file := FileAccess.open(SAVE_PATH + "save.sav", FileAccess.WRITE)
	var save_json = JSON.stringify(current_save)
	file.store_line(save_json)
	game_saved.emit()


func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH + "save.sav", FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_line())
	var save_dictionary: Dictionary = json.get_data() as Dictionary
	current_save = save_dictionary
	
	GlobalLevelManager.load_new_level(
		current_save.scene_path,
		 "",
		 Vector2(current_save.player.pos_x, current_save.player.pos_y))
	
	await GlobalLevelManager.level_load_started
	
	GlobalPlayerManager.set_player_position(Vector2(current_save.player.pos_x, current_save.player.pos_y))
	GlobalPlayerManager.set_player_health(current_save.player.hp, current_save.player.max_hp)
	
	await GlobalLevelManager.level_loaded
	
	game_loaded.emit()


func update_player_data() -> void:
	var player: CharacterBody2D = GlobalPlayerManager.player
	current_save.player.hp = player.current_health
	current_save.player.max_hp = player.MAX_HEALTH
	current_save.player.pos_x = player.global_position.x
	current_save.player.pos_y = player.global_position.y


func update_scene_path() -> void:
	var path: String = ""
	for child in get_tree().root.get_children():
		if child is Level:
			path = child.scene_file_path
	current_save.scene_path = path


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_save:
		save_game()
		get_viewport().set_input_as_handled()


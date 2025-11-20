extends Node

const SAVE_PATH = "user://"
const FIRST_LEVEL_PATH := "res://Scenes/Level/Level00Tutorial/room01.tscn"
signal game_saved
signal game_loaded

var can_save: bool = false

var current_save: Dictionary = {
	scene_path = "",
	player = {
		hp = 5,
		max_hp = 5,
		stamina = 100,
		pos_x = 0,
		pos_y = 0
	},
	items = [],
	persistence = {},
	quests = []
}


func save_game() -> void:
	update_scene_path()
	update_player_data()
	current_save.persistence = GlobalLevelManager.enemy_states
	var file := FileAccess.open(SAVE_PATH + "save.sav", FileAccess.WRITE)
	var save_json = JSON.stringify(current_save)
	file.store_line(save_json)
	game_saved.emit()


func load_game() -> void:
	if not has_save():
		return
	
	var file := FileAccess.open(SAVE_PATH + "save.sav", FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_line())
	var save_dictionary: Dictionary = json.get_data() as Dictionary
	current_save = save_dictionary
	
	if current_save.has("persistence"):
		GlobalLevelManager.enemy_states = current_save.persistence
	else:
		GlobalLevelManager.enemy_states = {}
	
	GlobalLevelManager.load_new_level(
		current_save.scene_path,
		"",
		Vector2.ZERO
	)
	
	await GlobalLevelManager.level_loaded
	
	var saved_position := Vector2(
		current_save.player.pos_x,
		current_save.player.pos_y
	)
	
	GlobalPlayerManager.set_player_position(saved_position)
	GlobalPlayerManager.set_player_health(
		current_save.player.hp, 
		current_save.player.max_hp
	)
	
	game_loaded.emit()
	
#
#	GlobalLevelManager.load_new_level(
#		current_save.scene_path,
#		 "",
#		 Vector2(current_save.player.pos_x, current_save.player.pos_y))
#
#	await GlobalLevelManager.level_load_started
#
#	GlobalPlayerManager.set_player_position(Vector2(current_save.player.pos_x, current_save.player.pos_y))
#	GlobalPlayerManager.set_player_health(current_save.player.hp, current_save.player.max_hp)
#
#	await GlobalLevelManager.level_loaded
#
#	game_loaded.emit()


func update_player_data() -> void:
	var player: CharacterBody2D = GlobalPlayerManager.player
	current_save.player.hp = player.current_health
	current_save.player.max_hp = player.MAX_HEALTH
	current_save.player.stamina = player.current_stamina
	current_save.player.pos_x = player.global_position.x
	current_save.player.pos_y = player.global_position.y


func update_scene_path() -> void:
	var path: String = ""
	for child in get_tree().root.get_children():
		if child is Level:
			path = child.scene_file_path
	current_save.scene_path = path


func soft_save() -> void:
	update_scene_path()
	update_player_data()


func reset_game() -> void:
	# 1) Reset in-memory save data to default values
	current_save = {
		scene_path = FIRST_LEVEL_PATH,
		player = {
			hp = 5,         # put your real MAX_HEALTH here
			max_hp = 5,
			pos_x = 0,
			pos_y = 0
		},
		items = [],
		persistence = {},   # enemy_states or other persistence
		quests = []
	}

	# 2) Clear runtime enemy persistence
	GlobalLevelManager.enemy_states.clear()

	# 3) Actually reload the first level using your existing level flow
	GlobalLevelManager.load_new_level(
		FIRST_LEVEL_PATH,
		"",
		Vector2.ZERO
	)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH + "save.sav")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and can_save:
		save_game()
		get_viewport().set_input_as_handled()


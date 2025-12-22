extends Node

const SAVE_PATH = "user://"
const FIRST_LEVEL_PATH := "res://Scenes/Level/Level00Tutorial/room01.tscn"
signal game_saved
signal game_loaded

var can_save: bool = false

func save_game() -> void:
	update_scene_path()
	update_player_data()
	update_item_data()
	GameState.save_data.enemy_persistence = GlobalLevelManager.enemy_states
	var file := FileAccess.open(SAVE_PATH + "save.sav", FileAccess.WRITE)
	var save_json = JSON.stringify(GameState.save_data)
	file.store_line(save_json)
	game_saved.emit()


func load_game() -> void:
	if not has_save():
		return
	
	var file := FileAccess.open(SAVE_PATH + "save.sav", FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_line())
	var save_dictionary: Dictionary = json.get_data() as Dictionary
	GameState.save_data = save_dictionary
	
	if GameState.save_data.has("enemy_persistence"):
		GlobalLevelManager.enemy_states = GameState.save_data.enemy_persistence
	else:
		GlobalLevelManager.enemy_states = {}

	
	GlobalLevelManager.load_new_level(
		GameState.save_data.scene_path,
		"",
		Vector2.ZERO
	)
	
	GlobalPlayerManager.INVENTORY_DATA.parse_save_data(GameState.save_data.items)
	
	await GlobalLevelManager.level_loaded
	
	var saved_position := Vector2(
		GameState.save_data.player.pos_x,
		GameState.save_data.player.pos_y
	)
	
	GlobalPlayerManager.set_player_position(saved_position)
	GlobalPlayerManager.set_player_health(
		GameState.save_data.player.hp, 
		GameState.save_data.player.max_hp
	)
	
	game_loaded.emit()


func update_player_data() -> void:
	var player: CharacterBody2D = GlobalPlayerManager.player
	GameState.save_data.player.hp = player.current_health
	GameState.save_data.player.max_hp = player.MAX_HEALTH
	GameState.save_data.player.stamina = player.current_stamina
	GameState.save_data.player.pos_x = player.global_position.x
	GameState.save_data.player.pos_y = player.global_position.y


func update_scene_path() -> void:
	var path: String = ""
	for child in get_tree().root.get_children():
		if child is Level:
			path = child.scene_file_path

	GameState.save_data.scene_path = path


func update_item_data() -> void:
	GameState.save_data.items = GlobalPlayerManager.INVENTORY_DATA.get_save_data()


func add_persistent_value(value: String) -> void:
	if check_persistent_value(value) == false:
		GameState.save_data.persistence.append(value)


func check_persistent_value(value: String) -> bool:
	var peristent_item = GameState.save_data.persistence as Array
	return peristent_item.has(value)


func soft_save() -> void:
	update_scene_path()
	update_player_data()
	update_item_data()


func reset_game() -> void:
	GameState.save_data = {
		scene_path = FIRST_LEVEL_PATH,
		player = {
			hp = 5,
			max_hp = 5,
			pos_x = 0,
			pos_y = 0
		},
		items = [],
		enemy_persistence = [],
		persistence = [],
		quests = []
	}

	GlobalLevelManager.enemy_states.clear()
	GlobalLevelManager.item_states.clear()

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


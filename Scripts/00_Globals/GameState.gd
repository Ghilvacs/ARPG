extends Node

var save_data: Dictionary = {
	scene_path = "",
	player = {
		hp = 5,
		max_hp = 5,
		stamina = 100,
		pos_x = 0.0,
		pos_y = 0.0,
	},
	items = [],
	enemy_persistence = [],
	persistence = [],
	quests = []
}

func to_dict() -> Dictionary:
	return save_data

func from_dict(data: Dictionary) -> void:
	save_data = data.duplicate(true)
	var scene_path = save_data.scene_path

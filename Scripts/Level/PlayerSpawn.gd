extends Node2D

func _ready() -> void:
	visible = false
	if not GlobalPlayerManager.player_spawned:
		GlobalPlayerManager.set_player_position(global_position)
		GlobalPlayerManager.player_spawned = true

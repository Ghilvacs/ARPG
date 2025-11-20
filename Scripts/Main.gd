extends Node2D

const FIRST_LEVEL_PATH := "res://Scenes/Level/Level00Tutorial/room01.tscn"

func _ready() -> void:
	# Wait a frame to be 100% sure everything is in the tree
	await get_tree().process_frame
	GlobalLevelManager.load_new_level(
		FIRST_LEVEL_PATH,
		"",              # target_transition (if you use it later)
		Vector2.ZERO     # position_offset default
	)

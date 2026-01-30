class_name Level extends Node2D

func _ready() -> void:
	self.y_sort_enabled = true
	GlobalLevelManager.level_load_started.connect(_free_level)


func _free_level() -> void:
	queue_free()

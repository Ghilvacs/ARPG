class_name InteractableArea extends Area2D

@onready var label_save_game: Label = $LabelSaveGame
@onready var game_is_saved_label: Label = $GameIsSavedLabel

@export var save_area: bool = false
@export var container: bool = false
@export var door: bool = false

func _ready() -> void:
	GlobalSaveManager.connect("game_saved", Callable(self, "_on_game_saved"))
	body_entered.connect(_player_entered)
	body_exited.connect(_player_exited)


func _player_entered(_p: Node2D) -> void:
	if _p.is_in_group("Player"):
		if save_area:
			label_save_game.visible = true
			GlobalSaveManager.can_save = true


func _player_exited(_p: Node2D) -> void:
	if _p.is_in_group("Player"):
		label_save_game.visible = false
		GlobalSaveManager.can_save = false
		game_is_saved_label.visible = false


func _on_game_saved() -> void:
	if save_area:
		label_save_game.visible = false
		game_is_saved_label.visible = true

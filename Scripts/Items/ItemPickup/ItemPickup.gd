@tool

class_name ItemPickup extends Node2D

@export var item_data: ItemData: set = _set_item_data

@onready var area_2d: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	
	if Engine.is_editor_hint():
		return


func _set_item_data(value: ItemData) -> void:
	item_data = value

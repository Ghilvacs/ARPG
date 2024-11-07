extends ProgressBar

@export var player: CharacterBody2D

func _ready() -> void:
	update(player.current_health)

func update(current_health: int):
	value = current_health * 100 / player.MAX_HEALTH

func _on_player_health_changed(current_health) -> void:
	update(current_health)

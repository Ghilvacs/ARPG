extends ProgressBar

@export var player: CharacterBody2D

func _ready() -> void:
	update(player.current_stamina)

func update(current_stamina: int):
	value = current_stamina * 100 / player.MAX_STAMINA

func _on_player_stamina_changed(current_stamina) -> void:
	update(current_stamina)

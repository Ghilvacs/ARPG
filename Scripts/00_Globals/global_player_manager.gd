extends Node

const PLAYER = preload("res://Scenes/Player/player.tscn")
var player: CharacterBody2D
var player_spawned: bool = false

signal PlayerSpawned(player: CharacterBody2D)
signal PlayerDespawned

func _ready() -> void:
	add_player_instance(get_tree().current_scene)
	await get_tree().create_timer(0.2).timeout
	player_spawned = true

func add_player_instance(parent: Node) -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	player = PLAYER.instantiate()
	parent.add_child(player)
	emit_signal("PlayerSpawned", player)
	player.connect("PlayerDied", Callable(self, "_on_player_died"))

func set_player_position(_new_position: Vector2) -> void:
	player.global_position = _new_position

func _on_player_died():
	emit_signal("PlayerDespawned")
	player.call_deferred("queue_free")
	player = null
#	await get_tree().create_timer(1.0).timeout
	add_player_instance(get_tree().current_scene)

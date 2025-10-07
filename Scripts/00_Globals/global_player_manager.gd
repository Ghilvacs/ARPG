extends Node

const PLAYER = preload("res://Scenes/Player/player.tscn")
var player: CharacterBody2D
var camera: Camera2D
var player_spawned: bool = false

signal PlayerSpawned(player: CharacterBody2D)
signal PlayerDespawned

func _ready() -> void:
	GlobalLevelManager.level_loaded.connect(_on_level_loaded)
	_spawn_player()

func _spawn_player() -> void:
	if not player or !is_instance_valid(player):
		player = PLAYER.instantiate()
		add_child(player) # Add to the manager (autoload)
		
	var level = get_tree().current_scene
	if level && player.get_parent() != level:
		level.add_child(player)

		# Set position from PlayerSpawn node if available
		var spawn = level.get_node_or_null("PlayerSpawn")
		if spawn:
			player.global_position = spawn.global_position

	camera = player.get_node("Camera2D")
	emit_signal("PlayerSpawned", player)
	player.connect("PlayerDied", Callable(self, "_on_player_died"))

	_apply_camera_bounds()
	player_spawned = true

func set_player_position(_new_position: Vector2) -> void:
	if player and is_instance_valid(player):
		player.global_position = _new_position

func _on_player_died():
	emit_signal("PlayerDespawned")
	if player and is_instance_valid(player):
		player.queue_free()
		player = null
	_spawn_player()

func _apply_camera_bounds():
	var level = get_tree().current_scene
	if not level: return

	var bounds = level.get_node_or_null("CameraBounds/CollisionShape2D")
	if bounds:
		var shape = bounds.shape as RectangleShape2D
		var size = shape.extents * 2.0
		var rect = Rect2(bounds.global_position - shape.extents, size)
		var target_position = camera.global_position

		target_position.x = clamp(target_position.x, rect.position.x, rect.position.x + rect.size.x)
		target_position.y = clamp(target_position.y, rect.position.y, rect.position.y + rect.size.y)
		camera.global_position = target_position

		camera.limit_left = rect.position.x
		camera.limit_top = rect.position.y
		camera.limit_right = rect.position.x + rect.size.x
		camera.limit_bottom = rect.position.y + rect.size.y

func despawn_player() -> void:
	var level = get_tree().current_scene
	if level:
		level.remove_child(player)

func _on_level_loaded():
	_spawn_player()

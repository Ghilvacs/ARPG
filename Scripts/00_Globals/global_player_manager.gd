extends Node

const PLAYER = preload("res://Scenes/Player/player.tscn")
var player: CharacterBody2D
var camera: Camera2D
var player_spawned: bool = false
var has_saved_state: bool = false
var saved_health: int = -1
var saved_stamina: float = -1.0

signal PlayerSpawned(player: CharacterBody2D)
signal PlayerDespawned


func _ready() -> void:
	GlobalLevelManager.level_loaded.connect(_on_level_loaded)


func _spawn_player() -> void:
	var level = get_tree().current_scene
	if level == null:
		return

	# 1. Create player if it doesn't exist
	if player == null or !is_instance_valid(player):
		player = PLAYER.instantiate()

	# 2. Make sure the player is a child of the current level
	if player.get_parent() != level:
		level.add_child(player)

	# 3. Get spawn point from Level
	var spawn := level.get_node_or_null("PlayerSpawn") as Node2D
	if spawn:
		player.global_position = spawn.global_position
	else:
		# Fallback if no spawn marker exists
		player.global_position = GlobalLevelManager.position_offset
	
	player.current_health = GameState.save_data.player.hp
	player.update_health(0)
	
	# 4. Hook up camera, signals, bounds
	camera = player.get_node("Camera2D")
	if camera.has_method("reset_smoothing"):
		camera.reset_smoothing()
	_apply_camera_bounds()

	if not player.is_connected("PlayerDied", Callable(self, "_on_player_died")):
		player.connect("PlayerDied", Callable(self, "_on_player_died"))

	_apply_camera_bounds()
	player_spawned = true
	emit_signal("PlayerSpawned", player)


func set_player_health(hp: int, max_hp: int) -> void:
	player.current_health = hp
	player.update_health(0)


func set_player_position(_new_position: Vector2) -> void:
	if player and is_instance_valid(player):
		player.global_position = _new_position


func teleport_player(new_position: Vector2) -> void:
	if player and is_instance_valid(player):
		player.global_position = new_position

		if camera and is_instance_valid(camera) and camera.has_method("reset_smoothing"):
			camera.reset_smoothing()


func _on_player_died():
	emit_signal("PlayerDespawned")
	
	if player != null and is_instance_valid(player):
		player.queue_free()
	
	player = null
	player_spawned = false
	
	if GlobalSaveManager.has_save():
		GlobalSaveManager.load_game()
	else:
		GlobalSaveManager.reset_game()


func _apply_camera_bounds():
	var level = get_tree().current_scene
	if not level:
		return

	var bounds = level.get_node_or_null("CameraBounds/CollisionShape2D")
	if bounds:
		var shape := bounds.shape as RectangleShape2D
		var size = shape.extents * 2.0
		var rect := Rect2(bounds.global_position - shape.extents, size)

		# Only set limits – do NOT touch camera.global_position
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

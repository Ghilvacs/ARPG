extends EnemyState
class_name EnemyWander

@export_category("Movement")
@export var move_speed: float = 40.0

@export_category("State Transitions")
@export var follow_state: EnemyState      # chase state (EnemyFollow)
@export var attack_state: EnemyState      # optional: direct Attack from idle (TNT / others)
@export var knockback_state: EnemyState
@export var dead_state: EnemyState        # optional, falls back to state_machine.dead_state

@export_category("Areas")
@export var detection_area: Area2D        # optional; fallback to enemy.DetectionArea
@export var attack_area: Area2D           # optional; fallback to enemy.AttackArea

var player: CharacterBody2D
var move_direction: Vector2
var wander_time: float

var player_in_detection_range: bool = false
var player_in_attack_range: bool = false


func enter(_prev_state: EnemyState) -> void:
	_ensure_player_connections()
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D

	randomize_wander()

	player_in_detection_range = false
	player_in_attack_range = false


func exit() -> void:
	pass


func randomize_wander() -> void:
	move_direction = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	wander_time = randf_range(1.0, 3.0)


func update(delta: float) -> EnemyState:
	# Simple wander timer logic
	if wander_time > 0.0:
		wander_time -= delta
	else:
		randomize_wander()

	# No direct transition from update; we decide in physics_update
	return null


func physics_update(_delta: float) -> EnemyState:
	if enemy == null:
		return null

	# --- Highest priority: death / knockback ---
	if enemy.dead and dead_state:
		return dead_state

	if enemy.hit and knockback_state:
		return knockback_state

	# --- Respect idle / transitionLocked if an enemy still uses them ---
	if ("idle" in enemy and enemy.idle) or ("transitionLocked" in enemy and enemy.transitionLocked):
		if "velocity" in enemy:
			enemy.velocity = Vector2.ZERO
		return null

	# --- Movement ---
	enemy.velocity = move_direction * move_speed

	# --- Combat-related transitions ---
	if player_in_attack_range and attack_state and _is_player_valid():
		return attack_state

	if player_in_detection_range and follow_state and _is_player_valid():
		return follow_state

	# Otherwise, keep wandering
	return null


func _is_player_valid() -> bool:
	return player != null and player.current_health > 0


func _ensure_player_connections() -> void:
	if not GlobalPlayerManager.is_connected("PlayerSpawned", Callable(self, "_on_player_spawned")):
		GlobalPlayerManager.connect("PlayerSpawned", Callable(self, "_on_player_spawned"))

	if not GlobalPlayerManager.is_connected("PlayerDespawned", Callable(self, "_on_player_despawned")):
		GlobalPlayerManager.connect("PlayerDespawned", Callable(self, "_on_player_despawned"))

	if enemy == null:
		return

	# Detection
	if detection_area == null and enemy.has_node("DetectionArea"):
		detection_area = enemy.get_node("DetectionArea") as Area2D

	if detection_area:
		if not detection_area.is_connected("body_entered", Callable(self, "_on_detection_area_entered")):
			detection_area.connect("body_entered", Callable(self, "_on_detection_area_entered"))
		if not detection_area.is_connected("body_exited", Callable(self, "_on_detection_area_exited")):
			detection_area.connect("body_exited", Callable(self, "_on_detection_area_exited"))

	# Attack (optional)
	if attack_area == null and enemy.has_node("AttackArea"):
		attack_area = enemy.get_node("AttackArea") as Area2D

	if attack_area:
		if not attack_area.is_connected("body_entered", Callable(self, "_on_attack_area_entered")):
			attack_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))
		if not attack_area.is_connected("body_exited", Callable(self, "_on_attack_area_exited")):
			attack_area.connect("body_exited", Callable(self, "_on_attack_area_exited"))


func _on_detection_area_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_detection_range = true


func _on_detection_area_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_detection_range = false


func _on_attack_area_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_attack_range = true


func _on_attack_area_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_attack_range = false


func _on_player_spawned(_player: CharacterBody2D) -> void:
	player = _player


func _on_player_despawned() -> void:
	player = null
	player_in_detection_range = false
	player_in_attack_range = false

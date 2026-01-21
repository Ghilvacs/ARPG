extends EnemyState
class_name EnemyWander

@export_category("Movement")
@export var move_speed: float = 40.0

@export_category("Wander Tuning")
@export var min_move_time: float = 1.0
@export var max_move_time: float = 3.0
@export var min_idle_time: float = 0.5
@export var max_idle_time: float = 1.5
@export var turn_lerp_speed: float = 5.0

@export_category("Detection Tuning")
@export var detection_confirm_time: float = 0.1  # how long player must stay in cone

@export_category("Wall Avoidance")
@export var avoid_walls: bool = true
@export var wall_check_distance: float = 8.0   # how far ahead we test for a wall
@export var wall_turn_min_time: float = 0.5    # new wander_time after turning
@export var wall_turn_max_time: float = 2.0

@export_category("State Transitions")
@export var follow_state: EnemyState      # chase state (EnemyFollow)
@export var attack_state: EnemyState      # optional: direct Attack from idle (TNT / others)
@export var knockback_state: EnemyState
@export var dead_state: EnemyState        # optional, falls back to state_machine.dead_state

@export_category("Areas")
@export var detection_area: Area2D        # optional; fallback to enemy.DetectionArea
@export var attack_area: Area2D           # optional; fallback to enemy.AttackArea

var player: CharacterBody2D
var move_direction_current: Vector2 = Vector2.ZERO
var move_direction_target: Vector2 = Vector2.ZERO
var phase_time: float
enum WanderPhase { MOVING, IDLE }
var phase: int = WanderPhase.IDLE
var detection_accumulator: float = 0.0

var player_in_detection_range: bool = false
var player_in_attack_range: bool = false


func enter(_prev_state: EnemyState) -> void:
	_ensure_player_connections()
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	enemy.isAttacking = false

	player_in_detection_range = false
	player_in_attack_range = false

	# Start in idle or moving, as you prefer
	_start_idle_phase()


func exit() -> void:
	pass


func update(delta: float) -> EnemyState:
	if phase_time > 0.0:
		phase_time -= delta
	else:
		# Switch between moving and idle
		if phase == WanderPhase.MOVING:
			_start_idle_phase()
		else:
			_start_move_phase()

	# No direct transition here; physics_update handles combat transitions
	return null


func physics_update(_delta: float) -> EnemyState:
	if enemy == null:
		print("Wander: enemy is null")
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

	if avoid_walls and phase == WanderPhase.MOVING and _is_heading_into_wall(_delta):
		_turn_away_from_wall()
	
	# --- Movement ---
	match phase:
		WanderPhase.IDLE:
			enemy.velocity = Vector2.ZERO

		WanderPhase.MOVING:
			# Gradually turn current direction towards target
			if move_direction_target != Vector2.ZERO:
				move_direction_current = move_direction_current.lerp(
					move_direction_target,
					turn_lerp_speed * _delta
				)

			if move_direction_current.length() > 0.1:
				enemy.velocity = move_direction_current.normalized() * move_speed
			else:
				enemy.velocity = Vector2.ZERO

	if player_in_attack_range and attack_state and _is_player_valid():
		return attack_state

# Smooth detection: don't switch to follow on a single-frame edge touch
	var detected_now := false
	if detection_area and _is_player_valid():
		detected_now = detection_area.overlaps_body(player)

	if detected_now:
		detection_accumulator += _delta
	else:
		detection_accumulator = 0.0

	if detection_accumulator >= detection_confirm_time and follow_state and _is_player_valid():
		return follow_state

	# Otherwise, keep wandering
	return null


func _start_move_phase() -> void:
	phase = WanderPhase.MOVING
	phase_time = randf_range(min_move_time, max_move_time)

	# Pick a new target direction, but don't instantly snap current
	move_direction_target = Vector2(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()

	# If we were completely stopped, start from target
	if move_direction_current == Vector2.ZERO:
		move_direction_current = move_direction_target


func _start_idle_phase() -> void:
	phase = WanderPhase.IDLE
	phase_time = randf_range(min_idle_time, max_idle_time)
	enemy.velocity = Vector2.ZERO


func _is_heading_into_wall(delta: float) -> bool:
	if enemy == null:
		return false

	if move_direction_current == Vector2.ZERO:
		return false

	# Look a bit ahead in the direction we're currently moving.
	var motion := move_direction_current.normalized() * wall_check_distance
	# If you prefer, you can incorporate speed:
	# var motion := move_direction_current.normalized() * (wall_check_distance + move_speed * delta * 0.25)

	return enemy.test_move(enemy.transform, motion)


func _turn_away_from_wall() -> void:
	if move_direction_current == Vector2.ZERO:
		return

	# Base "away" direction is opposite our current movement
	var away_dir := -move_direction_current.normalized()

	# Pick a side to slide along (left or right)
	var side := -1.0 if randf() < 0.5 else 1.0

	# Rotate away_dir by 45 degrees left/right to glide along the wall
	var desired_dir := away_dir.rotated(side * PI / 4.0).normalized()

	# Smoothly blend the target direction toward the new desired direction
	move_direction_target = move_direction_target.lerp(desired_dir, 0.6)

	# Shorter move phase after wall avoidance
	phase_time = randf_range(wall_turn_min_time, wall_turn_max_time)


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

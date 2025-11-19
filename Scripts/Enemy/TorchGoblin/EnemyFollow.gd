extends EnemyState
class_name EnemyFollow

@export_category("Movement")
@export var move_speed: float = 80.0
@export var wander_state: EnemyState
@export var knockback_state: EnemyState
@export var dead_state: EnemyState   # optional; falls back to state_machine.dead_state if null

@export_category("Detection / Attack Areas")
@export var detection_area: Area2D        # if null, will try enemy.DetectionArea
@export var attack_area: Area2D           # if set AND attack_state set => can switch to Attack state
@export var attack_state: EnemyState      # for enemies with a separate Attack state (e.g. TNT goblin)

@export_category("Melee while following")
@export var melee_while_following: bool = true
@export var use_vertical_attack_anims: bool = true
@export var base_attack_animation: String = "attack"
@export var attack_up_animation: String = "attack_up"
@export var attack_down_animation: String = "attack_down"
@export var attack_window_start: float = 0.3
@export var attack_window_end: float = 0.34

@export_category("Auto-throw")
@export var auto_throw: bool = false
@export var throw_chance_per_frame: float = 0.02
@export var throw_charge_time: float = 0.6

@export_category("Follow ↔ Attack delay")
@export var use_attack_transition_delay: bool = true
@export var attack_transition_delay: float = 0.25

var player: CharacterBody2D
var player_in_detection_range: bool = true
var _attack_request_timer: float = -1.0
var _request_attack: bool = false
var attack_animation: String = ""


func enter(prev_state: EnemyState) -> void:
	_ensure_player_connections()
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D

	# Only play detection once when we start actively following
	if not enemy.isAttacking and melee_while_following:
		enemy.isAttacking = true
	if prev_state is EnemyWander:
		enemy.player_detected_audio.play()

	if melee_while_following:
		_update_attack_animation()
		enemy.animation_player.play(attack_animation)


func exit() -> void:
	_reset_attack_request()


func physics_update(_delta: float) -> EnemyState:
	if enemy == null:
		return null

	# --- Death / Knockback ---
	if enemy.dead and dead_state:
		enemy.isAttacking = false
		return dead_state

	if enemy.hit and knockback_state:
		return knockback_state

	# --- Lost player / back to wander ---
	if (not player_in_detection_range or not _is_player_valid()) and wander_state:
		enemy.isAttacking = false
		_reset_attack_request()
		return wander_state

	if not _is_player_valid():
		_reset_attack_request()
		return null

	# --- Orientation ---
	if enemy.sprite:
		enemy.sprite.flip_h = player.global_position.x < enemy.global_position.x
	
	if enemy.has_node("TorchPivot/TorchAttackPoint"):
		var attack_point := enemy.get_node("TorchPivot/TorchAttackPoint") as Node2D
		attack_point.look_at(player.global_position)

	var direction := (player.global_position - enemy.global_position)

	# --- Movement
	enemy.velocity = direction.normalized() * move_speed

	# --- Melee attack while following (torch enemy) ---
	if melee_while_following:
		_update_attack_animation()

		# --- auto-throw for ranged enemies (TNT, archers, etc.) ---
	if auto_throw and enemy.has_method("throw"):
		if randf() < throw_chance_per_frame:
			enemy.throw(throw_charge_time)
	
	if attack_state:
			if use_attack_transition_delay:
				if _attack_request_timer > 0.0:
					_attack_request_timer -= _delta
					if _attack_request_timer <= 0.0:
						_attack_request_timer = -1.0
						_request_attack = false
						if enemy.isAttacking == false:
							enemy.isAttacking = true
						return attack_state
			else:
				if _request_attack:
					_request_attack = false
					if enemy.isAttacking == false:
						enemy.isAttacking = true
					return attack_state
	return null

# -------------------------------------------------------------------
# Helpers
# -------------------------------------------------------------------

func _update_attack_animation() -> void:
	if not melee_while_following or not _is_player_valid() or enemy == null:
		return
	var distance := player.global_position.y - enemy.global_position.y
	if use_vertical_attack_anims:
		if distance < -5.0:
			attack_animation = attack_up_animation
		elif distance > 5.0:
			attack_animation = attack_down_animation
		else:
			attack_animation = base_attack_animation
	else:
		attack_animation = base_attack_animation

	if enemy.animation_player and enemy.animation_player.current_animation != attack_animation:
		enemy.animation_player.play(attack_animation)


func _is_player_valid() -> bool:
	return player != null and player.current_health > 0


func _ensure_player_connections() -> void:
	if not GlobalPlayerManager.is_connected("PlayerSpawned", Callable(self, "_on_player_spawned")):
		GlobalPlayerManager.connect("PlayerSpawned", Callable(self, "_on_player_spawned"))

	if not GlobalPlayerManager.is_connected("PlayerDespawned", Callable(self, "_on_player_despawned")):
		GlobalPlayerManager.connect("PlayerDespawned", Callable(self, "_on_player_despawned"))
		
	# DetectionArea (can come from export or child node)
	var det_area: Area2D = detection_area
	if det_area == null and enemy and enemy.has_node("DetectionArea"):
		det_area = enemy.get_node("DetectionArea") as Area2D

	if det_area:
		if not det_area.is_connected("body_exited", Callable(self, "_on_detection_area_exited")):
			det_area.connect("body_exited", Callable(self, "_on_detection_area_exited"))
		if not det_area.is_connected("body_entered", Callable(self, "_on_detection_area_entered")):
			det_area.connect("body_entered", Callable(self, "_on_detection_area_entered"))

	# AttackArea (only relevant if we have an attack_state)
	var atk_area: Area2D = attack_area
	if atk_area == null and enemy and enemy.has_node("AttackArea"):
		atk_area = enemy.get_node("AttackArea") as Area2D

	if atk_area and attack_state:
		if not atk_area.is_connected("body_entered", Callable(self, "_on_attack_area_entered")):
			atk_area.connect("body_entered", Callable(self, "_on_attack_area_entered"))

func _reset_attack_request() -> void:
	_attack_request_timer = -1.0
	_request_attack = false
# -------------------------------------------------------------------
# Signals
# -------------------------------------------------------------------

func _on_detection_area_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_detection_range = false


func _on_detection_area_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_detection_range = true


func _on_attack_area_entered(body: Node) -> void:
	if body.is_in_group("Player") and _is_player_valid() and attack_state:
		if use_attack_transition_delay:
			if _attack_request_timer < 0.0:
				_attack_request_timer = attack_transition_delay
				_request_attack = true
		else:
			_request_attack = true


func _on_player_spawned(_player: CharacterBody2D) -> void:
	player = _player
	player_in_detection_range = true


func _on_player_despawned() -> void:
	player = null
	player_in_detection_range = false

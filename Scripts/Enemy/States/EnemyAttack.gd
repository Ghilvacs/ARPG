extends EnemyState
class_name EnemyAttack

@export_category("State Transitions")
@export var follow_state: EnemyState              # go here when attack area is left
@export var retreat_state: EnemyState             # go here if retreat area is entered
@export var knockback_state: EnemyState           # optional
@export var dead_state: EnemyState                # optional, defaults to state_machine.dead_state

@export_category("Attack Logic")
@export var attack_animation: String = "attack"
@export var can_move_during_attack: bool = true
@export var attack_move_speed: float = 0.0        # if 0, enemy stands still during attack

@export var requires_cooldown: bool = true
@export var cooldown_flag_name: String = "inCooldown"  # uses enemy.inCooldown if it exists

@export_category("Areas")
@export var attack_area: Area2D                   # leaving this area -> follow
@export var retreat_area: Area2D                  # entering this area -> retreat

@export_category("Attack ↔ Follow delay")
@export var use_follow_transition_delay: bool = true
@export var follow_transition_delay: float = 0.25

var player: CharacterBody2D
var _connected: bool = false
var _follow_request_timer: float = -1.0
var _retreat_requested: bool = false


func enter(previous_state: EnemyState) -> void:
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	_connect_areas()
	
	
	_follow_request_timer = -1.0
	_retreat_requested = false

	# Only play animation if not cooling down
	if not _enemy_in_cooldown():
		enemy.animation_player.play(attack_animation)
	
	enemy.isAttacking = true


func exit() -> void:
	_follow_request_timer = -1.0
	_retreat_requested = false


func physics_update(delta: float) -> EnemyState:
	if enemy == null:
		return null

	# death
	if enemy.dead and dead_state:
		enemy.isAttacking = false
		return dead_state

	# knockback
	if enemy.hit and knockback_state:
		return knockback_state

	# invalid player -> back to follow if possible
	if not _player_valid():
		if follow_state:
			enemy.isAttacking = false
			_reset_follow_request()
			return follow_state
		_reset_follow_request()
		return null
	
	if _retreat_requested and retreat_state:
		_retreat_requested = false
		enemy.isAttacking = false
		return retreat_state

	if follow_state:
		if use_follow_transition_delay:
			if _follow_request_timer > 0.0:
				_follow_request_timer -= delta
				if _follow_request_timer <= 0.0:
					_follow_request_timer = -1.0
					if "isAttacking" in enemy:
						enemy.isAttacking = false
					return follow_state

	# orientation
	if enemy.sprite:
		enemy.sprite.flip_h = player.global_position.x < enemy.global_position.x

	# optional movement during attack
	if can_move_during_attack and attack_move_speed > 0.0 and "velocity" in enemy:
		var dir := (player.global_position - enemy.global_position).normalized()
		enemy.velocity = dir * attack_move_speed
	elif "velocity" in enemy:
		enemy.velocity = Vector2.ZERO

	# animation replay if cooldown ended
	if not _enemy_in_cooldown():
		if enemy.animation_player and enemy.animation_player.current_animation != attack_animation:
			enemy.animation_player.play(attack_animation)

	return null

# -------------------------------------------------------------------
# AREA SIGNALS
# -------------------------------------------------------------------

func _on_attack_area_exited(body: Node) -> void:
	if body.is_in_group("Player") and follow_state:
		enemy.isAttacking = false
		if use_follow_transition_delay:
			if _follow_request_timer < 0.0:
				_follow_request_timer = follow_transition_delay


func _on_retreat_area_entered(body: Node) -> void:
	if body.is_in_group("Player") and retreat_state:
		_retreat_requested = true

# -------------------------------------------------------------------
# HELPERS
# -------------------------------------------------------------------

func _connect_areas() -> void:
	if _connected:
		return
	_connected = true

	if attack_area:
		if not attack_area.is_connected("body_exited", Callable(self, "_on_attack_area_exited")):
			attack_area.connect("body_exited", Callable(self, "_on_attack_area_exited"))

	if retreat_area:
		if not retreat_area.is_connected("body_entered", Callable(self, "_on_retreat_area_entered")):
			retreat_area.connect("body_entered", Callable(self, "_on_retreat_area_entered"))


func _enemy_in_cooldown() -> bool:
	if not requires_cooldown:
		return false
	if cooldown_flag_name in enemy:
		return enemy.get(cooldown_flag_name)
	return false


func _player_valid() -> bool:
	return player != null and player.current_health > 0


func _reset_follow_request() -> void:
	_follow_request_timer = -1.0

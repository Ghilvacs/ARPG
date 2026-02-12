extends EnemyState
class_name EnemyAttack

@export var stamina_cost: float = 5.0

@export_category("State Transitions")
@export var follow_state: EnemyState
@export var knockback_state: EnemyState
@export var stun_state: EnemyState
@export var dead_state: EnemyState

@export_category("Animation")
@export var attack_animation: String = "attack"

@export_category("Cooldown")
@export var requires_cooldown: bool = true
@export var cooldown_flag_name: String = "inCooldown"

@export_category("Phases")
@export var prepare_time: float = 0.25
@export var lunge_speed: float = 350.0
@export var lunge_duration: float = 0.12
@export var recover_time: float = 0.38
@export var recover_move_speed: float = 10.0
@export var recover_turn_lerp: float = 4.0

@export_category("Lunge Tuning")
@export var lunge_lock_direction: bool = true
@export var lunge_stop_after: bool = true
@export var lunge_drag: float = 0.0

@export_category("Poison release")
@export var poison_cloud_scene: PackedScene
@export var poison_spawn_step: float = 10.0
@export var poison_cloud_length: float = 14.0

var player: CharacterBody2D

enum Phase { PREPARE, LUNGE, RECOVER }
var _phase: int = Phase.PREPARE
var _t: float = 0.0

var _lunge_direction := Vector2.ZERO
var _recover_direction := Vector2.ZERO
var last_poison_position: Vector2


func enter(_prev: EnemyState) -> void:
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	enemy.isAttacking = true

	# play anim once
	if enemy.animation_player:
		enemy.animation_player.play(enemy.attack_animation)

	# start cooldown NOW (one attack = one cooldown)
	if requires_cooldown and (cooldown_flag_name in enemy):
		enemy.set(cooldown_flag_name, true)
		_start_attack_timer_if_present()

	# init phases
	_phase = Phase.PREPARE
	_t = enemy.prepare_time

	_snapshot_directions()


func exit() -> void:
	enemy.isAttacking = false


func physics_update(delta: float) -> EnemyState:
	if enemy == null:
		return null

	if enemy.hit and knockback_state and enemy.can_be_knocked_back:
		return knockback_state
	
	if enemy.dead and dead_state:
		enemy.isAttacking = false
		return dead_state
	
	if enemy.stunned and stun_state:
		enemy.isAttacking = false
		return stun_state

	if not _player_valid():
		enemy.isAttacking = false
		return follow_state if follow_state else null

	# face player
	if enemy.sprite:
		enemy.sprite.flip_h = player.global_position.x < enemy.global_position.x

	match _phase:
		Phase.PREPARE:
			enemy.velocity = Vector2.ZERO
			_t -= delta
			if _t <= 0.0:
				_phase = Phase.LUNGE
				_t = lunge_duration
				last_poison_position = enemy.global_position
				if not lunge_lock_direction: 
					_snapshot_directions()

		Phase.LUNGE:
			_apply_lunge(delta)
			_t -= delta
			if _t <= 0.0:
				_phase = Phase.RECOVER
				_t = enemy.recover_time
				if lunge_stop_after:
					enemy.velocity = Vector2.ZERO
			update_lunge_poison()

		Phase.RECOVER:
			_apply_recovery(delta)
			update_lunge_poison()
			_t -= delta
			if _t <= 0.0:
				enemy.isAttacking = false
				return follow_state if follow_state else null

	return null


func _apply_lunge(delta: float) -> void:
	if _lunge_direction == Vector2.ZERO:
		enemy.velocity = Vector2.ZERO
		return

	enemy.velocity = _lunge_direction * enemy.lunge_speed
	if lunge_drag > 0.0:
		enemy.velocity = enemy.velocity.move_toward(Vector2.ZERO, lunge_drag * delta)


func update_lunge_poison() -> void:
	var current_position: Vector2 = enemy.global_position
	var distance: float = last_poison_position.distance_to(current_position)
	
	if distance < poison_spawn_step:
		return
	
	var direction: Vector2 = (last_poison_position.direction_to(current_position)).normalized()
	var steps: int = int(distance / poison_spawn_step)
	
	for step in range(1, steps + 1):
		var position := last_poison_position + direction * poison_spawn_step * step
		spawn_poison_cloud(position, direction)
	
	last_poison_position = current_position


func spawn_poison_cloud(position: Vector2, direction: Vector2) -> void:
	var poison_cloud := poison_cloud_scene.instantiate()
	get_tree().current_scene.add_child(poison_cloud)
	poison_cloud.global_position = position
	poison_cloud.rotation = direction.angle()


func _apply_recovery(delta: float) -> void:
	if _player_valid():
		var desired := player.global_position - enemy.global_position
		if desired.length() > 0.001:
			_recover_direction = _recover_direction.lerp(desired.normalized(), recover_turn_lerp * delta)

	enemy.velocity = _recover_direction * recover_move_speed


func _snapshot_directions() -> void:
	if not _player_valid():
		_lunge_direction = Vector2.ZERO
		_recover_direction = Vector2.ZERO
		return

	var direction := player.global_position - enemy.global_position
	_lunge_direction = direction.normalized() if direction.length() > 0.001 else Vector2.ZERO
	_recover_direction = _lunge_direction


func _start_attack_timer_if_present() -> void:
	if enemy.has_node("TimerAttack"):
		var timer := enemy.get_node("TimerAttack") as Timer
		if timer and timer.is_stopped():
			timer.start()


func _player_valid() -> bool:
	return player != null and player.current_health > 0

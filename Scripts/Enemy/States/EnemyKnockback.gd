extends EnemyState
class_name EnemyKnockback

@export var knockback_distance: float = 10.0
@export var knockback_duration: float = 0.2
@export var stun_state: EnemyState
@export var dead_state: EnemyState

var player: CharacterBody2D
var knockback_time: float = 0.0
var _knockback_finished: bool = false

var knockback_velocity: Vector2 = Vector2.ZERO

func enter(_prev_state: EnemyState) -> void:
	enemy.hit = false
	enemy.in_knockback = true
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	knockback_time = 0.0
	_knockback_finished = false

	if enemy == null or player == null:
		_knockback_finished = true
		return

	# Direction away from player
	var direction := (enemy.global_position - player.global_position).normalized()

	# speed = distance / time
	var knockback_speed = knockback_distance / max(0.001, knockback_duration)
	knockback_velocity = direction * knockback_speed

	# If you use friction/accel elsewhere, you may want to zero out any steering here
	# enemy.velocity = Vector2.ZERO

func exit() -> void:
	enemy.in_knockback = false
	knockback_velocity = Vector2.ZERO
	# Don't kill tweens anymore (we removed them)

func update(delta: float) -> EnemyState:
	if enemy == null:
		return null

	knockback_time += delta

	# Dead should override everything
	if enemy.dead and dead_state:
		enemy.hit = false
		enemy.stunned = false
		return dead_state

	# End knockback -> go stun
	if (_knockback_finished or knockback_time >= knockback_duration) and stun_state:
		enemy.hit = false
#		enemy.velocity = Vector2.ZERO
		enemy.apply_stun(0.0)
		return stun_state

	return null

func physics_update(delta: float) -> EnemyState:
	if enemy == null or _knockback_finished:
		return null

	# Apply knockback through physics so walls block it
	enemy.velocity = knockback_velocity
	enemy.move_and_slide()

	# If we collide, stop the knockback early (prevents "pushing into wall")
	if enemy.get_slide_collision_count() > 0:
		_knockback_finished = true
		enemy.velocity = Vector2.ZERO

	# Time-based stop (if no collision)
	if knockback_time >= knockback_duration:
		_knockback_finished = true
		enemy.velocity = Vector2.ZERO

	return null

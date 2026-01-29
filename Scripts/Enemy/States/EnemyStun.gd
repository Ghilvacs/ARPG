extends EnemyState
class_name EnemyStun

@export var wander_state: EnemyState
@export var follow_state: EnemyState
@export var retreat_state: EnemyState
@export var knockback_state: EnemyState
@export var dead_state: EnemyState
@export var min_follow_distance: float = 500.0
@export var max_follow_distance: float = 600.0

var player: CharacterBody2D
var direction: Vector2 = Vector2.ZERO


func enter(_prev_state: EnemyState) -> void:
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D

	if enemy == null:
		return

	enemy.velocity = Vector2.ZERO

	if enemy.timer_stun and enemy.timer_stun.is_stopped():
		enemy.timer_stun.start()


func exit() -> void:
	pass


func physics_update(_delta: float) -> EnemyState:
	if enemy == null:
		return null
	
	if enemy.hit and knockback_state:
		return knockback_state
	
	if enemy.dead and dead_state:
		return dead_state

	if enemy.stunned:
		enemy.velocity = Vector2.ZERO
		return null

	if not _is_player_valid():
		if wander_state:
			return wander_state
		return null

	direction = player.global_position - enemy.global_position
	var distance := direction.length()

	if distance > max_follow_distance and wander_state:
		return wander_state

	if distance < min_follow_distance and retreat_state:
		return retreat_state

	if follow_state:
		return follow_state
	
	return null


func _is_player_valid() -> bool:
	return player != null and player.current_health > 0

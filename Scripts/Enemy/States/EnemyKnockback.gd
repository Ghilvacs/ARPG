extends EnemyState
class_name EnemyKnockback

@export var knockback_distance: float = 8.0
@export var knockback_duration: float = 0.2
@export var stun_state: EnemyState
@export var dead_state: EnemyState

var player: CharacterBody2D
var tween: Tween
var knockback_time: float = 0.0
var _knockback_finished: bool = false


func enter(_prev_state: EnemyState) -> void:
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	knockback_time = 0.0
	_knockback_finished = false

	if enemy == null or player == null:
		return

	if tween and tween.is_valid():
		tween.kill()

	var direction := (enemy.global_position - player.global_position).normalized()
	var target_position := enemy.global_position + direction * knockback_distance

	tween = enemy.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "global_position", target_position, knockback_duration)

	if not tween.is_connected("finished", Callable(self, "_on_knockback_finished")):
		tween.connect("finished", Callable(self, "_on_knockback_finished"))


func exit() -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = null


func update(delta: float) -> EnemyState:
	if enemy == null:
		return null

	knockback_time += delta

	if enemy.dead and dead_state:
		enemy.hit = false
		enemy.stunned = false
		if tween and tween.is_valid():
			tween.kill()
		return dead_state

	if ( _knockback_finished or knockback_time >= knockback_duration ) and stun_state:
		enemy.hit = false
		enemy.stunned = true
		enemy.velocity = Vector2.ZERO
		return stun_state

	return null


func physics_update(_delta: float) -> EnemyState:
	return null


func _on_knockback_finished() -> void:
	_knockback_finished = true

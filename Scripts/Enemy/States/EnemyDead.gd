extends EnemyState
class_name EnemyDead

var _entered: bool = false

func enter(_prev_state: EnemyState) -> void:
	if enemy == null:
		return
	_entered = true

	enemy.velocity = Vector2.ZERO

	var main_collider := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if main_collider:
		main_collider.disabled = true

	var attack_hitbox := enemy.get_node_or_null(
		"TorchPivot/TorchAttackPoint/TorchArea/CollisionShape2D"
	) as CollisionShape2D
	if attack_hitbox:
		attack_hitbox.disabled = true
		
	enemy.sprite.visible = false
	enemy.death_sprite.visible = true

	if enemy.animation_player:
		enemy.animation_player.play("death")


func exit() -> void:
	pass


func update(_delta: float) -> EnemyState:
	return null


func physics_update(_delta: float) -> EnemyState:
	if enemy:
		enemy.velocity = Vector2.ZERO
	return null

extends EnemyState
class_name EnemyDead

const PICKUP = preload("res://Scenes/Items/ItemPickup/ItemPickup.tscn")

@export_category("Item Drops")
@export var drops: Array[DropData]

var _entered: bool = false

func enter(_prev_state: EnemyState) -> void:
	if enemy == null:
		return
	_entered = true
	drop_items()
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


func drop_items() -> void:
	if drops.size() == 0:
		return
	
	for i in drops.size():
		if !drops[i] or !drops[i].item:
			continue
		
		var drop_count: int = drops[i].get_drop_count()
		for j in drop_count:
			var drop: ItemPickup = PICKUP.instantiate() as ItemPickup
			drop.item_data = drops[i].item
			enemy.get_parent().call_deferred("add_child", drop)
			drop.global_position = enemy.global_position
			drop.velocity = Vector2(25.0, 25.0).rotated(
				randf_range(-1.5, 1.5)) * \
				randf_range(0.9, 1.5)

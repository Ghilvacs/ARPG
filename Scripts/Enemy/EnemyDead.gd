extends State
class_name EnemyDead

@export var enemy: CharacterBody2D
@export var move_speed := 0

func enter() -> void:
	enemy.get_node("CollisionShape2D").disabled = true
	enemy.get_node("TorchPivot/TorchAttackPoint/TorchArea/CollisionShape2D").disabled = true
	enemy.get_node("AnimatedSprite2D").z_index = 0
	enemy.sprite.visible = false
	enemy.death_sprite.visible = true
	enemy.animation_player.play("death")

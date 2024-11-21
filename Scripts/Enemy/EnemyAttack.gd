extends State
class_name EnemyAttack

var player: CharacterBody2D

@export var enemy: CharacterBody2D
@export var move_speed := 0

@onready var timer: Timer = $"../../Timer"

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
func physics_update(delta: float) -> void:
	var direction = player.global_position - enemy.global_position
	if direction.length() > 90 && direction.length() < 400:
		Transitioned.emit(self, "Follow")
	elif  direction.length() > 400:
		Transitioned.emit(self, "Wander")
	elif player.current_health > 0:
		if enemy.global_position.y - player.global_position.y > 50:
			enemy.animated_sprite.play("attack_up")
		elif enemy.global_position.y - player.global_position.y < -30:
			enemy.animated_sprite.play("attack_down")
		else:
			enemy.animated_sprite.play("attack")
	
	enemy.torch_attack_point.look_at(player.global_position)

	if player.global_position.x > enemy.global_position.x:
		enemy.animated_sprite.flip_h = false
	else:
		enemy.animated_sprite.flip_h = true
	if enemy.animated_sprite.animation == "attack" || enemy.animated_sprite.animation == "attack_up" || enemy.animated_sprite.animation == "attack_down" && enemy.animated_sprite.frame == 1:
			enemy.get_node("TorchPivot/TorchAttackPoint/TorchArea/CollisionShape2D").disabled = false
	if enemy.dead:
		Transitioned.emit(self, "Dead")

func _on_timer_timeout() -> void:
	Transitioned.emit(self, "Wander")

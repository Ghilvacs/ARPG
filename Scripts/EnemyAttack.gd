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
	if direction.length() > 50 && direction.length() < 400:
		Transitioned.emit(self, "Follow")
	elif  direction.length() > 400:
		Transitioned.emit(self, "Wander")
	elif player.current_health > 0:
		enemy.animated_sprite.play("attack")

	if player.global_position.x > enemy.global_position.x:
		enemy.animated_sprite.flip_h = false
		enemy.get_node("TorchArea").set_scale(Vector2(1, 1))
	else:
		enemy.animated_sprite.flip_h = true
		enemy.get_node("TorchArea").set_scale(Vector2(-1, 1))
	if enemy.animated_sprite.animation == "attack" && enemy.animated_sprite.frame == 3:
			enemy.get_node("TorchArea/CollisionShape2D").disabled = false
	if enemy.dead:
		Transitioned.emit(self, "Dead")

func _on_timer_timeout() -> void:
	Transitioned.emit(self, "Wander")

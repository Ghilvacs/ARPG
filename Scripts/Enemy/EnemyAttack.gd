extends State
class_name EnemyAttack

var player: CharacterBody2D

@export var enemy: CharacterBody2D
@export var move_speed := 0
@onready var timer: Timer = $"../../Timer"

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
func physics_update(_delta: float) -> void:
	if !enemy.hit:
		var direction = player.global_position - enemy.global_position
		enemy.stamina_bar.value = enemy.current_stamina
		if direction.length() > 90 && direction.length() < 400:
			Transitioned.emit(self, "Follow")
		elif  direction.length() > 400:
			Transitioned.emit(self, "Wander")
		elif player.current_health > 0 && enemy.current_stamina >= 10:
			enemy.timer_stamina_regen.stop()
			if enemy.timer_stamina_regen_start.is_stopped():
				enemy.timer_stamina_regen_start.start()
			enemy.current_stamina -= 5
			if enemy.global_position.y - player.global_position.y > 50:
				enemy.animation_player.play("attack_up")
			elif enemy.global_position.y - player.global_position.y < -30:
				enemy.animation_player.play("attack_down")
			else:
				enemy.animation_player.play("attack")
		
		enemy.torch_attack_point.look_at(player.global_position)

		if player.global_position.x > enemy.global_position.x:
			enemy.sprite.flip_h = false
		else:
			enemy.sprite.flip_h = true
		if enemy.animation_player.current_animation == "attack" || enemy.animation_player.current_animation == "attack_up" || enemy.animation_player.current_animation == "attack_down":

			##### THIS IS BUGGY. NEED TO MAKE SOME CHANGES
			if enemy.animation_player.current_animation_position > 0.3 && enemy.animation_player.current_animation_position < 0.34:
				enemy.get_node("TorchPivot/TorchAttackPoint/TorchArea/CollisionShape2D").disabled = false
			else:
				enemy.get_node("TorchPivot/TorchAttackPoint/TorchArea/CollisionShape2D").disabled = true
			if enemy.dead:
				Transitioned.emit(self, "Dead")
	else:
		Transitioned.emit(self, "Knockback")

func _on_timer_timeout() -> void:
	Transitioned.emit(self, "Wander")

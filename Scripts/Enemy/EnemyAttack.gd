extends State
class_name EnemyAttack

var player: CharacterBody2D
@export var enemy: CharacterBody2D
@export var lunge_speed := 150.0   # tweak for how far/fast enemy lunges
var lunge_direction: Vector2 = Vector2.ZERO

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")

	# Lock direction at the start of the attack
	if player:
		lunge_direction = (player.global_position - enemy.global_position).normalized()
	else:
		# fallback to last facing direction if no player
		if enemy.velocity != Vector2.ZERO:
			lunge_direction = enemy.velocity.normalized()
		else:
			lunge_direction = Vector2.RIGHT
		lunge_direction = enemy.velocity.normalized()

	# Play correct animation based on y-offset
	var y_offset = enemy.global_position.y - player.global_position.y
	if y_offset > 20:
		enemy.animation_player.play("attack_up")
	elif y_offset < -10:
		enemy.animation_player.play("attack_down")
	else:
		enemy.animation_player.play("attack")

	# Face player
	enemy.sprite.flip_h = player.global_position.x < enemy.global_position.x

	# Spend stamina up front
	enemy.current_stamina -= 5
	enemy.stamina_bar.value = enemy.current_stamina
	enemy.timer_stamina_regen.stop()
	if enemy.timer_stamina_regen_start.is_stopped():
		enemy.timer_stamina_regen_start.start()

func physics_update(delta: float) -> void:
	if enemy.dead:
		Transitioned.emit(self, "Dead")
		return

	if enemy.hit:
		Transitioned.emit(self, "Knockback")
		return

	# Apply lunge movement only during early part of attack anim
	if enemy.animation_player.current_animation_position < 0.4:
		enemy.velocity = lunge_direction * lunge_speed
	else:
		enemy.velocity = Vector2.ZERO

	enemy.move_and_slide()

	# Enable/disable attack hitbox at right time
	if enemy.animation_player.current_animation in ["attack", "attack_up", "attack_down"]:
		if enemy.animation_player.current_animation_position > 0.3 \
		&& enemy.animation_player.current_animation_position < 0.34:
			enemy.get_node("TorchPivot/TorchAttackPoint/TorchArea/CollisionShape2D").disabled = false
		else:
			enemy.get_node("TorchPivot/TorchAttackPoint/TorchArea/CollisionShape2D").disabled = true

	# Transition logic
	var dist = player.global_position.distance_to(enemy.global_position)
	if dist > 250:
		Transitioned.emit(self, "Wander")
	elif dist > 20:
		Transitioned.emit(self, "Follow")

func _on_timer_timeout() -> void:
	Transitioned.emit(self, "Wander")

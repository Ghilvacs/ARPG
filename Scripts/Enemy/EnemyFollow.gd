extends State
class_name EnemyFollow

@export var enemy: CharacterBody2D
@export var move_speed := 400.0
@export var prediction_factor := 0.4  # How far ahead the enemy predicts (tweakable)
var player: CharacterBody2D

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
func physics_update(delta: float) -> void:
	# Predict the player's future position based on current velocity
	var predicted_position = player.global_position + (player.velocity * prediction_factor)
	var direction = predicted_position - enemy.global_position
	
	enemy.stamina_bar.value = enemy.current_stamina
	
	if direction.length() > 60:
		if enemy.current_stamina > 10:
			enemy.timer_stamina_regen.stop()
			enemy.velocity = direction.normalized() * move_speed
		else:
			enemy.velocity = direction.normalized() * move_speed
			if enemy.timer_stamina_regen_start.is_stopped():
				enemy.timer_stamina_regen_start.start()
	else:
		enemy.velocity = Vector2()
		if enemy.timer_stamina_regen_start.is_stopped():
			enemy.timer_stamina_regen_start.start()
	
	# Transitions
	if direction.length() > 600 or player.current_health < 1:
		if enemy.timer_stamina_regen_start.is_stopped():
			enemy.timer_stamina_regen_start.start()
		Transitioned.emit(self, "Wander")
	elif direction.length() < 80:
		Transitioned.emit(self, "Attack")
	
	if enemy.dead:
		Transitioned.emit(self, "Dead")
	if enemy.hit:
		Transitioned.emit(self, "Knockback")

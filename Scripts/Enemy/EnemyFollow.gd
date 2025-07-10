extends State
class_name EnemyFollow

@export var enemy: CharacterBody2D
@export var move_speed := 400.0
var player: CharacterBody2D

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
func physics_update(delta: float) -> void:
	var direction = player.global_position - enemy.global_position
	enemy.stamina_bar.value = enemy.current_stamina
	if direction.length() > 60:
		if enemy.current_stamina > 10:
#			move_speed = 200.0
			enemy.timer_stamina_regen.stop()
#			enemy.current_stamina -= 0.1
			enemy.velocity = direction.normalized() * move_speed
		else:
#			move_speed = 100.0
			enemy.velocity = direction.normalized() * move_speed
			if enemy.timer_stamina_regen_start.is_stopped():
					enemy.timer_stamina_regen_start.start()
	else:
		enemy.velocity = Vector2()
		if enemy.timer_stamina_regen_start.is_stopped():
				enemy.timer_stamina_regen_start.start()
	if direction.length() > 600 || player.current_health < 1:
		if enemy.timer_stamina_regen_start.is_stopped():
			enemy.timer_stamina_regen_start.start()
		Transitioned.emit(self, "Wander")
	elif direction.length() < 80:
		Transitioned.emit(self, "Attack")
	if enemy.dead:
		Transitioned.emit(self, "Dead")
	if enemy.hit:
		Transitioned.emit(self, "Knockback")

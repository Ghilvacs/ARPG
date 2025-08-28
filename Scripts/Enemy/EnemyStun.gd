extends State
class_name EnemyStun

@export var enemy: CharacterBody2D

var player: CharacterBody2D
var direction: Vector2

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	enemy.velocity = Vector2.ZERO
	if enemy.timer_stun.is_stopped():
		enemy.timer_stun.start(0)

func physics_update(_delta: float) -> void:
	direction = player.global_position - enemy.global_position
	if !enemy.stunned:
		if direction.length() > 600 || player.current_health < 1:
			if enemy.timer_stamina_regen_start.is_stopped():
				enemy.timer_stamina_regen_start.start()
			Transitioned.emit(self, "Wander")
		elif direction.length() < 500 && player.current_health > 1:
			Transitioned.emit(self, "Follow")
		elif direction.length() < 80:
			Transitioned.emit(self, "Attack")
	if enemy.dead:
		Transitioned.emit(self, "Dead")

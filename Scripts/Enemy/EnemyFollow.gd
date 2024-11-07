extends State
class_name EnemyFollow

@export var enemy: CharacterBody2D
@export var move_speed := 150.0
var player: CharacterBody2D

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
func physics_update(delta: float) -> void:
	var direction = player.global_position - enemy.global_position
	if direction.length() > 60:
		enemy.velocity = direction.normalized() * move_speed
	else:
		enemy.velocity = Vector2()
	if direction.length() > 600 || player.current_health < 1:
		Transitioned.emit(self, "Wander")
	elif direction.length() < 80:
		Transitioned.emit(self, "Attack")
	if enemy.dead:
		Transitioned.emit(self, "Dead")

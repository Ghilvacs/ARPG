extends State
class_name EnemyWander

@export var enemy: CharacterBody2D
@export var move_speed := 100.0

var player: CharacterBody2D

var move_direction: Vector2
var wander_time: float

func randomize_wander():
	move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	wander_time = randf_range(1, 3)

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	randomize_wander()
	
func update(delta: float) -> void:
	if wander_time > 0:
		wander_time -= delta
	else:
		randomize_wander()

func physics_update(delta: float) -> void:
	if enemy:
		enemy.velocity = move_direction * move_speed

	var direction = player.global_position - enemy.global_position
	
	if direction.length() < 500 && player.current_health > 1:
		Transitioned.emit(self, "Follow")

	if enemy.dead:
		Transitioned.emit(self, "Dead")
	

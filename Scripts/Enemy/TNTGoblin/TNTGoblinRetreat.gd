extends State
class_name TNTGoblinRetreat

@export var enemy: CharacterBody2D
@export var move_speed := 80.0
var player: CharacterBody2D
var player_in_retreat_range := true

func enter() -> void:
	print("Retreat")
	player = get_tree().get_first_node_in_group("Player")
	
	if enemy.has_node("RetreatArea"):
		var retreat_area = enemy.get_node("RetreatArea") as Area2D
		if not retreat_area.is_connected("body_exited", Callable(self, "_on_retreat_area_exited")):
			retreat_area.connect("body_exited", Callable(self, "_on_retreat_area_exited"))
	
func physics_update(_delta: float) -> void:
	if not enemy.inCooldown:
		if not player:
			return
		enemy.sprite.flip_h = player.global_position.x > enemy.global_position.x
		var direction = enemy.global_position - player.global_position
		
		enemy.stamina_bar.value = enemy.current_stamina
		
		if enemy.current_stamina > 10:
			enemy.timer_stamina_regen.stop()
			enemy.velocity = direction.normalized() * move_speed
		else:
			enemy.velocity = direction.normalized() * move_speed
			if enemy.timer_stamina_regen_start.is_stopped():
				enemy.timer_stamina_regen_start.start()
		
		# Transitions
		if player.current_health < 1:
			Transitioned.emit(self, "Wander")
		
		if enemy.dead:
			enemy.isAttacking = false
			Transitioned.emit(self, "Dead")
		if enemy.hit:
			Transitioned.emit(self, "Knockback")

func _on_retreat_area_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_retreat_range = false
		Transitioned.emit(self, "Attack")

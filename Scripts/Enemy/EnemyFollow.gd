extends State
class_name EnemyFollow

@export var enemy: CharacterBody2D
@export var move_speed := 80.0
var player: CharacterBody2D
var player_in_detection_range := true
var attack_animation: String = ""

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	enemy.isAttacking = true
	
	if enemy.has_node("DetectionArea"):
		var detection_area = enemy.get_node("DetectionArea") as Area2D
		if not detection_area.is_connected("body_exited", Callable(self, "_on_detection_area_exited")):
			detection_area.connect("body_exited", Callable(self, "_on_detection_area_exited"))
		if not detection_area.is_connected("body_entered", Callable(self, "_on_detection_area_entered")):
			detection_area.connect("body_entered", Callable(self, "_on_detection_area_entered"))
			
	_update_attack_animation()
	enemy.animation_player.play("attack")
	
func physics_update(_delta: float) -> void:
	if not player:
		return
	enemy.sprite.flip_h = player.global_position.x < enemy.global_position.x	
	enemy.torch_attack_point.look_at(player.global_position)
	var direction = player.global_position - enemy.global_position
	
	enemy.stamina_bar.value = enemy.current_stamina
	_update_attack_animation()
	
	if enemy.current_stamina > 10:
		enemy.timer_stamina_regen.stop()
		enemy.velocity = direction.normalized() * move_speed
	else:
		enemy.velocity = direction.normalized() * move_speed
		if enemy.timer_stamina_regen_start.is_stopped():
			enemy.timer_stamina_regen_start.start()

	if enemy.animation_player.current_animation in ["attack", "attack_up", "attack_down"]:
		if enemy.animation_player.current_animation_position > 0.3 \
		&& enemy.animation_player.current_animation_position < 0.34:
			enemy.get_node("TorchPivot/TorchAttackPoint/TorchArea/CollisionShape2D").disabled = false
		else:
			enemy.get_node("TorchPivot/TorchAttackPoint/TorchArea/CollisionShape2D").disabled = true
	
	# Transitions
	if not player_in_detection_range or player.current_health < 1:
		enemy.isAttacking = false
		if enemy.timer_stamina_regen_start.is_stopped():
			enemy.timer_stamina_regen_start.start()
		Transitioned.emit(self, "Wander")
	
	if enemy.dead:
		enemy.isAttacking = false
		Transitioned.emit(self, "Dead")
	if enemy.hit:
		Transitioned.emit(self, "Knockback")

func _on_detection_area_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_detection_range = false

func _on_detection_area_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_detection_range = true

func _update_attack_animation() -> void:
	var attack_animation: String = ""
	if player.global_position.y < enemy.global_position.y:
		attack_animation = "attack_up"
	elif player.global_position.y > enemy.global_position.y:
		attack_animation = "attack_down"
	else:
		attack_animation = "attack"
	if not enemy.animation_player.current_animation != attack_animation:
		enemy.animation_player.play(attack_animation)

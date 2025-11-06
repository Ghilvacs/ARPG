extends State
class_name TNTGoblinFollow

@export var enemy: CharacterBody2D
@export var move_speed := 80.0
var player: CharacterBody2D
var player_in_detection_range := true
var attack_animation: String = ""


func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	if enemy.has_node("DetectionArea"):
		var detection_area = enemy.get_node("DetectionArea") as Area2D
		if not detection_area.is_connected("body_exited", Callable(self, "_on_detection_area_exited")):
			detection_area.connect("body_exited", Callable(self, "_on_detection_area_exited"))
		if not detection_area.is_connected("body_entered", Callable(self, "_on_detection_area_entered")):
			detection_area.connect("body_entered", Callable(self, "_on_detection_area_entered"))
			
	if enemy.has_node("AttackArea"):
		var attack_area = enemy.get_node("AttackArea") as Area2D
		if not attack_area.is_connected("body_entered", Callable(self,"_on_attack_area_entered")):
			attack_area.connect("body_entered", Callable(self,"_on_attack_area_entered"))


func physics_update(_delta: float) -> void:
	if enemy.idle or enemy.transitionLocked:
		enemy.velocity = Vector2.ZERO
		return
	if not player:
		return
	enemy.sprite.flip_h = player.global_position.x < enemy.global_position.x	
	var direction = player.global_position - enemy.global_position
	enemy.stamina_bar.value = enemy.current_stamina
	
	if enemy.current_stamina > 10:
		enemy.timer_stamina_regen.stop()
		enemy.velocity = direction.normalized() * move_speed
	else:
		enemy.velocity = direction.normalized() * move_speed
		if enemy.timer_stamina_regen_start.is_stopped():
			enemy.timer_stamina_regen_start.start()
	
	# Transitions
	if not player_in_detection_range or player.current_health < 1:
		enemy.isAttacking = false
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


func _on_attack_area_entered(body: Node) -> void:
	if body.is_in_group("Player") and player.current_health > 1:
		enemy.trigger_state_transition("Attack", self)

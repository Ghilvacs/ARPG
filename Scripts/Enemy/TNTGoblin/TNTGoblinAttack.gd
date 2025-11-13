extends State
class_name TNTGoblinAttack

@export var enemy: CharacterBody2D
@export var move_speed := 0.0

var player: CharacterBody2D


func enter() -> void:
	if not enemy.inCooldown:
		enemy.animation_player.play("attack")
	enemy.isAttacking = true
	player = get_tree().get_first_node_in_group("Player")
	
	if enemy.has_node("AttackArea"):
		var attack_area = enemy.get_node("AttackArea") as Area2D
		if not attack_area.is_connected("body_exited", Callable(self,"_on_attack_area_exited")):
			attack_area.connect("body_exited", Callable(self,"_on_attack_area_exited"))
	
	if enemy.has_node("RetreatArea"):
		var retreat_area = enemy.get_node("RetreatArea") as Area2D
		if not retreat_area.is_connected("body_entered", Callable(self,"_on_retreat_area_entered")):
			retreat_area.connect("body_entered", Callable(self,"_on_retreat_area_entered"))


func physics_update(_delta: float) -> void:
	if enemy.idle or enemy.transitionLocked:
		enemy.velocity = Vector2.ZERO
		return
	
	if not player:
		return
	enemy.sprite.flip_h = player.global_position.x < enemy.global_position.x
	var direction = player.global_position - enemy.global_position
	enemy.velocity = direction.normalized() * move_speed
	
	player = get_tree().get_first_node_in_group("Player")
	if not enemy.inCooldown:
		enemy.animation_player.play("attack")
	
		if enemy.dead:
			enemy.isAttacking = false
			Transitioned.emit(self, "Dead")
		if enemy.hit:
			Transitioned.emit(self, "Knockback")


func _on_attack_area_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		enemy.isAttacking = false
		enemy.trigger_state_transition("Follow", self)


func _on_retreat_area_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		enemy.isAttacking = false
		enemy.trigger_state_transition("Retreat", self)

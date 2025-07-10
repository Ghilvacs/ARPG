extends State
class_name EnemyKnockback

@export var enemy: CharacterBody2D
@export var knockback_distance: float = 25.0
@export var knockback_duration: float = 0.2

var player: CharacterBody2D
var tween: Tween
var knockback_time := 0.0

func enter() -> void:
	player = get_tree().get_first_node_in_group("Player")
	
	var direction := (enemy.global_position - player.global_position).normalized()
	var target_position := enemy.global_position + direction * knockback_distance
	
	tween = enemy.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(enemy, "global_position", target_position, knockback_duration)
	
	tween.connect("finished", Callable(self, "_on_knockback_finished"))

func update(delta: float) -> void:
	knockback_time += delta

	if knockback_time >= knockback_duration:
		enemy.hit = false
		enemy.stunned = true
		enemy.velocity = Vector2.ZERO
		Transitioned.emit(self, "Stun")

	if enemy.dead:
		if tween:
			tween.kill()
		Transitioned.emit(self, "Dead")

func _on_knockback_finished():
	enemy.hit = false
	enemy.stunned = true
	Transitioned.emit(self, "Stun")
	
func physics_update(delta: float) -> void:
	pass

class_name StateDash extends PlayerState

@export var dash_distance: float = 40.0
@export var dash_duration: float = 0.1

@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"

var dash_time := 0.0
var effect_timer := 0.0
var direction: Vector2
var tween: Tween


func enter():
	player.isAttacking = false
	player.consume_stamina(1)
	player.hitbox_collision_shape.disabled = true
	player.dashed = true
	effect_timer = 0.0
	player.update_facing()
	direction = player.direction
	dash_time = 0.0
	player.dash_audio.play()
	var target_position := player.global_position + direction * dash_distance
	tween = player.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", target_position, dash_duration)


func exit():
	player.velocity = Vector2.ZERO
	player.hitbox_collision_shape.disabled = false


func update(delta: float) -> PlayerState:
	if player.dash_cooldown <= 0.0:
		player.dash_cooldown += delta
	elif player.dash_cooldown >= 2.0:
		player.dash_cooldown = 0.0
		
	dash_time += delta
	effect_timer -= delta
	
	if effect_timer < 0:
		effect_timer = player.dash_effect_delay
		player.spawn_dash_effect()
		
	if dash_time >= dash_duration:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk

	return null


func physics_update(_delta: float) -> PlayerState:
	return null

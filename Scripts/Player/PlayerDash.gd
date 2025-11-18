class_name StateDash extends PlayerState

@export var dash_distance: float = 35.0
@export var dash_duration: float = 0.2

@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"

var dash_time := 0.0
var direction: Vector2
var tween: Tween


func enter():
	player.update_facing()
	direction = player.direction
	dash_time = 0.0

	if player.current_stamina >= 25:
		player.dash_audio.play()
		player.consume_stamina(25.0)
		var target_position := player.global_position + direction * dash_distance
		tween = player.create_tween()
		tween.set_trans(Tween.TRANS_QUAD)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position", target_position, dash_duration)


func exit():
	player.velocity = Vector2.ZERO


func update(delta: float) -> PlayerState:
	dash_time += delta

	if dash_time >= dash_duration:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk

	return null


func physics_update(_delta: float) -> PlayerState:

	return null

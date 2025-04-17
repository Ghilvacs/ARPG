class_name StateDash extends PlayerState

@export var dash_speed: float = 3000.0
@export var dash_duration: float = 0.03

@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"

var dash_time := 0.0
var direction: Vector2

func enter():
	direction = player.direction
	dash_time = 0.0

	if player.current_stamina >= 20:
		player.timer_stamina_regen.stop()
		if player.timer_stamina_regen_start.is_stopped():
			player.timer_stamina_regen_start.start()

		player.current_stamina -= 20
		player.StaminaChanged.emit(player.current_stamina)

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

func physics_update(delta: float) -> PlayerState:
	var adjusted_speed = dash_speed * (1.0 - (0.5 * delta))
	player.velocity = direction.normalized() * adjusted_speed

	return null

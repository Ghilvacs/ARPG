class_name StateWalk extends PlayerState

const MAX_SPEED = 350
var current_speed

@onready var idle: PlayerState = $"../Idle"
@onready var attack: PlayerState = $"../Attack"
@onready var dash: PlayerState = $"../Dash"

func enter():
	player.update_animation("run")	
	pass

func exit():
	pass

func update(_delta: float) -> PlayerState:
	if player.direction == Vector2.ZERO:
		return idle
	
	return null

func physics_update(_delta: float) -> PlayerState:
	if Input.is_action_pressed("sprint") and player.current_stamina > 0:
		if player.sprite.flip_h && player.direction.x < 0 || !player.sprite.flip_h && player.direction.x > 0:
				player.timer_stamina_regen.stop()
				player.current_stamina -= 0.5
				player.StaminaChanged.emit(player.current_stamina)
				current_speed = MAX_SPEED
		else:
			current_speed = MAX_SPEED / 2
			if player.timer_stamina_regen_start.is_stopped():
				player.timer_stamina_regen_start.start()
	else:
		current_speed = MAX_SPEED / 2
		if player.timer_stamina_regen_start.is_stopped():
			player.timer_stamina_regen_start.start()
	player.velocity = player.direction * current_speed
	
	return null

func handle_input(_event: InputEvent) -> PlayerState:
	if _event.is_action_pressed("attack") and player.current_stamina >= 10:
		return attack
	if _event.is_action_pressed("dash") and player.current_stamina >= 20:
		return dash
	return null

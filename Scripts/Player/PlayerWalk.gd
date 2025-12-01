class_name StateWalk extends PlayerState

const MAX_SPEED = 100.0
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
	if Input.is_action_pressed("sprint") and player.current_stamina > 0.0:
		if player.sprite.flip_h && player.direction.x < 0 || !player.sprite.flip_h && player.direction.x > 0:
				player.consume_stamina(0.1)
				current_speed = MAX_SPEED
		else:
			current_speed = MAX_SPEED / 1.5
			player.resume_stamina_regen()
	else:
		current_speed = MAX_SPEED / 1.5
		player.resume_stamina_regen()
	player.velocity = player.direction * current_speed
	
	return null


func handle_input(_event: InputEvent) -> PlayerState:
	if _event.is_action_pressed("attack") and player.current_stamina >= 5:
		return attack
	if _event.is_action_pressed("dash") and player.dash_cooldown == 0.0:
		return dash
	return null

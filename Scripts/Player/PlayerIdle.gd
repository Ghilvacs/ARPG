class_name StateIdle extends PlayerState

@onready var walk: PlayerState = $"../Walk"
@onready var attack: PlayerState = $"../Attack"

func enter():
	player.update_animation("idle")
	pass

func exit():
	pass

func update(_delta: float) -> PlayerState:
	if player.direction != Vector2.ZERO:
		return walk
	
	return null

func physics_update(_delta: float) -> PlayerState:
	player.velocity = Vector2.ZERO
	
	return null

func handle_input(_event: InputEvent) -> PlayerState:
	if _event.is_action_pressed("attack") and player.current_stamina >= 5.0:
		return attack
	if _event.is_action_pressed("interact"):
		GlobalPlayerManager.InteractPressed.emit()
	return null

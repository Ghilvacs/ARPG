class_name StateDash extends PlayerState

@export var dash_distance: float = 20.0
@export var dash_duration: float = 0.1

@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"

var dash_time := 0.0
var effect_timer := 0.0
var direction: Vector2
var dash_velocity: Vector2

func enter():
	player.isAttacking = false
	player.consume_stamina(1)

	player.hitbox_collision_shape.disabled = true  # <- this is often the culprit

	player.dashed = true
	effect_timer = 0.0

	player.update_facing()
	direction = player.direction.normalized()
	dash_time = 0.0

	player.dash_audio.play()

	var dash_speed := dash_distance / dash_duration
	dash_velocity = direction * dash_speed

func exit():
	player.velocity = Vector2.ZERO
	player.hitbox_collision_shape.disabled = false

func update(delta: float) -> PlayerState:
	# your cooldown logic...
	if player.dash_cooldown <= 0.0:
		player.dash_cooldown += delta
	elif player.dash_cooldown >= 2.0:
		player.dash_cooldown = 0.0

	dash_time += delta
	effect_timer -= delta

	if effect_timer < 0.0:
		effect_timer = player.dash_effect_delay
		player.spawn_dash_effect()

	if dash_time >= dash_duration:
		if player.direction == Vector2.ZERO:
			return idle
		return walk

	return null

func physics_update(_delta: float) -> PlayerState:
	# Move through physics so walls stop you.
	player.velocity = dash_velocity
	player.move_and_slide()

	# Optional: if we hit a wall, stop early (feels better than "grinding" into it)
	if player.get_slide_collision_count() > 0:
		dash_time = dash_duration

	return null

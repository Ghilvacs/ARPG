class_name StateDashAttackRelease
extends PlayerState

@export var dash_attack_stamina_cost: float = 20.0
@export var dash_distance: float = 60.0
@export var dash_duration: float = 0.12

@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"

var dash_moving := false
var dash_tween: Tween
var effect_timer := 0.0
var attack_direction: Vector2


func enter() -> void:
	Engine.time_scale = 1.0
	player.animation_player.speed_scale = 1.0
	player.velocity = Vector2.ZERO
	dash_moving = false
	effect_timer = 0.0

	# pay cost + start release anim + movement
	player.dash_audio.play()
	player.consume_stamina(dash_attack_stamina_cost)

	var mouse_global := player.get_global_mouse_position()
	var mouse_local := player.to_local(mouse_global)

	_play_dash_release_anim(mouse_local)
	_start_dash_attack_movement(mouse_global, mouse_local)


func update(delta: float) -> PlayerState:
	if dash_moving:
		effect_timer -= delta
		if effect_timer <= 0.0:
			effect_timer = player.dash_effect_delay
			player.spawn_dash_effect()
		return null

	# movement done; wait for animation-driven isAttacking to end
	if !player.isAttacking:
		player.resume_stamina_regen()
		return idle if player.direction == Vector2.ZERO else walk

	return null


func physics_update(_delta: float) -> PlayerState:
	player.velocity = Vector2.ZERO
	return null


func _play_dash_release_anim(mouse_local: Vector2) -> void:
	var anim := "attack_dash_side"
	if mouse_local.y < -30 and abs(mouse_local.x) < 150:
		anim = "attack_dash_up"
	elif mouse_local.y > 30 and abs(mouse_local.x) < 150:
		anim = "attack_dash_down"

	player.animation_player.play(anim)


func _start_dash_attack_movement(mouse_global: Vector2, mouse_local: Vector2) -> void:
	dash_moving = true
	effect_timer = 0.0

	# lock facing during dash
	player.blade_one_attack_point.look_at(mouse_global)
	player.point_light.look_at(mouse_global)
	player.sprite.flip_h = mouse_local.x < 0

	attack_direction = (mouse_global - player.global_position).normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2.RIGHT

	var target := player.global_position + attack_direction * dash_distance

	if dash_tween and dash_tween.is_valid():
		dash_tween.kill()

	dash_tween = player.create_tween()
	dash_tween.set_trans(Tween.TRANS_QUAD)
	dash_tween.set_ease(Tween.EASE_OUT)
	dash_tween.tween_property(player, "global_position", target, dash_duration)
	dash_tween.tween_callback(func(): dash_moving = false)

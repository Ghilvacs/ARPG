class_name StateAttackCombo
extends PlayerState

@export var stamina_cost: float = 5.0
@export var attack_distance: float = 8.0
@export var attack_duration: float = 0.1
@export var combo_window_time: float = 0.25

@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"
@onready var dash: PlayerState = $"../Dash"

var attack_started := false
var combo_buffered := false
var combo_paused := false
var combo_timer := 0.0
var last_attack_variant := "side"
var _moved_this_attack := false
var _played_attack_sound: = false

var dash_tween: Tween
var attack_direction: Vector2


func enter() -> void:
	player.update_facing()
	attack_started = false
	_moved_this_attack = false
	_played_attack_sound = false
	combo_buffered = false
	combo_paused = false
	combo_timer = 0.0
	last_attack_variant = "side"

	player.velocity = Vector2.ZERO

	if !player.ComboPauseRequested.is_connected(_on_combo_pause_requested):
		player.ComboPauseRequested.connect(_on_combo_pause_requested)

	_start_normal_attack()


func exit() -> void:
	if player and player.ComboPauseRequested.is_connected(_on_combo_pause_requested):
		player.ComboPauseRequested.disconnect(_on_combo_pause_requested)

	# safety: if we were paused on last frame, ensure we aren't stuck
	if player and player.animation_player:
		_resume_animation()

	attack_started = false
	combo_buffered = false
	combo_paused = false
	combo_timer = 0.0


func update(delta: float) -> PlayerState:
	# buffer second press anytime during combo state
	if Input.is_action_just_pressed("attack"):
		combo_buffered = true

	# combo hold window (frozen last frame)
	if combo_paused:
		if Input.is_action_just_pressed("dash") and player.dash_cooldown == 0.0:
			_cancel_combo_hold()
			return dash
		
		if player.direction != Vector2.ZERO:
			_cancel_combo_hold()
			return walk
		
		combo_timer -= delta

		if combo_buffered:
			_start_attack_two()
			return null

		if combo_timer <= 0.0:
			_end_combo_hold()
			return idle if player.direction == Vector2.ZERO else walk

		return null

	# finished attacking normally -> go back
	if !player.isAttacking:
		return idle if player.direction == Vector2.ZERO else walk

	return null


func physics_update(_delta: float) -> PlayerState:
	player.velocity = Vector2.ZERO
	return null


# ---- core actions ----

func _start_normal_attack() -> void:
	if attack_started:
		return
	if player.current_stamina < stamina_cost:
		return

	attack_started = true
	_moved_this_attack = false
	_played_attack_sound = false

	_play_attack_one_variant()


func _play_attack_one_variant() -> void:
	var mouse_pos := player.get_local_mouse_position()

	var anim := "attack_one"
#	last_attack_variant = "side"

	if mouse_pos.y < -30 and abs(mouse_pos.x) < 150:
		anim = "attack_one_up"
#		last_attack_variant = "up"
	elif mouse_pos.y > 30 and abs(mouse_pos.x) < 150:
		anim = "attack_one_down"
#		last_attack_variant = "down"

	player.consume_stamina(stamina_cost)
	player.animation_player.play(anim)

	player.resume_stamina_regen()


func _on_combo_pause_requested(window: float) -> void:
	# only relevant while this state is active
	combo_paused = true
	combo_timer = max(0.0, window)
	player.animation_player.pause()

	# if press already buffered, chain immediately
	if combo_buffered:
		_start_attack_two()


func _start_attack_two() -> void:
	combo_paused = false
	combo_timer = 0.0
	combo_buffered = false
	_moved_this_attack = false
	_played_attack_sound = false
	
	var anim := "attack_two"
	
	var mouse_pos := player.get_local_mouse_position()
	if mouse_pos.y < -30 and abs(mouse_pos.x) < 150:
		anim = "attack_two_up"
	elif mouse_pos.y > 30 and abs(mouse_pos.x) < 150:
		anim = "attack_two_down"

	player.consume_stamina(stamina_cost)
	player.force_update_facing()
	player.animation_player.play(anim)

	player.resume_stamina_regen()


func _end_combo_hold() -> void:
	combo_paused = false
	combo_timer = 0.0
	combo_buffered = false

	_resume_animation()
	player.isAttacking = false
	player.animation_player.play("idle")


# ---- movement ----

func _start_base_attack_movement() -> void:
	if _moved_this_attack:
		return
	_moved_this_attack = true

	if dash_tween and dash_tween.is_valid():
		dash_tween.kill()

	var mouse_global := player.get_global_mouse_position()
	attack_direction = (mouse_global - player.global_position).normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2.RIGHT

	var target := player.global_position + attack_direction * attack_distance

	dash_tween = player.create_tween()
	dash_tween.set_trans(Tween.TRANS_QUAD)
	dash_tween.set_ease(Tween.EASE_OUT)
	dash_tween.tween_property(player, "global_position", target, attack_duration)


func _play_attack_audio() -> void:
	if _played_attack_sound:
		return
	_played_attack_sound = true
	player.sword_swing_audio.play_sword_swing()


func _resume_animation() -> void:
	var ap = player.animation_player
	var anim = ap.current_animation
	var pos = ap.current_animation_position
	ap.play(anim)
	ap.seek(pos, true)


func _cancel_combo_hold() -> void:
	combo_paused = false
	combo_timer = 0.0
	combo_buffered = false

	_resume_animation()
	player.isAttacking = false
	player.animation_player.play("idle")

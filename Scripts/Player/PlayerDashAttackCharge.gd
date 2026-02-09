class_name StateDashAttackCharge
extends PlayerState

@export var dash_attack_stamina_cost: float = 50.0
@export var dash_attack_hold_time: float = 0.2
@export var dash_buildup_zoom: Vector2 = Vector2(7.0, 7.0)
@export var dash_zoom_in_time: float = 0.5
@export var dash_zoom_out_time: float = 0.1
@export var dash_attack_slow_speed: float = 0.25

@onready var dash_release: PlayerState = $"../DashAttackRelease"
@onready var attack_combo: PlayerState = $"../AttackCombo"
@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"

var hold_time := 0.0
var started_buildup := false


func enter() -> void:
	hold_time = 0.0
	started_buildup = false

	if player.animation_player and !player.animation_player.animation_finished.is_connected(_on_anim_finished):
		player.animation_player.animation_finished.connect(_on_anim_finished)


func update(delta: float) -> PlayerState:
	if Input.is_action_pressed("attack"):
		hold_time += delta

		# Always allow facing updates while holding
		var mouse_global := player.get_global_mouse_position()
		var mouse_local := player.to_local(mouse_global)
		player.blade_one_attack_point.look_at(mouse_global)
		player.point_light.look_at(mouse_global)
		player.sprite.flip_h = mouse_local.x < 0

		# --- PREP PHASE: before threshold ---
		if !started_buildup:
			# Threshold reached: only commit if stamina allows
			if hold_time >= dash_attack_hold_time and player.current_stamina >= dash_attack_stamina_cost:
				started_buildup = true
				player.isAttacking = true

				player.velocity = Vector2.ZERO
				player.animation_player.play("attack_dash_buildup") # NOT looping

				Engine.time_scale = dash_attack_slow_speed
				player.animation_player.speed_scale = 1.0 / dash_attack_slow_speed

				player.tween_camera_zoom(dash_buildup_zoom, dash_zoom_in_time)

			return null

		# --- CHARGING PHASE: after threshold ---
		# Freeze movement while charging / holding pose
		player.velocity = Vector2.ZERO
		return null

	# Released
	if !started_buildup and hold_time < dash_attack_hold_time:
		# Tap -> normal attack
		return attack_combo

	if started_buildup:
		# Release -> dash release attack
		player.tween_camera_zoom(player.normal_camera_zoom, dash_zoom_out_time)
		return dash_release

	# Held too long but couldn't afford stamina -> treat as normal attack (or return to locomotion if you prefer)
	return attack_combo


func physics_update(_delta: float) -> PlayerState:
	# Only lock physics movement once we actually started buildup.
	if started_buildup:
		player.velocity = Vector2.ZERO
	return null


func exit() -> void:
	player.tween_camera_zoom(player.normal_camera_zoom, dash_zoom_out_time)

	if player.animation_player and player.animation_player.animation_finished.is_connected(_on_anim_finished):
		player.animation_player.animation_finished.disconnect(_on_anim_finished)

	# If we paused buildup, don't leave it paused
	if player.animation_player:
		_resume_animation()
	
	Engine.time_scale = 1.0
	player.animation_player.speed_scale = 1.0


func _on_anim_finished(anim_name: StringName) -> void:
	if anim_name == "attack_dash_buildup":
		player.animation_player.pause() # hold last frame until release


func _resume_animation() -> void:
	if !player or !player.animation_player:
		return
	var ap = player.animation_player
	var anim = ap.current_animation
	var pos = ap.current_animation_position
	ap.play(anim)
	ap.seek(pos, true)

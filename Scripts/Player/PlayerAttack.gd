class_name StateAttack extends PlayerState

@export var stamina_cost: float = 5.0
@export var dash_attack_stamina_cost: float = 20.0
@export var attack_distance: float = 8.0
@export var attack_duration: float = 0.1
@export var dash_distance: float = 60.0
@export var dash_duration: float = 0.12
@export var dash_attack_charge_duration: float = 0.2
@export var dash_attack_slow_speed: float = 0.25
@export var dash_attack_hold_time: float = 0.2
@export var dash_buildup_zoom: Vector2 = Vector2(7.0, 7.0) # zoom in (bigger values = closer)
@export var dash_zoom_in_time: float = 0.5
@export var dash_zoom_out_time: float = 0.1
@export var combo_window_time: float = 0.25

@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"
@onready var dash: PlayerState = $"../Dash"  # if you still need separate dash

var attack_started := false
var used_dash_attack := false
var is_charging_dash := false
var hold_time := 0.0
var dash_charge_time := 0.0
var dash_moving := false
var dash_tween: Tween
var attack_direction: Vector2
var dash_release_started := false
var dash_release_anim := ""
var effect_timer := 0.0
var combo_buffered := false
var combo_paused := false
var combo_timer := 0.0
var last_attack_variant := "side"
var _moved_this_attack := false


func enter():
	player.update_facing()
	attack_started = false
	_moved_this_attack = false
	
	used_dash_attack = false
	is_charging_dash = false
	hold_time = 0.0
	dash_charge_time = 0.0
	
	combo_buffered = false
	combo_paused = false
	combo_timer = 0.0
	last_attack_variant = "side"
	
	player.velocity = Vector2.ZERO  # stop movement while attacking
	
	if !player.ComboPauseRequested.is_connected(_on_combo_pause_requested):
		player.ComboPauseRequested.connect(_on_combo_pause_requested)


func exit():
	attack_started = false
	used_dash_attack = false
	is_charging_dash = false
	hold_time = 0.0
	dash_charge_time = 0.0
	
	combo_buffered = false
	combo_paused = false
	combo_timer = 0.0

	if player and player.ComboPauseRequested.is_connected(_on_combo_pause_requested):
		player.ComboPauseRequested.disconnect(_on_combo_pause_requested)

	# Safety: if we paused the animation during combo hold, unpause it
	if player and player.animation_player:
		_resume_animation()
	
	player.tween_camera_zoom(player.normal_camera_zoom, dash_zoom_out_time)
	
	# Reset time and animation speed on any exit, just to be safe
	Engine.time_scale = 1.0
	player.animation_player.speed_scale = 1.0


func update(delta: float) -> PlayerState:
	# Special handling if we're in dash-attack mode
	if used_dash_attack:
		return _update_dash_attack(delta)

	# ---------- NORMAL ATTACK / DASH DECISION PHASE ----------

	# We haven't started any attack animation yet: decide what to do
	if !attack_started:
		# Button is being held → accumulate hold time
		if Input.is_action_pressed("attack"):
			hold_time += delta

			# If they hold long enough → use dash attack
			if hold_time >= dash_attack_hold_time:
				if _start_dash_attack():
					return null
		else:
			# Button released before threshold → use normal attack
			if hold_time > 0.0 and !attack_started:
				_start_normal_attack()
			return null

		# Still deciding, stay in this state
		return null

	# ---------- NORMAL ATTACK ALREADY RUNNING (non-dash) ----------

	if !player.isAttacking:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk
	
	if attack_started and !used_dash_attack and Input.is_action_just_pressed("attack"):
		combo_buffered = true

	# If we are paused on the last frame waiting for combo input
	if combo_paused:
		combo_timer -= delta

		# If press happens during the window (or was buffered), chain
		if combo_buffered:
			_start_attack_two()
			return null

		# Window expired -> return to locomotion
		if combo_timer <= 0.0:
			_end_combo_hold()
			if player.direction == Vector2.ZERO:
				return idle
			return walk

		return null
	
	return null


func physics_update(_delta: float) -> PlayerState:
	# Let the animation control the motion (root motion / dash handled elsewhere)
	player.velocity = Vector2.ZERO
	return null


func handle_input(_event: InputEvent) -> PlayerState:
	# Optional: allow separate dash button if you still want that
	if !attack_started and _event.is_action_pressed("dash") and player.dash_cooldown == 0.0:
		return dash
	return null

# ==================== HELPERS ====================

func _start_normal_attack() -> void:
	if attack_started:
		return
	if player.current_stamina < stamina_cost:
		return

	attack_started = true

	_start_base_attack_movement()
	_handle_attack_animation()


func _start_dash_attack() -> bool:
	if attack_started:
		return false
	if player.current_stamina < dash_attack_stamina_cost:
		return false

	used_dash_attack = true
	is_charging_dash = true
	attack_started = true
	dash_charge_time = 0.0
	dash_release_started = false
	dash_release_anim = ""

	# Start buildup (make this animation loop in the editor)
	player.isAttacking = true
	player.animation_player.play("attack_dash_buildup")
	player.tween_camera_zoom(dash_buildup_zoom, dash_zoom_in_time)

	return true


func _update_dash_attack(delta: float) -> PlayerState:
	var mouse_global := player.get_global_mouse_position()
	var mouse_local := player.to_local(mouse_global)

	# Keep aiming while charging (so blade points correctly)
	if is_charging_dash:
		player.blade_one_attack_point.look_at(mouse_global)
		player.point_light.look_at(mouse_global)
		player.sprite.flip_h = mouse_local.x < 0

		# Wait for release
		if Input.is_action_just_released("attack"):
			player.dash_audio.play()
			is_charging_dash = false
			player.consume_stamina(dash_attack_stamina_cost)
			player.tween_camera_zoom(player.normal_camera_zoom, dash_zoom_out_time)
			_start_dash_release_attack(mouse_local)
			_start_dash_attack_movement()
			return null
		return null

	# After release: wait for dash movement and animation to finish
	if dash_moving:
		effect_timer -= delta
		if effect_timer <= 0.0:
			effect_timer = player.dash_effect_delay
			player.spawn_dash_effect()
		return null

	# Dash movement done; now wait for animation end via isAttacking
	if !player.isAttacking:
		player.resume_stamina_regen()
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk

	return null


func _start_base_attack_movement() -> void:
	if _moved_this_attack:
		return
	_moved_this_attack = true

	# kill previous tween so we don't stack movement
	if dash_tween and dash_tween.is_valid():
		dash_tween.kill()

	var mouse_global := player.get_global_mouse_position()
	attack_direction = (mouse_global - player.global_position).normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2.RIGHT

	var target_position := player.global_position + attack_direction * attack_distance

	dash_tween = player.create_tween()
	dash_tween.set_trans(Tween.TRANS_QUAD)
	dash_tween.set_ease(Tween.EASE_OUT)
	dash_tween.tween_property(player, "global_position", target_position, attack_duration)


func _start_dash_attack_movement() -> void:
	var mouse_global := player.get_global_mouse_position()
	var mouse_local := player.to_local(mouse_global)
	dash_moving = true
	effect_timer = 0.0

	# 🔁 Force blade + light to look at the mouse even while attacking
	player.blade_one_attack_point.look_at(mouse_global)
	player.point_light.look_at(mouse_global)
	player.sprite.flip_h = mouse_local.x < 0

	# Dash direction = towards mouse
	attack_direction = (mouse_global - player.global_position).normalized()
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2.RIGHT  # fallback

	var target_position := player.global_position + attack_direction * dash_distance

	dash_tween = player.create_tween()
	dash_tween.set_trans(Tween.TRANS_QUAD)
	dash_tween.set_ease(Tween.EASE_OUT)
	dash_tween.tween_property(player, "global_position", target_position, dash_duration)
	dash_tween.tween_callback(func():
		dash_moving = false
	)


func _start_dash_release_attack(mouse_local: Vector2) -> void:
	if dash_release_started:
		return

	dash_release_started = true

	var anim := "attack_dash_side"
	if mouse_local.y < -30 and abs(mouse_local.x) < 150:
		anim = "attack_dash_up"
	elif mouse_local.y > 30 and abs(mouse_local.x) < 150:
		anim = "attack_dash_down"

	dash_release_anim = anim
	player.animation_player.play(anim)


func _on_combo_pause_requested(window: float) -> void:
	# Only allow this for normal attack_one, not dash attacks
	if used_dash_attack:
		return
	if !attack_started:
		return

	combo_paused = true
	combo_timer = max(0.0, window)

	# Freeze on last frame
	player.animation_player.pause()

	# If the player already buffered the input, chain immediately
	if combo_buffered:
		_start_attack_two()


func _start_attack_two() -> void:
	combo_paused = false
	combo_timer = 0.0
	combo_buffered = false
	
	_moved_this_attack = false

	var anim := "attack_two"
	if last_attack_variant == "up":
		anim = "attack_two_up"
	elif last_attack_variant == "down":
		anim = "attack_two_down"
	if !player.animation_player.has_animation(anim):
		anim = "attack_two"

	player.consume_stamina(stamina_cost)
	player.animation_player.play(anim)


func _end_combo_hold() -> void:
	combo_paused = false
	combo_timer = 0.0
	combo_buffered = false

	# Unpause and snap out to idle/walk. Idle anim should keep hitboxes disabled.
	_resume_animation()
	player.isAttacking = false
	player.animation_player.play("idle")


func _handle_attack_animation():
	if player.current_stamina < stamina_cost:
		return

	var mouse_pos = player.get_local_mouse_position()

	var anim_name := "attack_one"
	last_attack_variant = "side"

	if mouse_pos.y < -30 and abs(mouse_pos.x) < 150:
		anim_name = "attack_one_up"
		last_attack_variant = "up"
	elif mouse_pos.y > 30 and abs(mouse_pos.x) < 150:
		anim_name = "attack_one_down"
		last_attack_variant = "down"

	attack(anim_name)


func _resume_animation() -> void:
	if !player or !player.animation_player:
		return

	var ap = player.animation_player
	var anim = ap.current_animation
	var pos = ap.current_animation_position

	# Calling play() resumes if paused, but it restarts unless we restore position.
	ap.play(anim)
	ap.seek(pos, true)


func attack(animation: String) -> void:
	player.consume_stamina(stamina_cost)
	player.animation_player.play(animation)

	if animation in ["attack_one", "attack_one_up", "attack_one_down", "attack_dash"]:
		await get_tree().process_frame
	
	player.resume_stamina_regen()

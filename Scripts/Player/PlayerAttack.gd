class_name StateAttack extends PlayerState

@export var stamina_cost: float = 5.0
@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"
@onready var dash: PlayerState = $"../Dash"

var attack_started := false

func enter():
	player.update_facing()
	attack_started = false
	player.velocity = Vector2.ZERO  # Stop movement while attacking
	_handle_attack_animation()

func exit():
	player.blade_area_one.get_node("CollisionShape2D").disabled = true
	player.isAttacking = false
	attack_started = false

func update(_delta: float) -> PlayerState:
	if !player.isAttacking:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk
	
	return null

func physics_update(_delta: float) -> PlayerState:
	return null

func handle_input(_event: InputEvent) -> PlayerState:
	if _event.is_action_pressed("dash") and player.current_stamina >= 20:
		return dash
	return null

func _handle_attack_animation():
#	if player.current_stamina < stamina_cost:
#		return

	player.isAttacking = true
#	player.current_stamina -= stamina_cost
#	player.StaminaChanged.emit(player.current_stamina)

	var mouse_pos = player.get_local_mouse_position()

	# Determine attack direction
	var anim_name := "attack_one"
	if mouse_pos.y < -30 and abs(mouse_pos.x) < 150:
		anim_name = "attack_one_up"
	elif mouse_pos.y > 30 and abs(mouse_pos.x) < 150:
		anim_name = "attack_one_down"

	attack(anim_name)

func attack(animation: String) -> void:
#	player.timer_stamina_regen.stop()
#	if player.timer_stamina_regen_start.is_stopped():
#		player.timer_stamina_regen_start.start()
	player.animation_player.play(animation)
	if animation in ["attack_one", "attack_one_up", "attack_one_down"]:
		player.blade_area_one.get_node("CollisionShape2D").disabled = false
		await get_tree().process_frame
	elif animation == "attack_two":
		player.blade_area_two.get_child(0).disabled = false

extends CharacterBody2D
signal EnemyDamaged
signal HealthChanged
signal StaminaChanged

const MAX_HEALTH = 100
const MAX_STAMINA = 100
const MAX_SPEED = 350

var current_health
var current_stamina
var current_speed
var isAttacking = false
var enemy: CharacterBody2D
var dead = false
var attack_speed
var mouse_position
var last_position
var dash_speed = 3000

@onready var sprite: Sprite2D = $Sprite2D
@onready var death_sprite: Sprite2D = $DeathSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var blade_area_two: Area2D = $BladeAreaTwo
@onready var timer_take_damage: Timer = $TimerTakeDamage
@onready var timer_death: Timer = $TimerDeath
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var blade_area_one: Area2D = $BladeOnePivot/BladeOneAttackPoint/BladeAreaOne
@onready var blade_one_attack_point: Marker2D = $BladeOnePivot/BladeOneAttackPoint
@onready var point_light: Marker2D = $PivotLight/PointLight
@onready var timer_stamina_regen: Timer = $TimerStaminaRegen
@onready var timer_stamina_regen_start: Timer = $TimerStaminaRegenStart

func _ready() -> void:
	current_health = MAX_HEALTH
	current_stamina = MAX_STAMINA
	animation_player.get_animation("idle").loop = true

func _physics_process(delta: float) -> void:
	if dead:
		point_light.visible = false
		if animation_player.is_playing() && animation_player.current_animation != "death":
			sprite.visible = false
			death_sprite.visible = true
			animation_player.play("death")
		return
	
	if current_stamina > 99.9:
		timer_stamina_regen.stop()
	
	if animation_player.current_animation == "attack_one" || "attack_one_up" || "attack_one_down" && animation_player.current_animation_position > 0.1:
		blade_area_one.get_child(0).disabled = true
	
	mouse_position = get_local_mouse_position()
	blade_one_attack_point.look_at(get_global_mouse_position())
	point_light.look_at(get_global_mouse_position())
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if !isAttacking:
		if Input.is_action_pressed("sprint") && current_stamina > 0:
			if sprite.flip_h && direction.x < 0 || !sprite.flip_h && direction.x > 0:
				timer_stamina_regen.stop()
				current_stamina -= 0.5
				StaminaChanged.emit(current_stamina)
				current_speed = MAX_SPEED
			else:
				current_speed = MAX_SPEED / 2
				if timer_stamina_regen_start.is_stopped():
					timer_stamina_regen_start.start()
		else:
			current_speed = MAX_SPEED / 2
			if timer_stamina_regen_start.is_stopped():
					timer_stamina_regen_start.start()

		velocity = direction * current_speed
	else:
		velocity = Vector2.ZERO
		
	
	if get_global_mouse_position().x > sprite.global_position.x && !isAttacking:
		sprite.flip_h = false
	elif get_global_mouse_position().x < sprite.global_position.x && !isAttacking:
		sprite.flip_h = true

	if direction && !isAttacking:
			animation_player.play("run")
	else:
		if !isAttacking:
			animation_player.play("idle")
	
	if Input.is_action_just_pressed("dash"):
		dash(direction, delta)
	
	move_and_slide()
	
	if Input.is_action_just_pressed("attack") && current_stamina >= 10:
		last_position = mouse_position.x > 0
		if mouse_position.y < -30 && mouse_position.x < 150 && mouse_position.x > -150:
			attack("attack_one_up")
		elif mouse_position.y > 30 && mouse_position.x < 150 && mouse_position.x > -150:
			attack("attack_one_down")
		else:
			if animation_player.current_animation == "attack_one" && animation_player.current_animation_position > 2:
				if last_position == (mouse_position.x > 0):
					blade_area_one.get_child(0).disabled = true
					attack("attack_two")
			elif !isAttacking:
				attack("attack_one")

func death() -> void:
	collision_shape.disabled = true
	sprite.z_index = 0
	blade_area_one.get_child(0).disabled = true
	get_node("BladeAreaTwo/CollisionShape2D").disabled = true
	current_speed = 0
	dead = true

func attack(animation: String) -> void:
	timer_stamina_regen.stop()
	if timer_stamina_regen_start.is_stopped():
		timer_stamina_regen_start.start()
	current_stamina -= 10
	StaminaChanged.emit(current_stamina)
	animation_player.play(animation)
	isAttacking = true
	if animation == "attack_one" || "attack_one_up" || "attack_one_down":
		blade_area_one.get_child(0).disabled = false
	elif animation == "attack_two":
		blade_area_two.get_child(0).disabled = false

func take_damage() -> void:
	if timer_take_damage.is_stopped():
		current_health -= 20
		HealthChanged.emit(current_health)
		sprite.material.set_shader_parameter('opacity', 0.9)
		sprite.material.set_shader_parameter('r', 1.0)
		sprite.material.set_shader_parameter('g', 0)
		sprite.material.set_shader_parameter('b', 0)
		sprite.material.set_shader_parameter('mix_color', 0.5)
		timer_take_damage.start(0)

func dash(direction: Vector2, delta: float) -> void:
	if current_stamina >= 20:
		timer_stamina_regen.stop()
		if timer_stamina_regen_start.is_stopped():
			timer_stamina_regen_start.start()
		current_stamina -= 20
		StaminaChanged.emit(current_stamina)
		velocity = direction.normalized() * dash_speed
		velocity *= 1.0 - (0.5 * delta)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("GoblinTorch"):
		take_damage()

func _on_timer_take_damage_timeout() -> void:
	if current_health < 1:
		death()
	sprite.material.set_shader_parameter('opacity', 1.0)
	sprite.material.set_shader_parameter('r', 0)
	sprite.material.set_shader_parameter('mix_color', 0)
	timer_take_damage.stop()

func _on_timer_death_timeout() -> void:
	get_tree().reload_current_scene()

func _on_timer_stamina_regen_timeout() -> void:
	current_stamina += 20
	StaminaChanged.emit(current_stamina)

func _on_timer_stamina_regen_start_timeout() -> void:
	if current_stamina < 100:
		if timer_stamina_regen.is_stopped():
			timer_stamina_regen.start()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		timer_death.start()
	elif anim_name == "attack_two":
		blade_area_two.get_child(0).disabled = true
		isAttacking = false
	elif anim_name == "attack_one" || "attack_one_up" || "attack_one_down":
		blade_area_one.get_child(0).disabled = true
		isAttacking = false

extends CharacterBody2D
signal EnemyDamaged
signal HealthChanged

const MAX_HEALTH = 100

var speed = 300
var current_health
var isAttacking = false
var enemy: CharacterBody2D
var dead = false
var attack_speed
var mouse_position
var last_position

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var blade_area_two: Area2D = $BladeAreaTwo
@onready var timer_take_damage: Timer = $TimerTakeDamage
@onready var timer_death: Timer = $TimerDeath
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var blade_area_one: Area2D = $BladeOnePivot/BladeOneAttackPoint/BladeAreaOne
@onready var blade_one_attack_point: Marker2D = $BladeOnePivot/BladeOneAttackPoint
@onready var point_light: Marker2D = $PivotLight/PointLight

func _ready() -> void:
	current_health = MAX_HEALTH

func _physics_process(delta: float) -> void:
	if dead:
		point_light.visible = false
		if animated_sprite.animation != "death":
			animated_sprite.play("death")
		return

	if animated_sprite.animation == "attack_one" || "attack_one_up" || "attack_one_down" && animated_sprite.frame > 1:
		blade_area_one.get_child(0).disabled = true
	
	mouse_position = get_local_mouse_position()
	blade_one_attack_point.look_at(get_global_mouse_position())
	point_light.look_at(get_global_mouse_position())
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if !isAttacking:
		if animated_sprite.flip_h && direction.x < 0 || !animated_sprite.flip_h && direction.x > 0:
			velocity = direction * speed
		else:
			velocity = direction * speed / 2
	else:
		velocity = Vector2.ZERO
	
	if get_global_mouse_position().x > animated_sprite.global_position.x && !isAttacking:
		animated_sprite.flip_h = false
	elif get_global_mouse_position().x < animated_sprite.global_position.x && !isAttacking:
		animated_sprite.flip_h = true

	if direction && !isAttacking:
		animated_sprite.play("run")
	else:
		if !isAttacking:
			animated_sprite.play("idle")
	
	move_and_slide()
	
	if Input.is_action_just_pressed("attack"):
		last_position = mouse_position.x > 0
		if mouse_position.y < -30 && mouse_position.x < 150 && mouse_position.x > -150:
			attack("attack_one_up")
		elif mouse_position.y > 30 && mouse_position.x < 150 && mouse_position.x > -150:
			attack("attack_one_down")
		else:
			if animated_sprite.animation == "attack_one" && animated_sprite.frame > 2:
				if last_position == (mouse_position.x > 0):
					blade_area_one.get_child(0).disabled = true
					attack("attack_two")
			elif !isAttacking:
				attack("attack_one")

func death() -> void:
	collision_shape.disabled = true
	animated_sprite.z_index = 0
	blade_area_one.get_child(0).disabled = true
	get_node("BladeAreaTwo/CollisionShape2D").disabled = true
	speed = 0
	dead = true

func attack(animation: String) -> void:
	animated_sprite.play(animation)
	isAttacking = true
	if animation == "attack_one" || "attack_one_up" || "attack_one_down":
		blade_area_one.get_child(0).disabled = false
	elif animation == "attack_two":
		blade_area_two.get_child(0).disabled = false

func take_damage() -> void:
	if timer_take_damage.is_stopped():
		current_health -= 20
		HealthChanged.emit(current_health)
		animated_sprite.material.set_shader_parameter('opacity', 0.9)
		animated_sprite.material.set_shader_parameter('r', 1.0)
		animated_sprite.material.set_shader_parameter('g', 0)
		animated_sprite.material.set_shader_parameter('b', 0)
		animated_sprite.material.set_shader_parameter('mix_color', 0.5)
		timer_take_damage.start(0)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "death":
		timer_death.start()
	elif animated_sprite.animation == "attack_two":
		blade_area_two.get_child(0).disabled = true
		isAttacking = false
	elif animated_sprite.animation == "attack_one" || "attack_one_up" || "attack_one_down":
		blade_area_one.get_child(0).disabled = true
		isAttacking = false

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("GoblinTorch"):
		take_damage()

func _on_timer_take_damage_timeout() -> void:
	if current_health < 1:
		death()
	animated_sprite.material.set_shader_parameter('opacity', 1.0)
	animated_sprite.material.set_shader_parameter('r', 0)
	animated_sprite.material.set_shader_parameter('mix_color', 0)
	timer_take_damage.stop()

func _on_timer_death_timeout() -> void:
	get_tree().reload_current_scene()

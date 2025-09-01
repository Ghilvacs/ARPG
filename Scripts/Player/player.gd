extends CharacterBody2D

signal EnemyDamaged
signal HealthChanged
signal StaminaChanged
signal PlayerDied

const MAX_HEALTH = 5
const MAX_STAMINA = 100

var current_health
var current_stamina = MAX_STAMINA
var isAttacking = false
var enemy: CharacterBody2D
var dead = false
var attack_speed
var mouse_position
var last_position
var direction: Vector2
var stamina_regen = false

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
@onready var timer_stamina_regen_start: Timer = $TimerStaminaRegenStart
@onready var player_state_machine: Node = $PlayerStateMachine
@onready var crystals = $Sprite2D.get_children()

func _ready() -> void:
	current_health = MAX_HEALTH
#	current_stamina = MAX_STAMINA
	player_state_machine.initialize(self)
	StaminaChanged.emit(current_stamina)

func _physics_process(delta: float) -> void:
	player_state_machine.current_state.physics_update(delta)
	if dead:
		point_light.visible = false
		if animation_player.is_playing() && animation_player.current_animation != "death":
			sprite.visible = false
			death_sprite.visible = true
			animation_player.play("death")
		return
	
	if current_stamina > 99.9:
		current_stamina = 100.0
		stamina_regen = false
		timer_stamina_regen_start.stop()
	
	if stamina_regen:
		if current_stamina < 0:
			current_stamina = 0
		current_stamina += 0.2
		StaminaChanged.emit(current_stamina)
	
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()
	
	update_facing()
	
	move_and_slide()

func update_animation(state: String) -> void:
	animation_player.play(state)

func update_facing() -> void:
	mouse_position = get_local_mouse_position()
	if !isAttacking:
		blade_one_attack_point.look_at(get_global_mouse_position())
		point_light.look_at(get_global_mouse_position())
		sprite.flip_h = mouse_position.x < 0

func death() -> void:
	collision_shape.disabled = true
	sprite.z_index = 0
	blade_area_one.get_child(0).disabled = true
	get_node("BladeAreaTwo/CollisionShape2D").disabled = true
	dead = true

func take_damage() -> void:
	if timer_take_damage.is_stopped():
		current_health -= 1
		update_crystals()
		HealthChanged.emit(current_health)
		sprite.material.set_shader_parameter('opacity', 0.9)
		sprite.material.set_shader_parameter('r', 1.0)
		sprite.material.set_shader_parameter('g', 0)
		sprite.material.set_shader_parameter('b', 0)
		sprite.material.set_shader_parameter('mix_color', 0.5)
		timer_take_damage.start(0)

func update_crystals() -> void:
	for i in range(crystals.size()):
		var light = crystals[i].get_node("PointLight2D")
		if i < current_health:
			light.visible = true
		else:
			light.visible = false

func get_hp_percent() -> float:
	return float(current_health) / float(MAX_HEALTH)

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
	emit_signal("PlayerDied")
#	get_tree().reload_current_scene()
	queue_free()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		timer_death.start()
	elif anim_name == "attack_two":
		blade_area_two.get_child(0).disabled = true
		isAttacking = false
	elif anim_name in ["attack_one", "attack_one_up", "attack_one_down"]:
		blade_area_one.get_child(0).disabled = true
		isAttacking = false

func _on_timer_stamina_regen_start_timeout() -> void:
	stamina_regen = true

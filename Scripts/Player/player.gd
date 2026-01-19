extends CharacterBody2D

signal EnemyDamaged
signal HealthChanged
signal StaminaChanged
signal PlayerDied
signal DirectionChanged
signal ComboPauseRequested(window: float)

const MAX_HEALTH = 5
const MAX_STAMINA = 100

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
@onready var dash_audio: AudioStreamPlayer2D = $DashAudio
@onready var player_damage_taken_audio: AudioStreamPlayer2D = $PlayerDamageTakenAudio
@onready var player_death_audio: AudioStreamPlayer2D = $PlayerDeathAudio
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var sword_swing_audio: AudioStreamPlayer2D = $SwordSwingAudio

@export var isAttacking = false

@export_category("Dash Effect")
@export var dash_effect_delay: float = 0.01
@export var dash_effect_fade_time: float = 0.2
@export var dash_effect_shader: Shader = preload("res://Scenes/Shaders/player_ghost.gdshader")

var current_health = MAX_HEALTH
var current_stamina = MAX_STAMINA
var enemy: CharacterBody2D
var dead = false
var attack_speed
var mouse_position
var last_position
var direction: Vector2
var stamina_regen = false
var dashed := false
var dash_cooldown := 0.0
var camera_zoom_tween: Tween
var normal_camera_zoom: Vector2
var current_direction: Vector2 = Vector2.ZERO
var input_locked := false


func _ready() -> void:
	player_state_machine.initialize(self)
	if camera:
		normal_camera_zoom = camera.zoom
	current_stamina = MAX_STAMINA
	StaminaChanged.emit(current_stamina)
	var dash_shape := blade_area_one.get_child(1) as CollisionShape2D
	dash_shape.disabled = true


func _physics_process(delta: float) -> void:
	if input_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if dead:
		point_light.visible = false
		if animation_player.is_playing() && animation_player.current_animation != "death":
			sprite.visible = false
			death_sprite.visible = true
			animation_player.play("death")
		return
	
	if dashed && dash_cooldown < 1.0:
		dash_cooldown += delta
	if dash_cooldown >= 1.0:
		dash_cooldown = 0.0
		dashed = false
	
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
	DirectionChanged.emit(direction)
	if !isAttacking:
		blade_one_attack_point.look_at(get_global_mouse_position())
		point_light.look_at(get_global_mouse_position())
		sprite.flip_h = mouse_position.x < 0


func force_update_facing() -> void:
	mouse_position = get_local_mouse_position()
	blade_one_attack_point.look_at(get_global_mouse_position())
	point_light.look_at(get_global_mouse_position())
	sprite.flip_h = mouse_position.x < 0


func update_health(amount: int) -> void:
	current_health += amount
	for crystal in range(crystals.size()):
		var light = crystals[crystal].get_node("PointLight2D")
		if crystal < current_health:
			light.visible = true
		else:
			light.visible = false


func consume_stamina(amount: float) -> void:
	stamina_regen = false
	current_stamina -= amount
	StaminaChanged.emit(current_stamina)


func resume_stamina_regen() -> void:
	if timer_stamina_regen_start.is_stopped():
		timer_stamina_regen_start.start()


func take_hit(hurtbox: Hurtbox) -> void:
	take_damage(hurtbox.damage)


func take_damage(amount: int) -> void:
	if timer_take_damage.is_stopped():
		player_damage_taken_audio.play()
		update_health(-amount)
		HealthChanged.emit(current_health)
		
		shader_color(0.9, 1.0, 0.0, 0.0, 0.5)
		timer_take_damage.start(0)


func spawn_dash_effect() -> void:
	var effect := Node2D.new()
	get_parent().add_child(effect)
	effect.global_position = global_position

	var sprite_copy: Sprite2D = sprite.duplicate()
	sprite_copy.scale = scale
	for child in sprite_copy.get_children():
		child.visible = false
	effect.add_child(sprite_copy)

	var ghost_mat := ShaderMaterial.new()
	ghost_mat.shader = dash_effect_shader
	ghost_mat.set_shader_parameter("opacity", 1.0)
	sprite_copy.material = ghost_mat

	var t := create_tween()
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(ghost_mat, "shader_parameter/opacity", 0.0, dash_effect_fade_time)
	t.chain().tween_callback(effect.queue_free)


func shader_color(
	opacity: float,
	r: float, 
	g: float, 
	b: float, 
	mix_color: float) -> void:
		var shader_mat = sprite.material
		shader_mat.set_shader_parameter('opacity', opacity)
		shader_mat.set_shader_parameter('r', r)
		shader_mat.set_shader_parameter('g', g)
		shader_mat.set_shader_parameter('b', b)
		shader_mat.set_shader_parameter('mix_color', mix_color)


func get_hp_percent() -> float:
	return float(current_health) / float(MAX_HEALTH)


func death() -> void:
	collision_shape.disabled = true
	player_death_audio.play()
	sprite.z_index = 0
	blade_area_one.get_child(0).disabled = true
	get_node("BladeAreaTwo/CollisionShape2D").disabled = true
	dead = true


func set_input_locked(value: bool) -> void:
	input_locked = value
	if input_locked:
		cancel_current_action()


func cancel_current_action() -> void:
	velocity = Vector2.ZERO

	isAttacking = false
	dashed = false
	dash_cooldown = 0.0

	hitbox_collision_shape.disabled = true
	animation_player.play("idle")


func tween_camera_zoom(target_zoom: Vector2, duration: float) -> void:
	if !camera:
		return
	if camera_zoom_tween and camera_zoom_tween.is_running():
		camera_zoom_tween.kill()

	camera_zoom_tween = create_tween()
	camera_zoom_tween.set_trans(Tween.TRANS_QUAD)
	camera_zoom_tween.set_ease(Tween.EASE_OUT)
	camera_zoom_tween.tween_property(camera, "zoom", target_zoom, duration)


func animation_combo_pause(window: float = 0.5) -> void:
	ComboPauseRequested.emit(window)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if area is Hurtbox and area.team == 1:
		var hurtbox := area as Hurtbox
		take_hit(hurtbox)


func _on_timer_take_damage_timeout() -> void:
	if current_health < 1:
		death()
	shader_color(1.0, 1.0, 1.0, 1.0, 0.0)
	timer_take_damage.stop()


func _on_timer_death_timeout() -> void:
	emit_signal("PlayerDied")
	queue_free()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		timer_death.start()


func _on_timer_stamina_regen_start_timeout() -> void:
	stamina_regen = true

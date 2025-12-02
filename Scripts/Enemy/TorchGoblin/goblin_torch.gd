extends CharacterBody2D
signal StaminaChanged

const MAX_HEALTH: int = 4
const MAX_STAMINA: int = 100

var current_health: int
var current_stamina: float
var dead: bool = false
var stunned: bool = false
var hit: bool = false
var player: CharacterBody2D
var isAttacking: bool = false
var facing_direction: Vector2 = Vector2.DOWN
@export_range(-180.0, 180.0) var vision_rotation_offset_deg: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: EnemyStateMachine = $StateMachine
@onready var torch_area: Area2D = $TorchPivot/TorchAttackPoint/TorchArea
@onready var timer_take_damage: Timer = $TimerTakeDamage
@onready var health_bar: ProgressBar = $HealthBar
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var torch_light: PointLight2D = $PointLight2D
@onready var torch_attack_point: Marker2D = $TorchPivot/TorchAttackPoint
@onready var sprite: Sprite2D = $Sprite2D
@onready var death_sprite: Sprite2D = $DeathSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer_stamina_regen: Timer = $TimerStaminaRegen
@onready var timer_stamina_regen_start: Timer = $TimerStaminaRegenStart
@onready var timer_stun: Timer = $TimerStun
@onready var timer_knockback: Timer = $TimerKnockback
@onready var sword_hit_audio: AudioStreamPlayer2D = $SwordHitAudio
@onready var player_detected_audio: AudioStreamPlayer2D = $PlayerDetectedAudio
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea


func _ready() -> void:
	# Global player tracking
	if not GlobalPlayerManager.is_connected("PlayerSpawned", Callable(self, "_on_player_spawned")):
		GlobalPlayerManager.connect("PlayerSpawned", Callable(self, "_on_player_spawned"))
	if not GlobalPlayerManager.is_connected("PlayerDespawned", Callable(self, "_on_player_despawned")):
		GlobalPlayerManager.connect("PlayerDespawned", Callable(self, "_on_player_despawned"))

	# If this enemy should not exist in this level state, remove it early
	if not GlobalLevelManager.is_enemy_alive(name):
		queue_free()
		return

	# Duplicate material so shader tweaks don't affect all instances
	if sprite.material:
		var shader_mat := sprite.material.duplicate()
		sprite.material = shader_mat

	current_health = MAX_HEALTH
	current_stamina = MAX_STAMINA
	health_bar.value = current_health
	stamina_bar.value = current_stamina

	# Initial player reference if already spawned
	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D

	# Make sure the state machine has a reference to this enemy,
	# even if you forgot to set it in the inspector.
	if state_machine:
		state_machine.enemy = self


func _physics_process(_delta: float) -> void:
	# Stamina regen management
	if current_stamina >= MAX_STAMINA - 0.01:
		current_stamina = MAX_STAMINA
		if not timer_stamina_regen.is_stopped():
			timer_stamina_regen.stop()

	# Hide stuff & stop processing movement when dead
	if dead:
		torch_light.visible = false
		health_bar.visible = false
		stamina_bar.visible = false
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Basic locomotion animations (states only set velocity / isAttacking)
	if velocity.length() > 0.0 and not isAttacking:
		animation_player.play("run")
	elif not isAttacking:
		animation_player.play("idle")

	# Flip sprite based on direction & stun status
	if not stunned:
		if velocity.x > 0.0:
			sprite.flip_h = false
		elif velocity.x < 0.0:
			sprite.flip_h = true
	else:
		# While stunned, we can invert logic if you want a "knocked back" look
		if velocity.x < 0.0:
			sprite.flip_h = false
		elif velocity.x > 0.0:
			sprite.flip_h = true
	
	_update_vision_cones()
	move_and_slide()


func take_hit(hurtbox: Hurtbox) -> void:
	take_damage(hurtbox.damage)


func take_damage(damage: int) -> void:
	if timer_take_damage.is_stopped() and not dead:
		hit = true
		sword_hit_audio.play()

		current_health -= damage
		if current_health < 0:
			current_health = 0

		health_bar.value = current_health
		shader_color(0.9, 1.0, 0.0, 0.0, 0.5)
		timer_take_damage.start(0.0)


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


func _update_vision_cones() -> void:
	var direction := velocity
	
	if direction.length() < 0.1 and player:
		direction = player.global_position - global_position
	
	if direction.length() > 0.1:
		facing_direction = direction.normalized()
	
	var angle := facing_direction.angle() + deg_to_rad(vision_rotation_offset_deg)
	
	if detection_area:
		detection_area.rotation = angle
	if attack_area:
		attack_area.rotation = angle


func _on_hitbox_area_entered(area: Area2D) -> void:
	if dead:
		return

	if area is Hurtbox and area.team == 0:
		var hurtbox := area as Hurtbox
		take_hit(hurtbox)


func _on_timer_take_damage_timeout() -> void:
	if current_health < 1 and not dead:
		GlobalLevelManager.record_enemy_state(name, false)
		dead = true
		# States (Wander/Follow/Knockback/Stun) see dead == true and transition to EnemyDead.
	shader_color(1.0, 1.0, 1.0, 1.0, 0.0)
	timer_take_damage.stop()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		queue_free()


func _on_timer_stamina_regen_timeout() -> void:
	if dead:
		return

	current_stamina += 5.0
	if current_stamina > MAX_STAMINA:
		current_stamina = MAX_STAMINA

	stamina_bar.value = current_stamina
	StaminaChanged.emit(current_stamina)


func _on_timer_stamina_regen_start_timeout() -> void:
	if dead:
		return

	if current_stamina < MAX_STAMINA:
		if timer_stamina_regen.is_stopped():
			timer_stamina_regen.start()


func _on_timer_stun_timeout() -> void:
	stunned = false
	timer_stun.stop()


func _on_timer_knockback_timeout() -> void:
	# After knockback finishes, if stun timer isn't already running, start it
	if timer_stun.is_stopped():
		stunned = true
		timer_stun.start(0.0)
	timer_knockback.stop()


func _on_player_spawned(p: CharacterBody2D) -> void:
	player = p


func _on_player_despawned() -> void:
	player = null

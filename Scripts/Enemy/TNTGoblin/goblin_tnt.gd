extends CharacterBody2D
signal StaminaChanged

const MAX_HEALTH = 50
const MAX_STAMINA = 100

var current_health
var current_stamina
var dead = false
var stunned = false
var hit = false
var player: CharacterBody2D
var isAttacking = false
var inCooldown = false
var idle = false
var transitionLocked = false
var pending_target_state = null

@onready var state_machine: Node = $StateMachine
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
@onready var timer_attack: Timer = $TimerAttack
@onready var timer_state_transition: Timer = $TimerStateTransition


func _ready() -> void:
	GlobalPlayerManager.connect("PlayerSpawned", Callable(self, "_on_player_spawned"))
	GlobalPlayerManager.connect("PlayerDespawned", Callable(self, "_on_player_despawned"))
	
	if not GlobalLevelManager.is_enemy_alive(name):
		queue_free()
		
	if sprite.material:
		var shader_mat = sprite.material.duplicate()
		sprite.material = shader_mat
	current_health = MAX_HEALTH
	current_stamina = MAX_STAMINA
	health_bar.value = current_health
	stamina_bar.value = current_stamina
	
	player = get_tree().get_first_node_in_group("Player")


func _physics_process(_delta: float) -> void:
	if current_stamina > 99.9:
		timer_stamina_regen.stop()
		pass
		
	if dead:
		torch_light.visible = false
		health_bar.visible = false
		stamina_bar.visible = false
		return
		
	if velocity.length() > 0 && !isAttacking:
		animation_player.play("run")
	elif animation_player.current_animation != "attack":
		animation_player.play("idle")
	
	if !stunned:
		if velocity.x > 0:
			sprite.flip_h = false
		else:
			sprite.flip_h = true
	else:
		if velocity.x < 0:
			sprite.flip_h = false
		else:
			sprite.flip_h = true
		
	move_and_slide()


func take_damage(damage: int) -> void:
	if timer_take_damage.is_stopped():
		hit = true
#		sword_hit_audio.play()
		current_health -= damage
		health_bar.value = current_health
		var shader_mat = sprite.material
		shader_mat.set_shader_parameter('opacity', 0.9)
		shader_mat.set_shader_parameter('r', 1.0)
		shader_mat.set_shader_parameter('g', 0)
		shader_mat.set_shader_parameter('b', 0)
		shader_mat.set_shader_parameter('mix_color', 0.5)
		timer_take_damage.start(0)


func trigger_state_transition(target_state: String, from_state: Node) -> void:
	if transitionLocked:
		# Don’t start a new transition while locked, but remember what we wanted to do.
		pending_target_state = target_state
		return

	transitionLocked = true
	idle = true
	pending_target_state = target_state
	timer_state_transition.start()


func _on_hitbox_area_entered(area: Area2D) -> void:
	if !dead:
		if area.is_in_group("BladeOne"):
			take_damage(12)
		elif area.is_in_group("BladeTwo"):
			take_damage(24)


func _on_timer_take_damage_timeout() -> void:
	if current_health < 1:
		GlobalLevelManager.record_enemy_state(name, false)
		dead = true
	var shader_mat = sprite.material
	shader_mat.set_shader_parameter('opacity', 1.0)
	shader_mat.set_shader_parameter('r', 1.0)
	shader_mat.set_shader_parameter('g', 1.0)
	shader_mat.set_shader_parameter('b', 1.0)
	shader_mat.set_shader_parameter('mix_color', 0.0)
	timer_take_damage.stop()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "death":
		queue_free()


func _on_timer_stamina_regen_timeout() -> void:
	current_stamina += 5


func _on_timer_stamina_regen_start_timeout() -> void:
	if current_stamina < 100:
		if timer_stamina_regen.is_stopped():
			timer_stamina_regen.start()


func _on_timer_stun_timeout() -> void:
	stunned = false
	timer_stun.stop()


func _on_timer_knockback_timeout() -> void:
	if timer_stun.is_stopped():
		stunned = true
		timer_stun.start(0)
	timer_knockback.stop()


func _on_player_spawned(player: CharacterBody2D) -> void:
		self.player = player


func _on_player_despawned() -> void:
	player = null
	pending_target_state = null


func _on_timer_attack_timeout() -> void:
	inCooldown = false


func _on_timer_state_transition_timeout() -> void:
	transitionLocked = false
	idle = false

	if pending_target_state != null:
		# Perform the actual transition *now*
		state_machine.current_state.Transitioned.emit(
			state_machine.current_state,
			pending_target_state
		)
		pending_target_state = null

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

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: Node = $StateMachine
@onready var torch_area: Area2D = $TorchPivot/TorchAttackPoint/TorchArea
@onready var timer_take_damage: Timer = $TimerTakeDamage
@onready var health_bar: ProgressBar = $HealthBar
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var timer: Timer = $Timer
@onready var torch_light: PointLight2D = $PointLight2D
@onready var torch_attack_point: Marker2D = $TorchPivot/TorchAttackPoint
@onready var sprite: Sprite2D = $Sprite2D
@onready var death_sprite: Sprite2D = $DeathSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer_stamina_regen: Timer = $TimerStaminaRegen
@onready var timer_stamina_regen_start: Timer = $TimerStaminaRegenStart
@onready var timer_stun: Timer = $TimerStun
@onready var timer_knockback: Timer = $TimerKnockback

func _ready() -> void:
	GlobalPlayerManager.connect("PlayerSpawned", Callable(self, "_on_player_spawned"))
	GlobalPlayerManager.connect("PlayerDespawned", Callable(self, "_on_player_despawned"))
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
	if dead:
		torch_light.visible = false
		health_bar.visible = false
		stamina_bar.visible = false
		return
	if velocity.length() > 0 && !isAttacking:
		animation_player.play("run")
	elif !isAttacking:
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
		current_health -= damage
		health_bar.value = current_health
		var shader_mat = sprite.material
		shader_mat.set_shader_parameter('opacity', 0.9)
		shader_mat.set_shader_parameter('r', 1.0)
		shader_mat.set_shader_parameter('g', 0)
		shader_mat.set_shader_parameter('b', 0)
		shader_mat.set_shader_parameter('mix_color', 0.5)
		timer_take_damage.start(0)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if !dead:
		if area.is_in_group("BladeOne"):
			take_damage(12)
		elif area.is_in_group("BladeTwo"):
			take_damage(24)

func _on_timer_take_damage_timeout() -> void:
	if current_health < 1:
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
	print("Knockback timer started")
	if timer_stun.is_stopped():
		print("Stun timer start")
		stunned = true
		timer_stun.start(0)
	print("Knockback timer stop")
	timer_knockback.stop()

func _on_player_spawned(player: CharacterBody2D) -> void:
		self.player = player
		
func _on_player_despawned() -> void:
	player = null

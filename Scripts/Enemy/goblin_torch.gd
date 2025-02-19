extends CharacterBody2D
signal StaminaChanged

const MAX_HEALTH = 50
const MAX_STAMINA = 100

var current_health
var current_stamina
var dead = false
var player: CharacterBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var state_machine: Node = $StateMachine
@onready var torch_area: Area2D = $TorchPivot/TorchAttackPoint/TorchArea
@onready var timer_take_damage: Timer = $TimerTakeDamage
@onready var health_bar: ProgressBar = $HealthBar
@onready var timer: Timer = $Timer
@onready var torch_light: PointLight2D = $PointLight2D
@onready var torch_attack_point: Marker2D = $TorchPivot/TorchAttackPoint
@onready var sprite: Sprite2D = $Sprite2D
@onready var death_sprite: Sprite2D = $DeathSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer_stamina_regen: Timer = $TimerStaminaRegen
@onready var timer_stamina_regen_start: Timer = $TimerStaminaRegenStart

func _ready() -> void:
	current_health = MAX_HEALTH
	current_stamina = MAX_STAMINA
	health_bar.value = current_health
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	print(current_stamina)
	
	if current_stamina > 99.9:
		timer_stamina_regen.stop()
	
	if animation_player.current_animation == "attack" || animation_player.current_animation == "attack_up" || animation_player.current_animation == "attack_down":
		return
	if dead:
		torch_light.visible = false
		health_bar.visible = false
		return
	if velocity.length() > 0:
		animation_player.play("run")
	else:
		animation_player.play("idle")
	if velocity.x > 0:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
		
	move_and_slide()

func take_damage(damage: int) -> void:
	if timer_take_damage.is_stopped():
		current_health -= damage
		health_bar.value = current_health
		sprite.material.set_shader_parameter('opacity', 0.9)
		sprite.material.set_shader_parameter('r', 1.0)
		sprite.material.set_shader_parameter('g', 0)
		sprite.material.set_shader_parameter('b', 0)
		sprite.material.set_shader_parameter('mix_color', 0.5)
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
	sprite.material.set_shader_parameter('opacity', 1.0)
	sprite.material.set_shader_parameter('r', 0)
	sprite.material.set_shader_parameter('mix_color', 0)
	timer_take_damage.stop()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "attack" || "attack_up" || "attack_down":
		torch_area.get_child(0).disabled = true
		animation_player.play("run")
		if player.current_health < 1:
			timer.start()
	if anim_name == "death":
		queue_free()
	if !dead:
		animation_player.play("run")

func _on_timer_stamina_regen_timeout() -> void:
	current_stamina += 20

func _on_timer_stamina_regen_start_timeout() -> void:
	if current_stamina < 100:
		if timer_stamina_regen.is_stopped():
			timer_stamina_regen.start()

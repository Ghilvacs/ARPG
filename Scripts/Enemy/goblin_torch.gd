extends CharacterBody2D

const MAX_HEALTH = 50

var current_health
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

func _ready() -> void:
	current_health = MAX_HEALTH
	health_bar.value = current_health
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if animated_sprite.animation == "attack" || animated_sprite.animation == "attack_up" || animated_sprite.animation == "attack_down":
		return
	if dead:
		torch_light.visible = false
		health_bar.visible = false
		return
	if velocity.length() > 0:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")
	if velocity.x > 0:
		animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = true
		
	move_and_slide()

func take_damage(damage: int) -> void:
	if timer_take_damage.is_stopped():
		current_health -= damage
		health_bar.value = current_health
		animated_sprite.material.set_shader_parameter('opacity', 0.9)
		animated_sprite.material.set_shader_parameter('r', 1.0)
		animated_sprite.material.set_shader_parameter('g', 0)
		animated_sprite.material.set_shader_parameter('b', 0)
		animated_sprite.material.set_shader_parameter('mix_color', 0.5)
		timer_take_damage.start(0)

func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack" || animated_sprite.animation == "attack_up" || animated_sprite.animation == "attack_down":
		torch_area.get_child(0).disabled = true
		animated_sprite.play("run")
		if player.current_health < 1:
			timer.start()
	elif animated_sprite.animation == "death":
		queue_free()
	elif !dead:
		animated_sprite.play("run")
	
func _on_hitbox_area_entered(area: Area2D) -> void:
	if !dead:
		if area.is_in_group("BladeOne"):
			take_damage(12)
		elif area.is_in_group("BladeTwo"):
			take_damage(24)

func _on_timer_take_damage_timeout() -> void:
	if current_health < 1:
		dead = true
	animated_sprite.material.set_shader_parameter('opacity', 1.0)
	animated_sprite.material.set_shader_parameter('r', 0)
	animated_sprite.material.set_shader_parameter('mix_color', 0)
	timer_take_damage.stop()

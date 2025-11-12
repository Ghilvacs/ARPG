class_name Dynamite
extends Node2D

@export var initial_speed: float = 300.0
@export var arc_duration: float = 0.6  # time to reach target
@export var arc_height: float = 30.0   # visual height of the arc
@export var slowdown_factor: float = 0.6  # how much slower it gets mid-air

@onready var sprite: Sprite2D = $Sprite2D
@onready var explosion_sprite: Sprite2D = $ExplosionSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var start_position: Vector2
var target_position: Vector2
var elapsed_time := 0.0
var thrown := false


func throw(throw_direction: Vector2) -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if not player:
		return
	
	get_node("DamageArea/CollisionShape2D").disabled = true
	start_position = global_position
	target_position = player.global_position
	elapsed_time = 0.0
	thrown = true
	animation_player.play("throw")


func _physics_process(delta: float) -> void:
	if not thrown:
		return
	
	elapsed_time += delta
	var t = clamp(elapsed_time / arc_duration, 0.0, 1.0)
	var flat_position = start_position.lerp(target_position, t)
	var height = -4 * arc_height * (t - 0.5) * (t - 0.5) + arc_height
	var speed_curve = lerp(1.0, slowdown_factor, sin(t * PI))

	global_position = flat_position
	sprite.position.y = -height
	
	if t >= 1.0:
		_on_landed()


func _on_landed() -> void:
	thrown = false
	sprite.position.y = 0
	animation_player.stop()
	await get_tree().create_timer(0.2).timeout
	sprite.visible = false
	explosion_sprite.visible = true
	animation_player.play("explode")
	get_node("DamageArea/CollisionShape2D").disabled = false


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "explode":
		queue_free()

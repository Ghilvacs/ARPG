class_name StateDash extends PlayerState

@export var dash_distance: float = 35.0
@export var dash_duration: float = 0.1

@onready var idle: PlayerState = $"../Idle"
@onready var walk: PlayerState = $"../Walk"

var dash_time := 0.0
var effect_delay := 0.01
var effect_timer := 0.0
var direction: Vector2
var tween: Tween


func enter():
	player.isAttacking = false
	player.hitbox_collision_shape.disabled = true
	player.dashed = true
	effect_timer = 0.0
	player.update_facing()
	direction = player.direction
	dash_time = 0.0
	player.dash_audio.play()
	var target_position := player.global_position + direction * dash_distance
	tween = player.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "global_position", target_position, dash_duration)


func exit():
	player.velocity = Vector2.ZERO
	player.hitbox_collision_shape.disabled = false


func update(delta: float) -> PlayerState:
	if player.dash_cooldown <= 0.0:
		player.dash_cooldown += delta
	elif player.dash_cooldown >= 2.0:
		player.dash_cooldown = 0.0
		
	dash_time += delta
	effect_timer -= delta
	
	if effect_timer < 0:
		effect_timer = effect_delay
		spawn_effect()
		
	if dash_time >= dash_duration:
		if player.direction == Vector2.ZERO:
			return idle
		else:
			return walk

	return null


func physics_update(_delta: float) -> PlayerState:
	return null


func spawn_effect() -> void:
	var effect: Node2D = Node2D.new()
	player.get_parent().add_child(effect)
	effect.global_position = player.global_position
	
	var sprite_copy: Sprite2D = player.sprite.duplicate()
	sprite_copy.scale = player.scale
	for child in sprite_copy.get_children():
		child.visible = false
	effect.add_child(sprite_copy)
	
	var ghost_mat := ShaderMaterial.new()
	ghost_mat.shader = preload("res://Scenes/Shaders/player_ghost.gdshader")
	ghost_mat.set_shader_parameter("opacity", 1.0)
	sprite_copy.material = ghost_mat
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost_mat, "shader_parameter/opacity", 0.0, 0.2)
	tween.chain().tween_callback(effect.queue_free)
	
	
	

extends EnemyState
class_name EnemyFollow

const PATHFINDER: PackedScene = preload("res://Scenes/Enemy/Pathfinder.tscn")

@export_category("Movement")
@export var move_speed: float = 60.0
@export var wander_state: EnemyState
@export var knockback_state: EnemyState
@export var stun_state: EnemyState
@export var dead_state: EnemyState

@export_category("Areas")
@export var detection_area: Area2D
@export var attack_area: Area2D
@export var attack_state: EnemyState

@export_category("Follow → Attack delay")
@export var use_attack_transition_delay: bool = true
@export var attack_transition_delay: float = 0.20

@export_category("Melee while following")
@export var melee_while_following: bool = true
@export var use_vertical_attack_anims: bool = true
@export var base_attack_animation: String = "attack"
@export var attack_up_animation: String = "attack_up"
@export var attack_down_animation: String = "attack_down"

var player: CharacterBody2D
var pathfinder: Pathfinder
var direction: Vector2 = Vector2.ZERO

var player_in_detection_range := true
var player_in_attack_range := false

var _attack_request_timer := -1.0
var _connected := false
var _attack_anim := ""


func enter(prev_state: EnemyState) -> void:
	enemy.vision_mode = enemy.VisionMode.LOOK_AT_PLAYER

	pathfinder = PATHFINDER.instantiate() as Pathfinder
	enemy.add_child(pathfinder)
	pathfinder.position = Vector2.ZERO

	player = get_tree().get_first_node_in_group("Player") as CharacterBody2D
	_attack_request_timer = -1.0

	_connect_areas()

	# optional “threat anim” while following
	if melee_while_following:
		_update_attack_animation()
		if enemy.animation_player:
			enemy.animation_player.play(_attack_anim)


func exit() -> void:
	enemy.vision_mode = enemy.VisionMode.MOVE_DIRECTION
	if pathfinder:
		pathfinder.queue_free()
		pathfinder = null
	_attack_request_timer = -1.0


func physics_update(delta: float) -> EnemyState:
	if enemy == null:
		return null

	if enemy.hit and knockback_state:
		return knockback_state
	
	if enemy.dead and dead_state:
		enemy.isAttacking = false
		return dead_state
	
	if enemy.stunned and stun_state:
		enemy.isAttacking = false
		return stun_state

	if (not player_in_detection_range or not _is_player_valid()) and wander_state:
		enemy.isAttacking = false
		return wander_state

	if not _is_player_valid():
		return null

	# face player
	if enemy.sprite:
		enemy.sprite.flip_h = player.global_position.x < enemy.global_position.x
	
	if enemy.has_node("TorchPivot") and player:
		var pivot := enemy.get_node("TorchPivot") as Node2D
		pivot.look_at(player.global_position)
	
	# steer
	if pathfinder:
		direction = direction.lerp(pathfinder.move_direction, min(1.0, 8.0 * delta))

	# move
	enemy.velocity = direction.normalized() * move_speed if direction.length() > 0.01 else Vector2.ZERO

	# optional “threat anim” while following
	if melee_while_following:
		_update_attack_animation()

	# attack decision (only place where we go to Attack)
	if attack_state and player_in_attack_range and not enemy.inCooldown:
		if not use_attack_transition_delay:
			return attack_state

		# start countdown once
		if _attack_request_timer < 0.0:
			_attack_request_timer = attack_transition_delay
		else:
			_attack_request_timer -= delta
			if _attack_request_timer <= 0.0:
				_attack_request_timer = -1.0
				return attack_state
	else:
		_attack_request_timer = -1.0

	return null


func _update_attack_animation() -> void:
	if not melee_while_following or not _is_player_valid() or enemy == null:
		return
	
	enemy.isAttacking = true
	
	var distance := player.global_position.y - enemy.global_position.y
	if use_vertical_attack_anims:
		if distance < -5.0:
			_attack_anim = attack_up_animation
		elif distance > 5.0:
			_attack_anim = attack_down_animation
		else:
			_attack_anim = base_attack_animation
	else:
		_attack_anim = base_attack_animation

	if enemy.animation_player and enemy.animation_player.current_animation != _attack_anim:
		enemy.animation_player.play(_attack_anim)


func _connect_areas() -> void:
	if _connected:
		return
	_connected = true

	var det := detection_area
	if det == null and enemy.has_node("DetectionArea"):
		det = enemy.get_node("DetectionArea") as Area2D
	if det:
		if not det.body_entered.is_connected(_on_detection_entered):
			det.body_entered.connect(_on_detection_entered)
		if not det.body_exited.is_connected(_on_detection_exited):
			det.body_exited.connect(_on_detection_exited)

	var atk := attack_area
	if atk == null and enemy.has_node("AttackArea"):
		atk = enemy.get_node("AttackArea") as Area2D
	if atk:
		if not atk.body_entered.is_connected(_on_attack_entered):
			atk.body_entered.connect(_on_attack_entered)
		if not atk.body_exited.is_connected(_on_attack_exited):
			atk.body_exited.connect(_on_attack_exited)


func _on_detection_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_detection_range = true


func _on_detection_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_detection_range = false
		player_in_attack_range = false
		_attack_request_timer = -1.0


func _on_attack_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_attack_range = true


func _on_attack_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player_in_attack_range = false
		_attack_request_timer = -1.0


func _is_player_valid() -> bool:
	return player != null and player.current_health > 0

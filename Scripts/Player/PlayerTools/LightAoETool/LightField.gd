extends Node2D


signal depleted(field_position: Vector2)

@export var active_time: float = 5.0
@export var area_path: NodePath = ^"Area2D"

var _inside := {} # instance_id -> Node

@onready var area: Area2D = get_node(area_path) as Area2D
@onready var light_2d: PointLight2D = $PointLight2D
@onready var ghost_ring: Sprite2D = $GhostRing
@onready var light_ring: Sprite2D = $LightRing


func _ready() -> void:
	# Just connect to whatever the manager already built.
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if active_time <= 0.0:
		emit_signal("depleted")
		queue_free()
		
		return
	
	_timer(delta)
	_apply_continuous_effects(delta)


func _timer(delta: float) -> void:
	active_time -= delta
	
	if active_time <= 0.0:
		active_time = 0.0


func _on_body_entered(body: Node) -> void:
	var actor := _get_actor_root(body)
	if actor:
		_inside[actor.get_instance_id()] = actor
		_apply_enter_effects(actor)


func _on_body_exited(body: Node) -> void:
	var actor := _get_actor_root(body)
	if actor:
		_apply_exit_effects(actor)
		_inside.erase(actor.get_instance_id())


func _get_actor_root(node: Node) -> Node:
	var current := node
	while current:
		if current.is_in_group("Enemy") or current.is_in_group("Player"):
			return current
		current = current.get_parent()
	return null


func _apply_enter_effects(body: Node) -> void:
	if body.is_in_group("Enemy"):
		body.in_circle = true
		body.can_be_knocked_back = true
		if body.has_method("is_light_sensitive") and body.call("is_light_sensitive"):
			if body.has_method("apply_stun"):
				body.call("apply_stun", 2.0)


func _apply_exit_effects(body: Node) -> void:
	if body.is_in_group("Enemy"):
		body.in_circle = false
		body.can_be_knocked_back = false


func _apply_continuous_effects(delta: float) -> void:
	for id in _inside.keys():
		var node: Node = _inside.get(id)
		if node == null or not is_instance_valid(node):
			_inside.erase(id)
			continue

		# Enemies: stronger regen & more pressure at higher phases
		if node.is_in_group("Enemy"):
			if node.has_method("apply_regen"):
				var regen_per_sec := 0.2
				node.call("apply_regen", regen_per_sec * delta)

			if node.has_method("set_field_phase"):
				node.call("set_field_phase")

		# Player: smaller regen + penalties scale with phase
		if node.is_in_group("Player"):
			if node.has_method("apply_regen"):
				var regen_per_sec := 0.4
				node.call("apply_regen", regen_per_sec * delta)

			if node.has_method("set_sensory_clarity"):
				var clarity := 1.0 - 0.12
				node.call("set_sensory_clarity", clamp(clarity, 0.55, 1.0))

		# Organic: accelerated growth in higher phases
		if node.is_in_group("organic"):
			if node.has_method("accelerate_growth"):
				node.call("accelerate_growth", 1.0, delta)


func _get_enemy_root(node: Node) -> Node:
	var current := node
	while current:
		if current.is_in_group("Enemy"):
			return current
		current = current.get_parent()
	return null

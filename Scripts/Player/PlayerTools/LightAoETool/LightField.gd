extends Node2D

signal phase_changed(new_phase: int, exposure_ratio: float)
signal depleted(field_position: Vector2)

enum Phase { MAX, MEDIUM, LOW, DEPLETED }

@export var exposure_max: float = 1.0
@export var exposure: float = 0.35

# Ratio thresholds (exposure / exposure_max)
@export var max_threshold: float = 0.75
@export var medium_threshold: float = 0.40
@export var low_threshold: float = 0.10 # <= this => DEPLETED

# Drain per second by phase (MAX drains fastest)
@export var drain_max: float = 0.2
@export var drain_medium: float = 0.15
@export var drain_low: float = 0.1

# Effect multipliers by phase (MAX effects strongest)
@export var mult_max: float = 1.60
@export var mult_medium: float = 1.20
@export var mult_low: float = 1

@export var area_path: NodePath = ^"Area2D"

var phase: Phase = Phase.MAX
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
	_update_phase(true)

func _physics_process(delta: float) -> void:
	if phase == Phase.DEPLETED:
		return

	_update_phase()
	_drain(delta/2)
	_apply_continuous_effects(delta)

	if exposure <= 0.0 or _ratio() <= low_threshold:
		_set_depleted()

func _ratio() -> float:
	return exposure / max(exposure_max, 0.0001)

func _update_phase(force: bool = false) -> void:
	var ratio := _ratio()
	var new_phase: Phase

	if ratio > max_threshold:
		new_phase = Phase.MAX
	elif ratio > medium_threshold:
		new_phase = Phase.MEDIUM
	elif ratio > low_threshold:
		new_phase = Phase.LOW
	else:
		new_phase = Phase.DEPLETED

	if force or new_phase != phase:
		phase = new_phase
		emit_signal("phase_changed", int(phase), ratio)

func _drain(delta: float) -> void:
	var drain := 0.0
	match phase:
		Phase.MAX: drain = drain_max
		Phase.MEDIUM: drain = drain_medium
		Phase.LOW: drain = drain_low
		Phase.DEPLETED: drain = 0.0

	exposure = max(exposure - drain * delta, 0.0)

func _multiplier() -> float:
	match phase:
		Phase.MAX: return mult_max
		Phase.MEDIUM: return mult_medium
		Phase.LOW: return mult_low
		Phase.DEPLETED: return 0.0
	return 1.0

func _on_body_entered(body: Node) -> void:
	var actor := _get_actor_root(body)
	if actor:
		_inside[actor.get_instance_id()] = actor
		_apply_enter_effects(actor)

func _on_body_exited(body: Node) -> void:
	var actor := _get_actor_root(body)
	if actor:
		_inside.erase(actor.get_instance_id())


func _get_actor_root(node: Node) -> Node:
	var current := node
	while current:
		if current.is_in_group("Enemy") or current.is_in_group("Player"):
			return current
		current = current.get_parent()
	return null


func _apply_enter_effects(body: Node) -> void:
	# Optional “entry kick” scales with phase.
	var multiplier := _multiplier()
	if multiplier <= 0.0:
		return

	if body.is_in_group("Enemy"):
		if body.has_method("is_light_sensitive") and body.call("is_light_sensitive"):
			if body.has_method("apply_stun"):
				body.call("apply_stun", 1.5 * multiplier)

func _apply_exit_effects(_body: Node) -> void:
	pass

func _apply_continuous_effects(delta: float) -> void:
	var multiplier := _multiplier()
	if multiplier <= 0.0:
		return

	for id in _inside.keys():
		var node: Node = _inside.get(id)
		if node == null or not is_instance_valid(node):
			_inside.erase(id)
			continue

		# Enemies: stronger regen & more pressure at higher phases
		if node.is_in_group("Enemy"):
			if node.has_method("apply_regen"):
				var regen_per_sec := 0.4 * multiplier
				node.call("apply_regen", regen_per_sec * delta)

			if node.has_method("set_field_phase"):
				node.call("set_field_phase", int(phase)) # MAX/MEDIUM/LOW

		# Player: smaller regen + penalties scale with phase
		if node.is_in_group("Player"):
			if node.has_method("apply_regen"):
				node.call("apply_regen", (0.4 * multiplier) * delta)

			if node.has_method("set_sensory_clarity"):
				var clarity := 1.0 - (0.12 * multiplier) # MAX worsens more
				node.call("set_sensory_clarity", clamp(clarity, 0.55, 1.0))

		# Organic: accelerated growth in higher phases
		if node.is_in_group("organic"):
			if node.has_method("accelerate_growth"):
				node.call("accelerate_growth", 1.0 * multiplier, delta)

func _set_depleted() -> void:
	phase = Phase.DEPLETED
	emit_signal("phase_changed", int(phase), _ratio())

	# Optional callbacks for things inside at depletion
	for id in _inside.keys():
		var node: Node = _inside.get(id)
		if node != null and is_instance_valid(node) and node.has_method("on_light_field_depleted"):
			node.call("on_light_field_depleted")

	emit_signal("depleted", global_position)
	queue_free()


func _get_enemy_root(node: Node) -> Node:
	var current := node
	while current:
		if current.is_in_group("Enemy"):
			return current
		current = current.get_parent()
	return null

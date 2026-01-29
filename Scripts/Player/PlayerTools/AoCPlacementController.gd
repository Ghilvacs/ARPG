extends Node

@export var circle_scene: PackedScene
@export var max_place_distance: float = 220.0
@export var allow_place_through_walls := false

const WALL_LAYER := 1 << 2

var placing: bool = false
var ghost: Node2D
var player: Node2D
var world: Node


func _ready() -> void:
	player = owner as Node2D
	world = get_tree().current_scene


func _unhandled_input(event: InputEvent) -> void:
	# Toggle into placement mode
	if event.is_action_pressed("aoc_place"):
		if placing:
			cancel()
		else:
			start()
		get_viewport().set_input_as_handled()
		return

	if not placing:
		return

	# Cancel
	if event.is_action_pressed("aoc_cancel"):
		cancel()
		get_viewport().set_input_as_handled()
		return

	# Confirm (left click)
	if event.is_action_pressed("aoc_confirm"):
		try_confirm()
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if not placing:
		return
	update_ghost_position()


func start() -> void:
	placing = true

	# Optional: pause player attacks / movement via a flag on the player
	if player.has_method("set_is_placing"):
		player.call("set_is_placing", true)

	# Create a ghost preview (instance the real scene but disable logic)
	ghost = circle_scene.instantiate() as Node2D
	world.add_child(ghost)

	# Disable runtime effects in preview
	ghost.set_physics_process(false)
	ghost.set_process(false)

	# Disable collisions in preview so it doesn't affect bodies
	var area := ghost.get_node_or_null("Area2D") as Area2D
	if area:
		area.monitoring = false
		area.monitorable = false

	# Visual hint the user it's a preview (you can replace this with a custom sprite/shader)
	_set_ghost_visual(ghost, true)
	update_ghost_position()


func cancel() -> void:
	placing = false

	if is_instance_valid(ghost):
		ghost.queue_free()
	ghost = null

	if player.has_method("set_is_placing"):
		player.call("set_is_placing", false)


func try_confirm() -> void:
	if not is_instance_valid(ghost):
		cancel()
		return

	var target_position := ghost.global_position
	if not _can_place_at(target_position):
		# Optional: play error sound / flash red
		return

	# Replace ghost with the real field
	ghost.queue_free()
	ghost = null

	var field := circle_scene.instantiate() as Node2D
	world.add_child(field)
	field.global_position = target_position
	field.ghost_ring.visible = false
	field.light_ring.visible = true
	field.light_2d.visible = true
	# If you need to initialize exposure from the player/tool resource, do it here:
	# field.exposure = owner.current_exposure
	# field.exposure_max = owner.exposure_max

	placing = false
	if player.has_method("set_is_placing"):
		player.call("set_is_placing", false)


func update_ghost_position() -> void:
	var mouse_world := player.get_global_mouse_position()
	var from := player.global_position
	var direction := (mouse_world - from)
	var distance = min(direction.length(), max_place_distance)
	var position = from + direction.normalized() * (distance if distance > 0.001 else 0.0)

	if not allow_place_through_walls:
		position = _clip_to_los(from, position)

	ghost.global_position = position

	# Optional: change color based on valid/invalid placement
	var ok := _can_place_at(position)
	_set_ghost_valid(ghost, ok)


func _can_place_at(pos: Vector2) -> bool:
	# Basic rule: inside range already ensured by clamping.
	# Add “no-place zones” or “must be on floor” rules here.

	# Example: block placement if overlapping a "NoAoC" area
	# (Requires you to create an Area2D layer/mask for that)
	var space := player.get_world_2d().direct_space_state

	var query := PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = WALL_LAYER
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var hits := space.intersect_point(query)
	return hits.is_empty()
	return true


func _clip_to_los(from: Vector2, to: Vector2) -> Vector2:
	var space := player.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [player]
	# query.collision_mask = 1 << 0  # set to your walls layer if needed
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return to
	# stop a bit before the wall
	return (hit.position as Vector2) - (to - from).normalized() * 8.0


func _set_ghost_visual(node: Node, is_ghost: bool) -> void:
	# If you have a Sprite2D or a ring child, change modulate/alpha here.
	# This is intentionally generic.
	if node is CanvasItem:
		(node as CanvasItem).modulate.a = 0.5 if is_ghost else 1.0


func _set_ghost_valid(node: Node, ok: bool) -> void:
	# Optional: green/red feedback (still diegetic enough if subtle)
	if node is CanvasItem:
		var c := (node as CanvasItem).modulate
		c.a = 0.5
		# keep subtle: slightly dimmer if invalid
		c.r = 1.0
		c.g = 1.0 if ok else 0.6
		c.b = 1.0 if ok else 0.6
		(node as CanvasItem).modulate = c

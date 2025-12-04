class_name Pathfinder extends Node2D

var vectors: Array[Vector2] = [
	Vector2(0, -1), #UP
	Vector2(1, -1), #UP/RIGHT
	Vector2(1, 0), #RIGHT
	Vector2(1, 1), #DOWN/RIGHT
	Vector2(0, 1), #DOWN
	Vector2(-1, 1), #DONW/LEFT
	Vector2(-1, 0), #LEFT
	Vector2(-1, -1) #UP/LEFT
]

var interests: Array[float]
var obstacles: Array[float] = [0, 0, 0, 0, 0, 0, 0, 0]
var outcomes: Array[float] = [0, 0, 0, 0, 0, 0, 0, 0]
var rays: Array[RayCast2D] = []
var move_direction: Vector2 = Vector2.ZERO
var path: Vector2 = Vector2.ZERO

@onready var timer: Timer = $Timer


func _ready() -> void:
	timer.timeout.connect(set_path)
	
	for child in get_children():
		if child is RayCast2D:
			rays.append(child)
	
	for vector in vectors:
		vector = vector.normalized()
	
	set_path()


func _process(delta: float) -> void:
	move_direction = lerp(move_direction, path, 10 * delta)


func set_path() -> void:
	if GlobalPlayerManager.player == null:
		return
	var player_direction: Vector2 = GlobalPlayerManager.player.global_position - global_position
	
	for index in 8:
		obstacles[index] = 0
		outcomes[index] = 0
	
	for index in 8:
		if rays[index].is_colliding():
			obstacles[index] += 4
			obstacles[get_next_index(index)] += 1
			obstacles[get_previous_index(index)] += 1
	
	if obstacles.max() == 0:
		path = player_direction
		return

	interests.clear()
	
	for vector in vectors:
		interests.append(vector.dot(player_direction))
	
	for index in 8:
		outcomes[index] = interests[index] - obstacles[index]
	
	path = vectors[outcomes.find(outcomes.max())]


func get_next_index(index: int) -> int:
	var next_index: int = index + 1
	if next_index >= 8:
		return 0
	else:
		return next_index


func get_previous_index(index: int) -> int:
	var previous_index: int = index - 1
	if previous_index < 0:
		return 7
	else:
		return previous_index

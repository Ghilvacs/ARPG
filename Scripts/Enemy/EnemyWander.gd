extends State
class_name EnemyWander

@export var enemy: CharacterBody2D
@export var move_speed := 40.0

var player: CharacterBody2D
var move_direction: Vector2
var wander_time: float

func randomize_wander():
	move_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	wander_time = randf_range(1, 3)

func enter() -> void:
	GlobalPlayerManager.connect("PlayerSpawned", Callable(self, "_on_player_spawned"))
	GlobalPlayerManager.connect("PlayerDespawned", Callable(self, "_on_player_despawned"))
	player = get_tree().get_first_node_in_group("Player")
	randomize_wander()
	
	if enemy.has_node("DetectionArea"):
		var detection_area = enemy.get_node("DetectionArea") as Area2D
		if not detection_area.is_connected("body_entered", Callable(self,"_on_detection_area_entered")):
			detection_area.connect("body_entered", Callable(self,"_on_detection_area_entered"))
		
	
func update(delta: float) -> void:
	if wander_time > 0:
		wander_time -= delta
	else:
		randomize_wander()

func physics_update(_delta: float) -> void:
	if enemy:
		enemy.velocity = move_direction * move_speed
		
	if enemy.dead:
		Transitioned.emit(self, "Dead")
		
	if enemy.hit:
		Transitioned.emit(self, "Knockback")

func _on_detection_area_entered(body: Node) -> void:
	if body.is_in_group("Player") and player and player.current_health > 1:
		Transitioned.emit(self, "Follow")

func _on_player_spawned(player: CharacterBody2D) -> void:
		self.player = player
		
func _on_player_despawned() -> void:
	player = null




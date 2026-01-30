extends Area2D
class_name Hurtbox

@export var damage: int = 10
@export var team: int = 0  # 0 = Player, 1 = Enemy, 2 = Neutral
@export var knockback_force: float = 0.0

var _already_hit: = []


func _ready() -> void:
	monitoring = false  # off by default, turned on by animation
	connect("area_entered", Callable(self, "_on_area_entered"))


func start_attack() -> void:
	_already_hit.clear()
	monitoring = true


func end_attack() -> void:
	monitoring = false
	_already_hit.clear()


func _on_area_entered(area: Area2D) -> void:
	if not monitoring:
		return

	if area in _already_hit:
		return

	if area is Hitbox:
		var hitbox := area as Hurtbox
		if hitbox.is_valid_target(team):
			_already_hit.append(area)
			hitbox.apply_hit(self)

extends Area2D
class_name Hitbox

@export var team: int = 1  # 0 = Player, 1 = Enemy

func _ready() -> void:
	if owner == null:
		owner = get_parent()

func is_valid_target(attacker_team: int) -> bool:
	return attacker_team != team

func apply_hit(hurtbox: Hurtbox) -> void:
	if owner and owner.has_method("take_hit"):
		owner.take_hit(hurtbox)

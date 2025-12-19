class_name ItemEffectHeal extends ItemEffect

@export var heal_amount: int = 1
@export var sound: AudioStream


func use() -> void:
	GlobalPlayerManager.player.update_health(heal_amount)
	#PlaySound

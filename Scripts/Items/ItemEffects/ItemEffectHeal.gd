class_name ItemEffectHeal extends ItemEffect

@export var heal_amount: int = 1
@export var sound: AudioStream


func use() -> bool:
	var player = GlobalPlayerManager.player
	
	if not player:
		return false
		
	if player.current_health >= player.MAX_HEALTH:
		return false
		
	player.update_health(heal_amount)
	
	return true

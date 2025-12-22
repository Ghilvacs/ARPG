class_name ItemData extends Resource

@export var name: String = ""
@export_multiline var description: String = ""
@export var texture: Texture2D

@export_category("Item Use Effects")
@export var effects: Array[ItemEffect]


func use() -> bool:
	if effects.size() == 0:
		return false
	
	var applied: bool = false
	
	for effect in effects:
		if effect and effect.use():
			applied = true
	return applied

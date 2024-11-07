extends Node2D

var click_position: Array = []

func _draw() -> void:
	for point in click_position:
		draw_circle(point, 5.0, Color.DARK_RED)
	
func _process(delta: float) -> void:
	if Input.is_action_pressed("draw"):
		click_position.append(get_local_mouse_position())
		queue_redraw()
	else: 
		return
	

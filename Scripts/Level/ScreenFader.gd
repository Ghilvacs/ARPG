extends CanvasLayer

var fade_rect: ColorRect
var tween: Tween

func _ready():
	fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.visible = false
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)

	# fullscreen anchors
	fade_rect.anchor_left = 0.0
	fade_rect.anchor_top = 0.0
	fade_rect.anchor_right = 1.0
	fade_rect.anchor_bottom = 1.0

func fade_out(duration: float = 1.0) -> void:
	# Stop any existing tween
	if tween and tween.is_valid():
		tween.kill()

	fade_rect.visible = true
	fade_rect.modulate.a = 0.0

	tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func fade_in(duration: float = 1.0) -> void:
	if tween and tween.is_valid():
		tween.kill()

	tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	fade_rect.visible = false

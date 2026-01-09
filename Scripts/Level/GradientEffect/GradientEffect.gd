extends PointLight2D

@export var source_gradient: GradientTexture2D
@export var bake_size := Vector2i(1024, 1024)

func _ready() -> void:
	if source_gradient == null:
		return

	# Temporarily render at higher res
	source_gradient.width = bake_size.x
	source_gradient.height = bake_size.y
	source_gradient.use_hdr = true

	var img := source_gradient.get_image()
	var baked := ImageTexture.create_from_image(img)

	# Godot 4: force linear filtering on this *baked* texture
	# (property name varies slightly by minor version, so try both)
	if baked.has_method("set_texture_filter"):
		baked.set_texture_filter(CanvasItem.TEXTURE_FILTER_LINEAR)
	elif "texture_filter" in baked:
		baked.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	texture = baked

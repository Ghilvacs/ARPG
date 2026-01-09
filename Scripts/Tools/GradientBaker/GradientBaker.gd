@tool
extends Node

@export var generate := false
@export_file("*.png", "*.jpg", "*.jpeg", "*.webp") var source_path := "res://Assets/LightTexture/source_crack.png"
@export var output_path := "res://Assets/LightTexture/light_from_crack2.png"

# What counts as "black" (hole/cracks)?
@export_range(0.0, 1.0, 0.01) var darkness_threshold := 0.65 # higher = fewer lit pixels
@export_range(0.0, 0.5, 0.01) var softness := 0.02           # feathering around threshold
@export_range(0.2, 5.0, 0.1) var gamma := 2.0               # higher = thinner/stronger core

# Glow around the lit shape
@export var glow_radius := 15
@export_range(0.0, 3.0, 0.05) var glow_strength := 1.0
@export_range(0.5, 4.0, 0.1) var glow_gamma := 1.8

# Banding control
@export_range(0.0, 0.03, 0.001) var dither := 0.01

func _process(_delta):
	if generate:
		generate = false
		call_deferred("_do_generate")

func _do_generate() -> void:
	generate_from_image()

func generate_from_image() -> void:
	if not FileAccess.file_exists(source_path):
		push_error("Source image not found: " + source_path)
		return

	var src := Image.load_from_file(source_path)
	if src == null:
		push_error("Failed to load: " + source_path)
		return

	# Ensure a format we can work with
	if src.get_format() != Image.FORMAT_RGBA8:
		src.convert(Image.FORMAT_RGBA8)

	var w := src.get_width()
	var h := src.get_height()

	# 1) Build a mask: dark -> bright
	var mask := PackedFloat32Array()
	mask.resize(w * h)

	for y in range(h):
		for x in range(w):
			var col := src.get_pixel(x, y)

			# Luminance (perceived brightness)
			var lum := 0.2126 * col.r + 0.7152 * col.g + 0.0722 * col.b  # 0..1

			# "Black parts become light": invert luminance
			var inv := 1.0 - lum

			# Soft-threshold so only the dark regions turn on
			var t0 := darkness_threshold - softness
			var t1 := darkness_threshold + softness
			var v := smoothstep(t0, t1, inv)

			# Shape intensity (thin bright cracks + strong core)
			v = pow(v, gamma)

			mask[y * w + x] = clamp(v, 0.0, 1.0)

	# 2) Glow (blurred mask)
	var glow := mask
	if glow_radius > 0 and glow_strength > 0.0:
		glow = blur_separable(mask, w, h, int(glow_radius))

	# 3) Compose final texture
	var out := Image.create(w, h, false, Image.FORMAT_RGBA8)

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	for y in range(h):
		for x in range(w):
			var core := mask[y * w + x]
			var g := glow[y * w + x]
			g = pow(clamp(g, 0.0, 1.0), glow_gamma)

			var value = clamp(core + g * glow_strength, 0.0, 1.0)

			# Dither (tiny)
			if dither > 0.0:
				var dn := (rng.randf() - 0.5) * 2.0 * dither
				value = clamp(value + dn, 0.0, 1.0)

			out.set_pixel(x, y, Color(value, value, value, 1.0))

	out.save_png(output_path)
	print("Light mask saved to: ", output_path)

# --- Helpers must be at script scope ---

func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clamp((x - edge0) / max(0.00001, (edge1 - edge0)), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func blur_separable(src: PackedFloat32Array, w: int, h: int, radius: int) -> PackedFloat32Array:
	if radius <= 0:
		return src

	var tmp := PackedFloat32Array()
	tmp.resize(w * h)
	var out := PackedFloat32Array()
	out.resize(w * h)

	var size := radius * 2 + 1
	var inv := 1.0 / float(size)

	# horizontal
	for y in range(h):
		var acc := 0.0
		for k in range(-radius, radius + 1):
			var xx = clamp(k, 0, w - 1)
			acc += src[y * w + xx]
		for x in range(w):
			tmp[y * w + x] = acc * inv
			var x_out = clamp(x - radius, 0, w - 1)
			var x_in = clamp(x + radius + 1, 0, w - 1)
			acc += src[y * w + x_in] - src[y * w + x_out]

	# vertical
	for x in range(w):
		var acc := 0.0
		for k in range(-radius, radius + 1):
			var yy = clamp(k, 0, h - 1)
			acc += tmp[yy * w + x]
		for y in range(h):
			out[y * w + x] = acc * inv
			var y_out = clamp(y - radius, 0, h - 1)
			var y_in = clamp(y + radius + 1, 0, h - 1)
			acc += tmp[y_in * w + x] - tmp[y_out * w + x]

	return out

extends PointLight2D

@export var player: CharacterBody2D
@export_range(0.0, 1.0, 0.01) var min_energy := 0.6
@export_range(0.0, 1.0, 0.01) var max_energy := 1.0
@export var min_color: Color = Color(1, 0, 0) 
@export var max_color: Color = Color(1, 1, 1)

@export var flicker_chance_per_second := 5.0
@export var flicker_strength := 0.5
@export var flicker_duration := 0.05

@export var blackout_chance_per_second := 0.5
@export_range(0.1, 2.0, 0.1) var blackout_duration := 2.0
@export var blackout_threshold := 0.4

var flicker_timer := 0.0
var is_flickering := false
var flicker_elapsed := 0.0

var is_blackout := false
var blackout_elapsed := 0.0

func _process(delta: float) -> void:
	var hp_percent = clamp(player.get_hp_percent(), 0.0, 1.0)
	var base_energy = lerp(min_energy, max_energy, hp_percent)
	
	var flicker_chance = flicker_chance_per_second * (1.0 - hp_percent)
	flicker_timer += delta
	
	if is_flickering:
		flicker_elapsed += delta
		if flicker_elapsed >= flicker_duration:
			is_flickering = false
	else:
		if randf() < flicker_chance * delta:
			is_flickering = true
			flicker_elapsed = 0.0
	
	if hp_percent < blackout_threshold:
		var blackout_chance = blackout_chance_per_second * (1.0 - hp_percent / blackout_threshold)
		if not is_blackout and randf() < blackout_chance * delta:
			is_blackout = true
			blackout_elapsed = 0.0

	if is_blackout:
		blackout_elapsed += delta
		if blackout_elapsed >= blackout_duration:
			is_blackout = false
				
	var final_energy = base_energy
	if is_blackout:
		final_energy = 0.0
	elif is_flickering:
		final_energy = max(min_energy, base_energy - flicker_strength)

	energy = clamp(final_energy, 0.0, 1.0)
	color = min_color.lerp(max_color, hp_percent)

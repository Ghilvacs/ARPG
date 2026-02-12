extends Node2D

@export var damage_per_tick: int = 1
@export var tick_rate: float = 0.5
@export var lifetime: float = 5.0

var tick_accumulation: float = 0.0

@onready var timer: Timer = $Timer
@onready var area: Area2D = $Area2D

func _ready() -> void:
	timer.wait_time = lifetime
	timer.start()


func _process(delta: float) -> void:
	apply_poison(delta)


func apply_poison(delta: float) -> void:
	tick_accumulation += delta
	if tick_accumulation >= tick_rate:
		tick_accumulation = 0.0
		for body in area.get_overlapping_bodies():
			if body.is_in_group("Player"):
				body.take_damage(damage_per_tick)


func _on_timer_timeout() -> void:
	queue_free()

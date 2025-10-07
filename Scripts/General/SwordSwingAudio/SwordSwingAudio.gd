class_name SwordSwingAudio extends AudioStreamPlayer2D

@export var sword_swings: Array[AudioStream]

func play_sword_swing() -> void:
	self.stream = sword_swings.pick_random()
	play()

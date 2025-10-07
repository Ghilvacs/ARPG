class_name FootstepAudio extends AudioStreamPlayer2D

@export var footstep: Array[AudioStream]

func play_footstep() -> void:
	self.stream = footstep.pick_random()
	play()

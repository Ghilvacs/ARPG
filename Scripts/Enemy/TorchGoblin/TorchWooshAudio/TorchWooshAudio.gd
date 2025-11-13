class_name TorchWooshAudio extends AudioStreamPlayer2D

@export var torches: Array[AudioStream]

func play_torch() -> void:
	self.stream = torches.pick_random()
	play()

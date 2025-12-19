extends CanvasLayer

signal Shown
signal Hidden

@onready var button_reload: Button = $Control/HBoxContainer/ButtonReload
@onready var button_quit: Button = $Control/HBoxContainer/ButtonQuit
@onready var item_description_label: Label = $Control/ItemDescriptionLabel

var is_paused: bool = false


func _ready() -> void:
	button_reload.pressed.connect(_on_load_button_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if not is_paused:
			show_pause_menu()
		else:
			hide_pause_menu()
		get_viewport().set_input_as_handled()


func show_pause_menu() -> void:
	get_tree().paused = true
	visible = true
	is_paused = true
#	button_reload.grab_focus()
	Shown.emit()


func hide_pause_menu() -> void:
	get_tree().paused = false
	visible = false
	is_paused = false
	Hidden.emit()


func update_item_description(new_text: String) -> void:
	item_description_label.text = new_text


func _on_load_button_pressed() -> void:
	if not is_paused:
		return
	GlobalSaveManager.load_game()
	hide_pause_menu()

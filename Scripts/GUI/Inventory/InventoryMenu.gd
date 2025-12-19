extends CanvasLayer

signal InventoryShown
signal InventoryHidden

@onready var item_description_label: Label = $Control/ItemDescriptionLabel

var in_inventory: bool = false


func _ready() -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and !PauseMenu.is_paused:
		if not in_inventory:
			show_inventory_menu()
		else:
			hide_inventory_menu()
		get_viewport().set_input_as_handled()


func show_inventory_menu() -> void:
	visible = true
	in_inventory = true
	GlobalPlayerManager.player.set_input_locked(true)
	InventoryShown.emit()


func hide_inventory_menu() -> void:
	visible = false
	in_inventory = false
	GlobalPlayerManager.player.set_input_locked(false)
	InventoryHidden.emit()


func update_item_description(new_text: String) -> void:
	item_description_label.text = new_text

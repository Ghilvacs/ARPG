extends CanvasLayer

signal InventoryShown
signal InventoryHidden

@onready var item_description_label: Label = $Control/ItemDescriptionLabel
@onready var currency_label: Label = $Control/Label2/CurrencyLabel

var in_inventory: bool = false


func _ready() -> void:
	var inv := GlobalPlayerManager.INVENTORY_DATA
	inv.currency_changed.connect(_update_currency_label)
	_update_currency_label(inv.currency)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if not in_inventory:
			show_inventory_menu()
		else:
			hide_inventory_menu()
		get_viewport().set_input_as_handled()


func show_inventory_menu() -> void:
	if PauseMenu.is_paused:
		PauseMenu.hide_pause_menu()
	if JournalMenu.in_journal:
		JournalMenu.hide_journal()
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


func _update_currency_label(value: int) -> void:
	currency_label.text = str(value)

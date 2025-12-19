class_name InventoryUI extends Control

const INVENTORY_SLOT = preload("res://Scenes/GUI/Inventory/InventorySlot.tscn")

var focus_index: int = 0

@export var data: InventoryData


func _ready() -> void:
	InventoryMenu.InventoryShown.connect(update_inventory)
	InventoryMenu.InventoryHidden.connect(clear_inventory)
	clear_inventory()
	data.changed.connect(_on_inventory_changed)


func clear_inventory() -> void:
	for child in get_children():
		child.queue_free()


func update_inventory(index: int = 0) -> void:
	for slot in data.slots:
		var new_slot = INVENTORY_SLOT.instantiate()
		add_child(new_slot)
		new_slot.slot_data = slot
		new_slot.focus_exited
	
	await get_tree().process_frame
	get_child(index).grab_focus()


func item_focused() -> void:
	for index in get_child_count():
		if get_child(index).has_focus():
			focus_index = index
			return


func _on_inventory_changed() -> void:
	clear_inventory()
	update_inventory(focus_index)
	

class_name InventoryUI extends Control

const INVENTORY_SLOT = preload("res://Scenes/GUI/Inventory/InventorySlot.tscn")

@export var data: InventoryData


func _ready() -> void:
	InventoryMenu.InventoryShown.connect(update_inventory)
	InventoryMenu.InventoryHidden.connect(clear_inventory)
	clear_inventory()


func clear_inventory() -> void:
	for child in get_children():
		child.queue_free()


func update_inventory() -> void:
	for slot in data.slots:
		var new_slot = INVENTORY_SLOT.instantiate()
		add_child(new_slot)
		new_slot.slot_data = slot
	
	get_child(0).grab_focus()

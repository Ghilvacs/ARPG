class_name InventoryData extends Resource

@export var slots: Array[SlotData]


func _init() -> void:
	connect_slots()
	


func add_item(item: ItemData, quantity: int = 1) -> bool:
	for slot in slots:
		if slot:
			if slot.item_data == item:
				slot.quantity += quantity
				return true
	
	for index in slots.size():
		if !slots[index]:
			var new_slot = SlotData.new()
			new_slot.item_data = item
			new_slot.quantity = quantity
			slots[index] = new_slot
			new_slot.changed.connect(slot_changed)
			return true
	
	print("Inventory full!")
	return false


func connect_slots() -> void:
	for slot in slots:
		if slot:
			slot.changed.connect(slot_changed)


func slot_changed() -> void:
	for slot in slots:
		if slot:
			if slot.quantity < 1:
				slot.changed.disconnect(slot_changed)
				var index = slots.find(slot)
				slots [index] = null
				emit_changed()

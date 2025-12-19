class_name InventoryData extends Resource

@export var slots: Array[SlotData]


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
			return true
	print("Inventory full!")
	return false 

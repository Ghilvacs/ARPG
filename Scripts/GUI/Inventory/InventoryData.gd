class_name InventoryData extends Resource

signal currency_changed(new_value: int)

@export var slots: Array[SlotData]
@export var currency: int = 0: set = set_currency


func _init() -> void:
	connect_slots()


func set_currency(value: int) -> void:
	currency = max(0, value)
	currency_changed.emit(currency)


func add_currency(amount: int) -> void:
	set_currency(currency + amount)


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


func get_save_data() -> Dictionary:
	var item_save: Array = []
	
	for index in slots.size():
		item_save.append(item_to_save(slots[index]))
	
	return {
		"slots": item_save,
		"currency": currency
		}


func item_to_save(slot: SlotData) -> Dictionary:
	var result = {
		item = "",
		quantity = 0
		}
		
	if slot:
		result.quantity = slot.quantity
		if slot.item_data:
			result.item = slot.item_data.resource_path
	
	return result


func parse_save_data(save_data: Dictionary) -> void:
	# currency
	set_currency(int(save_data.get("currency", 0)))

	# slots
	var slots_data: Array = save_data.get("slots", [])
	var array_size = slots.size()
	slots.clear()
	slots.resize(array_size)

	for index in min(slots_data.size(), array_size):
		slots[index] = item_from_save(slots_data[index])

	connect_slots()

func item_from_save(save_object: Dictionary) -> SlotData:
	if save_object.item == "":
		return null
	
	var new_slot: SlotData = SlotData.new()
	new_slot.item_data = load(save_object.item)
	new_slot.quantity = int(save_object.quantity)
	
	return new_slot





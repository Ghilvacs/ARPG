@tool
class_name TreasureChest extends Node2D

@export var item_data: ItemData: set = _set_item_data
@export var quantity: int = 1: set = _set_quantity

var is_open: bool = false

@onready var item_sprite: Sprite2D = $ItemSprite
@onready var label: Label = $ItemSprite/Label
@onready var interactable_area: Area2D = $InteractableArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var is_open_data: Node = $IsOpen


func _ready() -> void:
	_update_texture()
	_update_label()
	if Engine.is_editor_hint():
		return
	
	interactable_area.body_entered.connect(_on_body_enter)
	interactable_area.body_exited.connect(_on_body_exit)
	
	is_open_data.data_loaded.connect(set_chest_state)
	set_chest_state()


func set_chest_state() -> void:
	is_open = is_open_data.value
	if is_open:
		animation_player.play("opened")
	else:
		animation_player.play("closed")


func player_interact() -> void:
	if is_open:
		return
	
	is_open = true
	is_open_data.set_value()
	animation_player.play("open_chest")
	
	if item_data and quantity:
		GlobalPlayerManager.INVENTORY_DATA.add_item(item_data, quantity)
	else:
		printerr("No items in chest!")
		push_error("No items in chest!	ChestName: ", name)


func _set_item_data(value: ItemData) -> void:
	item_data = value
	_update_texture()


func _set_quantity(value: int) -> void:
	quantity = value
	_update_label()


func _update_texture() -> void:
	if item_data and item_sprite:
		item_sprite.texture = item_data.texture


func _update_label() -> void:
	if label:
		if quantity <= 1:
			label.text = ""
		else:
			label.text = "x" + str(quantity)


func _on_body_enter(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if not GlobalPlayerManager.InteractPressed.is_connected(player_interact):
		GlobalPlayerManager.InteractPressed.connect(player_interact)


func _on_body_exit(body: Node) -> void:
	if not body.is_in_group("Player"):
		return
	if GlobalPlayerManager.InteractPressed.is_connected(player_interact):
		GlobalPlayerManager.InteractPressed.disconnect(player_interact)

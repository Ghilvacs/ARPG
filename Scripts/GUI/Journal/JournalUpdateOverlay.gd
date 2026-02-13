extends CanvasLayer

@onready var timer: Timer = $Timer
@onready var label_entry_title: Label = $Control/MarginContainer/VBoxContainer/LabelEntryTitle

signal JournalUpdateOverlayShown
signal JournalUpdateOverlayHidden

func show_journal_update_overlay(entry_title: String) -> void:
	if PauseMenu.is_paused or InventoryMenu.in_inventory or JournalMenu.in_journal:
		return
	label_entry_title.text = entry_title
	visible = true
	JournalUpdateOverlayShown.emit()
	if not timer.is_stopped():
		timer.stop()
		timer.start()
	else:
		timer.start()


func hide_journal_update_overlay() -> void:
	visible = false
	JournalUpdateOverlayHidden.emit()


func _on_timer_timeout() -> void:
	hide_journal_update_overlay()

extends CanvasLayer

@onready var sections_container: HBoxContainer = $Control/MarginContainer/VBoxContainer/SectionsContainer
@onready var button_goals: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonGoals
@onready var button_quests: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonQuests
@onready var button_tools: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonTools
@onready var button_enemies: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonEnemies
@onready var button_factions: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonFactions
@onready var button_locations: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonLocations
@onready var button_lore: Button = $Control/MarginContainer/VBoxContainer/SectionsContainer/ButtonLore
@onready var topic_list_container: VBoxContainer = $Control/MarginContainer/VBoxContainer/HSplitContainer/ScrollContainer/TopicListContainer
@onready var detail_title_label: Label = $Control/MarginContainer/VBoxContainer/HSplitContainer/Panel/MarginContainer/DetailsContainer/DetailTitleLabel
@onready var entry_list_container: VBoxContainer = $Control/MarginContainer/VBoxContainer/HSplitContainer/Panel/MarginContainer/DetailsContainer/HBoxContainer/ScrollContainer/EntryListContainer
@onready var scroll_container_overview: ScrollContainer = $Control/MarginContainer/VBoxContainer/HSplitContainer/Panel/MarginContainer/DetailsContainer/HBoxContainer/ScrollContainerOverview
@onready var overview_description_label: RichTextLabel = $Control/MarginContainer/VBoxContainer/HSplitContainer/Panel/MarginContainer/DetailsContainer/HBoxContainer/ScrollContainerOverview/OverviewDescriptionLabel

enum Category { GOAL, QUEST, TOOL, ENEMY, FACTION, LOCATION, LORE }

var current_category = Category.GOAL
var current_topic: JournalTopic
var in_journal: bool = false
var entry_text_indices: Dictionary = {}

signal JournalShown
signal JournalHidden


func _ready() -> void:
	button_goals.pressed.connect(show_category.bind(Category.GOAL))
	button_quests.pressed.connect(show_category.bind(Category.QUEST))
	button_tools.pressed.connect(show_category.bind(Category.TOOL))
	button_enemies.pressed.connect(show_category.bind(Category.ENEMY))
	button_factions.pressed.connect(show_category.bind(Category.FACTION))
	button_locations.pressed.connect(show_category.bind(Category.LOCATION))
	button_lore.pressed.connect(show_category.bind(Category.LORE))
	
	JournalManager.journal_updated.connect(_on_journal_updated)
	show_category(Category.GOAL)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		if JournalManager.is_journal_update_overlay and JournalManager.last_unlocked_entry:
			open_to_specific_entry(JournalManager.last_unlocked_entry)
		elif not in_journal:
			show_journal()
		else:
			hide_journal()
				
		get_viewport().set_input_as_handled()


func show_journal() -> void:
	PauseMenu.hide_pause_menu()
	InventoryMenu.hide_inventory_menu()
	JournalUpdateOverlay.hide_journal_update_overlay()
	visible = true
	in_journal = true
	GlobalPlayerManager.player.set_input_locked(true)
	JournalShown.emit()


func hide_journal() -> void:
	visible = false
	in_journal = false
	GlobalPlayerManager.player.set_input_locked(false)
	JournalHidden.emit()


func show_category(category: int) -> void:
	current_category = category
	_clear_topic_list()
	_clear_entry_list()
	
	var topics = JournalManager.get_known_topics(category)
	
	for topic in topics:
		var button = Button.new()
		button.text = topic.title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(200.0, 0.0)
		button.add_theme_font_size_override("Arial", 30)
		button.pressed.connect(select_topic.bind(topic))
		topic_list_container.add_child(button)
	
	if not topics.is_empty():
		select_topic(topics[0])
		topic_list_container.get_child(0).grab_focus()
	else:
		detail_title_label.text = ""
		overview_description_label.text = ""
		current_topic = null

func select_topic(topic: JournalTopic) -> void:
	current_topic = topic
	_clear_entry_list()
	detail_title_label.text = topic.title
	
	for child in entry_list_container.get_children():
		child.queue_free()
	entry_text_indices.clear()
	
	var entries = JournalManager.get_entries_for_topic(topic)
	var full_display_text: String = ""
	
	for entry in entries:
		var button = Button.new()
		button.text = entry.title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_highlight_entry.bind(entry))
		entry_list_container.add_child(button)
		entry_text_indices[entry] = full_display_text.length()
		full_display_text += entry.description + "\n\n"
	
	overview_description_label.text = full_display_text


func open_to_specific_entry(entry: JournalEntry) -> void:
	if not in_journal:
		show_journal()
	
	var parent_topic = entry.parent_topic
	
	if parent_topic:
		show_category(parent_topic.category)
		select_topic(parent_topic)
		_highlight_entry(entry)


func _highlight_entry(selected_entry: JournalEntry) -> void:
	var entries = JournalManager.get_entries_for_topic(current_topic)
	var final_bbcode = ""
	
	for entry in entries:
		if entry == selected_entry:
			final_bbcode += "[color=#ffab4b]" + entry.description + "[/color]\n\n"
		else:
			final_bbcode += "[color=#ffffff]" + entry.description + "[/color]\n\n"
	
	overview_description_label.text = final_bbcode
	
	await get_tree().process_frame
	
	if entry_text_indices.has(selected_entry):
		var character_index = entry_text_indices[selected_entry]
		var line_index = overview_description_label.get_character_line(character_index)
		var y_position = overview_description_label.get_line_offset(line_index)
		var tween = create_tween()
		tween.tween_property(scroll_container_overview, "scroll_vertical", y_position, 0.3).set_trans(Tween.TRANS_CUBIC)


func _clear_topic_list() -> void:
	for child in topic_list_container.get_children():
		child.queue_free()


func _clear_entry_list() -> void:
	for child in entry_list_container.get_children():
		child.queue_free()


func _on_journal_updated() -> void:
	show_category(current_category)
	
	if current_topic:
		select_topic(current_topic)

extends Node

var unlocked_entries: Array[JournalEntry] = []
var discovered_clues: Array[ClueData] = []
var solved_deductions: Array[DeductionData] = []

signal journal_updated(entry: JournalEntry)
signal clue_added(clue: ClueData)
signal deduction_formed(deduction: DeductionData)


func get_known_topics(category_enum: int) -> Array[JournalTopic]:
	var known_topics: Array[JournalTopic] = []
	
	for entry in unlocked_entries:
		if entry.parent_topic and entry.parent_topic.category == category_enum:
			if not known_topics.has(entry.parent_topic):
				known_topics.append(entry.parent_topic)
	
	return known_topics


func get_entries_for_topic(topic: JournalTopic) -> Array[JournalEntry]:
	var entries: Array[JournalEntry] = []
	
	for entry in unlocked_entries:
		if entry.parent_topic == topic:
			entries.append(entry)
	return entries


func unlock_entry(entry: JournalEntry) -> void:
	if not unlocked_entries.has(entry):
		unlocked_entries.append(entry)
		emit_signal("journal_updated")
		print("Journal Entry Unlocked: " + entry.title)


func add_clue(clue: ClueData) -> void:
	if clue not in discovered_clues:
		discovered_clues.append(clue)
		emit_signal("clue_added", clue)


func attempt_clues_connection(clue_a: ClueData, clue_b: ClueData) -> bool:
	return false

class_name JournalEntry extends Resource

enum Category { GOAL, QUEST, TOOL, ENEMY, LOCATION, FACTION, LORE }

@export var parent_topic: JournalTopic
@export var title: String
@export var icon: Texture2D

@export_group("Content")
@export_multiline var description: String


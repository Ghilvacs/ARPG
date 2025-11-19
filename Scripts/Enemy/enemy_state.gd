class_name EnemyState extends Node

var state_machine
var enemy: CharacterBody2D


func enter(previous_state: EnemyState) -> void:
	pass


func exit() -> void:
	pass


func update(_delta: float) -> EnemyState:
	return null


func physics_update(_delta: float) -> EnemyState:
	return null


func handle_input(_event: InputEvent) -> EnemyState:
	return null

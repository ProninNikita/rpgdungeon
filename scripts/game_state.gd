extends Node

var current_enemy_id: String = ""
var defeated_enemies: Dictionary = {}

func start_battle(enemy_id: String) -> void:
	current_enemy_id = enemy_id

func mark_current_enemy_defeated() -> void:
	if current_enemy_id.is_empty():
		return
	defeated_enemies[current_enemy_id] = true

func is_enemy_defeated(enemy_id: String) -> bool:
	return defeated_enemies.has(enemy_id)

func clear_current_battle() -> void:
	current_enemy_id = ""

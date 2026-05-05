extends Node

const SAVE_SLOT_COUNT = 3
const MAIN_LEVEL_PATH = "res://scenes/levels/main_level.tscn"

var active_save_slot: int = 0
var selected_character_id: String = "base"
var current_enemy_id: String = ""
var defeated_enemies: Dictionary = {}

func start_new_game(character_id: String) -> void:
	selected_character_id = character_id
	current_enemy_id = ""
	defeated_enemies.clear()
	active_save_slot = get_first_empty_save_slot()
	if active_save_slot != 0:
		save_current_game()

func load_game(slot: int) -> bool:
	var save_data = load_save_slot(slot)
	if save_data.is_empty():
		return false
	
	active_save_slot = slot
	selected_character_id = save_data.get("selected_character_id", "base")
	current_enemy_id = ""
	defeated_enemies = save_data.get("defeated_enemies", {})
	return true

func save_current_game() -> void:
	if active_save_slot == 0:
		return
	
	var save_data = {
		"version": "0.1.0",
		"selected_character_id": selected_character_id,
		"defeated_enemies": defeated_enemies,
		"updated_at": Time.get_datetime_string_from_system(false, true)
	}
	
	var file = FileAccess.open(get_save_path(active_save_slot), FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(save_data, "\t"))

func load_save_slot(slot: int) -> Dictionary:
	if not save_slot_exists(slot):
		return {}
	
	var file = FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file == null:
		return {}
	
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	
	return parsed

func delete_save_slot(slot: int) -> void:
	if not save_slot_exists(slot):
		return
	DirAccess.remove_absolute(get_save_path(slot))
	if active_save_slot == slot:
		active_save_slot = 0

func save_slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))

func get_first_empty_save_slot() -> int:
	for slot in range(1, SAVE_SLOT_COUNT + 1):
		if not save_slot_exists(slot):
			return slot
	return 0

func get_save_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot

func start_battle(enemy_id: String) -> void:
	current_enemy_id = enemy_id

func mark_current_enemy_defeated() -> void:
	if current_enemy_id.is_empty():
		return
	defeated_enemies[current_enemy_id] = true
	save_current_game()

func is_enemy_defeated(enemy_id: String) -> bool:
	return defeated_enemies.has(enemy_id)

func clear_current_battle() -> void:
	current_enemy_id = ""

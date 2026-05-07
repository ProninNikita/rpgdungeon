extends Control

@onready var slot_rows = [
	$Content/Slots/Slot1,
	$Content/Slots/Slot2,
	$Content/Slots/Slot3
]

func _ready() -> void:
	for index in range(slot_rows.size()):
		var slot = index + 1
		var row = slot_rows[index]
		row.get_node("LoadButton").pressed.connect(_on_load_slot_pressed.bind(slot))
		row.get_node("DeleteButton").pressed.connect(_on_delete_slot_pressed.bind(slot))
	
	$BackButton.pressed.connect(_on_back_pressed)
	refresh_slots()

func refresh_slots() -> void:
	for index in range(slot_rows.size()):
		var slot = index + 1
		var row = slot_rows[index]
		var save_data = GameState.load_save_slot(slot)
		var has_save = not save_data.is_empty()
		
		row.get_node("Title").text = "Slot %d" % slot
		row.get_node("Description").text = get_slot_description(save_data)
		row.get_node("LoadButton").disabled = not has_save
		row.get_node("DeleteButton").disabled = not has_save

func get_slot_description(save_data: Dictionary) -> String:
	if save_data.is_empty():
		return "Empty"
	
	var character_id = save_data.get("selected_character_id", "base")
	var level_data = save_data.get("level_data", {})
	var floor_number = int(save_data.get("current_floor", level_data.get("floor_number", 1)))
	var path_label = get_path_label(str(level_data.get("path", "normal")))
	var gold = int(save_data.get("gold", 0))
	var defeated_count = save_data.get("defeated_enemies", {}).size()
	var updated_at = save_data.get("updated_at", "unknown time")
	return "Character: %s | Floor: %d/3 | Path: %s\nGold: %d | Defeated: %d | Saved: %s" % [
		character_id,
		floor_number,
		path_label,
		gold,
		defeated_count,
		updated_at
	]

func get_path_label(path_type: String) -> String:
	if path_type == "elite":
		return "Elite"
	return "Normal"

func _on_load_slot_pressed(slot: int) -> void:
	if GameState.load_game(slot):
		get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)

func _on_delete_slot_pressed(slot: int) -> void:
	GameState.delete_save_slot(slot)
	refresh_slots()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

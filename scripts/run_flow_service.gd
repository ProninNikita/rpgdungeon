extends RefCounted

const SaveManager = preload("res://scripts/save_manager.gd")
const RunState = preload("res://scripts/run_state.gd")

static func start_new_game(state: Node, character_id: String, slot: int, overwrite: bool = false) -> bool:
	if not SaveManager.is_valid_slot(slot):
		return false
	if state.save_slot_exists(slot) and not overwrite:
		return false

	state.selected_character_id = character_id
	state.current_enemy_id = ""
	state.defeated_enemies.clear()
	state.completed_run_summary.clear()
	state.current_floor = 1
	state.gold = 0
	state.inventory.clear()
	state.equipment = state.DEFAULT_EQUIPMENT.duplicate()
	state.level_data = state.generate_level_data(state.current_floor, state.FLOOR_PATH_NORMAL)
	state.player_grid_pos = state.level_data.get("start_position", state.START_GRID_POS).duplicate()
	state.player_stats = state.get_character_stats(character_id)
	state.active_save_slot = slot
	state.save_current_game()
	return true

static func advance_to_next_floor(state: Node, exit_id: String) -> bool:
	for exit_data in state.get_visible_exits():
		if exit_data.get("id", "") != exit_id:
			continue
		if int(exit_data.get("to_floor", state.current_floor + 1)) > state.MAX_FLOOR:
			complete_run(state)
			return true

		state.current_floor = int(exit_data.get("to_floor", state.current_floor + 1))
		state.current_enemy_id = ""
		state.defeated_enemies.clear()
		state.level_data = state.generate_level_data(state.current_floor, str(exit_data.get("path", state.FLOOR_PATH_NORMAL)))
		state.player_grid_pos = state.level_data.get("start_position", state.START_GRID_POS).duplicate()
		state.save_current_game()
		return true
	return false

static func handle_player_defeat(state: Node) -> void:
	state.current_enemy_id = ""
	if state.active_save_slot != 0:
		state.delete_save_slot(state.active_save_slot)

static func complete_run(state: Node) -> Dictionary:
	state.completed_run_summary = RunState.make_run_summary(
		str(state.get_player_battle_stats().get("name", "Герой")),
		state.get_current_path_label(),
		state.current_floor,
		state.MAX_FLOOR,
		state.gold,
		state.defeated_enemies.size(),
		state.equipment,
		Callable(state, "get_item_name")
	)
	state.current_enemy_id = ""
	if state.active_save_slot != 0:
		state.delete_save_slot(state.active_save_slot)
	return state.completed_run_summary

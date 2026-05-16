extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const ResultData = preload("res://scripts/result_data.gd")

const DEFAULT_SAVE_DIR = "/private/tmp/rpg_full_run_check"

var failures: Array = []
var game_state: Node

func _init() -> void:
	call_deferred("run")

func run() -> void:
	configure_isolated_save_dir()
	game_state = get_game_state()
	if game_state == null:
		failures.append("GameState autoload is not available.")
	else:
		cleanup_save_slots()
		validate_full_run_flow()
		cleanup_save_slots()

	if failures.is_empty():
		print("Full run flow check passed.")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func get_game_state() -> Node:
	if root.has_node("GameState"):
		return root.get_node("GameState")

	var state = GameStateScript.new()
	state.name = "GameState"
	root.add_child(state)
	return state

func configure_isolated_save_dir() -> void:
	var save_dir = get_requested_save_dir()
	ProjectSettings.set_setting(SaveManager.SAVE_DIR_SETTING, save_dir)
	if not SaveManager.ensure_save_dir_exists():
		failures.append("Could not create isolated save dir: %s" % save_dir)

func get_requested_save_dir() -> String:
	var user_args = OS.get_cmdline_user_args()
	if not user_args.is_empty() and not str(user_args[0]).strip_edges().is_empty():
		return str(user_args[0]).strip_edges()
	return DEFAULT_SAVE_DIR

func cleanup_save_slots() -> void:
	for slot in range(1, SaveManager.SAVE_SLOT_COUNT + 1):
		SaveManager.delete_save_slot(slot)

func validate_full_run_flow() -> void:
	if not failures.is_empty():
		return

	assert_true(game_state.start_new_game("base"), "start new game")
	var active_slot = int(game_state.active_save_slot)
	assert_true(active_slot != 0, "new game chooses an active save slot")
	assert_true(SaveManager.save_slot_exists(active_slot), "new game writes a save slot")
	assert_special_rooms("new game floor")
	validate_special_room_rewards()

	validate_enemy_fight()
	validate_inventory_equip()
	validate_floor_clear_and_chest()
	validate_exit_paths()
	validate_victory_completion(active_slot)
	validate_death_deletes_save(active_slot)

func validate_enemy_fight() -> void:
	var enemy_encounter = get_first_enemy_encounter()
	assert_true(not enemy_encounter.is_empty(), "generated level has an enemy")
	if enemy_encounter.is_empty():
		return

	var enemy_id = str(enemy_encounter.get("id", ""))
	var return_position = Vector2i(int(enemy_encounter.get("x", 0)), int(enemy_encounter.get("y", 0)))
	var gold_before = int(game_state.gold)
	game_state.start_battle(enemy_id, return_position)
	var reward = game_state.grant_current_enemy_reward()
	game_state.mark_current_enemy_defeated()
	game_state.clear_current_battle()

	assert_true(game_state.is_enemy_defeated(enemy_id), "fight marks enemy as defeated")
	assert_true(int(game_state.gold) > gold_before, "fight grants gold")
	assert_true(reward.has(ResultData.KEY_GOLD), "fight returns a reward result")

func validate_inventory_equip() -> void:
	game_state.inventory.clear()
	game_state.equipment = game_state.DEFAULT_EQUIPMENT.duplicate()

	assert_true(game_state.add_inventory_item("wooden_sword"), "item can be added to inventory")
	assert_true(game_state.equip_inventory_item(0), "inventory item can be equipped")
	assert_true(str(game_state.equipment.get("weapon", "")) == "wooden_sword", "weapon slot contains equipped item")
	assert_true(game_state.unequip_equipment_slot("weapon"), "equipped item can be unequipped")
	assert_true(str(game_state.equipment.get("weapon", "")).is_empty(), "weapon slot is empty after unequip")

func validate_floor_clear_and_chest() -> void:
	mark_current_floor_cleared()
	assert_true(game_state.is_level_cleared(), "floor can be cleared")

	var gold_before = int(game_state.gold)
	var reward = game_state.open_level_chest()
	assert_true(bool(reward.get(ResultData.KEY_OPENED, false)), "cleared floor chest opens")
	assert_true(int(game_state.gold) >= gold_before, "chest does not reduce gold")
	assert_true(bool(game_state.level_data.get("chest", {}).get("is_opened", false)), "chest is marked opened")
	assert_special_rooms("cleared floor")

func validate_exit_paths() -> void:
	prepare_cleared_floor(2, game_state.FLOOR_PATH_NORMAL)
	var normal_exit = find_exit_by_path(game_state.FLOOR_PATH_NORMAL)
	assert_true(not normal_exit.is_empty(), "normal floor 2 exit exists")
	if not normal_exit.is_empty():
		assert_true(game_state.advance_to_next_floor(str(normal_exit.get("id", ""))), "normal exit advances")
		assert_true(str(game_state.level_data.get("path", "")) == game_state.FLOOR_PATH_NORMAL, "normal exit keeps normal path")

	prepare_cleared_floor(2, game_state.FLOOR_PATH_NORMAL)
	var elite_exit = find_exit_by_path(game_state.FLOOR_PATH_ELITE)
	assert_true(not elite_exit.is_empty(), "elite floor 2 exit exists")
	if not elite_exit.is_empty():
		assert_true(game_state.advance_to_next_floor(str(elite_exit.get("id", ""))), "elite exit advances")
		assert_true(str(game_state.level_data.get("path", "")) == game_state.FLOOR_PATH_ELITE, "elite exit switches to elite path")

func validate_victory_completion(active_slot: int) -> void:
	game_state.active_save_slot = active_slot
	prepare_cleared_floor(game_state.MAX_FLOOR, game_state.FLOOR_PATH_ELITE)
	assert_true(not game_state.is_run_complete(), "final floor waits for final chest before completion")
	var final_reward = game_state.open_level_chest()
	assert_true(bool(final_reward.get(ResultData.KEY_OPENED, false)), "final floor chest opens before victory")
	assert_true(game_state.is_run_complete(), "final chest enables completed run")
	var summary = game_state.complete_run()
	assert_true(not summary.is_empty(), "completed run creates a result summary")
	assert_true(str(summary.get("character", "")).length() > 0, "result summary has character")
	assert_true(int(summary.get("gold", -1)) >= 0, "result summary has gold")
	assert_true(int(summary.get("defeated_enemies", 0)) > 0, "result summary has defeated enemies")
	assert_true(not SaveManager.save_slot_exists(active_slot), "completed run removes active save slot")

func validate_death_deletes_save(active_slot: int) -> void:
	game_state.active_save_slot = active_slot
	game_state.save_current_game()
	assert_true(SaveManager.save_slot_exists(active_slot), "death check starts with a saved slot")

	game_state.handle_player_defeat()
	assert_true(not SaveManager.save_slot_exists(active_slot), "death deletes active save slot")
	assert_true(int(game_state.active_save_slot) == 0, "death clears active save slot")

func get_first_enemy_encounter() -> Dictionary:
	for enemy_encounter in game_state.level_data.get("enemies", []):
		if not game_state.is_enemy_defeated(str(enemy_encounter.get("id", ""))):
			return enemy_encounter
	return {}

func mark_current_floor_cleared() -> void:
	for enemy_encounter in game_state.level_data.get("enemies", []):
		game_state.defeated_enemies[str(enemy_encounter.get("id", ""))] = true

func prepare_cleared_floor(floor_number: int, path_type: String) -> void:
	game_state.current_floor = floor_number
	game_state.current_enemy_id = ""
	game_state.defeated_enemies.clear()
	game_state.level_data = game_state.generate_level_data(floor_number, path_type)
	game_state.player_grid_pos = game_state.level_data.get("start_position", game_state.START_GRID_POS).duplicate()
	mark_current_floor_cleared()
	game_state.save_current_game()

func assert_special_rooms(context: String) -> void:
	var special_rooms = game_state.level_data.get("special_rooms", [])
	assert_true(special_rooms.size() == 2, "%s has two special rooms" % context)
	var room_types = {}
	for special_room in special_rooms:
		room_types[str(special_room.get("type", ""))] = true
	assert_true(room_types.has("artifact"), "%s has an artifact room" % context)
	assert_true(room_types.has("shop"), "%s has a shop room" % context)

func validate_special_room_rewards() -> void:
	var artifact_room = find_special_room_by_type("artifact")
	assert_true(not artifact_room.is_empty(), "artifact room exists")
	if not artifact_room.is_empty():
		var artifact_choice = game_state.use_special_room(str(artifact_room.get("id", "")))
		var artifact_options = artifact_choice.get("options", [])
		var artifact_item = str(artifact_options[0].get("item_id", ""))
		var artifact_result = game_state.use_special_room_option(str(artifact_room.get("id", "")), 0)
		assert_true(str(artifact_result.get("message", "")).length() > 0, "artifact room returns a message")
		assert_true(game_state.inventory.has(artifact_item), "artifact room grants its item")

	var shop_room = find_special_room_by_type("shop")
	assert_true(not shop_room.is_empty(), "shop room exists")
	if not shop_room.is_empty():
		var shop_choice = game_state.use_special_room(str(shop_room.get("id", "")))
		var shop_options = shop_choice.get("options", [])
		var shop_item = str(shop_options[0].get("item_id", ""))
		var shop_price = int(shop_options[0].get("price", 0))
		game_state.add_gold(shop_price)
		var gold_before = int(game_state.gold)
		var shop_result = game_state.use_special_room_option(str(shop_room.get("id", "")), 0)
		assert_true(str(shop_result.get("message", "")).length() > 0, "shop room returns a message")
		assert_true(game_state.inventory.has(shop_item), "shop room adds purchased item")
		assert_true(int(game_state.gold) == gold_before - shop_price, "shop room spends gold")

func find_special_room_by_type(room_type: String) -> Dictionary:
	for special_room in game_state.level_data.get("special_rooms", []):
		if str(special_room.get("type", "")) == room_type:
			return special_room
	return {}

func find_exit_by_path(path_type: String) -> Dictionary:
	for exit_data in game_state.get_visible_exits():
		if str(exit_data.get("path", "")) == path_type:
			return exit_data
	return {}

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

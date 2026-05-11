extends Node

const SaveManager = preload("res://scripts/save_manager.gd")
const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")
const ItemDatabase = preload("res://scripts/item_database.gd")
const ScenePaths = preload("res://scripts/scene_paths.gd")
const ResultData = preload("res://scripts/result_data.gd")

const SAVE_SLOT_COUNT = SaveManager.SAVE_SLOT_COUNT
const SAVE_VERSION = "0.1.2"
const MAIN_LEVEL_PATH = ScenePaths.MAIN_LEVEL
const ROOM_WIDTH = DungeonGenerator.ROOM_WIDTH
const ROOM_HEIGHT = DungeonGenerator.ROOM_HEIGHT
const MIN_ROOM_COUNT = DungeonGenerator.MIN_ROOM_COUNT
const MAX_ROOM_COUNT = DungeonGenerator.MAX_ROOM_COUNT
const MIN_ROOM_SIZE = DungeonGenerator.MIN_ROOM_SIZE
const MAX_ROOM_SIZE = DungeonGenerator.MAX_ROOM_SIZE
const ENEMY_COUNT = DungeonGenerator.ENEMY_COUNT
const MAX_FLOOR = DungeonGenerator.MAX_FLOOR
const START_GRID_POS = DungeonGenerator.START_GRID_POS
const DEFAULT_ENEMY_TYPE = "goblin"
const DUNGEON_ENEMY_TYPES = DungeonGenerator.DUNGEON_ENEMY_TYPES
const FLOOR_PATH_NORMAL = DungeonGenerator.FLOOR_PATH_NORMAL
const FLOOR_PATH_ELITE = DungeonGenerator.FLOOR_PATH_ELITE
const MAX_INVENTORY_SIZE = ItemDatabase.MAX_INVENTORY_SIZE
const LOOT_TABLES = ItemDatabase.LOOT_TABLES
const CHARACTER_DEFINITIONS = {
	"base": {
		"name": "Герой",
		"hp": 100,
		"max_hp": 100,
		"attack": 10,
		"defense": 2,
		"passives": [
			{
				"id": "resolve",
				"name": "Стойкость",
				"trigger_hp_percent": 0.30,
				"heal_percent": 0.20
			}
		]
	},
	"vampire": {
		"name": "Вампир",
		"hp": 90,
		"max_hp": 90,
		"attack": 11,
		"defense": 1,
		"passives": [
			{
				"id": "vampirism",
				"name": "Вампиризм",
				"heal_percent": 0.05
			}
		]
	}
}
const ENEMY_DEFINITIONS = {
	"goblin": {
		"name": "Гоблин",
		"hp": 28,
		"max_hp": 28,
		"attack": 6,
		"defense": 1,
		"features": []
	},
	"skeleton": {
		"name": "Скелет",
		"hp": 24,
		"max_hp": 24,
		"attack": 10,
		"defense": 0,
		"features": [
			{
				"id": "armor_pierce",
				"name": "Пробитие брони",
				"pierce": 2
			}
		]
	},
	"bat": {
		"name": "Летучая мышь",
		"hp": 18,
		"max_hp": 18,
		"attack": 5,
		"defense": 0,
		"features": [
			{
				"id": "evasion",
				"name": "Уклонение",
				"chance": 0.25
			}
		]
	},
	"slime": {
		"name": "Слизень",
		"hp": 42,
		"max_hp": 42,
		"attack": 4,
		"defense": 2,
		"features": [
			{
				"id": "regeneration",
				"name": "Регенерация",
				"heal": 2
			}
		]
	}
}
const ITEM_DEFINITIONS = ItemDatabase.ITEM_DEFINITIONS
const DEFAULT_EQUIPMENT = ItemDatabase.DEFAULT_EQUIPMENT

var active_save_slot: int = 0
var selected_character_id: String = "base"
var current_floor: int = 1
var level_data: Dictionary = {}
var player_grid_pos: Dictionary = START_GRID_POS.duplicate()
var player_stats: Dictionary = get_default_player_stats()
var gold: int = 0
var inventory: Array = []
var equipment: Dictionary = DEFAULT_EQUIPMENT.duplicate()
var current_enemy_id: String = ""
var defeated_enemies: Dictionary = {}

func start_new_game(character_id: String) -> bool:
	var save_slot = get_first_empty_save_slot()
	if save_slot == 0:
		return false

	return start_new_game_in_slot(character_id, save_slot, false)

func start_new_game_in_slot(character_id: String, slot: int, overwrite: bool = false) -> bool:
	if not SaveManager.is_valid_slot(slot):
		return false
	if save_slot_exists(slot) and not overwrite:
		return false

	selected_character_id = character_id
	current_enemy_id = ""
	defeated_enemies.clear()
	current_floor = 1
	gold = 0
	inventory.clear()
	equipment = DEFAULT_EQUIPMENT.duplicate()
	level_data = generate_level_data(current_floor, FLOOR_PATH_NORMAL)
	player_grid_pos = level_data.get("start_position", START_GRID_POS).duplicate()
	player_stats = get_character_stats(character_id)
	active_save_slot = slot
	save_current_game()
	return true

func load_game(slot: int) -> bool:
	var save_data = load_save_slot(slot)
	if save_data.is_empty():
		return false
	save_data = migrate_save_data(save_data)

	active_save_slot = slot
	selected_character_id = save_data.get("selected_character_id", "base")
	current_floor = int(save_data.get("current_floor", 1))
	var saved_level_data = save_data.get("level_data", {})
	level_data = saved_level_data if typeof(saved_level_data) == TYPE_DICTIONARY else {}
	var regenerated_level = false
	if not is_valid_level_data(level_data):
		level_data = generate_level_data(current_floor, FLOOR_PATH_NORMAL)
		regenerated_level = true
	else:
		normalize_level_data()
	current_floor = int(level_data.get("floor_number", current_floor))
	player_grid_pos = normalize_grid_position(save_data.get("player_grid_pos", {}), level_data.get("start_position", START_GRID_POS))
	if regenerated_level or not is_grid_position_walkable(level_data, player_grid_pos):
		player_grid_pos = level_data.get("start_position", START_GRID_POS).duplicate()
	player_stats = normalize_player_stats(save_data.get("player_stats", {}), selected_character_id)
	gold = normalize_gold(save_data.get("gold", 0))
	inventory = normalize_inventory(save_data.get("inventory", []))
	equipment = normalize_equipment(save_data.get("equipment", {}))
	current_enemy_id = ""
	defeated_enemies = normalize_defeated_enemies(save_data.get("defeated_enemies", {}))
	return true

func migrate_save_data(save_data: Dictionary) -> Dictionary:
	var migrated = save_data.duplicate(true)
	var version = str(migrated.get("version", "0.1.0"))
	if version.is_empty():
		version = "0.1.0"

	if version in ["0.1.0", "0.1.1"]:
		migrated = migrate_pre_0_1_2_save_data(migrated)

	migrated["version"] = SAVE_VERSION
	return migrated

func migrate_pre_0_1_2_save_data(save_data: Dictionary) -> Dictionary:
	var migrated = save_data.duplicate(true)
	if not migrated.has("inventory"):
		migrated["inventory"] = []
	if not migrated.has("equipment"):
		migrated["equipment"] = DEFAULT_EQUIPMENT.duplicate()
	if not migrated.has("gold"):
		migrated["gold"] = 0
	if not migrated.has("defeated_enemies"):
		migrated["defeated_enemies"] = {}
	return migrated

func normalize_player_stats(saved_stats: Variant, character_id: String) -> Dictionary:
	var base_stats = get_character_stats(character_id)
	if typeof(saved_stats) != TYPE_DICTIONARY:
		return base_stats

	var max_hp = max(1, int(saved_stats.get("max_hp", base_stats["max_hp"])))
	return {
		"hp": clampi(int(saved_stats.get("hp", base_stats["hp"])), 0, max_hp),
		"max_hp": max_hp,
		"attack": max(0, int(saved_stats.get("attack", base_stats["attack"]))),
		"defense": max(0, int(saved_stats.get("defense", base_stats["defense"]))),
		"name": str(saved_stats.get("name", base_stats["name"])),
		"passives": normalize_passives(saved_stats.get("passives", base_stats["passives"]))
	}

func normalize_passives(saved_passives: Variant) -> Array:
	if typeof(saved_passives) != TYPE_ARRAY:
		return []
	return saved_passives.duplicate(true)

func normalize_grid_position(saved_grid_position: Variant, fallback_position: Variant) -> Dictionary:
	var fallback = fallback_position if typeof(fallback_position) == TYPE_DICTIONARY else START_GRID_POS
	if typeof(saved_grid_position) != TYPE_DICTIONARY:
		return fallback.duplicate()

	return {
		"x": int(saved_grid_position.get("x", fallback.get("x", START_GRID_POS["x"]))),
		"y": int(saved_grid_position.get("y", fallback.get("y", START_GRID_POS["y"])))
	}

func normalize_gold(saved_gold: Variant) -> int:
	return max(0, int(saved_gold))

func normalize_defeated_enemies(saved_defeated_enemies: Variant) -> Dictionary:
	var normalized = {}
	if typeof(saved_defeated_enemies) != TYPE_DICTIONARY:
		return normalized

	for enemy_id in saved_defeated_enemies.keys():
		if bool(saved_defeated_enemies[enemy_id]):
			normalized[str(enemy_id)] = true
	return normalized

func save_current_game() -> void:
	if active_save_slot == 0:
		return

	var save_data = {
		"version": SAVE_VERSION,
		"selected_character_id": selected_character_id,
		"current_floor": current_floor,
		"level_data": level_data,
		"player_grid_pos": player_grid_pos,
		"player_stats": player_stats,
		"gold": gold,
		"inventory": inventory,
		"equipment": equipment,
		"defeated_enemies": defeated_enemies,
		"updated_at": Time.get_datetime_string_from_system(false, true)
	}

	SaveManager.write_save_slot(active_save_slot, save_data)

func load_save_slot(slot: int) -> Dictionary:
	return SaveManager.load_save_slot(slot)

func delete_save_slot(slot: int) -> void:
	SaveManager.delete_save_slot(slot)
	if active_save_slot == slot:
		active_save_slot = 0

func save_slot_exists(slot: int) -> bool:
	return SaveManager.save_slot_exists(slot)

func get_first_empty_save_slot() -> int:
	return SaveManager.get_first_empty_save_slot()

func has_empty_save_slot() -> bool:
	return SaveManager.has_empty_save_slot()

func get_save_path(slot: int) -> String:
	return SaveManager.get_save_path(slot)

func get_save_file_name(slot: int) -> String:
	return SaveManager.get_save_file_name(slot)

func ensure_level_data() -> void:
	if not is_valid_level_data(level_data):
		level_data = generate_level_data(current_floor, FLOOR_PATH_NORMAL)
		player_grid_pos = level_data.get("start_position", START_GRID_POS).duplicate()
	else:
		normalize_level_data()

func is_valid_level_data(data: Dictionary) -> bool:
	return data.has("floor_tiles") \
		and typeof(data.get("floor_tiles")) == TYPE_ARRAY \
		and data.has("walls") \
		and typeof(data.get("walls")) == TYPE_ARRAY \
		and data.has("rooms") \
		and typeof(data.get("rooms")) == TYPE_ARRAY \
		and data.has("enemies") \
		and typeof(data.get("enemies")) == TYPE_ARRAY

func is_grid_position_walkable(data: Dictionary, grid_position: Dictionary) -> bool:
	var key = get_grid_key(int(grid_position.get("x", START_GRID_POS["x"])), int(grid_position.get("y", START_GRID_POS["y"])))
	for floor_tile in data.get("floor_tiles", []):
		if get_grid_key(floor_tile["x"], floor_tile["y"]) == key:
			return true
	return false

func get_default_player_stats() -> Dictionary:
	return get_character_stats("base")

func get_character_stats(character_id: String) -> Dictionary:
	var definition = CHARACTER_DEFINITIONS.get(character_id, CHARACTER_DEFINITIONS["base"])
	return {
		"hp": int(definition["hp"]),
		"max_hp": int(definition["max_hp"]),
		"attack": int(definition["attack"]),
		"defense": int(definition["defense"]),
		"name": str(definition["name"]),
		"passives": definition.get("passives", []).duplicate(true)
	}

func get_enemy_stats(enemy_type: String) -> Dictionary:
	var definition = ENEMY_DEFINITIONS.get(enemy_type, ENEMY_DEFINITIONS[DEFAULT_ENEMY_TYPE])
	return {
		"type": enemy_type if ENEMY_DEFINITIONS.has(enemy_type) else DEFAULT_ENEMY_TYPE,
		"name": str(definition["name"]),
		"hp": int(definition["hp"]),
		"max_hp": int(definition["max_hp"]),
		"attack": int(definition["attack"]),
		"defense": int(definition["defense"]),
		"features": definition.get("features", []).duplicate(true)
	}

func get_current_enemy_battle_stats() -> Dictionary:
	var enemy_encounter = get_enemy_encounter_data(current_enemy_id)
	if enemy_encounter.is_empty():
		return get_enemy_stats(DEFAULT_ENEMY_TYPE)

	var stats = get_enemy_stats(str(enemy_encounter.get("type", DEFAULT_ENEMY_TYPE)))
	stats.merge(enemy_encounter, true)
	stats.erase("id")
	stats.erase("x")
	stats.erase("y")
	return {
		"type": str(stats.get("type", DEFAULT_ENEMY_TYPE)),
		"name": str(stats.get("name", "Гоблин")),
		"hp": int(stats.get("hp", stats.get("max_hp", 30))),
		"max_hp": int(stats.get("max_hp", 30)),
		"attack": int(stats.get("attack", 5)),
		"defense": int(stats.get("defense", 0)),
		"features": stats.get("features", []).duplicate(true)
	}

func get_enemy_encounter_data(enemy_id: String) -> Dictionary:
	for enemy_encounter in level_data.get("enemies", []):
		if enemy_encounter.get("id", "") == enemy_id:
			return enemy_encounter
	return {}

func normalize_level_data() -> void:
	level_data["floor_number"] = int(level_data.get("floor_number", current_floor))
	level_data["path"] = str(level_data.get("path", FLOOR_PATH_NORMAL))

	var normalized_enemies = []
	for enemy_encounter in level_data.get("enemies", []):
		normalized_enemies.append(normalize_enemy_encounter_data(enemy_encounter))
	level_data["enemies"] = normalized_enemies

	if not level_data.has("exits"):
		level_data["exits"] = DungeonGenerator.generate_exit_data(level_data.get("rooms", []), int(level_data["floor_number"]), str(level_data["path"]))
	if not level_data.has("chest"):
		level_data["chest"] = DungeonGenerator.generate_chest_data(level_data.get("exits", []), int(level_data["floor_number"]), str(level_data["path"]), level_data.get("rooms", []))
	if not level_data.has("fountain"):
		level_data["fountain"] = DungeonGenerator.generate_fountain_data(level_data.get("rooms", []), int(level_data["floor_number"]))

func normalize_enemy_encounter_data(enemy_encounter: Dictionary) -> Dictionary:
	var enemy_type = str(enemy_encounter.get("type", DEFAULT_ENEMY_TYPE))
	var stats = scale_enemy_stats(
		get_enemy_stats(enemy_type),
		int(level_data.get("floor_number", current_floor)),
		str(level_data.get("path", FLOOR_PATH_NORMAL))
	)
	return {
		"id": str(enemy_encounter.get("id", "")),
		"type": stats["type"],
		"name": stats["name"],
		"x": int(enemy_encounter.get("x", START_GRID_POS["x"])),
		"y": int(enemy_encounter.get("y", START_GRID_POS["y"])),
		"hp": min(int(enemy_encounter.get("hp", stats["hp"])), int(stats["max_hp"])),
		"max_hp": stats["max_hp"],
		"attack": stats["attack"],
		"defense": stats["defense"],
		"features": stats["features"].duplicate(true)
	}

func normalize_inventory(saved_inventory: Variant) -> Array:
	return ItemDatabase.normalize_inventory(saved_inventory)

func normalize_equipment(saved_equipment: Variant) -> Dictionary:
	return ItemDatabase.normalize_equipment(saved_equipment)

func get_item_definition(item_id: String) -> Dictionary:
	return ItemDatabase.get_item_definition(item_id)

func get_item_name(item_id: String) -> String:
	return ItemDatabase.get_item_name(item_id)

func get_item_stat_bonuses(item_id: String) -> Dictionary:
	return ItemDatabase.get_item_stat_bonuses(item_id)

func get_equipment_stat_bonuses() -> Dictionary:
	return ItemDatabase.get_equipment_stat_bonuses(equipment)

func get_item_bonus_text(item_id: String) -> String:
	return ItemDatabase.get_item_bonus_text(item_id)

func add_inventory_item(item_id: String, should_save: bool = false) -> bool:
	if not ItemDatabase.can_add_inventory_item(inventory, item_id):
		return false

	inventory.append(item_id)
	if should_save:
		save_current_game()
	return true

func add_gold(amount: int, should_save: bool = false) -> void:
	gold = max(0, gold + amount)
	if should_save:
		save_current_game()

func equip_inventory_item(inventory_index: int, should_save: bool = true) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false

	var item_id = str(inventory[inventory_index])
	var item = get_item_definition(item_id)
	if item.is_empty():
		return false

	var slot = str(item.get("slot", ""))
	if not equipment.has(slot):
		return false

	var previous_item_id = str(equipment.get(slot, ""))
	equipment[slot] = item_id
	inventory.remove_at(inventory_index)
	if not previous_item_id.is_empty():
		inventory.append(previous_item_id)

	if should_save:
		save_current_game()
	return true

func unequip_equipment_slot(slot: String, should_save: bool = true) -> bool:
	if not equipment.has(slot):
		return false

	var item_id = str(equipment.get(slot, ""))
	if item_id.is_empty() or not ItemDatabase.can_add_inventory_item(inventory, item_id):
		return false

	equipment[slot] = ""
	inventory.append(item_id)
	if should_save:
		save_current_game()
	return true

func discard_inventory_item(inventory_index: int, should_save: bool = true) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false

	inventory.remove_at(inventory_index)
	if should_save:
		save_current_game()
	return true

func grant_current_enemy_reward() -> Dictionary:
	var enemy_encounter = get_enemy_encounter_data(current_enemy_id)
	var enemy_type = str(enemy_encounter.get("type", DEFAULT_ENEMY_TYPE))
	var path_type = str(level_data.get("path", FLOOR_PATH_NORMAL))
	var loot_table = ItemDatabase.get_loot_table(enemy_type, DEFAULT_ENEMY_TYPE)
	var gold_amount = randi_range(int(loot_table["gold_min"]), int(loot_table["gold_max"]))
	if path_type == FLOOR_PATH_ELITE:
		gold_amount = ceili(gold_amount * 1.5)
	add_gold(gold_amount)

	var reward = ResultData.make_reward_result(gold_amount)

	var item_chance = float(loot_table.get("item_chance", 0.0))
	if path_type == FLOOR_PATH_ELITE:
		item_chance += 0.15
	if randf() > item_chance:
		return reward

	var item_id = ItemDatabase.get_random_loot_item_id(loot_table.get("items", []))
	if item_id.is_empty():
		return reward

	reward[ResultData.KEY_ITEM_ID] = item_id
	reward[ResultData.KEY_ITEM_ADDED] = add_inventory_item(item_id)
	return reward

func is_level_cleared() -> bool:
	for enemy_encounter in level_data.get("enemies", []):
		if not is_enemy_defeated(str(enemy_encounter.get("id", ""))):
			return false
	return true

func get_remaining_enemy_count() -> int:
	var remaining_count = 0
	for enemy_encounter in level_data.get("enemies", []):
		if not is_enemy_defeated(str(enemy_encounter.get("id", ""))):
			remaining_count += 1
	return remaining_count

func get_current_path_label() -> String:
	var path_type = str(level_data.get("path", FLOOR_PATH_NORMAL))
	if path_type == FLOOR_PATH_ELITE:
		return "Элитный"
	return "Обычный"

func get_visible_exits() -> Array:
	if not is_level_cleared():
		return []
	return level_data.get("exits", [])

func get_visible_chest() -> Dictionary:
	if not is_level_cleared():
		return {}

	var chest_data = level_data.get("chest", {})
	if chest_data.is_empty() or bool(chest_data.get("is_opened", false)):
		return {}
	return chest_data

func get_visible_fountain() -> Dictionary:
	var fountain_data = level_data.get("fountain", {})
	if fountain_data.is_empty() or bool(fountain_data.get("is_used", false)):
		return {}
	return fountain_data

func use_level_fountain() -> int:
	var fountain_data = get_visible_fountain()
	if fountain_data.is_empty():
		return 0

	var stats = get_player_battle_stats()
	var previous_hp = int(stats.get("hp", 0))
	var max_hp = int(stats.get("max_hp", 1))
	var heal_amount = ceili(max_hp * float(fountain_data.get("heal_percent", 0.25)))
	stats["hp"] = min(max_hp, previous_hp + heal_amount)
	set_player_battle_stats(stats)

	level_data["fountain"]["is_used"] = true
	save_current_game()
	return int(stats["hp"]) - previous_hp

func open_level_chest() -> Dictionary:
	var reward = ResultData.make_reward_result()

	var chest_data = get_visible_chest()
	if chest_data.is_empty():
		return reward

	var gold_amount = int(chest_data.get("gold", 0))
	var item_id = str(chest_data.get("item_id", ""))
	reward[ResultData.KEY_GOLD] = gold_amount
	reward[ResultData.KEY_ITEM_ID] = item_id

	if gold_amount > 0:
		add_gold(gold_amount)
	if not item_id.is_empty():
		reward[ResultData.KEY_ITEM_ADDED] = add_inventory_item(item_id)

	level_data["chest"]["is_opened"] = true
	save_current_game()
	reward[ResultData.KEY_OPENED] = true
	return reward

func get_visible_chest_gold() -> int:
	var chest_data = get_visible_chest()
	if chest_data.is_empty():
		return 0
	return int(chest_data.get("gold", 0))

func advance_to_next_floor(exit_id: String) -> bool:
	for exit_data in get_visible_exits():
		if exit_data.get("id", "") != exit_id:
			continue

		current_floor = int(exit_data.get("to_floor", current_floor + 1))
		current_enemy_id = ""
		defeated_enemies.clear()
		level_data = generate_level_data(current_floor, str(exit_data.get("path", FLOOR_PATH_NORMAL)))
		player_grid_pos = level_data.get("start_position", START_GRID_POS).duplicate()
		save_current_game()
		return true

	return false

func get_player_grid_position() -> Vector2i:
	return Vector2i(int(player_grid_pos.get("x", START_GRID_POS["x"])), int(player_grid_pos.get("y", START_GRID_POS["y"])))

func set_player_grid_position(grid_pos: Vector2i, should_save: bool = false) -> void:
	player_grid_pos = {"x": grid_pos.x, "y": grid_pos.y}
	if should_save:
		save_current_game()

func get_player_base_stats() -> Dictionary:
	var stats = get_default_player_stats()
	stats.merge(player_stats, true)
	return stats

func get_player_battle_stats() -> Dictionary:
	var stats = get_player_base_stats()
	var equipment_bonuses = get_equipment_stat_bonuses()
	stats["max_hp"] = int(stats.get("max_hp", 100)) + int(equipment_bonuses.get("max_hp", 0))
	stats["hp"] = min(int(stats.get("hp", 100)), int(stats["max_hp"]))
	stats["attack"] = int(stats.get("attack", 10)) + int(equipment_bonuses.get("attack", 0))
	stats["defense"] = int(stats.get("defense", 2)) + int(equipment_bonuses.get("defense", 0))
	return stats

func set_player_battle_stats(stats: Dictionary, should_save: bool = false) -> void:
	var equipment_bonuses = get_equipment_stat_bonuses()
	var base_max_hp = max(1, int(stats.get("max_hp", 100)) - int(equipment_bonuses.get("max_hp", 0)))
	player_stats = {
		"hp": min(base_max_hp, int(stats.get("hp", 100))),
		"max_hp": base_max_hp,
		"attack": int(stats.get("attack", 10)) - int(equipment_bonuses.get("attack", 0)),
		"defense": int(stats.get("defense", 2)) - int(equipment_bonuses.get("defense", 0)),
		"name": str(stats.get("name", "Герой")),
		"passives": stats.get("passives", []).duplicate(true)
	}
	if should_save:
		save_current_game()

func generate_level_data(floor_number: int = 1, path_type: String = FLOOR_PATH_NORMAL) -> Dictionary:
	return DungeonGenerator.generate_level_data(
		floor_number,
		path_type,
		Callable(self, "build_enemy_encounter_data")
	)

func build_enemy_encounter_data(enemy_id: String, enemy_type: String, enemy_pos: Dictionary, floor_number: int = 1, path_type: String = FLOOR_PATH_NORMAL) -> Dictionary:
	var stats = get_enemy_stats(enemy_type)
	var scaled_stats = scale_enemy_stats(stats, floor_number, path_type)
	return {
		"id": enemy_id,
		"type": scaled_stats["type"],
		"name": scaled_stats["name"],
		"x": enemy_pos["x"],
		"y": enemy_pos["y"],
		"hp": scaled_stats["hp"],
		"max_hp": scaled_stats["max_hp"],
		"attack": scaled_stats["attack"],
		"defense": scaled_stats["defense"],
		"features": scaled_stats["features"].duplicate(true)
	}

func scale_enemy_stats(stats: Dictionary, floor_number: int, path_type: String) -> Dictionary:
	var scaled_stats = stats.duplicate(true)
	var floor_bonus = max(0, floor_number - 1)
	var elite_bonus = 1 if path_type == FLOOR_PATH_ELITE else 0
	scaled_stats["hp"] = int(stats["hp"]) + floor_bonus * 6 + elite_bonus * 8
	scaled_stats["max_hp"] = int(stats["max_hp"]) + floor_bonus * 6 + elite_bonus * 8
	scaled_stats["attack"] = int(stats["attack"]) + floor_bonus * 2 + elite_bonus * 2
	scaled_stats["defense"] = int(stats["defense"]) + elite_bonus
	return scaled_stats

func get_grid_key(x: int, y: int) -> String:
	return "%d:%d" % [x, y]

func start_battle(enemy_id: String, return_grid_pos: Vector2i) -> void:
	current_enemy_id = enemy_id
	set_player_grid_position(return_grid_pos, true)

func mark_current_enemy_defeated() -> void:
	if current_enemy_id.is_empty():
		return
	defeated_enemies[current_enemy_id] = true
	save_current_game()

func is_enemy_defeated(enemy_id: String) -> bool:
	return defeated_enemies.has(enemy_id)

func clear_current_battle() -> void:
	current_enemy_id = ""

func handle_player_defeat() -> void:
	current_enemy_id = ""
	if active_save_slot != 0:
		delete_save_slot(active_save_slot)

extends Node

const SAVE_SLOT_COUNT = 3
const MAIN_LEVEL_PATH = "res://scenes/levels/main_level.tscn"
const ROOM_WIDTH = 16
const ROOM_HEIGHT = 16
const MIN_ROOM_COUNT = 4
const MAX_ROOM_COUNT = 5
const MIN_ROOM_SIZE = 3
const MAX_ROOM_SIZE = 5
const ENEMY_COUNT = 4
const MAX_FLOOR = 3
const START_GRID_POS = {"x": 8, "y": 8}
const DEFAULT_ENEMY_TYPE = "goblin"
const DUNGEON_ENEMY_TYPES = ["goblin", "skeleton", "bat", "slime"]
const FLOOR_PATH_NORMAL = "normal"
const FLOOR_PATH_ELITE = "elite"
const MAX_INVENTORY_SIZE = 16
const LOOT_TABLES = {
	"goblin": {
		"gold_min": 4,
		"gold_max": 8,
		"item_chance": 0.20,
		"items": ["wooden_sword"]
	},
	"skeleton": {
		"gold_min": 6,
		"gold_max": 10,
		"item_chance": 0.25,
		"items": ["leather_chestpiece"]
	},
	"bat": {
		"gold_min": 3,
		"gold_max": 7,
		"item_chance": 0.15,
		"items": ["wooden_sword"]
	},
	"slime": {
		"gold_min": 5,
		"gold_max": 9,
		"item_chance": 0.20,
		"items": ["leather_chestpiece"]
	}
}
const CHARACTER_DEFINITIONS = {
	"base": {
		"name": "Player",
		"hp": 100,
		"max_hp": 100,
		"attack": 10,
		"defense": 2,
		"passives": []
	},
	"vampire": {
		"name": "Vampire",
		"hp": 90,
		"max_hp": 90,
		"attack": 11,
		"defense": 1,
		"passives": [
			{
				"id": "vampirism",
				"name": "Vampirism",
				"heal_percent": 0.05
			}
		]
	}
}
const ENEMY_DEFINITIONS = {
	"goblin": {
		"name": "Goblin",
		"hp": 28,
		"max_hp": 28,
		"attack": 6,
		"defense": 1,
		"features": []
	},
	"skeleton": {
		"name": "Skeleton",
		"hp": 24,
		"max_hp": 24,
		"attack": 10,
		"defense": 0,
		"features": [
			{
				"id": "armor_pierce",
				"name": "Armor Pierce",
				"pierce": 2
			}
		]
	},
	"bat": {
		"name": "Bat",
		"hp": 18,
		"max_hp": 18,
		"attack": 5,
		"defense": 0,
		"features": [
			{
				"id": "evasion",
				"name": "Evasion",
				"chance": 0.25
			}
		]
	},
	"slime": {
		"name": "Slime",
		"hp": 42,
		"max_hp": 42,
		"attack": 4,
		"defense": 2,
		"features": [
			{
				"id": "regeneration",
				"name": "Regeneration",
				"heal": 2
			}
		]
	}
}
const ITEM_DEFINITIONS = {
	"wooden_sword": {
		"name": "Деревянный меч",
		"type": "weapon",
		"slot": "weapon",
		"bonuses": {
			"attack": 2
		}
	},
	"leather_chestpiece": {
		"name": "Кожаный нагрудник",
		"type": "armor",
		"slot": "armor",
		"bonuses": {
			"defense": 1
		}
	}
}
const DEFAULT_EQUIPMENT = {
	"weapon": "",
	"armor": "",
	"accessory": ""
}

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

func start_new_game(character_id: String) -> void:
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
	active_save_slot = get_first_empty_save_slot()
	if active_save_slot != 0:
		save_current_game()

func load_game(slot: int) -> bool:
	var save_data = load_save_slot(slot)
	if save_data.is_empty():
		return false

	active_save_slot = slot
	selected_character_id = save_data.get("selected_character_id", "base")
	current_floor = int(save_data.get("current_floor", 1))
	level_data = save_data.get("level_data", {})
	var regenerated_level = false
	if not is_valid_level_data(level_data):
		level_data = generate_level_data(current_floor, FLOOR_PATH_NORMAL)
		regenerated_level = true
	else:
		normalize_level_data()
	current_floor = int(level_data.get("floor_number", current_floor))
	player_grid_pos = save_data.get("player_grid_pos", level_data.get("start_position", START_GRID_POS).duplicate())
	if regenerated_level or not is_grid_position_walkable(level_data, player_grid_pos):
		player_grid_pos = level_data.get("start_position", START_GRID_POS).duplicate()
	player_stats = save_data.get("player_stats", get_default_player_stats())
	gold = int(save_data.get("gold", 0))
	inventory = normalize_inventory(save_data.get("inventory", []))
	equipment = normalize_equipment(save_data.get("equipment", {}))
	current_enemy_id = ""
	defeated_enemies = save_data.get("defeated_enemies", {})
	return true

func save_current_game() -> void:
	if active_save_slot == 0:
		return

	var save_data = {
		"version": "0.1.0",
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
	var save_dir = DirAccess.open("user://")
	if save_dir != null:
		save_dir.remove(get_save_file_name(slot))
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
	return "user://%s" % get_save_file_name(slot)

func get_save_file_name(slot: int) -> String:
	return "save_slot_%d.json" % slot

func ensure_level_data() -> void:
	if not is_valid_level_data(level_data):
		level_data = generate_level_data(current_floor, FLOOR_PATH_NORMAL)
		player_grid_pos = level_data.get("start_position", START_GRID_POS).duplicate()
	else:
		normalize_level_data()

func is_valid_level_data(data: Dictionary) -> bool:
	return data.has("floor_tiles") and data.has("walls") and data.has("rooms") and data.has("enemies")

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
	var enemy_data = get_enemy_data(current_enemy_id)
	if enemy_data.is_empty():
		return get_enemy_stats(DEFAULT_ENEMY_TYPE)

	var stats = get_enemy_stats(str(enemy_data.get("type", DEFAULT_ENEMY_TYPE)))
	stats.merge(enemy_data, true)
	stats.erase("id")
	stats.erase("x")
	stats.erase("y")
	return {
		"type": str(stats.get("type", DEFAULT_ENEMY_TYPE)),
		"name": str(stats.get("name", "Goblin")),
		"hp": int(stats.get("hp", stats.get("max_hp", 30))),
		"max_hp": int(stats.get("max_hp", 30)),
		"attack": int(stats.get("attack", 5)),
		"defense": int(stats.get("defense", 0)),
		"features": stats.get("features", []).duplicate(true)
	}

func get_enemy_data(enemy_id: String) -> Dictionary:
	for enemy_data in level_data.get("enemies", []):
		if enemy_data.get("id", "") == enemy_id:
			return enemy_data
	return {}

func normalize_level_data() -> void:
	level_data["floor_number"] = int(level_data.get("floor_number", current_floor))
	level_data["path"] = str(level_data.get("path", FLOOR_PATH_NORMAL))

	var normalized_enemies = []
	for enemy_data in level_data.get("enemies", []):
		normalized_enemies.append(normalize_enemy_data(enemy_data))
	level_data["enemies"] = normalized_enemies

	if not level_data.has("exits"):
		level_data["exits"] = generate_exit_data(level_data.get("rooms", []), int(level_data["floor_number"]), str(level_data["path"]))
	if not level_data.has("chest"):
		level_data["chest"] = generate_chest_data(level_data.get("exits", []), int(level_data["floor_number"]), str(level_data["path"]), level_data.get("rooms", []))

func normalize_enemy_data(enemy_data: Dictionary) -> Dictionary:
	var enemy_type = str(enemy_data.get("type", DEFAULT_ENEMY_TYPE))
	var stats = scale_enemy_stats(
		get_enemy_stats(enemy_type),
		int(level_data.get("floor_number", current_floor)),
		str(level_data.get("path", FLOOR_PATH_NORMAL))
	)
	return {
		"id": str(enemy_data.get("id", "")),
		"type": stats["type"],
		"name": stats["name"],
		"x": int(enemy_data.get("x", START_GRID_POS["x"])),
		"y": int(enemy_data.get("y", START_GRID_POS["y"])),
		"hp": min(int(enemy_data.get("hp", stats["hp"])), int(stats["max_hp"])),
		"max_hp": stats["max_hp"],
		"attack": stats["attack"],
		"defense": stats["defense"],
		"features": stats["features"].duplicate(true)
	}

func normalize_inventory(saved_inventory: Variant) -> Array:
	var normalized = []
	if typeof(saved_inventory) != TYPE_ARRAY:
		return normalized

	for item_id in saved_inventory:
		var item_id_string = str(item_id)
		if ITEM_DEFINITIONS.has(item_id_string) and normalized.size() < MAX_INVENTORY_SIZE:
			normalized.append(item_id_string)
	return normalized

func normalize_equipment(saved_equipment: Variant) -> Dictionary:
	var normalized = DEFAULT_EQUIPMENT.duplicate()
	if typeof(saved_equipment) != TYPE_DICTIONARY:
		return normalized

	for slot in normalized.keys():
		var item_id = str(saved_equipment.get(slot, ""))
		if item_id.is_empty():
			continue
		var item = get_item_definition(item_id)
		if not item.is_empty() and item.get("slot", "") == slot:
			normalized[slot] = item_id
	return normalized

func get_item_definition(item_id: String) -> Dictionary:
	return ITEM_DEFINITIONS.get(item_id, {})

func get_item_name(item_id: String) -> String:
	var item = get_item_definition(item_id)
	if item.is_empty():
		return "Неизвестный предмет"
	return str(item.get("name", item_id))

func get_item_stat_bonuses(item_id: String) -> Dictionary:
	var item = get_item_definition(item_id)
	var bonuses = item.get("bonuses", {})
	if typeof(bonuses) != TYPE_DICTIONARY:
		return {}
	return bonuses

func get_equipment_stat_bonuses() -> Dictionary:
	var total_bonuses = {
		"max_hp": 0,
		"attack": 0,
		"defense": 0
	}

	for item_id in equipment.values():
		var item_id_string = str(item_id)
		if item_id_string.is_empty():
			continue

		var item_bonuses = get_item_stat_bonuses(item_id_string)
		total_bonuses["max_hp"] += int(item_bonuses.get("max_hp", 0))
		total_bonuses["attack"] += int(item_bonuses.get("attack", 0))
		total_bonuses["defense"] += int(item_bonuses.get("defense", 0))

	return total_bonuses

func get_item_bonus_text(item_id: String) -> String:
	var bonuses = get_item_stat_bonuses(item_id)
	var parts = []
	var attack_bonus = int(bonuses.get("attack", 0))
	var defense_bonus = int(bonuses.get("defense", 0))
	var max_hp_bonus = int(bonuses.get("max_hp", 0))

	if attack_bonus != 0:
		parts.append("+%d атака" % attack_bonus)
	if defense_bonus != 0:
		parts.append("+%d защита" % defense_bonus)
	if max_hp_bonus != 0:
		parts.append("+%d HP" % max_hp_bonus)

	return ", ".join(parts)

func add_inventory_item(item_id: String, should_save: bool = false) -> bool:
	if not ITEM_DEFINITIONS.has(item_id) or inventory.size() >= MAX_INVENTORY_SIZE:
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

func discard_inventory_item(inventory_index: int, should_save: bool = true) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false

	inventory.remove_at(inventory_index)
	if should_save:
		save_current_game()
	return true

func grant_current_enemy_reward() -> Dictionary:
	var enemy_data = get_enemy_data(current_enemy_id)
	var enemy_type = str(enemy_data.get("type", DEFAULT_ENEMY_TYPE))
	var path_type = str(level_data.get("path", FLOOR_PATH_NORMAL))
	var loot_table = LOOT_TABLES.get(enemy_type, LOOT_TABLES[DEFAULT_ENEMY_TYPE])
	var gold_amount = randi_range(int(loot_table["gold_min"]), int(loot_table["gold_max"]))
	if path_type == FLOOR_PATH_ELITE:
		gold_amount = ceili(gold_amount * 1.5)
	add_gold(gold_amount)

	var reward = {
		"gold": gold_amount,
		"item_id": "",
		"item_added": false
	}

	var item_chance = float(loot_table.get("item_chance", 0.0))
	if path_type == FLOOR_PATH_ELITE:
		item_chance += 0.15
	if randf() > item_chance:
		return reward

	var item_id = get_random_loot_item_id(loot_table.get("items", []))
	if item_id.is_empty():
		return reward

	reward["item_id"] = item_id
	reward["item_added"] = add_inventory_item(item_id)
	return reward

func get_random_loot_item_id(items: Array) -> String:
	if items.is_empty():
		return ""
	return str(items[randi_range(0, items.size() - 1)])

func is_level_cleared() -> bool:
	for enemy_data in level_data.get("enemies", []):
		if not is_enemy_defeated(str(enemy_data.get("id", ""))):
			return false
	return true

func get_remaining_enemy_count() -> int:
	var remaining_count = 0
	for enemy_data in level_data.get("enemies", []):
		if not is_enemy_defeated(str(enemy_data.get("id", ""))):
			remaining_count += 1
	return remaining_count

func get_current_path_label() -> String:
	var path_type = str(level_data.get("path", FLOOR_PATH_NORMAL))
	if path_type == FLOOR_PATH_ELITE:
		return "Elite"
	return "Normal"

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

func open_level_chest() -> String:
	var chest_data = get_visible_chest()
	if chest_data.is_empty():
		return ""

	var gold_amount = int(chest_data.get("gold", 0))
	var item_id = str(chest_data.get("item_id", ""))
	if item_id.is_empty():
		return ""

	if gold_amount > 0:
		add_gold(gold_amount)
	if not add_inventory_item(item_id):
		return ""

	level_data["chest"]["is_opened"] = true
	save_current_game()
	return item_id

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
		"name": str(stats.get("name", "Player")),
		"passives": stats.get("passives", []).duplicate(true)
	}
	if should_save:
		save_current_game()

func generate_level_data(floor_number: int = 1, path_type: String = FLOOR_PATH_NORMAL) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var level_seed = rng.randi()
	rng.seed = level_seed

	var rooms = generate_rooms(rng)
	var floor_positions = {}

	for room in rooms:
		carve_room(room, floor_positions)

	for index in range(rooms.size() - 1):
		connect_rooms(rooms[index], rooms[index + 1], floor_positions, rng)

	var floor_tiles = positions_to_array(floor_positions)
	var walls = build_wall_tiles(floor_positions)
	var start_position = get_room_center(rooms[0])
	var exits = generate_exit_data(rooms, floor_number, path_type)
	var chest = generate_chest_data(exits, floor_number, path_type, rooms)
	var enemies = generate_enemy_data(rooms, floor_positions, start_position, exits, rng, floor_number, path_type)

	return {
		"seed": level_seed,
		"floor_number": floor_number,
		"path": path_type,
		"width": ROOM_WIDTH,
		"height": ROOM_HEIGHT,
		"start_position": start_position,
		"rooms": rooms,
		"floor_tiles": floor_tiles,
		"walls": walls,
		"enemies": enemies,
		"exits": exits,
		"chest": chest
	}

func generate_rooms(rng: RandomNumberGenerator) -> Array:
	var rooms = []
	var target_room_count = rng.randi_range(MIN_ROOM_COUNT, MAX_ROOM_COUNT)
	var attempts = 0

	while rooms.size() < target_room_count and attempts < 120:
		attempts += 1
		var width = rng.randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var height = rng.randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var x = rng.randi_range(1, ROOM_WIDTH - width - 1)
		var y = rng.randi_range(1, ROOM_HEIGHT - height - 1)
		var room = {"x": x, "y": y, "width": width, "height": height}

		if not does_room_overlap(room, rooms):
			rooms.append(room)

	if rooms.is_empty():
		rooms.append({"x": 5, "y": 5, "width": 5, "height": 5})

	return rooms

func does_room_overlap(room: Dictionary, rooms: Array) -> bool:
	for other in rooms:
		if room["x"] - 1 < other["x"] + other["width"] + 1 \
				and room["x"] + room["width"] + 1 > other["x"] - 1 \
				and room["y"] - 1 < other["y"] + other["height"] + 1 \
				and room["y"] + room["height"] + 1 > other["y"] - 1:
			return true
	return false

func carve_room(room: Dictionary, floor_positions: Dictionary) -> void:
	for y in range(room["y"], room["y"] + room["height"]):
		for x in range(room["x"], room["x"] + room["width"]):
			floor_positions[get_grid_key(x, y)] = {"x": x, "y": y}

func connect_rooms(from_room: Dictionary, to_room: Dictionary, floor_positions: Dictionary, rng: RandomNumberGenerator) -> void:
	var from_center = get_room_center(from_room)
	var to_center = get_room_center(to_room)

	if rng.randi_range(0, 1) == 0:
		carve_horizontal_corridor(from_center["x"], to_center["x"], from_center["y"], floor_positions)
		carve_vertical_corridor(from_center["y"], to_center["y"], to_center["x"], floor_positions)
	else:
		carve_vertical_corridor(from_center["y"], to_center["y"], from_center["x"], floor_positions)
		carve_horizontal_corridor(from_center["x"], to_center["x"], to_center["y"], floor_positions)

func carve_horizontal_corridor(from_x: int, to_x: int, y: int, floor_positions: Dictionary) -> void:
	for x in range(min(from_x, to_x), max(from_x, to_x) + 1):
		floor_positions[get_grid_key(x, y)] = {"x": x, "y": y}

func carve_vertical_corridor(from_y: int, to_y: int, x: int, floor_positions: Dictionary) -> void:
	for y in range(min(from_y, to_y), max(from_y, to_y) + 1):
		floor_positions[get_grid_key(x, y)] = {"x": x, "y": y}

func get_room_center(room: Dictionary) -> Dictionary:
	return {
		"x": int(room["x"] + floori(room["width"] / 2.0)),
		"y": int(room["y"] + floori(room["height"] / 2.0))
	}

func positions_to_array(positions: Dictionary) -> Array:
	var result = []
	for position in positions.values():
		result.append(position)
	return result

func build_wall_tiles(floor_positions: Dictionary) -> Array:
	var walls = []
	for y in range(ROOM_HEIGHT):
		for x in range(ROOM_WIDTH):
			if not floor_positions.has(get_grid_key(x, y)):
				walls.append({"x": x, "y": y})
	return walls

func generate_exit_data(rooms: Array, floor_number: int, path_type: String) -> Array:
	if floor_number >= MAX_FLOOR or rooms.is_empty():
		return []

	var exit_room = rooms[rooms.size() - 1]
	var exit_center = get_room_center(exit_room)
	if floor_number == 2:
		return [
			build_exit_data("normal_exit", "Обычный путь", FLOOR_PATH_NORMAL, floor_number + 1, exit_center),
			build_exit_data("elite_exit", "Сложный путь", FLOOR_PATH_ELITE, floor_number + 1, get_room_position_with_offset(exit_room, Vector2i(1, 0)))
		]

	return [
		build_exit_data("floor_exit", "Спуск", path_type, floor_number + 1, exit_center)
	]

func build_exit_data(exit_id: String, label: String, path_type: String, to_floor: int, grid_position: Dictionary) -> Dictionary:
	return {
		"id": exit_id,
		"label": label,
		"path": path_type,
		"to_floor": to_floor,
		"x": grid_position["x"],
		"y": grid_position["y"]
	}

func generate_chest_data(exits: Array, floor_number: int, path_type: String, rooms: Array = []) -> Dictionary:
	if exits.is_empty() and (floor_number < MAX_FLOOR or rooms.is_empty()):
		return {}

	var chest_position = {}
	if exits.is_empty():
		chest_position = get_room_center(rooms[rooms.size() - 1])
	else:
		var first_exit = exits[0]
		chest_position = get_nearby_walkable_position({"x": first_exit["x"], "y": first_exit["y"]})
	return {
		"id": "floor_%d_chest" % floor_number,
		"x": chest_position["x"],
		"y": chest_position["y"],
		"item_id": get_floor_chest_reward(floor_number, path_type),
		"gold": get_floor_chest_gold(floor_number, path_type),
		"is_opened": false
	}

func get_floor_chest_reward(floor_number: int, path_type: String) -> String:
	if path_type == FLOOR_PATH_ELITE:
		return "leather_chestpiece"
	if floor_number >= 2:
		return "leather_chestpiece"
	return "wooden_sword"

func get_floor_chest_gold(floor_number: int, path_type: String) -> int:
	var min_gold = 15 + (floor_number - 1) * 5
	var max_gold = 25 + (floor_number - 1) * 5
	if path_type == FLOOR_PATH_ELITE:
		min_gold += 10
		max_gold += 15
	return randi_range(min_gold, max_gold)

func get_room_position_with_offset(room: Dictionary, offset: Vector2i) -> Dictionary:
	var center = get_room_center(room)
	return {
		"x": clampi(center["x"] + offset.x, room["x"], room["x"] + room["width"] - 1),
		"y": clampi(center["y"] + offset.y, room["y"], room["y"] + room["height"] - 1)
	}

func get_nearby_walkable_position(position_data: Dictionary) -> Dictionary:
	return {
		"x": clampi(int(position_data["x"]) - 1, 0, ROOM_WIDTH - 1),
		"y": int(position_data["y"])
	}

func generate_enemy_data(
	rooms: Array,
	floor_positions: Dictionary,
	start_position: Dictionary,
	exits: Array,
	rng: RandomNumberGenerator,
	floor_number: int,
	path_type: String
) -> Array:
	var enemies = []
	var occupied = {
		get_grid_key(start_position["x"], start_position["y"]): true
	}
	for exit_data in exits:
		occupied[get_grid_key(exit_data["x"], exit_data["y"])] = true
	var chest_data = generate_chest_data(exits, floor_number, path_type, rooms)
	if not chest_data.is_empty():
		occupied[get_grid_key(chest_data["x"], chest_data["y"])] = true

	var enemy_rooms = rooms.slice(1)
	if not exits.is_empty() and rooms.size() > 2:
		enemy_rooms = rooms.slice(1, rooms.size() - 1)
	var enemy_count = get_floor_enemy_count(floor_number, path_type)

	for index in range(enemy_count):
		var enemy_pos = get_random_floor_position(rng, floor_positions, occupied, start_position, enemy_rooms)
		occupied[get_grid_key(enemy_pos["x"], enemy_pos["y"])] = true
		var enemy_type = DUNGEON_ENEMY_TYPES[index % DUNGEON_ENEMY_TYPES.size()]
		enemies.append(build_enemy_data("level_enemy_%02d" % [index + 1], enemy_type, enemy_pos, floor_number, path_type))

	return enemies

func get_floor_enemy_count(floor_number: int, path_type: String) -> int:
	var count = ENEMY_COUNT + max(0, floor_number - 1)
	if path_type == FLOOR_PATH_ELITE:
		count += 1
	return count

func build_enemy_data(enemy_id: String, enemy_type: String, enemy_pos: Dictionary, floor_number: int = 1, path_type: String = FLOOR_PATH_NORMAL) -> Dictionary:
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

func get_random_floor_position(
	rng: RandomNumberGenerator,
	floor_positions: Dictionary,
	occupied: Dictionary,
	start_position: Dictionary,
	preferred_rooms: Array
) -> Dictionary:
	for _attempt in range(200):
		var candidate = get_random_room_position(rng, preferred_rooms)
		if is_valid_spawn_position(candidate, occupied, start_position):
			return candidate

	var floor_tiles = floor_positions.values()
	for _attempt in range(200):
		var candidate = floor_tiles[rng.randi_range(0, floor_tiles.size() - 1)]
		if is_valid_spawn_position(candidate, occupied, start_position):
			return candidate

	return start_position

func get_random_room_position(rng: RandomNumberGenerator, rooms: Array) -> Dictionary:
	if rooms.is_empty():
		return START_GRID_POS

	var room = rooms[rng.randi_range(0, rooms.size() - 1)]
	return {
		"x": rng.randi_range(room["x"], room["x"] + room["width"] - 1),
		"y": rng.randi_range(room["y"], room["y"] + room["height"] - 1)
	}

func is_valid_spawn_position(candidate: Dictionary, occupied: Dictionary, start_position: Dictionary) -> bool:
	var key = get_grid_key(candidate["x"], candidate["y"])
	var distance = abs(candidate["x"] - start_position["x"]) + abs(candidate["y"] - start_position["y"])
	return not occupied.has(key) and distance >= 4

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

extends RefCounted

const KEY_VERSION = "version"
const KEY_SELECTED_CHARACTER_ID = "selected_character_id"
const KEY_CURRENT_FLOOR = "current_floor"
const KEY_LEVEL_DATA = "level_data"
const KEY_PLAYER_GRID_POS = "player_grid_pos"
const KEY_PLAYER_STATS = "player_stats"
const KEY_GOLD = "gold"
const KEY_INVENTORY = "inventory"
const KEY_EQUIPMENT = "equipment"
const KEY_DEFEATED_ENEMIES = "defeated_enemies"
const KEY_UPDATED_AT = "updated_at"

static func make_save_data(
	version: String,
	character_id: String,
	current_floor: int,
	level_data: Dictionary,
	player_grid_pos: Dictionary,
	player_stats: Dictionary,
	gold: int,
	inventory: Array,
	equipment: Dictionary,
	defeated_enemies: Dictionary
) -> Dictionary:
	return {
		KEY_VERSION: version,
		KEY_SELECTED_CHARACTER_ID: character_id,
		KEY_CURRENT_FLOOR: current_floor,
		KEY_LEVEL_DATA: level_data,
		KEY_PLAYER_GRID_POS: player_grid_pos,
		KEY_PLAYER_STATS: player_stats,
		KEY_GOLD: gold,
		KEY_INVENTORY: inventory,
		KEY_EQUIPMENT: equipment,
		KEY_DEFEATED_ENEMIES: defeated_enemies,
		KEY_UPDATED_AT: Time.get_datetime_string_from_system(false, true)
	}

static func make_run_summary(
	character_name: String,
	path_label: String,
	current_floor: int,
	max_floor: int,
	gold: int,
	defeated_count: int,
	equipment: Dictionary,
	get_item_name: Callable
) -> Dictionary:
	var equipped_items = []
	for slot in equipment.keys():
		var item_id = str(equipment.get(slot, ""))
		if item_id.is_empty():
			continue
		equipped_items.append("%s: %s" % [get_equipment_slot_label(str(slot)), get_item_name.call(item_id)])

	return {
		"character": character_name,
		"path": path_label,
		"floor": current_floor,
		"max_floor": max_floor,
		"gold": gold,
		"defeated_enemies": defeated_count,
		"equipment": equipped_items
	}

static func get_equipment_slot_label(slot: String) -> String:
	if slot == "weapon":
		return "Оружие"
	if slot == "armor":
		return "Броня"
	if slot == "accessory":
		return "Аксессуар"
	return slot

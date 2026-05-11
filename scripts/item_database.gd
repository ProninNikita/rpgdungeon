extends RefCounted

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
		"items": ["leather_chestpiece", "iron_sword"]
	},
	"bat": {
		"gold_min": 3,
		"gold_max": 7,
		"item_chance": 0.15,
		"items": ["wooden_sword", "vitality_ring"]
	},
	"slime": {
		"gold_min": 5,
		"gold_max": 9,
		"item_chance": 0.20,
		"items": ["leather_chestpiece", "chainmail"]
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
	},
	"iron_sword": {
		"name": "Железный меч",
		"type": "weapon",
		"slot": "weapon",
		"bonuses": {
			"attack": 4
		}
	},
	"chainmail": {
		"name": "Кольчуга",
		"type": "armor",
		"slot": "armor",
		"bonuses": {
			"defense": 2
		}
	},
	"vitality_ring": {
		"name": "Кольцо живучести",
		"type": "accessory",
		"slot": "accessory",
		"bonuses": {
			"max_hp": 15
		}
	}
}
const DEFAULT_EQUIPMENT = {
	"weapon": "",
	"armor": "",
	"accessory": ""
}

static func normalize_inventory(saved_inventory: Variant) -> Array:
	var normalized = []
	if typeof(saved_inventory) != TYPE_ARRAY:
		return normalized

	for item_id in saved_inventory:
		var item_id_string = str(item_id)
		if ITEM_DEFINITIONS.has(item_id_string) and normalized.size() < MAX_INVENTORY_SIZE:
			normalized.append(item_id_string)
	return normalized

static func normalize_equipment(saved_equipment: Variant) -> Dictionary:
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

static func get_item_definition(item_id: String) -> Dictionary:
	return ITEM_DEFINITIONS.get(item_id, {})

static func get_item_name(item_id: String) -> String:
	var item = get_item_definition(item_id)
	if item.is_empty():
		return "Неизвестный предмет"
	return str(item.get("name", item_id))

static func get_item_stat_bonuses(item_id: String) -> Dictionary:
	var item = get_item_definition(item_id)
	var bonuses = item.get("bonuses", {})
	if typeof(bonuses) != TYPE_DICTIONARY:
		return {}
	return bonuses

static func get_equipment_stat_bonuses(equipment: Dictionary) -> Dictionary:
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

static func get_item_bonus_text(item_id: String) -> String:
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

static func can_add_inventory_item(inventory: Array, item_id: String) -> bool:
	return ITEM_DEFINITIONS.has(item_id) and inventory.size() < MAX_INVENTORY_SIZE

static func get_loot_table(enemy_type: String, default_enemy_type: String) -> Dictionary:
	return LOOT_TABLES.get(enemy_type, LOOT_TABLES[default_enemy_type])

static func get_random_loot_item_id(items: Array) -> String:
	if items.is_empty():
		return ""
	return str(items[randi_range(0, items.size() - 1)])

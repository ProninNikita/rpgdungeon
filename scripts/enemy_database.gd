extends RefCounted

const DEFAULT_ENEMY_TYPE = "goblin"
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

static func get_enemy_stats(enemy_type: String) -> Dictionary:
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

static func scale_enemy_stats(stats: Dictionary, floor_number: int, path_type: String, elite_path: String) -> Dictionary:
	var scaled_stats = stats.duplicate(true)
	var floor_bonus = max(0, floor_number - 1)
	var elite_bonus = 1 if path_type == elite_path else 0
	scaled_stats["hp"] = int(stats["hp"]) + floor_bonus * 6 + elite_bonus * 8
	scaled_stats["max_hp"] = int(stats["max_hp"]) + floor_bonus * 6 + elite_bonus * 8
	scaled_stats["attack"] = int(stats["attack"]) + floor_bonus * 2 + elite_bonus * 2
	scaled_stats["defense"] = int(stats["defense"]) + elite_bonus
	return scaled_stats

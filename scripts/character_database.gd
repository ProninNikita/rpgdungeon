extends RefCounted

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

static func get_character_stats(character_id: String) -> Dictionary:
	var definition = CHARACTER_DEFINITIONS.get(character_id, CHARACTER_DEFINITIONS["base"])
	return {
		"hp": int(definition["hp"]),
		"max_hp": int(definition["max_hp"]),
		"attack": int(definition["attack"]),
		"defense": int(definition["defense"]),
		"name": str(definition["name"]),
		"passives": definition.get("passives", []).duplicate(true)
	}

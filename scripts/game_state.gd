extends Node

const SAVE_SLOT_COUNT = 3
const MAIN_LEVEL_PATH = "res://scenes/levels/main_level.tscn"
const ROOM_WIDTH = 16
const ROOM_HEIGHT = 16
const WALL_COUNT = 20
const ENEMY_COUNT = 3
const START_GRID_POS = {"x": 8, "y": 8}
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

var active_save_slot: int = 0
var selected_character_id: String = "base"
var level_data: Dictionary = {}
var player_grid_pos: Dictionary = START_GRID_POS.duplicate()
var player_stats: Dictionary = get_default_player_stats()
var current_enemy_id: String = ""
var defeated_enemies: Dictionary = {}

func start_new_game(character_id: String) -> void:
	selected_character_id = character_id
	current_enemy_id = ""
	defeated_enemies.clear()
	level_data = generate_level_data()
	player_grid_pos = START_GRID_POS.duplicate()
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
	level_data = save_data.get("level_data", {})
	if level_data.is_empty():
		level_data = generate_level_data()
	player_grid_pos = save_data.get("player_grid_pos", START_GRID_POS.duplicate())
	player_stats = save_data.get("player_stats", get_default_player_stats())
	current_enemy_id = ""
	defeated_enemies = save_data.get("defeated_enemies", {})
	return true

func save_current_game() -> void:
	if active_save_slot == 0:
		return
	
	var save_data = {
		"version": "0.1.0",
		"selected_character_id": selected_character_id,
		"level_data": level_data,
		"player_grid_pos": player_grid_pos,
		"player_stats": player_stats,
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
	if level_data.is_empty():
		level_data = generate_level_data()

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

func get_player_grid_position() -> Vector2i:
	return Vector2i(int(player_grid_pos.get("x", START_GRID_POS["x"])), int(player_grid_pos.get("y", START_GRID_POS["y"])))

func set_player_grid_position(grid_pos: Vector2i, should_save: bool = false) -> void:
	player_grid_pos = {"x": grid_pos.x, "y": grid_pos.y}
	if should_save:
		save_current_game()

func get_player_battle_stats() -> Dictionary:
	var stats = get_default_player_stats()
	stats.merge(player_stats, true)
	return stats

func set_player_battle_stats(stats: Dictionary, should_save: bool = false) -> void:
	player_stats = {
		"hp": int(stats.get("hp", 100)),
		"max_hp": int(stats.get("max_hp", 100)),
		"attack": int(stats.get("attack", 10)),
		"defense": int(stats.get("defense", 2)),
		"name": str(stats.get("name", "Player")),
		"passives": stats.get("passives", []).duplicate(true)
	}
	if should_save:
		save_current_game()

func generate_level_data() -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var level_seed = rng.randi()
	rng.seed = level_seed
	
	var occupied = {}
	for y in range(START_GRID_POS["y"] - 1, START_GRID_POS["y"] + 2):
		for x in range(START_GRID_POS["x"] - 1, START_GRID_POS["x"] + 2):
			occupied[get_grid_key(x, y)] = true
	
	var walls = []
	while walls.size() < WALL_COUNT:
		var wall_pos = get_random_free_position(rng, occupied, 1)
		walls.append(wall_pos)
		occupied[get_grid_key(wall_pos["x"], wall_pos["y"])] = true
	
	var enemies = []
	for index in range(ENEMY_COUNT):
		var enemy_pos = get_random_free_position(rng, occupied, 3)
		occupied[get_grid_key(enemy_pos["x"], enemy_pos["y"])] = true
		enemies.append({
			"id": "level_enemy_%02d" % [index + 1],
			"name": "Goblin",
			"x": enemy_pos["x"],
			"y": enemy_pos["y"]
		})
	
	return {
		"seed": level_seed,
		"width": ROOM_WIDTH,
		"height": ROOM_HEIGHT,
		"start_position": START_GRID_POS,
		"walls": walls,
		"enemies": enemies
	}

func get_random_free_position(rng: RandomNumberGenerator, occupied: Dictionary, min_distance_from_start: int) -> Dictionary:
	for _attempt in range(500):
		var x = rng.randi_range(1, ROOM_WIDTH - 2)
		var y = rng.randi_range(1, ROOM_HEIGHT - 2)
		var key = get_grid_key(x, y)
		var distance = abs(x - START_GRID_POS["x"]) + abs(y - START_GRID_POS["y"])
		if not occupied.has(key) and distance >= min_distance_from_start:
			return {"x": x, "y": y}
	
	return {"x": START_GRID_POS["x"], "y": START_GRID_POS["y"]}

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

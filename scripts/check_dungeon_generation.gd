extends SceneTree

const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")

const RUN_COUNT = 100

var failures: Array = []

func _init() -> void:
	for run_index in range(RUN_COUNT):
		validate_generated_level(run_index, 1, DungeonGenerator.FLOOR_PATH_NORMAL)
		validate_generated_level(run_index, 2, DungeonGenerator.FLOOR_PATH_NORMAL)
		validate_generated_level(run_index, 3, DungeonGenerator.FLOOR_PATH_NORMAL)
		validate_generated_level(run_index, 3, DungeonGenerator.FLOOR_PATH_ELITE)

	if failures.is_empty():
		print("Dungeon generation check passed for %d generated levels." % (RUN_COUNT * 4))
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func validate_generated_level(run_index: int, floor_number: int, path_type: String) -> void:
	var level_data = DungeonGenerator.generate_level_data(
		floor_number,
		path_type,
		Callable(self, "build_enemy_encounter_data")
	)
	var floor_positions = get_floor_position_lookup(level_data.get("floor_tiles", []))
	var occupied = {}
	var context = "run %d floor %d path %s" % [run_index, floor_number, path_type]

	var start_position = level_data.get("start_position", {})
	assert_walkable(context, "start", start_position, floor_positions)
	occupied[get_grid_key_from_data(start_position)] = "start"

	var chest_data = level_data.get("chest", {})
	if not chest_data.is_empty():
		assert_walkable(context, "chest", chest_data, floor_positions)
		assert_unoccupied(context, "chest", chest_data, occupied)

	var fountain_data = level_data.get("fountain", {})
	if not fountain_data.is_empty():
		assert_walkable(context, "fountain", fountain_data, floor_positions)
		assert_unoccupied(context, "fountain", fountain_data, occupied)

	var special_rooms = level_data.get("special_rooms", [])
	assert_special_rooms(context, special_rooms)
	for special_room in special_rooms:
		assert_walkable(context, "special room %s" % str(special_room.get("type", "")), special_room, floor_positions)
		assert_unoccupied(context, "special room %s" % str(special_room.get("type", "")), special_room, occupied)

	for exit_data in level_data.get("exits", []):
		assert_walkable(context, "exit", exit_data, floor_positions)
		assert_unoccupied(context, "exit", exit_data, occupied)

	var enemies = level_data.get("enemies", [])
	if enemies.is_empty():
		failures.append("%s: generated no enemies" % context)

	for enemy_encounter in enemies:
		assert_walkable(context, "enemy %s" % str(enemy_encounter.get("id", "")), enemy_encounter, floor_positions)
		assert_unoccupied(context, "enemy %s" % str(enemy_encounter.get("id", "")), enemy_encounter, occupied)

func build_enemy_encounter_data(enemy_id: String, enemy_type: String, enemy_pos: Dictionary, _floor_number: int, _path_type: String) -> Dictionary:
	return {
		"id": enemy_id,
		"type": enemy_type,
		"x": enemy_pos["x"],
		"y": enemy_pos["y"]
	}

func get_floor_position_lookup(floor_tiles: Array) -> Dictionary:
	var lookup = {}
	for floor_tile in floor_tiles:
		lookup[get_grid_key_from_data(floor_tile)] = true
	return lookup

func assert_walkable(context: String, label: String, position_data: Dictionary, floor_positions: Dictionary) -> void:
	var key = get_grid_key_from_data(position_data)
	if not floor_positions.has(key):
		failures.append("%s: %s is not walkable at %s" % [context, label, key])

func assert_unoccupied(context: String, label: String, position_data: Dictionary, occupied: Dictionary) -> void:
	var key = get_grid_key_from_data(position_data)
	if occupied.has(key):
		failures.append("%s: %s overlaps %s at %s" % [context, label, occupied[key], key])
	else:
		occupied[key] = label

func assert_special_rooms(context: String, special_rooms: Array) -> void:
	if special_rooms.size() != DungeonGenerator.SPECIAL_ROOM_COUNT:
		failures.append("%s: expected %d special rooms, got %d" % [context, DungeonGenerator.SPECIAL_ROOM_COUNT, special_rooms.size()])
		return

	var room_types = {}
	for special_room in special_rooms:
		room_types[str(special_room.get("type", ""))] = true
	if not room_types.has(DungeonGenerator.ROOM_TYPE_ARTIFACT):
		failures.append("%s: missing artifact room" % context)
	if not room_types.has(DungeonGenerator.ROOM_TYPE_SHOP):
		failures.append("%s: missing shop room" % context)

func get_grid_key_from_data(position_data: Dictionary) -> String:
	return "%d:%d" % [int(position_data.get("x", -1)), int(position_data.get("y", -1))]

extends RefCounted

const ROOM_WIDTH = 16
const ROOM_HEIGHT = 16
const MIN_ROOM_COUNT = 4
const MAX_ROOM_COUNT = 5
const MIN_ROOM_SIZE = 3
const MAX_ROOM_SIZE = 5
const ENEMY_COUNT = 4
const MAX_FLOOR = 3
const START_GRID_POS = {"x": 8, "y": 8}
const DUNGEON_ENEMY_TYPES = ["goblin", "skeleton", "bat", "slime"]
const FLOOR_PATH_NORMAL = "normal"
const FLOOR_PATH_ELITE = "elite"
const ROOM_TYPE_ARTIFACT = "artifact"
const ROOM_TYPE_SHOP = "shop"
const SPECIAL_ROOM_COUNT = 2

static func generate_level_data(
	floor_number: int,
	path_type: String,
	enemy_encounter_builder: Callable
) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var level_seed = rng.randi()
	rng.seed = level_seed

	var rooms = generate_rooms(rng)
	var special_rooms = assign_special_rooms(rooms)
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
	var fountain = generate_fountain_data(rooms, floor_number)
	var enemies = generate_enemy_encounter_data(rooms, floor_positions, start_position, exits, chest, fountain, special_rooms, rng, floor_number, path_type, enemy_encounter_builder)

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
		"chest": chest,
		"fountain": fountain,
		"special_rooms": special_rooms
	}

static func generate_rooms(rng: RandomNumberGenerator) -> Array:
	var rooms = []
	var target_room_count = rng.randi_range(MIN_ROOM_COUNT, MAX_ROOM_COUNT) + SPECIAL_ROOM_COUNT
	var attempts = 0

	while rooms.size() < target_room_count and attempts < 180:
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

static func assign_special_rooms(rooms: Array) -> Array:
	if rooms.size() < 3:
		return []

	var candidate_indexes = []
	for index in range(1, rooms.size() - 1):
		candidate_indexes.append(index)
	if candidate_indexes.size() < SPECIAL_ROOM_COUNT:
		for index in range(1, rooms.size()):
			if not candidate_indexes.has(index):
				candidate_indexes.append(index)

	if candidate_indexes.size() < SPECIAL_ROOM_COUNT:
		return []

	var artifact_room_index = candidate_indexes[0]
	var shop_room_index = candidate_indexes[1]
	rooms[artifact_room_index]["room_type"] = ROOM_TYPE_ARTIFACT
	rooms[shop_room_index]["room_type"] = ROOM_TYPE_SHOP
	return build_special_room_data(rooms)

static func build_special_room_data(rooms: Array) -> Array:
	var special_rooms = []
	for index in range(rooms.size()):
		var room = rooms[index]
		var room_type = str(room.get("room_type", ""))
		if room_type.is_empty():
			continue
		var room_center = get_room_center(room)
		special_rooms.append({
			"id": "%s_room_%02d" % [room_type, index],
			"type": room_type,
			"label": get_special_room_label(room_type),
			"marker": get_special_room_marker(room_type),
			"room_index": index,
			"x": room_center["x"],
			"y": room_center["y"]
		})
	return special_rooms

static func get_special_room_label(room_type: String) -> String:
	if room_type == ROOM_TYPE_ARTIFACT:
		return "Артефактная комната"
	if room_type == ROOM_TYPE_SHOP:
		return "Магазин"
	return "Особая комната"

static func get_special_room_marker(room_type: String) -> String:
	if room_type == ROOM_TYPE_ARTIFACT:
		return "A"
	if room_type == ROOM_TYPE_SHOP:
		return "$"
	return "?"

static func does_room_overlap(room: Dictionary, rooms: Array) -> bool:
	for other in rooms:
		if room["x"] - 1 < other["x"] + other["width"] + 1 \
				and room["x"] + room["width"] + 1 > other["x"] - 1 \
				and room["y"] - 1 < other["y"] + other["height"] + 1 \
				and room["y"] + room["height"] + 1 > other["y"] - 1:
			return true
	return false

static func carve_room(room: Dictionary, floor_positions: Dictionary) -> void:
	for y in range(room["y"], room["y"] + room["height"]):
		for x in range(room["x"], room["x"] + room["width"]):
			var floor_data = {"x": x, "y": y}
			var room_type = str(room.get("room_type", ""))
			if not room_type.is_empty():
				floor_data["room_type"] = room_type
			floor_positions[get_grid_key(x, y)] = floor_data

static func connect_rooms(from_room: Dictionary, to_room: Dictionary, floor_positions: Dictionary, rng: RandomNumberGenerator) -> void:
	var from_center = get_room_center(from_room)
	var to_center = get_room_center(to_room)

	if rng.randi_range(0, 1) == 0:
		carve_horizontal_corridor(from_center["x"], to_center["x"], from_center["y"], floor_positions)
		carve_vertical_corridor(from_center["y"], to_center["y"], to_center["x"], floor_positions)
	else:
		carve_vertical_corridor(from_center["y"], to_center["y"], from_center["x"], floor_positions)
		carve_horizontal_corridor(from_center["x"], to_center["x"], to_center["y"], floor_positions)

static func carve_horizontal_corridor(from_x: int, to_x: int, y: int, floor_positions: Dictionary) -> void:
	for x in range(min(from_x, to_x), max(from_x, to_x) + 1):
		floor_positions[get_grid_key(x, y)] = {"x": x, "y": y}

static func carve_vertical_corridor(from_y: int, to_y: int, x: int, floor_positions: Dictionary) -> void:
	for y in range(min(from_y, to_y), max(from_y, to_y) + 1):
		floor_positions[get_grid_key(x, y)] = {"x": x, "y": y}

static func get_room_center(room: Dictionary) -> Dictionary:
	return {
		"x": int(room["x"] + floori(room["width"] / 2.0)),
		"y": int(room["y"] + floori(room["height"] / 2.0))
	}

static func positions_to_array(positions: Dictionary) -> Array:
	var result = []
	for position in positions.values():
		result.append(position)
	return result

static func build_wall_tiles(floor_positions: Dictionary) -> Array:
	var walls = []
	for y in range(ROOM_HEIGHT):
		for x in range(ROOM_WIDTH):
			if not floor_positions.has(get_grid_key(x, y)):
				walls.append({"x": x, "y": y})
	return walls

static func generate_exit_data(rooms: Array, floor_number: int, path_type: String) -> Array:
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

static func build_exit_data(exit_id: String, label: String, path_type: String, to_floor: int, grid_position: Dictionary) -> Dictionary:
	return {
		"id": exit_id,
		"label": label,
		"path": path_type,
		"to_floor": to_floor,
		"x": grid_position["x"],
		"y": grid_position["y"]
	}

static func generate_chest_data(exits: Array, floor_number: int, path_type: String, rooms: Array = []) -> Dictionary:
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

static func generate_fountain_data(rooms: Array, floor_number: int) -> Dictionary:
	if rooms.is_empty():
		return {}

	var fountain_position = get_room_position_with_offset(rooms[0], Vector2i(1, 0))
	return {
		"id": "floor_%d_fountain" % floor_number,
		"x": fountain_position["x"],
		"y": fountain_position["y"],
		"heal_percent": 0.25,
		"is_used": false
	}

static func get_floor_chest_reward(floor_number: int, path_type: String) -> String:
	if path_type == FLOOR_PATH_ELITE:
		return "vitality_ring"
	if floor_number >= 3:
		return "iron_sword"
	if floor_number >= 2:
		return "leather_chestpiece"
	return "wooden_sword"

static func get_floor_chest_gold(floor_number: int, path_type: String) -> int:
	var min_gold = 15 + (floor_number - 1) * 5
	var max_gold = 25 + (floor_number - 1) * 5
	if path_type == FLOOR_PATH_ELITE:
		min_gold += 10
		max_gold += 15
	return randi_range(min_gold, max_gold)

static func get_room_position_with_offset(room: Dictionary, offset: Vector2i) -> Dictionary:
	var center = get_room_center(room)
	return {
		"x": clampi(center["x"] + offset.x, room["x"], room["x"] + room["width"] - 1),
		"y": clampi(center["y"] + offset.y, room["y"], room["y"] + room["height"] - 1)
	}

static func get_nearby_walkable_position(position_data: Dictionary) -> Dictionary:
	return {
		"x": clampi(int(position_data["x"]) - 1, 0, ROOM_WIDTH - 1),
		"y": int(position_data["y"])
	}

static func generate_enemy_encounter_data(
	rooms: Array,
	floor_positions: Dictionary,
	start_position: Dictionary,
	exits: Array,
	chest_data: Dictionary,
	fountain_data: Dictionary,
	special_rooms: Array,
	rng: RandomNumberGenerator,
	floor_number: int,
	path_type: String,
	enemy_encounter_builder: Callable
) -> Array:
	var enemies = []
	var occupied = {
		get_grid_key(start_position["x"], start_position["y"]): true
	}
	for exit_data in exits:
		occupied[get_grid_key(exit_data["x"], exit_data["y"])] = true
	if not chest_data.is_empty():
		occupied[get_grid_key(chest_data["x"], chest_data["y"])] = true
	if not fountain_data.is_empty():
		occupied[get_grid_key(fountain_data["x"], fountain_data["y"])] = true
	var special_room_indexes = {}
	for special_room in special_rooms:
		var room_index = int(special_room.get("room_index", -1))
		if room_index >= 0:
			special_room_indexes[room_index] = true
			occupy_room_tiles(rooms[room_index], occupied)

	var enemy_rooms = []
	for room_index in range(1, rooms.size()):
		if special_room_indexes.has(room_index):
			continue
		if not exits.is_empty() and room_index == rooms.size() - 1:
			continue
		enemy_rooms.append(rooms[room_index])
	var enemy_count = get_floor_enemy_count(floor_number, path_type)

	for index in range(enemy_count):
		var enemy_pos = get_random_floor_position(rng, floor_positions, occupied, start_position, enemy_rooms)
		if enemy_pos.is_empty():
			break
		occupied[get_grid_key(enemy_pos["x"], enemy_pos["y"])] = true
		var enemy_type = DUNGEON_ENEMY_TYPES[index % DUNGEON_ENEMY_TYPES.size()]
		enemies.append(enemy_encounter_builder.call("level_enemy_%02d" % [index + 1], enemy_type, enemy_pos, floor_number, path_type))

	return enemies

static func occupy_room_tiles(room: Dictionary, occupied: Dictionary) -> void:
	for y in range(room["y"], room["y"] + room["height"]):
		for x in range(room["x"], room["x"] + room["width"]):
			occupied[get_grid_key(x, y)] = true

static func get_floor_enemy_count(floor_number: int, path_type: String) -> int:
	var count = ENEMY_COUNT + max(0, floor_number - 1)
	if path_type == FLOOR_PATH_ELITE:
		count += 1
	return count

static func get_random_floor_position(
	rng: RandomNumberGenerator,
	floor_positions: Dictionary,
	occupied: Dictionary,
	start_position: Dictionary,
	preferred_rooms: Array
) -> Dictionary:
	for _attempt in range(200):
		var candidate = get_random_room_position(rng, preferred_rooms)
		if candidate.is_empty():
			continue
		if is_valid_spawn_position(candidate, occupied, start_position):
			return candidate

	var floor_tiles = floor_positions.values()
	for _attempt in range(200):
		var candidate = floor_tiles[rng.randi_range(0, floor_tiles.size() - 1)]
		if is_valid_spawn_position(candidate, occupied, start_position):
			return candidate

	var start_key = get_grid_key(start_position["x"], start_position["y"])
	for candidate in floor_tiles:
		var key = get_grid_key(candidate["x"], candidate["y"])
		if not occupied.has(key) and key != start_key:
			return candidate

	return {}

static func get_random_room_position(rng: RandomNumberGenerator, rooms: Array) -> Dictionary:
	if rooms.is_empty():
		return {}

	var room = rooms[rng.randi_range(0, rooms.size() - 1)]
	return {
		"x": rng.randi_range(room["x"], room["x"] + room["width"] - 1),
		"y": rng.randi_range(room["y"], room["y"] + room["height"] - 1)
	}

static func is_valid_spawn_position(candidate: Dictionary, occupied: Dictionary, start_position: Dictionary) -> bool:
	var key = get_grid_key(candidate["x"], candidate["y"])
	var distance = abs(candidate["x"] - start_position["x"]) + abs(candidate["y"] - start_position["y"])
	return not occupied.has(key) and distance >= 4

static func get_grid_key(x: int, y: int) -> String:
	return "%d:%d" % [x, y]

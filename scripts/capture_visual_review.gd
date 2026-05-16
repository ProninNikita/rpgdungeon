extends SceneTree

const ScenePaths = preload("res://scripts/scene_paths.gd")

const DEFAULT_CAPTURE_DIR = "/private/tmp/rpg_visual_review"
const VIEWPORT_SIZE = Vector2i(1600, 900)
const MAP_CASES = [
	{"name": "map_crypt", "floor": 1, "path": "normal", "seed": 1301},
	{"name": "map_vampire_crypt", "floor": 1, "path": "normal", "seed": 1301, "character_id": "vampire"},
	{"name": "map_moss", "floor": 2, "path": "normal", "seed": 2302},
	{"name": "map_ember", "floor": 2, "path": "elite", "seed": 3303},
	{"name": "map_dense_room", "floor": 2, "path": "normal", "seed": 2302, "dense": true},
	{"name": "map_enemy_dark_prop", "floor": 1, "path": "normal", "seed": 1301, "enemy_prop_focus": true},
	{"name": "map_interactives_vs_decor", "floor": 2, "path": "normal", "seed": 2302, "dense": true},
	{"name": "map_accent_tiles", "floor": 2, "path": "normal", "seed": 2302, "accent_focus": true}
]
const MAP_ANIMATION_CASE = {"floor": 2, "path": "normal", "seed": 2302, "dense": true}
const MAP_STEP_DIRECTIONS = [
	{"name": "right", "direction": Vector2i(1, 0)},
	{"name": "left", "direction": Vector2i(-1, 0)},
	{"name": "up", "direction": Vector2i(0, -1)},
	{"name": "down", "direction": Vector2i(0, 1)}
]
const REQUIRED_CAPTURE_FILES = [
	"map_crypt.png",
	"map_vampire_crypt.png",
	"map_moss.png",
	"map_ember.png",
	"map_dense_room.png",
	"map_enemy_dark_prop.png",
	"map_interactives_vs_decor.png",
	"map_accent_tiles.png",
	"map_step_mid.png",
	"map_bump_wall.png",
	"map_step_right.png",
	"map_step_left.png",
	"map_step_up.png",
	"map_step_down.png",
	"map_vampire_step_mid.png",
	"map_vampire_bump_wall.png"
]
const REQUIRED_INVENTORY_CAPTURE_FILES = [
	"inventory_empty.png",
	"inventory_full.png",
	"inventory_full_equipped.png",
	"inventory_selected_detail.png"
]
const BATTLE_CASES = [
	{"name": "battle_crypt_goblin", "floor": 1, "path": "normal", "seed": 1301, "enemy_type": "goblin"},
	{"name": "battle_crypt_skeleton", "floor": 1, "path": "normal", "seed": 1301, "enemy_type": "skeleton"},
	{"name": "battle_crypt_bat", "floor": 1, "path": "normal", "seed": 1301, "enemy_type": "bat"},
	{"name": "battle_crypt_slime", "floor": 1, "path": "normal", "seed": 1301, "enemy_type": "slime"},
	{"name": "battle_moss_slime", "floor": 2, "path": "normal", "seed": 2302, "enemy_type": "slime"},
	{"name": "battle_moss_goblin", "floor": 2, "path": "normal", "seed": 2302, "enemy_type": "goblin"},
	{"name": "battle_moss_bat", "floor": 2, "path": "normal", "seed": 2302, "enemy_type": "bat"},
	{"name": "battle_ember_skeleton", "floor": 2, "path": "elite", "seed": 3303, "enemy_type": "skeleton"},
	{"name": "battle_ember_goblin", "floor": 2, "path": "elite", "seed": 3303, "enemy_type": "goblin"},
	{"name": "battle_ember_bat", "floor": 2, "path": "elite", "seed": 3303, "enemy_type": "bat"},
	{"name": "battle_ember_slime", "floor": 2, "path": "elite", "seed": 3303, "enemy_type": "slime"},
	{"name": "battle_vampire_crypt_goblin", "floor": 1, "path": "normal", "seed": 1301, "enemy_type": "goblin", "character_id": "vampire"},
	{"name": "battle_vampire_ember_skeleton", "floor": 2, "path": "elite", "seed": 3303, "enemy_type": "skeleton", "character_id": "vampire"}
]
const FULL_INVENTORY_ITEMS = [
	"wooden_sword",
	"iron_sword",
	"steel_sword",
	"leather_chestpiece",
	"chainmail",
	"plate_armor",
	"vitality_ring",
	"ancient_amulet",
	"wooden_sword",
	"iron_sword",
	"steel_sword",
	"leather_chestpiece",
	"chainmail",
	"plate_armor",
	"vitality_ring",
	"ancient_amulet"
]

var game_state: Node
var capture_dir: String = DEFAULT_CAPTURE_DIR
var has_failed := false

func _init() -> void:
	call_deferred("run")

func run() -> void:
	capture_dir = get_capture_dir()
	DirAccess.make_dir_recursive_absolute(capture_dir)
	clear_capture_pngs()
	verify_capture_dir_is_clean()
	if has_failed:
		return
	root.size = VIEWPORT_SIZE
	game_state = root.get_node("GameState")
	for capture_case in MAP_CASES:
		await capture_map_case(capture_case)
		if has_failed:
			return
	await capture_map_step_frame()
	if has_failed:
		return
	await capture_map_bump_frame()
	if has_failed:
		return
	for step_case in MAP_STEP_DIRECTIONS:
		await capture_map_direction_step_frame(step_case)
		if has_failed:
			return
	await capture_map_vampire_step_frame()
	if has_failed:
		return
	await capture_map_vampire_bump_frame()
	if has_failed:
		return
	for capture_case in BATTLE_CASES:
		await capture_battle_case(capture_case)
		if has_failed:
			return
		await capture_battle_player_attack_case(capture_case)
		if has_failed:
			return
		await capture_battle_enemy_attack_case(capture_case)
		if has_failed:
			return
	await capture_empty_inventory()
	if has_failed:
		return
	await capture_full_inventory_only()
	if has_failed:
		return
	await capture_full_inventory()
	if has_failed:
		return
	await capture_selected_inventory_detail()
	if has_failed:
		return
	verify_required_capture_files()
	if has_failed:
		return
	print("Visual review captures saved to %s" % capture_dir)
	quit(0)

func get_capture_dir() -> String:
	var user_args = OS.get_cmdline_user_args()
	if not user_args.is_empty() and not str(user_args[0]).strip_edges().is_empty():
		return str(user_args[0]).strip_edges()
	return DEFAULT_CAPTURE_DIR

func clear_capture_pngs() -> void:
	var directory = DirAccess.open(capture_dir)
	if directory == null:
		return
	directory.list_dir_begin()
	var file_name = directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension().to_lower() == "png":
			DirAccess.remove_absolute(capture_dir.path_join(file_name))
		file_name = directory.get_next()
	directory.list_dir_end()

func verify_capture_dir_is_clean() -> void:
	var directory = DirAccess.open(capture_dir)
	if directory == null:
		fail_capture("Could not open visual review capture dir: %s" % capture_dir)
		return
	directory.list_dir_begin()
	var file_name = directory.get_next()
	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.get_extension().to_lower() == "png":
			directory.list_dir_end()
			fail_capture("Visual review capture dir was not cleaned before capture: %s" % file_name)
			return
		file_name = directory.get_next()
	directory.list_dir_end()

func verify_required_capture_files() -> void:
	for file_name in REQUIRED_CAPTURE_FILES:
		verify_png_capture(file_name)
	for capture_case in BATTLE_CASES:
		var capture_name = str(capture_case["name"])
		verify_png_capture("%s.png" % capture_name)
		verify_png_capture("%s_player_attack.png" % capture_name)
		verify_png_capture("%s_enemy_attack.png" % capture_name)
	for file_name in REQUIRED_INVENTORY_CAPTURE_FILES:
		verify_png_capture(file_name)
	if has_failed:
		return

func verify_png_capture(file_name: String) -> void:
	if has_failed:
		return
	var path = capture_dir.path_join(file_name)
	if not FileAccess.file_exists(path):
		fail_capture("Missing required visual review capture: %s" % path)
		return
	var image = Image.load_from_file(path)
	if image == null or image.is_empty():
		fail_capture("Invalid visual review PNG capture: %s" % path)
		return

func capture_map_case(capture_case: Dictionary) -> void:
	prepare_level(capture_case)
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	save_viewport("%s/%s.png" % [capture_dir, str(capture_case["name"])])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_map_step_frame() -> void:
	prepare_level(MAP_ANIMATION_CASE)
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	var direction = get_valid_step_direction(scene)
	var start_grid = scene.player.grid_pos
	var target_grid = start_grid + direction
	var start_position = scene.player.grid_to_world_position(start_grid)
	var target_position = scene.player.grid_to_world_position(target_grid)
	scene.player.apply_step_facing(direction)
	scene.player.position = start_position.lerp(target_position, 0.52)
	scene.player.set_step_visual_progress(0.52)
	await process_frame
	save_viewport("%s/map_step_mid.png" % capture_dir)
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_map_direction_step_frame(step_case: Dictionary) -> void:
	prepare_level(MAP_ANIMATION_CASE)
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	var requested_direction = step_case["direction"]
	var direction = find_valid_direction_or_reposition(scene, requested_direction)
	position_player_mid_step(scene, direction, 0.52)
	await process_frame
	save_viewport("%s/map_step_%s.png" % [capture_dir, str(step_case["name"])])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_map_bump_frame() -> void:
	prepare_level(MAP_ANIMATION_CASE)
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	var direction = get_blocked_step_direction(scene)
	scene.player.apply_step_facing(direction)
	scene.player.position += Vector2(direction).normalized() * 5.0
	scene.player.set_bump_visual_progress(0.70)
	await process_frame
	save_viewport("%s/map_bump_wall.png" % capture_dir)
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_map_vampire_step_frame() -> void:
	var capture_case = MAP_ANIMATION_CASE.duplicate()
	capture_case["character_id"] = "vampire"
	prepare_level(capture_case)
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	var direction = get_valid_step_direction(scene)
	position_player_mid_step(scene, direction, 0.52)
	await process_frame
	save_viewport("%s/map_vampire_step_mid.png" % capture_dir)
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_map_vampire_bump_frame() -> void:
	var capture_case = MAP_ANIMATION_CASE.duplicate()
	capture_case["character_id"] = "vampire"
	prepare_level(capture_case)
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	var direction = get_blocked_step_direction(scene)
	scene.player.apply_step_facing(direction)
	scene.player.position += Vector2(direction).normalized() * 5.0
	scene.player.set_bump_visual_progress(0.70)
	await process_frame
	save_viewport("%s/map_vampire_bump_wall.png" % capture_dir)
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func position_player_mid_step(scene: Node, direction: Vector2i, progress: float) -> void:
	var start_grid = scene.player.grid_pos
	var target_grid = start_grid + direction
	var start_position = scene.player.grid_to_world_position(start_grid)
	var target_position = scene.player.grid_to_world_position(target_grid)
	scene.player.apply_step_facing(direction)
	scene.player.position = start_position.lerp(target_position, progress)
	scene.player.set_step_visual_progress(progress)

func find_valid_direction_or_reposition(scene: Node, requested_direction: Vector2i) -> Vector2i:
	if scene.player.is_valid_position(scene.player.grid_pos + requested_direction):
		return requested_direction
	var candidate = find_floor_position_with_neighbor(scene, requested_direction)
	if candidate != Vector2i(-1, -1):
		scene.player.set_grid_position(candidate)
		game_state.player_grid_pos = {"x": candidate.x, "y": candidate.y}
		return requested_direction
	return get_valid_step_direction(scene)

func find_floor_position_with_neighbor(scene: Node, direction: Vector2i) -> Vector2i:
	for floor_data in game_state.level_data.get("floor_tiles", []):
		var grid_pos = Vector2i(int(floor_data.get("x", 0)), int(floor_data.get("y", 0)))
		if scene.player.is_valid_position(grid_pos) and scene.player.is_valid_position(grid_pos + direction):
			return grid_pos
	return Vector2i(-1, -1)

func get_valid_step_direction(scene: Node) -> Vector2i:
	for direction in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
		if scene.player.is_valid_position(scene.player.grid_pos + direction):
			return direction
	return Vector2i(1, 0)

func get_blocked_step_direction(scene: Node) -> Vector2i:
	for direction in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1)]:
		if not scene.player.is_valid_position(scene.player.grid_pos + direction):
			return direction
	return Vector2i(-1, 0)

func capture_battle_case(capture_case: Dictionary) -> void:
	prepare_battle(capture_case)
	var scene = load(ScenePaths.BATTLE).instantiate()
	if not validate_battle_scene(scene):
		scene.queue_free()
		return
	scene.is_battle_active = false
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	save_viewport("%s/%s.png" % [capture_dir, str(capture_case["name"])])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_battle_player_attack_case(capture_case: Dictionary) -> void:
	prepare_battle(capture_case)
	var scene = load(ScenePaths.BATTLE).instantiate()
	if not validate_battle_scene(scene):
		scene.queue_free()
		return
	scene.is_battle_active = false
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	scene.player_sprite.frame = 1
	scene.enemy_sprite.frame = 2
	scene.status_label.text = "Ход: %s" % scene.player_stats.get("name", "Герой")
	scene.show_effect("Удар")
	await process_frame
	save_viewport("%s/%s_player_attack.png" % [capture_dir, str(capture_case["name"])])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_battle_enemy_attack_case(capture_case: Dictionary) -> void:
	prepare_battle(capture_case)
	var scene = load(ScenePaths.BATTLE).instantiate()
	if not validate_battle_scene(scene):
		scene.queue_free()
		return
	scene.is_battle_active = false
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	scene.enemy_sprite.frame = 1
	scene.player_sprite.frame = 2
	scene.status_label.text = "Ход: %s" % scene.enemy_stats.get("name", "Враг")
	scene.show_effect("Ответный удар")
	await process_frame
	save_viewport("%s/%s_enemy_attack.png" % [capture_dir, str(capture_case["name"])])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func validate_battle_scene(scene: Node) -> bool:
	if not has_node_property(scene, "is_battle_active"):
		fail_capture("Battle scene script did not load correctly: missing is_battle_active.")
		return false
	for property_name in ["player_sprite", "enemy_sprite", "status_label", "player_stats", "enemy_stats"]:
		if not has_node_property(scene, property_name):
			fail_capture("Battle scene script did not load correctly: missing %s." % property_name)
			return false
	return true

func has_node_property(node: Node, property_name: String) -> bool:
	for property in node.get_property_list():
		if str(property.get("name", "")) == property_name:
			return true
	return false

func capture_full_inventory() -> void:
	prepare_full_inventory()
	await capture_inventory_scene("inventory_full_equipped")

func capture_empty_inventory() -> void:
	prepare_empty_inventory()
	await capture_inventory_scene("inventory_empty")

func capture_full_inventory_only() -> void:
	prepare_full_inventory_only()
	await capture_inventory_scene("inventory_full")

func capture_selected_inventory_detail() -> void:
	prepare_full_inventory()
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.inventory_ui.open()
	scene.inventory_ui.selected_inventory_index = 5
	scene.inventory_ui.refresh_character_info()
	await process_frame
	await process_frame
	save_viewport("%s/inventory_selected_detail.png" % capture_dir)
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_inventory_scene(capture_name: String) -> void:
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.inventory_ui.open()
	await process_frame
	await process_frame
	save_viewport("%s/%s.png" % [capture_dir, capture_name])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func prepare_level(capture_case: Dictionary) -> void:
	reset_game_state(capture_case)
	game_state.level_data = game_state.generate_level_data(
		int(capture_case["floor"]),
		str(capture_case["path"]),
		int(capture_case["seed"])
	)
	game_state.player_grid_pos = game_state.level_data.get("start_position", game_state.START_GRID_POS).duplicate()
	game_state.player_stats = game_state.get_character_stats(game_state.selected_character_id)
	if bool(capture_case.get("dense", false)):
		prepare_dense_map_objects()
	if bool(capture_case.get("enemy_prop_focus", false)):
		prepare_enemy_prop_focus()
	if bool(capture_case.get("accent_focus", false)):
		prepare_accent_tile_focus()

func prepare_battle(capture_case: Dictionary) -> void:
	reset_game_state(capture_case)
	game_state.current_enemy_id = "visual_review_enemy"
	game_state.level_data = game_state.generate_level_data(
		int(capture_case["floor"]),
		str(capture_case["path"]),
		int(capture_case["seed"])
	)
	var enemy = game_state.level_data.get("enemies", [])[0]
	var enemy_type = str(capture_case["enemy_type"])
	var enemy_stats = game_state.get_enemy_stats(enemy_type)
	enemy["id"] = "visual_review_enemy"
	enemy["type"] = enemy_type
	enemy["name"] = str(enemy_stats.get("name", enemy_type))
	enemy["hp"] = int(enemy_stats.get("hp", enemy_stats.get("max_hp", 30)))
	enemy["max_hp"] = int(enemy_stats.get("max_hp", 30))
	enemy["attack"] = int(enemy_stats.get("attack", 5))
	enemy["defense"] = int(enemy_stats.get("defense", 0))
	enemy["features"] = enemy_stats.get("features", []).duplicate(true)
	game_state.level_data["enemies"][0] = enemy
	var character_id = str(capture_case.get("character_id", "base"))
	game_state.selected_character_id = character_id
	game_state.player_stats = game_state.get_character_stats(character_id)

func reset_game_state(capture_case: Dictionary) -> void:
	game_state.active_save_slot = 0
	game_state.selected_character_id = str(capture_case.get("character_id", "base"))
	game_state.current_floor = int(capture_case["floor"])
	game_state.current_enemy_id = ""
	game_state.defeated_enemies.clear()
	game_state.gold = 42
	game_state.inventory.clear()
	game_state.equipment = game_state.DEFAULT_EQUIPMENT.duplicate()

func prepare_full_inventory() -> void:
	reset_game_state({"floor": 2})
	game_state.current_floor = 2
	game_state.level_data = game_state.generate_level_data(2, "normal", 2302)
	game_state.player_grid_pos = game_state.level_data.get("start_position", game_state.START_GRID_POS).duplicate()
	game_state.gold = 999
	game_state.equipment = {
		"weapon": "steel_sword",
		"armor": "plate_armor",
		"accessory": "ancient_amulet"
	}
	game_state.inventory = FULL_INVENTORY_ITEMS.duplicate()
	game_state.player_stats = game_state.get_character_stats("base")

func prepare_empty_inventory() -> void:
	reset_game_state({"floor": 2})
	game_state.current_floor = 2
	game_state.level_data = game_state.generate_level_data(2, "normal", 2302)
	game_state.player_grid_pos = game_state.level_data.get("start_position", game_state.START_GRID_POS).duplicate()
	game_state.gold = 25
	game_state.player_stats = game_state.get_character_stats("base")

func prepare_full_inventory_only() -> void:
	prepare_full_inventory()
	game_state.equipment = game_state.DEFAULT_EQUIPMENT.duplicate()

func prepare_dense_map_objects() -> void:
	var room = find_best_dense_room()
	if room.is_empty():
		return
	var x = int(room.get("x", 0))
	var y = int(room.get("y", 0))
	var width = int(room.get("width", 4))
	var height = int(room.get("height", 4))
	var center = Vector2i(x + floori(width / 2.0), y + floori(height / 2.0))
	game_state.player_grid_pos = center
	game_state.level_data["enemies"] = [
		make_capture_enemy("dense_goblin", "goblin", center + Vector2i(2, 0)),
		make_capture_enemy("dense_skeleton", "skeleton", center + Vector2i(-2, 0)),
		make_capture_enemy("dense_bat", "bat", center + Vector2i(0, -2)),
		make_capture_enemy("dense_slime", "slime", center + Vector2i(0, 2))
	]
	game_state.level_data["chest"] = {
		"id": "dense_chest",
		"x": clampi(center.x + 2, x + 1, x + width - 2),
		"y": clampi(center.y + 2, y + 1, y + height - 2),
		"gold": 48,
		"item_id": "steel_sword",
		"is_opened": false
	}
	game_state.level_data["fountain"] = {
		"id": "dense_fountain",
		"x": clampi(center.x - 2, x + 1, x + width - 2),
		"y": clampi(center.y + 2, y + 1, y + height - 2),
		"is_used": false
	}
	game_state.level_data["exits"] = [
		{
			"id": "dense_exit",
			"x": clampi(center.x + 3, x + 1, x + width - 2),
			"y": center.y,
			"to_floor": 3,
			"path": "normal"
		}
	]

func prepare_enemy_prop_focus() -> void:
	var room = find_distant_normal_room()
	if room.is_empty():
		room = find_best_dense_room()
	if room.is_empty():
		return
	var x = int(room.get("x", 0))
	var y = int(room.get("y", 0))
	var width = int(room.get("width", 4))
	var height = int(room.get("height", 4))
	var center = Vector2i(x + floori(width / 2.0), y + floori(height / 2.0))
	game_state.level_data["enemies"] = [
		make_capture_enemy("dark_goblin", "goblin", center),
		make_capture_enemy("dark_skeleton", "skeleton", Vector2i(clampi(center.x + 1, x + 1, x + width - 2), center.y)),
		make_capture_enemy("dark_bat", "bat", Vector2i(center.x, clampi(center.y - 1, y + 1, y + height - 2))),
		make_capture_enemy("dark_slime", "slime", Vector2i(clampi(center.x - 1, x + 1, x + width - 2), center.y))
	]

func prepare_accent_tile_focus() -> void:
	var target_room = find_special_capture_room()
	if target_room.is_empty():
		return
	game_state.player_grid_pos = {
		"x": int(target_room.get("x", 0)),
		"y": int(target_room.get("y", 0))
	}

func find_distant_normal_room() -> Dictionary:
	var start = game_state.level_data.get("start_position", game_state.START_GRID_POS)
	var start_pos = Vector2i(int(start.get("x", 8)), int(start.get("y", 8)))
	var best_room = {}
	var best_distance = -1
	for room in game_state.level_data.get("rooms", []):
		if typeof(room) != TYPE_DICTIONARY:
			continue
		if not str(room.get("room_type", "")).is_empty():
			continue
		var center = Vector2i(
			int(room.get("x", 0)) + floori(int(room.get("width", 1)) / 2.0),
			int(room.get("y", 0)) + floori(int(room.get("height", 1)) / 2.0)
		)
		var distance = abs(center.x - start_pos.x) + abs(center.y - start_pos.y)
		if distance > best_distance:
			best_distance = distance
			best_room = room
	return best_room

func find_special_capture_room() -> Dictionary:
	for special_room in game_state.level_data.get("special_rooms", []):
		if typeof(special_room) == TYPE_DICTIONARY and str(special_room.get("type", "")) == "artifact":
			return special_room
	for special_room in game_state.level_data.get("special_rooms", []):
		if typeof(special_room) == TYPE_DICTIONARY:
			return special_room
	return {}

func find_best_dense_room() -> Dictionary:
	var best_room = {}
	var best_area = 0
	for room in game_state.level_data.get("rooms", []):
		if typeof(room) != TYPE_DICTIONARY:
			continue
		if not str(room.get("room_type", "")).is_empty():
			continue
		var area = int(room.get("width", 0)) * int(room.get("height", 0))
		if area > best_area and int(room.get("width", 0)) >= 6 and int(room.get("height", 0)) >= 6:
			best_area = area
			best_room = room
	return best_room

func make_capture_enemy(enemy_id: String, enemy_type: String, grid_pos: Vector2i) -> Dictionary:
	var enemy_stats = game_state.get_enemy_stats(enemy_type)
	return {
		"id": enemy_id,
		"type": enemy_type,
		"name": str(enemy_stats.get("name", enemy_type)),
		"x": grid_pos.x,
		"y": grid_pos.y,
		"hp": int(enemy_stats.get("hp", enemy_stats.get("max_hp", 30))),
		"max_hp": int(enemy_stats.get("max_hp", 30)),
		"attack": int(enemy_stats.get("attack", 5)),
		"defense": int(enemy_stats.get("defense", 0)),
		"features": enemy_stats.get("features", []).duplicate(true)
	}

func save_viewport(path: String) -> void:
	var texture = root.get_texture()
	if texture == null:
		fail_capture("Could not read visual review viewport texture: %s" % path)
		return
	var image = texture.get_image()
	if image == null or image.is_empty():
		fail_capture("Could not read visual review viewport image: %s" % path)
		return
	var error = image.save_png(path)
	if error != OK or not FileAccess.file_exists(path):
		fail_capture("Failed to save visual review capture: %s" % path)
		return
	print(path)

func fail_capture(message: String) -> void:
	if has_failed:
		return
	has_failed = true
	push_error(message)
	quit(1)

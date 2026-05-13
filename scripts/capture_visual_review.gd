extends SceneTree

const ScenePaths = preload("res://scripts/scene_paths.gd")

const DEFAULT_CAPTURE_DIR = "/private/tmp/rpg_visual_review"
const VIEWPORT_SIZE = Vector2i(1600, 900)
const MAP_CASES = [
	{"name": "map_crypt", "floor": 1, "path": "normal", "seed": 1301},
	{"name": "map_moss", "floor": 2, "path": "normal", "seed": 2302},
	{"name": "map_ember", "floor": 2, "path": "elite", "seed": 3303}
]
const BATTLE_CASES = [
	{"name": "battle_crypt_goblin", "floor": 1, "path": "normal", "seed": 1301, "enemy_type": "goblin"},
	{"name": "battle_ember_skeleton", "floor": 2, "path": "elite", "seed": 3303, "enemy_type": "skeleton"}
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

func _init() -> void:
	call_deferred("run")

func run() -> void:
	capture_dir = get_capture_dir()
	DirAccess.make_dir_recursive_absolute(capture_dir)
	root.size = VIEWPORT_SIZE
	game_state = root.get_node("GameState")
	for capture_case in MAP_CASES:
		await capture_map_case(capture_case)
	for capture_case in BATTLE_CASES:
		await capture_battle_case(capture_case)
	await capture_full_inventory()
	print("Visual review captures saved to %s" % capture_dir)
	quit(0)

func get_capture_dir() -> String:
	var user_args = OS.get_cmdline_user_args()
	if not user_args.is_empty() and not str(user_args[0]).strip_edges().is_empty():
		return str(user_args[0]).strip_edges()
	return DEFAULT_CAPTURE_DIR

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

func capture_battle_case(capture_case: Dictionary) -> void:
	prepare_battle(capture_case)
	var scene = load(ScenePaths.BATTLE).instantiate()
	scene.is_battle_active = false
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	save_viewport("%s/%s.png" % [capture_dir, str(capture_case["name"])])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_full_inventory() -> void:
	prepare_full_inventory()
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.inventory_ui.open()
	await process_frame
	await process_frame
	save_viewport("%s/inventory_full_equipped.png" % capture_dir)
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
	game_state.player_stats = game_state.get_character_stats("base")

func prepare_battle(capture_case: Dictionary) -> void:
	reset_game_state(capture_case)
	game_state.current_enemy_id = "visual_review_enemy"
	game_state.level_data = game_state.generate_level_data(
		int(capture_case["floor"]),
		str(capture_case["path"]),
		int(capture_case["seed"])
	)
	var enemy = game_state.level_data.get("enemies", [])[0]
	enemy["id"] = "visual_review_enemy"
	enemy["type"] = str(capture_case["enemy_type"])
	game_state.level_data["enemies"][0] = enemy
	game_state.player_stats = game_state.get_character_stats("base")

func reset_game_state(capture_case: Dictionary) -> void:
	game_state.active_save_slot = 0
	game_state.selected_character_id = "base"
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

func save_viewport(path: String) -> void:
	var image = root.get_texture().get_image()
	image.save_png(path)
	print(path)

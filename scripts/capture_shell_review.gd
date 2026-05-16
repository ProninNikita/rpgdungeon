extends SceneTree

const ScenePaths = preload("res://scripts/scene_paths.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const RunState = preload("res://scripts/run_state.gd")

const DEFAULT_CAPTURE_DIR = "/private/tmp/rpg_shell_review"
const SAVE_DIR = "/private/tmp/rpg_shell_review/saves"
const VIEWPORT_SIZE = Vector2i(1600, 900)
const MAX_POST_DRAW_WAIT_FRAMES = 8
const REQUIRED_CAPTURE_FILES = [
	"main_menu.png",
	"load_menu_empty.png",
	"character_select_empty.png",
	"character_select_base_selected.png",
	"character_select_vampire_selected.png",
	"load_menu_full.png",
	"load_delete_dialog.png",
	"character_select_full.png",
	"character_overwrite_dialog.png",
	"character_overwrite_dialog_vampire.png",
	"death_screen.png",
	"death_screen_base.png",
	"death_screen_vampire_full_run.png",
	"result_normal_full_equipment.png",
	"result_elite_full_equipment.png",
	"result_normal_empty_equipment.png"
]

var capture_dir: String = DEFAULT_CAPTURE_DIR
var has_failed := false
var did_post_draw := false

func _init() -> void:
	call_deferred("run")

func run() -> void:
	capture_dir = get_capture_dir()
	DirAccess.make_dir_recursive_absolute(capture_dir)
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	clear_capture_pngs()
	ProjectSettings.set_setting(SaveManager.SAVE_DIR_SETTING, SAVE_DIR)
	root.size = VIEWPORT_SIZE

	clear_capture_saves()
	await capture_scene(ScenePaths.MAIN_MENU, "main_menu")
	if has_failed:
		return
	await capture_scene(ScenePaths.LOAD_MENU, "load_menu_empty")
	if has_failed:
		return
	await capture_scene(ScenePaths.CHARACTER_SELECT, "character_select_empty")
	if has_failed:
		return
	await capture_character_selected("base", "character_select_base_selected")
	if has_failed:
		return
	await capture_character_selected("vampire", "character_select_vampire_selected")
	if has_failed:
		return

	write_full_capture_saves()
	if has_failed:
		return
	await capture_scene(ScenePaths.LOAD_MENU, "load_menu_full")
	if has_failed:
		return
	await capture_load_delete_dialog()
	if has_failed:
		return
	await capture_scene(ScenePaths.CHARACTER_SELECT, "character_select_full")
	if has_failed:
		return
	await capture_character_overwrite_dialog()
	if has_failed:
		return
	await capture_character_overwrite_dialog_for("vampire", "character_overwrite_dialog_vampire")
	if has_failed:
		return
	await capture_death_case("base", "death_screen")
	if has_failed:
		return
	await capture_death_case("base", "death_screen_base")
	if has_failed:
		return
	await capture_death_case("vampire", "death_screen_vampire_full_run", true)
	if has_failed:
		return
	await capture_result_case("result_normal_full_equipment", make_result_summary("Герой", "Обычный", 3, 214, 14, true))
	if has_failed:
		return
	await capture_result_case("result_elite_full_equipment", make_result_summary("Герой", "Элитный", 3, 286, 18, true))
	if has_failed:
		return
	await capture_result_case("result_normal_empty_equipment", make_result_summary("Вампир", "Обычный", 3, 180, 13, false))
	if has_failed:
		return
	verify_required_capture_files()
	if has_failed:
		return

	print("Shell review captures saved to %s" % capture_dir)
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

func clear_capture_saves() -> void:
	for slot in range(1, SaveManager.SAVE_SLOT_COUNT + 1):
		var path = SAVE_DIR.path_join(SaveManager.get_save_file_name(slot))
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func write_full_capture_saves() -> void:
	for slot in range(1, SaveManager.SAVE_SLOT_COUNT + 1):
		var character_id = "vampire" if slot == 2 else "base"
		var level_data = {
			"floor_number": slot,
			"path": "elite" if slot == 3 else "normal"
		}
		var save_data = RunState.make_save_data(
			"0.1.4",
			character_id,
			slot,
			level_data,
			{"x": 7 + slot, "y": 5 + slot},
			{
				"hp": 72 + slot * 5,
				"max_hp": 100,
				"attack": 10 + slot,
				"defense": 2 + slot,
				"name": "Вампир" if character_id == "vampire" else "Герой",
				"passives": []
			},
			48 * slot,
			["wooden_sword", "vitality_ring"],
			{"weapon": "iron_sword" if slot > 1 else "wooden_sword", "armor": "", "accessory": "vitality_ring"},
			make_defeated_enemies(slot)
		)
		if not SaveManager.write_save_slot(slot, save_data):
			fail_capture("Failed to write capture save slot %d" % slot)
			return

func make_defeated_enemies(count: int) -> Dictionary:
	var defeated = {}
	for index in range(count):
		defeated["review_enemy_%d" % index] = true
	return defeated

func capture_scene(scene_path: String, capture_name: String) -> void:
	var scene = load(scene_path).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	await settle_capture_frame()
	save_viewport("%s/%s.png" % [capture_dir, capture_name])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_load_delete_dialog() -> void:
	var scene = load(ScenePaths.LOAD_MENU).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.show_delete_confirmation(2)
	await process_frame
	await process_frame
	await settle_capture_frame()
	save_viewport("%s/load_delete_dialog.png" % capture_dir)
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_character_selected(character_id: String, capture_name: String) -> void:
	var scene = load(ScenePaths.CHARACTER_SELECT).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.pending_character_id = character_id
	scene.refresh_character_selection()
	await process_frame
	await settle_capture_frame()
	save_viewport("%s/%s.png" % [capture_dir, capture_name])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_character_overwrite_dialog() -> void:
	await capture_character_overwrite_dialog_for("base", "character_overwrite_dialog")

func capture_character_overwrite_dialog_for(character_id: String, capture_name: String) -> void:
	var slot_path = SaveManager.get_save_path(1)
	var before_text = read_text(slot_path)
	var scene = load(ScenePaths.CHARACTER_SELECT).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.start_character_game(character_id)
	await process_frame
	scene._on_overwrite_slot_pressed(1)
	await process_frame
	await process_frame
	var after_text = read_text(slot_path)
	if before_text != after_text:
		fail_capture("Overwrite happened before confirmation.")
		return
	await settle_capture_frame()
	save_viewport("%s/%s.png" % [capture_dir, capture_name])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_result_case(capture_name: String, summary: Dictionary) -> void:
	var game_state = root.get_node("GameState")
	game_state.completed_run_summary = summary
	var scene = load(ScenePaths.RESULT_SCREEN).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	await settle_capture_frame()
	save_viewport("%s/%s.png" % [capture_dir, capture_name])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func capture_death_case(character_id: String, capture_name: String, full_run: bool = false) -> void:
	var game_state = root.get_node("GameState")
	game_state.selected_character_id = character_id
	game_state.current_floor = 3 if full_run else 2
	game_state.gold = 176 if full_run else 64
	game_state.defeated_enemies = make_defeated_enemies(12 if full_run else 4)
	game_state.player_stats = game_state.get_character_stats(character_id)
	if full_run:
		game_state.equipment = {
			"weapon": "steel_sword",
			"armor": "plate_armor",
			"accessory": "ancient_amulet"
		}
		game_state.inventory = ["wooden_sword", "iron_sword", "chainmail", "vitality_ring"]
	else:
		game_state.equipment = game_state.DEFAULT_EQUIPMENT.duplicate()
		game_state.inventory = []
	var scene = load(ScenePaths.DEATH_SCREEN).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	await settle_capture_frame()
	save_viewport("%s/%s.png" % [capture_dir, capture_name])
	root.remove_child(scene)
	scene.queue_free()
	await process_frame

func settle_capture_frame() -> void:
	var callback = Callable(self, "_on_frame_post_draw")
	if RenderingServer.frame_post_draw.is_connected(callback):
		RenderingServer.frame_post_draw.disconnect(callback)
	did_post_draw = false
	RenderingServer.frame_post_draw.connect(callback, CONNECT_ONE_SHOT)
	for _index in range(MAX_POST_DRAW_WAIT_FRAMES):
		await process_frame
		if did_post_draw:
			return
	if RenderingServer.frame_post_draw.is_connected(callback):
		RenderingServer.frame_post_draw.disconnect(callback)
	if DisplayServer.get_name().to_lower() != "headless":
		push_warning("Timed out waiting for frame_post_draw before shell review capture.")

func _on_frame_post_draw() -> void:
	did_post_draw = true

func make_result_summary(character_name: String, path_label: String, floor_number: int, gold: int, defeated_count: int, has_equipment: bool) -> Dictionary:
	var equipment = []
	if has_equipment:
		equipment = [
			"Оружие: Стальной меч",
			"Броня: Пластинчатая броня",
			"Аксессуар: Древний амулет"
		]
	return {
		"character": character_name,
		"path": path_label,
		"floor": floor_number,
		"max_floor": 3,
		"gold": gold,
		"defeated_enemies": defeated_count,
		"equipment": equipment
	}

func read_text(path: String) -> String:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_as_text()

func verify_required_capture_files() -> void:
	for file_name in REQUIRED_CAPTURE_FILES:
		verify_png_capture(file_name)
		if has_failed:
			return

func verify_png_capture(file_name: String) -> void:
	var path = capture_dir.path_join(file_name)
	if not FileAccess.file_exists(path):
		fail_capture("Missing required shell review capture: %s" % path)
		return
	var image = Image.load_from_file(path)
	if image == null or image.is_empty():
		fail_capture("Invalid shell review PNG capture: %s" % path)
		return

func save_viewport(path: String) -> void:
	var texture = root.get_texture()
	if texture == null:
		fail_capture("Could not read shell review viewport texture: %s" % path)
		return
	var image = texture.get_image()
	if image == null or image.is_empty():
		fail_capture("Could not read shell review viewport image: %s" % path)
		return
	var error = image.save_png(path)
	if error != OK or not FileAccess.file_exists(path):
		fail_capture("Failed to save shell review capture: %s" % path)
		return
	print(path)

func fail_capture(message: String) -> void:
	if has_failed:
		return
	has_failed = true
	push_error(message)
	quit(1)

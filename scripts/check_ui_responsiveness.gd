extends SceneTree

const ScenePaths = preload("res://scripts/scene_paths.gd")
const SaveManager = preload("res://scripts/save_manager.gd")

const DEFAULT_SAVE_DIR = "/private/tmp/rpg_ui_responsiveness_check"
const VIEWPORT_SIZES = [
	Vector2i(960, 540),
	Vector2i(1280, 720)
]
const SCENES = [
	{"label": "main menu", "path": ScenePaths.MAIN_MENU, "nodes": ["Title", "MenuPanel"]},
	{"label": "character select", "path": ScenePaths.CHARACTER_SELECT, "nodes": ["Content", "BackButton"]},
	{"label": "load menu", "path": ScenePaths.LOAD_MENU, "nodes": ["Content", "BackButton"]},
	{"label": "death screen", "path": ScenePaths.DEATH_SCREEN, "nodes": ["Content"]},
	{"label": "result screen", "path": ScenePaths.RESULT_SCREEN, "nodes": ["Content"]},
	{"label": "inventory", "path": "res://scenes/ui/inventory_ui.tscn", "nodes": ["Window"]}
]

var failures: Array = []

func _init() -> void:
	call_deferred("run")

func run() -> void:
	configure_isolated_save_dir()
	prepare_game_state()
	for viewport_size in VIEWPORT_SIZES:
		for scene_data in SCENES:
			await validate_scene_at_viewport(scene_data, viewport_size)

	if failures.is_empty():
		print("UI responsiveness check passed for %d sizes and %d scenes." % [VIEWPORT_SIZES.size(), SCENES.size()])
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func configure_isolated_save_dir() -> void:
	ProjectSettings.set_setting(SaveManager.SAVE_DIR_SETTING, DEFAULT_SAVE_DIR)
	SaveManager.ensure_save_dir_exists()
	for slot in range(1, SaveManager.SAVE_SLOT_COUNT + 1):
		SaveManager.delete_save_slot(slot)
		remove_if_exists("%s.tmp" % SaveManager.get_save_path(slot))
		remove_if_exists("%s.bak" % SaveManager.get_save_path(slot))

func prepare_game_state() -> void:
	if not root.has_node("GameState"):
		return
	var game_state = root.get_node("GameState")
	game_state.active_save_slot = 0
	game_state.selected_character_id = "base"
	game_state.current_floor = 2
	game_state.gold = 123
	game_state.defeated_enemies = {"ui_enemy_1": true, "ui_enemy_2": true}
	game_state.inventory = ["wooden_sword", "leather_chestpiece", "vitality_ring"]
	game_state.equipment = {
		"weapon": "iron_sword",
		"armor": "chainmail",
		"accessory": "ancient_amulet"
	}
	game_state.level_data = game_state.generate_level_data(2, game_state.FLOOR_PATH_NORMAL, 2302)
	game_state.player_grid_pos = game_state.level_data.get("start_position", game_state.START_GRID_POS).duplicate()
	game_state.player_stats = game_state.get_character_stats("base")

func validate_scene_at_viewport(scene_data: Dictionary, viewport_size: Vector2i) -> void:
	var label = str(scene_data.get("label", "unknown"))
	var path = str(scene_data.get("path", ""))
	var packed_scene = load(path)
	if packed_scene == null or not packed_scene is PackedScene:
		failures.append("%s: failed to load %s" % [label, path])
		return

	var test_viewport = SubViewport.new()
	test_viewport.size = viewport_size
	test_viewport.disable_3d = true
	root.add_child(test_viewport)
	await process_frame

	var instance = packed_scene.instantiate()
	if instance == null:
		failures.append("%s: failed to instantiate %s" % [label, path])
		test_viewport.queue_free()
		return

	if instance is Control:
		var control_root = instance as Control
		control_root.set_anchors_preset(Control.PRESET_FULL_RECT)

	test_viewport.add_child(instance)
	await process_frame
	await process_frame

	for node_path in scene_data.get("nodes", []):
		validate_control_rect(instance, label, str(node_path), viewport_size)

	test_viewport.remove_child(instance)
	instance.free()
	root.remove_child(test_viewport)
	test_viewport.free()
	await process_frame

func validate_control_rect(scene: Node, label: String, node_path: String, viewport_size: Vector2i) -> void:
	var node = scene.get_node_or_null(node_path)
	if node == null:
		failures.append("%s: missing node %s" % [label, node_path])
		return
	if not node is Control:
		failures.append("%s: node %s is not Control" % [label, node_path])
		return

	var control = node as Control
	var rect = get_transformed_control_rect(control)
	var viewport_rect = Rect2(Vector2.ZERO, Vector2(viewport_size))
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		failures.append("%s: node %s has empty rect at %s" % [label, node_path, viewport_size])
		return
	if not viewport_rect.grow(1.0).encloses(rect):
		failures.append("%s: node %s escapes viewport %s with rect %s" % [label, node_path, viewport_size, rect])

func get_transformed_control_rect(control: Control) -> Rect2:
	var transform = control.get_global_transform()
	var corners = [
		Vector2.ZERO,
		Vector2(control.size.x, 0.0),
		Vector2(0.0, control.size.y),
		control.size
	]
	var min_pos = transform * corners[0]
	var max_pos = min_pos
	for corner in corners:
		var point = transform * corner
		min_pos.x = min(min_pos.x, point.x)
		min_pos.y = min(min_pos.y, point.y)
		max_pos.x = max(max_pos.x, point.x)
		max_pos.y = max(max_pos.y, point.y)
	return Rect2(min_pos, max_pos - min_pos)

func remove_if_exists(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

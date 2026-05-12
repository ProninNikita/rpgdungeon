extends SceneTree

const ScenePaths = preload("res://scripts/scene_paths.gd")

const SCENES = [
	{"label": "main menu", "path": ScenePaths.MAIN_MENU},
	{"label": "character select", "path": ScenePaths.CHARACTER_SELECT},
	{"label": "load menu", "path": ScenePaths.LOAD_MENU},
	{"label": "main level", "path": ScenePaths.MAIN_LEVEL},
	{"label": "inventory", "path": "res://scenes/ui/inventory_ui.tscn"},
	{"label": "battle", "path": ScenePaths.BATTLE},
	{"label": "death screen", "path": ScenePaths.DEATH_SCREEN},
	{"label": "result screen", "path": ScenePaths.RESULT_SCREEN}
]

var failures: Array = []

func _init() -> void:
	call_deferred("run")

func run() -> void:
	prepare_game_state()

	for scene_data in SCENES:
		await validate_scene_load(scene_data)

	if failures.is_empty():
		print("Scene load smoke check passed for %d scenes." % SCENES.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func prepare_game_state() -> void:
	if not root.has_node("GameState"):
		return

	var game_state = root.get_node("GameState")
	game_state.active_save_slot = 0
	game_state.selected_character_id = "base"
	game_state.current_floor = 1
	game_state.current_enemy_id = "level_enemy_01"
	game_state.defeated_enemies.clear()
	game_state.gold = 0
	game_state.inventory.clear()
	game_state.equipment = game_state.DEFAULT_EQUIPMENT.duplicate()
	game_state.level_data = game_state.generate_level_data(1, game_state.FLOOR_PATH_NORMAL)
	game_state.player_grid_pos = game_state.level_data.get("start_position", game_state.START_GRID_POS).duplicate()
	game_state.player_stats = game_state.get_character_stats("base")

func validate_scene_load(scene_data: Dictionary) -> void:
	var label = str(scene_data.get("label", "unknown"))
	var path = str(scene_data.get("path", ""))
	var packed_scene = load(path)
	if packed_scene == null:
		failures.append("%s: failed to load %s" % [label, path])
		return
	if not packed_scene is PackedScene:
		failures.append("%s: resource is not a PackedScene at %s" % [label, path])
		return

	var instance = packed_scene.instantiate()
	if instance == null:
		failures.append("%s: failed to instantiate %s" % [label, path])
		return

	if label == "battle":
		instance.is_battle_active = false

	root.add_child(instance)
	if label == "battle":
		await create_timer(1.6).timeout
	else:
		await process_frame

	if not is_instance_valid(instance):
		failures.append("%s: scene freed itself during smoke load" % label)
		return

	root.remove_child(instance)
	instance.free()
	await process_frame

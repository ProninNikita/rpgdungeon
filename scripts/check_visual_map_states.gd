extends SceneTree

const ScenePaths = preload("res://scripts/scene_paths.gd")

const CASES = [
	{"floor": 1, "path": "normal", "seed": 1301, "variant": "crypt"},
	{"floor": 2, "path": "normal", "seed": 2302, "variant": "moss"},
	{"floor": 2, "path": "elite", "seed": 3303, "variant": "ember"}
]

var failures: Array = []
var game_state: Node

func _init() -> void:
	call_deferred("run")

func run() -> void:
	if not root.has_node("GameState"):
		failures.append("GameState autoload is not available.")
	else:
		game_state = root.get_node("GameState")
		for visual_case in CASES:
			await validate_visual_case(visual_case)

	if failures.is_empty():
		print("Visual map state check passed for %d variants." % CASES.size())
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func validate_visual_case(visual_case: Dictionary) -> void:
	prepare_game_state(visual_case)
	var scene = load(ScenePaths.MAIN_LEVEL).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	mark_current_floor_cleared()
	scene.rebuild_interactables()
	await process_frame

	var context = "floor %d path %s" % [int(visual_case["floor"]), str(visual_case["path"])]
	assert_true(str(scene.map_variant) == str(visual_case["variant"]), "%s uses %s map variant" % [context, str(visual_case["variant"])])
	assert_node_exists(scene, "GeneratedFloors", context)
	assert_node_exists(scene, "GeneratedFloorDecorations", context)
	assert_node_exists(scene, "GeneratedProps", context)
	assert_node_exists(scene, "GeneratedFloorEdges", context)
	assert_node_exists(scene, "GeneratedWalls", context)
	assert_node_exists(scene, "GeneratedInteractables", context)
	assert_node_exists(scene, "LightingOverlay", context)
	assert_node_exists(scene, "AtmosphereParticles", context)
	assert_node_exists(scene, "InteractionHighlight", context)

	assert_true(scene.floor_positions.size() == game_state.level_data.get("floor_tiles", []).size(), "%s registers all floor tiles" % context)
	assert_true(scene.local_light_positions.size() > 0, "%s registers local object lights" % context)
	assert_true(scene.interactable_hints.size() > 0, "%s registers contextual object hints" % context)
	assert_true(not str(scene.legend_label.text).contains("Артефакт   $"), "%s no longer uses the old symbol legend" % context)

	root.remove_child(scene)
	scene.queue_free()
	scene = null
	await process_frame
	await process_frame
	await process_frame

func prepare_game_state(visual_case: Dictionary) -> void:
	game_state.active_save_slot = 0
	game_state.selected_character_id = "base"
	game_state.current_floor = int(visual_case["floor"])
	game_state.current_enemy_id = ""
	game_state.defeated_enemies.clear()
	game_state.gold = 0
	game_state.inventory.clear()
	game_state.equipment = game_state.DEFAULT_EQUIPMENT.duplicate()
	game_state.level_data = game_state.generate_level_data(
		int(visual_case["floor"]),
		str(visual_case["path"]),
		int(visual_case["seed"])
	)
	game_state.player_grid_pos = game_state.level_data.get("start_position", game_state.START_GRID_POS).duplicate()
	game_state.player_stats = game_state.get_character_stats("base")

func mark_current_floor_cleared() -> void:
	for enemy_encounter in game_state.level_data.get("enemies", []):
		game_state.defeated_enemies[str(enemy_encounter.get("id", ""))] = true

func assert_node_exists(scene: Node, node_name: String, context: String) -> void:
	assert_true(scene.get_node_or_null(node_name) != null, "%s creates %s" % [context, node_name])

func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

extends Node2D

const ScenePaths = preload("res://scripts/scene_paths.gd")
const ResultData = preload("res://scripts/result_data.gd")
const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")
const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")
const ROOM_WIDTH = 16
const ROOM_HEIGHT = 16
const TILE_SIZE = 32
const MAX_LOCAL_LIGHTS = 6
const MAP_CAMERA_ZOOM = 2.0
const LIGHTING_SHADER_CODE = """
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 dark_color : source_color = vec4(0.010, 0.009, 0.014, 0.62);
uniform vec2 player_uv = vec2(0.5, 0.5);
uniform float player_radius = 0.24;
uniform float local_light_radius = 0.105;
uniform float vignette_strength = 0.20;
uniform int light_count = 0;
uniform vec2 light_0 = vec2(-1.0, -1.0);
uniform vec2 light_1 = vec2(-1.0, -1.0);
uniform vec2 light_2 = vec2(-1.0, -1.0);
uniform vec2 light_3 = vec2(-1.0, -1.0);
uniform vec2 light_4 = vec2(-1.0, -1.0);
uniform vec2 light_5 = vec2(-1.0, -1.0);

float radial_light(vec2 uv, vec2 center, float radius) {
	float d = distance(uv, center);
	return smoothstep(radius, radius * 0.36, d);
}

void fragment() {
	float light = radial_light(UV, player_uv, player_radius);
	if (light_count > 0) {
		light = max(light, radial_light(UV, light_0, local_light_radius));
	}
	if (light_count > 1) {
		light = max(light, radial_light(UV, light_1, local_light_radius));
	}
	if (light_count > 2) {
		light = max(light, radial_light(UV, light_2, local_light_radius));
	}
	if (light_count > 3) {
		light = max(light, radial_light(UV, light_3, local_light_radius));
	}
	if (light_count > 4) {
		light = max(light, radial_light(UV, light_4, local_light_radius));
	}
	if (light_count > 5) {
		light = max(light, radial_light(UV, light_5, local_light_radius));
	}

	float vignette = smoothstep(0.32, 0.76, distance(UV, vec2(0.5, 0.5))) * vignette_strength;
	float alpha = clamp(dark_color.a + vignette - light * 0.48, 0.0, 0.82);
	COLOR = vec4(dark_color.rgb, alpha);
}
"""
const INTERACTION_HIGHLIGHT_SHADER_CODE = """
shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform vec4 highlight_color : source_color = vec4(1.0, 0.72, 0.24, 0.82);
uniform float pulse = 0.0;

void fragment() {
	vec2 edge = min(UV, vec2(1.0) - UV);
	float edge_distance = min(edge.x, edge.y);
	float horizontal_line = 1.0 - smoothstep(0.030, 0.070, edge.y);
	float vertical_line = 1.0 - smoothstep(0.030, 0.070, edge.x);
	float corner_x = max(1.0 - smoothstep(0.20, 0.34, UV.x), smoothstep(0.66, 0.80, UV.x));
	float corner_y = max(1.0 - smoothstep(0.20, 0.34, UV.y), smoothstep(0.66, 0.80, UV.y));
	float border = max(horizontal_line * corner_x, vertical_line * corner_y);
	float glow = 1.0 - smoothstep(0.08, 0.42, edge_distance);
	float wave = 0.68 + 0.32 * sin(pulse * 4.0);
	float center_breath = (1.0 - smoothstep(0.12, 0.48, distance(UV, vec2(0.5)))) * 0.18 * wave;
	float alpha = border * 0.70 + glow * 0.12 * wave + center_breath;
	COLOR = vec4(highlight_color.rgb, alpha * highlight_color.a);
}
"""

var floor_positions: Dictionary = {}
var wall_positions: Dictionary = {}
var prop_positions: Dictionary = {}
var floors_container: Node2D
var decorations_container: Node2D
var props_container: Node2D
var floor_edges_container: Node2D
var walls_container: Node2D
var wall_decorations_container: Node2D
var enemies_container: Node2D
var interactables_container: Node2D
var lighting_overlay: ColorRect
var lighting_material: ShaderMaterial
var local_light_positions: Array[Vector2] = []
var interaction_highlight: ColorRect
var interaction_highlight_material: ShaderMaterial
var atmosphere_particles: CPUParticles2D
var interactable_hints: Dictionary = {}
var message_sequence: int = 0
var enemy_scene: PackedScene = load(ScenePaths.ENEMY)
var map_variant: String = PixelAssetPaths.MAP_VARIANT
var choice_panel: Panel
var choice_title: Label
var choice_message: Label
var choice_buttons: Array = []
var choice_cancel_button: Button
var pending_choice_room_id: String = ""
var pending_exit_id: String = ""

@onready var player = $Player
@onready var camera = $Player/Camera2D
@onready var inventory_ui = $UI/InventoryUI
@onready var floor_label = $UI/Hud/HudContent/FloorLabel
@onready var path_label = $UI/Hud/HudContent/PathLabel
@onready var gold_label = $UI/Hud/HudContent/GoldLabel
@onready var enemies_label = $UI/Hud/HudContent/EnemiesLabel
@onready var legend_label = $UI/Hud/HudContent/LegendLabel
@onready var message_panel = $UI/MessagePanel
@onready var message_label = $UI/MessagePanel/MessageLabel

func _ready():
	RenderingServer.set_default_clear_color(Color(0.010, 0.010, 0.013, 1.0))
	inventory_ui.inventory_toggled.connect(_on_inventory_toggled)
	create_choice_panel()
	layout_overlay_panels()
	configure_map_camera()
	GameState.ensure_level_data()
	if GameState.is_run_complete():
		GameState.complete_run()
		get_tree().call_deferred("change_scene_to_file", ScenePaths.RESULT_SCREEN)
		return
	apply_map_ui_style()
	build_level()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and message_panel != null:
		layout_overlay_panels()
		configure_map_camera()

func layout_overlay_panels() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	$UI/Hud.position = Vector2(16.0, 16.0)
	$UI/Hud.size = Vector2(248.0, 106.0)
	$UI/Hud/HudContent.position = Vector2(10.0, 8.0)
	$UI/Hud/HudContent.size = Vector2(228.0, 90.0)
	var panel_width = min(484.0, max(320.0, viewport_size.x - 360.0))
	message_panel.position = Vector2(min(336.0, max(16.0, viewport_size.x - panel_width - 16.0)), 16.0)
	message_panel.size = Vector2(panel_width, 54.0)
	message_label.position = Vector2(12.0, 8.0)
	message_label.size = Vector2(panel_width - 24.0, 38.0)
	if choice_panel != null:
		choice_panel.position = Vector2(message_panel.position.x, 92.0)
		choice_panel.size = Vector2(panel_width, 214.0)

func apply_map_ui_style() -> void:
	apply_panel_style($UI/Hud, Color(0.032, 0.027, 0.025, 0.84), Color(0.36, 0.26, 0.17, 0.90))
	apply_panel_style(message_panel, Color(0.038, 0.032, 0.030, 0.94), Color(0.48, 0.36, 0.22, 1.0))
	if choice_panel != null:
		apply_panel_style(choice_panel, Color(0.040, 0.033, 0.030, 0.96), Color(0.54, 0.39, 0.24, 1.0))
	$UI/Hud/HudContent.add_theme_constant_override("separation", 2)
	apply_label_style(floor_label, Color(0.91, 0.84, 0.72, 1.0), 14)
	apply_label_style(path_label, Color(0.68, 0.63, 0.55, 1.0), 12)
	apply_label_style(gold_label, Color(0.96, 0.74, 0.28, 1.0), 13)
	apply_label_style(enemies_label, Color(0.84, 0.62, 0.52, 1.0), 13)
	apply_label_style(legend_label, Color(0.62, 0.78, 0.68, 1.0), 12)
	apply_label_style(message_label, Color(0.91, 0.86, 0.76, 1.0), 15)
	apply_label_style(choice_title, Color(0.95, 0.78, 0.45, 1.0), 18)
	apply_label_style(choice_message, Color(0.88, 0.82, 0.72, 1.0), 14)
	for button in choice_buttons:
		apply_button_style(button)
	apply_button_style(choice_cancel_button)

func apply_panel_style(panel: Panel, background_color: Color, border_color: Color) -> void:
	if panel == null:
		return
	var style = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

func apply_label_style(label: Label, color: Color, font_size: int) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.018, 0.015, 0.014, 1.0))
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_font_size_override("font_size", font_size)

func apply_button_style(button: Button) -> void:
	if button == null:
		return
	button.add_theme_color_override("font_color", Color(0.92, 0.84, 0.70, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.66, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.70, 0.95, 0.78, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.42, 0.39, 0.35, 1.0))
	button.add_theme_stylebox_override("normal", create_button_style(Color(0.10, 0.075, 0.055, 0.96), Color(0.40, 0.28, 0.17, 1.0)))
	button.add_theme_stylebox_override("hover", create_button_style(Color(0.16, 0.105, 0.065, 0.98), Color(0.70, 0.47, 0.24, 1.0)))
	button.add_theme_stylebox_override("pressed", create_button_style(Color(0.07, 0.09, 0.065, 1.0), Color(0.54, 0.70, 0.46, 1.0)))
	button.add_theme_stylebox_override("disabled", create_button_style(Color(0.055, 0.050, 0.048, 0.86), Color(0.22, 0.20, 0.18, 1.0)))

func create_button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 8
	style.content_margin_top = 5
	style.content_margin_right = 8
	style.content_margin_bottom = 5
	return style

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		inventory_ui.toggle()
		get_viewport().set_input_as_handled()

func _on_inventory_toggled(is_open: bool) -> void:
	player.input_locked = is_open

func _process(_delta: float) -> void:
	update_lighting_overlay()
	update_interaction_feedback()

func build_level() -> void:
	floor_positions.clear()
	wall_positions.clear()
	prop_positions.clear()
	local_light_positions.clear()
	interactable_hints.clear()
	map_variant = get_level_map_variant()
	$Background.z_index = -100
	$Background.position = Vector2(-ROOM_WIDTH * TILE_SIZE, -ROOM_HEIGHT * TILE_SIZE)
	$Background.size = Vector2(ROOM_WIDTH * TILE_SIZE * 3.0, ROOM_HEIGHT * TILE_SIZE * 3.0)
	$Background.color = get_world_backdrop_color()
	player.z_index = 20

	floors_container = Node2D.new()
	floors_container.name = "GeneratedFloors"
	floors_container.z_index = -10
	add_child(floors_container)

	decorations_container = Node2D.new()
	decorations_container.name = "GeneratedFloorDecorations"
	decorations_container.z_index = -9
	add_child(decorations_container)

	props_container = Node2D.new()
	props_container.name = "GeneratedProps"
	props_container.z_index = -7
	add_child(props_container)

	floor_edges_container = Node2D.new()
	floor_edges_container.name = "GeneratedFloorEdges"
	floor_edges_container.z_index = -8
	add_child(floor_edges_container)

	walls_container = Node2D.new()
	walls_container.name = "GeneratedWalls"
	walls_container.z_index = -5
	add_child(walls_container)

	wall_decorations_container = Node2D.new()
	wall_decorations_container.name = "GeneratedWallDecorations"
	wall_decorations_container.z_index = -4
	add_child(wall_decorations_container)

	enemies_container = Node2D.new()
	enemies_container.name = "GeneratedEnemies"
	enemies_container.z_index = 10
	add_child(enemies_container)

	interactables_container = Node2D.new()
	interactables_container.name = "GeneratedInteractables"
	interactables_container.z_index = 8
	add_child(interactables_container)

	place_player()
	build_floors()
	build_floor_decorations()
	build_floor_edges()
	build_room_scene_props()
	build_environment_props()
	build_walls()
	build_wall_decorations()
	spawn_enemies()
	build_interactables()
	create_lighting_overlay()
	create_atmosphere_particles()
	create_interaction_highlight()
	update_hud()
	if GameState.is_level_cleared():
		show_map_message("Этаж зачищен. Сундук и выходы доступны.")

func configure_map_camera() -> void:
	if camera == null:
		return
	camera.zoom = Vector2(MAP_CAMERA_ZOOM, MAP_CAMERA_ZOOM)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = ROOM_WIDTH * TILE_SIZE
	camera.limit_bottom = ROOM_HEIGHT * TILE_SIZE
	camera.limit_smoothed = false
	camera.position_smoothing_enabled = false

func get_world_backdrop_color() -> Color:
	if map_variant == "ember":
		return Color(0.035, 0.006, 0.003, 1.0)
	if map_variant == "moss":
		return Color(0.004, 0.018, 0.014, 1.0)
	return Color(0.006, 0.007, 0.012, 1.0)

func place_player() -> void:
	if player != null and player.has_method("set_grid_position"):
		if player.has_method("set_map_variant"):
			player.set_map_variant(map_variant)
		player.set_grid_position(GameState.get_player_grid_position())

func build_floors() -> void:
	for floor_data in GameState.level_data.get("floor_tiles", []):
		var grid_pos = Vector2i(floor_data["x"], floor_data["y"])
		floor_positions[get_grid_key(grid_pos)] = true

		var floor_tile = ColorRect.new()
		floor_tile.position = grid_pos * TILE_SIZE
		floor_tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		floor_tile.color = get_floor_tile_color(floor_data)
		floors_container.add_child(floor_tile)

		var floor_sprite = Sprite2D.new()
		floor_sprite.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		floor_sprite.texture = get_floor_tile_texture(floor_data)
		floor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		floors_container.add_child(floor_sprite)

func get_floor_tile_color(floor_data: Dictionary) -> Color:
	var room_type = str(floor_data.get("room_type", ""))
	if room_type == DungeonGenerator.ROOM_TYPE_ARTIFACT:
		return Color(0.62, 0.46, 0.12, 1)
	if room_type == DungeonGenerator.ROOM_TYPE_SHOP:
		return Color(0.34, 0.21, 0.12, 1)
	return Color(0.14, 0.14, 0.18, 1)

func get_floor_tile_texture(floor_data: Dictionary) -> Texture2D:
	var room_type = str(floor_data.get("room_type", ""))
	var grid_pos = Vector2i(int(floor_data.get("x", 0)), int(floor_data.get("y", 0)))
	if room_type == DungeonGenerator.ROOM_TYPE_ARTIFACT and should_use_room_accent_tile(grid_pos, 7):
		return PixelAssetPaths.map_texture("artifact_floor", map_variant)
	if room_type == DungeonGenerator.ROOM_TYPE_SHOP and should_use_room_accent_tile(grid_pos, 6):
		return PixelAssetPaths.map_texture("shop_floor", map_variant)
	return PixelAssetPaths.map_texture(get_floor_variant_name(grid_pos), map_variant)

func get_floor_variant_name(grid_pos: Vector2i) -> String:
	var variant_index = get_tile_hash(grid_pos) % 4
	if variant_index == 0:
		return "floor"
	return "floor_%d" % variant_index

func should_use_room_accent_tile(grid_pos: Vector2i, spacing: int) -> bool:
	return get_tile_hash(grid_pos) % spacing == 0

func build_floor_decorations() -> void:
	for floor_data in GameState.level_data.get("floor_tiles", []):
		var grid_pos = Vector2i(floor_data["x"], floor_data["y"])
		var detail_name = get_floor_detail_name(grid_pos, floor_data)
		if detail_name.is_empty():
			continue

		var detail_sprite = Sprite2D.new()
		detail_sprite.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		detail_sprite.texture = PixelAssetPaths.map_texture(detail_name, map_variant)
		detail_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		decorations_container.add_child(detail_sprite)

func get_floor_detail_name(grid_pos: Vector2i, floor_data: Dictionary) -> String:
	if str(floor_data.get("room_type", "")).is_empty() == false:
		return ""
	var hash_value = get_tile_hash(grid_pos)
	var roll = hash_value % 100
	if roll < 5:
		return "detail_crack"
	if roll < 9:
		return "detail_rubble"
	if roll < 11:
		return "detail_accent"
	return ""

func build_environment_props() -> void:
	for floor_data in GameState.level_data.get("floor_tiles", []):
		var grid_pos = Vector2i(floor_data["x"], floor_data["y"])
		if not can_place_environment_prop(grid_pos, floor_data):
			continue
		var prop_name = get_environment_prop_name(grid_pos)
		if prop_name.is_empty():
			continue

		var prop = Sprite2D.new()
		prop.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		prop.texture = PixelAssetPaths.map_texture(prop_name, map_variant)
		prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		props_container.add_child(prop)
		prop_positions[get_grid_key(grid_pos)] = true

func can_place_environment_prop(grid_pos: Vector2i, floor_data: Dictionary) -> bool:
	if str(floor_data.get("room_type", "")).is_empty() == false:
		return false
	if prop_positions.has(get_grid_key(grid_pos)):
		return false
	if grid_pos == GameState.get_player_grid_position():
		return false
	if is_reserved_map_position(grid_pos):
		return false
	return true

func is_reserved_map_position(grid_pos: Vector2i) -> bool:
	for enemy_encounter in GameState.level_data.get("enemies", []):
		if Vector2i(int(enemy_encounter.get("x", -1)), int(enemy_encounter.get("y", -1))) == grid_pos:
			return true

	var chest_data = GameState.get_visible_chest()
	if not chest_data.is_empty() and Vector2i(int(chest_data.get("x", -1)), int(chest_data.get("y", -1))) == grid_pos:
		return true

	var fountain_data = GameState.get_visible_fountain()
	if not fountain_data.is_empty() and Vector2i(int(fountain_data.get("x", -1)), int(fountain_data.get("y", -1))) == grid_pos:
		return true

	for exit_data in GameState.get_visible_exits():
		if Vector2i(int(exit_data.get("x", -1)), int(exit_data.get("y", -1))) == grid_pos:
			return true

	for special_room in GameState.get_visible_special_rooms():
		if Vector2i(int(special_room.get("x", -1)), int(special_room.get("y", -1))) == grid_pos:
			return true

	return false

func get_environment_prop_name(grid_pos: Vector2i) -> String:
	var density = get_environment_prop_density(grid_pos)
	var roll = get_tile_hash(grid_pos) % 100
	if roll >= density:
		return ""
	var prop_index = (get_tile_hash(grid_pos + Vector2i(11, 17)) % 3)
	if map_variant == "ember":
		return ["prop_embers", "prop_lava_crack", "prop_scorched"][prop_index]
	if map_variant == "moss":
		return ["prop_roots", "prop_moss", "prop_puddle"][prop_index]
	return ["prop_bones", "prop_column", "prop_chain"][prop_index]

func get_environment_prop_density(grid_pos: Vector2i) -> int:
	var room = get_level_room_at_grid_pos(grid_pos)
	if room.is_empty():
		return 8
	var room_hash = get_room_hash(room)
	if room_hash % 5 == 0:
		return 26
	if room_hash % 3 == 0:
		return 18
	return 10

func build_room_scene_props() -> void:
	for room_index in range(GameState.level_data.get("rooms", []).size()):
		var room = GameState.level_data.get("rooms", [])[room_index]
		if typeof(room) != TYPE_DICTIONARY:
			continue
		if not str(room.get("room_type", "")).is_empty():
			continue
		var scene_name = get_room_scene_name(room, room_index)
		if scene_name.is_empty():
			continue
		var grid_pos = get_room_scene_position(room, room_index)
		if grid_pos == Vector2i(-1, -1):
			continue

		var prop = Sprite2D.new()
		prop.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		prop.texture = PixelAssetPaths.map_texture(scene_name, map_variant)
		prop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		props_container.add_child(prop)
		prop_positions[get_grid_key(grid_pos)] = true

func get_room_scene_name(room: Dictionary, room_index: int) -> String:
	var room_hash = get_room_hash(room) + room_index * 17
	if room_hash % 100 >= 42:
		return ""
	var scene_index = room_hash % 3
	if scene_index == 0:
		return "scene_altar"
	if scene_index == 1:
		return "scene_rubble"
	return "scene_ruined_corner"

func get_room_scene_position(room: Dictionary, room_index: int) -> Vector2i:
	var candidates = get_room_scene_candidates(room, room_index)
	for candidate in candidates:
		if is_floor_position(candidate) and can_place_scene_prop(candidate):
			return candidate
	return Vector2i(-1, -1)

func get_room_scene_candidates(room: Dictionary, room_index: int) -> Array:
	var x = int(room.get("x", 0))
	var y = int(room.get("y", 0))
	var width = int(room.get("width", 1))
	var height = int(room.get("height", 1))
	var candidates = [
		Vector2i(x + 1, y + 1),
		Vector2i(x + width - 2, y + 1),
		Vector2i(x + 1, y + height - 2),
		Vector2i(x + width - 2, y + height - 2),
		Vector2i(x + floori(width / 2.0), y + floori(height / 2.0))
	]
	var offset = room_index % candidates.size()
	var ordered = []
	for index in range(candidates.size()):
		ordered.append(candidates[(index + offset) % candidates.size()])
	return ordered

func can_place_scene_prop(grid_pos: Vector2i) -> bool:
	if prop_positions.has(get_grid_key(grid_pos)):
		return false
	if grid_pos == GameState.get_player_grid_position():
		return false
	if is_reserved_map_position(grid_pos):
		return false
	return true

func is_floor_position(grid_pos: Vector2i) -> bool:
	return floor_positions.has(get_grid_key(grid_pos))

func get_level_room_at_grid_pos(grid_pos: Vector2i) -> Dictionary:
	for room in GameState.level_data.get("rooms", []):
		if typeof(room) != TYPE_DICTIONARY:
			continue
		var x = int(room.get("x", 0))
		var y = int(room.get("y", 0))
		var width = int(room.get("width", 0))
		var height = int(room.get("height", 0))
		if grid_pos.x >= x and grid_pos.x < x + width and grid_pos.y >= y and grid_pos.y < y + height:
			return room
	return {}

func get_room_hash(room: Dictionary) -> int:
	return absi(
		int(room.get("x", 0)) * 92821
		+ int(room.get("y", 0)) * 68917
		+ int(room.get("width", 0)) * 31337
		+ int(room.get("height", 0)) * 27143
		+ int(GameState.level_data.get("floor_number", GameState.current_floor)) * 83492791
	)

func build_floor_edges() -> void:
	for floor_data in GameState.level_data.get("floor_tiles", []):
		var grid_pos = Vector2i(floor_data["x"], floor_data["y"])
		add_floor_edge_overlays(grid_pos)

func add_floor_edge_overlays(grid_pos: Vector2i) -> void:
	var origin = Vector2(grid_pos * TILE_SIZE)
	var top_open = not floor_positions.has(get_grid_key(grid_pos + Vector2i(0, -1)))
	var bottom_open = not floor_positions.has(get_grid_key(grid_pos + Vector2i(0, 1)))
	var left_open = not floor_positions.has(get_grid_key(grid_pos + Vector2i(-1, 0)))
	var right_open = not floor_positions.has(get_grid_key(grid_pos + Vector2i(1, 0)))
	if top_open:
		add_floor_edge_sprite(origin, "floor_edge_top")
	if bottom_open:
		add_floor_edge_sprite(origin, "floor_edge_bottom")
	if left_open:
		add_floor_edge_sprite(origin, "floor_edge_left")
	if right_open:
		add_floor_edge_sprite(origin, "floor_edge_right")

	if top_open and left_open:
		add_floor_edge_sprite(origin, "floor_corner_tl")
	if top_open and right_open:
		add_floor_edge_sprite(origin, "floor_corner_tr")
	if bottom_open and left_open:
		add_floor_edge_sprite(origin, "floor_corner_bl")
	if bottom_open and right_open:
		add_floor_edge_sprite(origin, "floor_corner_br")

func add_floor_edge_sprite(origin: Vector2, edge_name: String) -> void:
	var edge = Sprite2D.new()
	edge.position = origin + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	edge.texture = PixelAssetPaths.map_texture(edge_name, map_variant)
	edge.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	floor_edges_container.add_child(edge)

func build_walls() -> void:
	for wall_data in GameState.level_data.get("walls", []):
		var grid_pos = Vector2i(wall_data["x"], wall_data["y"])
		if not should_render_wall_tile(grid_pos):
			continue
		wall_positions[get_grid_key(grid_pos)] = true

		var wall = ColorRect.new()
		wall.position = grid_pos * TILE_SIZE
		wall.size = Vector2(TILE_SIZE, TILE_SIZE)
		wall.color = Color(0.018, 0.018, 0.024, 1)
		walls_container.add_child(wall)

		var wall_sprite = Sprite2D.new()
		wall_sprite.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		wall_sprite.texture = PixelAssetPaths.map_texture(get_wall_variant_name(grid_pos), map_variant)
		wall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		walls_container.add_child(wall_sprite)

func build_wall_decorations() -> void:
	for key in wall_positions.keys():
		var grid_pos = get_grid_pos_from_key(str(key))
		if not should_add_wall_breakup(grid_pos):
			continue
		add_wall_breakup(grid_pos)

func should_add_wall_breakup(grid_pos: Vector2i) -> bool:
	var horizontal = wall_positions.has(get_grid_key(grid_pos + Vector2i(-1, 0))) and wall_positions.has(get_grid_key(grid_pos + Vector2i(1, 0)))
	var vertical = wall_positions.has(get_grid_key(grid_pos + Vector2i(0, -1))) and wall_positions.has(get_grid_key(grid_pos + Vector2i(0, 1)))
	if not horizontal and not vertical:
		return false
	return get_tile_hash(grid_pos + Vector2i(31, 47)) % 100 < 18

func add_wall_breakup(grid_pos: Vector2i) -> void:
	var origin = Vector2(grid_pos * TILE_SIZE)
	var hash_value = get_tile_hash(grid_pos + Vector2i(53, 19))
	var line_count = 1 + hash_value % 2
	for index in range(line_count):
		var chip = ColorRect.new()
		var horizontal = hash_value % 3 != 0
		var length = 6.0 + float((hash_value + index * 7) % 8)
		if horizontal:
			chip.size = Vector2(length, 1.0)
			chip.position = origin + Vector2(5.0 + float((hash_value + index * 5) % 18), 8.0 + float((hash_value + index * 3) % 14))
		else:
			chip.size = Vector2(1.0, length)
			chip.position = origin + Vector2(8.0 + float((hash_value + index * 3) % 14), 5.0 + float((hash_value + index * 5) % 18))
		chip.color = get_wall_breakup_color()
		wall_decorations_container.add_child(chip)

func get_wall_breakup_color() -> Color:
	if map_variant == "ember":
		return Color(0.34, 0.10, 0.035, 0.52)
	if map_variant == "moss":
		return Color(0.07, 0.13, 0.085, 0.45)
	return Color(0.10, 0.12, 0.15, 0.46)

func should_render_wall_tile(grid_pos: Vector2i) -> bool:
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			if floor_positions.has(get_grid_key(grid_pos + Vector2i(offset_x, offset_y))):
				return true
	return false

func get_wall_variant_name(grid_pos: Vector2i) -> String:
	var top_floor = floor_positions.has(get_grid_key(grid_pos + Vector2i(0, -1)))
	var bottom_floor = floor_positions.has(get_grid_key(grid_pos + Vector2i(0, 1)))
	var left_floor = floor_positions.has(get_grid_key(grid_pos + Vector2i(-1, 0)))
	var right_floor = floor_positions.has(get_grid_key(grid_pos + Vector2i(1, 0)))
	if bottom_floor:
		return "wall_top"
	if top_floor:
		return "wall_bottom"
	if right_floor:
		return "wall_left"
	if left_floor:
		return "wall_right"

	if floor_positions.has(get_grid_key(grid_pos + Vector2i(1, 1))):
		return "wall_corner_tl"
	if floor_positions.has(get_grid_key(grid_pos + Vector2i(-1, 1))):
		return "wall_corner_tr"
	if floor_positions.has(get_grid_key(grid_pos + Vector2i(1, -1))):
		return "wall_corner_bl"
	if floor_positions.has(get_grid_key(grid_pos + Vector2i(-1, -1))):
		return "wall_corner_br"
	return "wall_%d" % ((get_tile_hash(grid_pos) % 2) + 1)

func get_tile_hash(grid_pos: Vector2i) -> int:
	var floor_number = int(GameState.level_data.get("floor_number", GameState.current_floor))
	return absi(grid_pos.x * 73856093 + grid_pos.y * 19349663 + floor_number * 83492791)

func spawn_enemies() -> void:
	for enemy_encounter in GameState.level_data.get("enemies", []):
		var enemy_id = enemy_encounter["id"]
		if GameState.is_enemy_defeated(enemy_id):
			continue

		var enemy = enemy_scene.instantiate()
		var grid_pos = Vector2i(enemy_encounter["x"], enemy_encounter["y"])
		enemy.name = "Enemy_%s" % enemy_id
		enemy.enemy_id = enemy_id
		enemy.enemy_type = str(enemy_encounter.get("type", "goblin"))
		enemy.grid_pos = grid_pos
		enemy.name_label = enemy_encounter.get("name", "Гоблин")
		if enemy.has_method("set_map_variant"):
			enemy.set_map_variant(map_variant)
		enemies_container.add_child(enemy)

func build_interactables() -> void:
	for special_room in GameState.get_visible_special_rooms():
		create_special_room_marker(special_room)

	var fountain_data = GameState.get_visible_fountain()
	if not fountain_data.is_empty():
		create_map_marker(Vector2i(fountain_data["x"], fountain_data["y"]), Color(0.2, 0.55, 0.9, 1), "marker_fountain")

	var chest_data = GameState.get_visible_chest()
	if not chest_data.is_empty():
		create_map_marker(Vector2i(chest_data["x"], chest_data["y"]), Color(0.85, 0.58, 0.16, 1), "marker_chest")

	for exit_data in GameState.get_visible_exits():
		var marker_name = "marker_elite" if exit_data.get("path", "") == "elite" else "marker_exit"
		var color = Color(0.8, 0.25, 0.25, 1) if exit_data.get("path", "") == "elite" else Color(0.2, 0.7, 0.35, 1)
		create_map_marker(Vector2i(exit_data["x"], exit_data["y"]), color, marker_name)

func create_special_room_marker(special_room: Dictionary) -> void:
	var room_type = str(special_room.get("type", ""))
	var color = Color(0.72, 0.52, 0.12, 1)
	if room_type == DungeonGenerator.ROOM_TYPE_SHOP:
		color = Color(0.45, 0.27, 0.13, 1)
	if bool(special_room.get("is_used", false)):
		color = Color(0.28, 0.28, 0.3, 1)
	var marker_name = "marker_shop" if room_type == DungeonGenerator.ROOM_TYPE_SHOP else "marker_artifact"
	if bool(special_room.get("is_used", false)):
		marker_name = "marker_used"
	create_map_marker(
		Vector2i(int(special_room.get("x", 0)), int(special_room.get("y", 0))),
		color,
		marker_name
	)

func create_map_marker(grid_pos: Vector2i, color: Color, marker_name: String) -> void:
	var sprite = Sprite2D.new()
	sprite.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	sprite.texture = PixelAssetPaths.map_texture(get_map_object_name(marker_name), map_variant)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	interactables_container.add_child(sprite)
	register_interactable_hint(grid_pos, marker_name, color)
	register_local_light(grid_pos, marker_name)

func get_map_object_name(marker_name: String) -> String:
	if marker_name == "marker_chest":
		return "object_chest"
	if marker_name == "marker_fountain":
		return "object_fountain"
	if marker_name == "marker_exit":
		return "object_exit"
	if marker_name == "marker_elite":
		return "object_elite_exit"
	if marker_name == "marker_shop":
		return "object_shop"
	if marker_name == "marker_artifact":
		return "object_artifact"
	if marker_name == "marker_used":
		return "object_used"
	return marker_name

func register_interactable_hint(grid_pos: Vector2i, marker_name: String, color: Color) -> void:
	interactable_hints[get_grid_key(grid_pos)] = {
		"grid_pos": grid_pos,
		"label": get_interactable_hint_text(marker_name),
		"color": get_interactable_highlight_color(marker_name, color),
		"marker_name": marker_name
	}

func get_interactable_hint_text(marker_name: String) -> String:
	if marker_name == "marker_chest":
		return "Сундук"
	if marker_name == "marker_fountain":
		return "Фонтан"
	if marker_name == "marker_exit":
		return "Выход"
	if marker_name == "marker_elite":
		return "Элитный выход"
	if marker_name == "marker_shop":
		return "Лавка"
	if marker_name == "marker_artifact":
		return "Артефакт"
	if marker_name == "marker_used":
		return "Использовано"
	return "Объект"

func get_interactable_highlight_color(marker_name: String, fallback_color: Color) -> Color:
	if marker_name == "marker_fountain":
		return Color(0.78, 0.86, 0.58, 0.58)
	if marker_name == "marker_exit":
		return Color(0.86, 0.78, 0.42, 0.62)
	if marker_name == "marker_elite":
		return Color(1.0, 0.42, 0.22, 0.66)
	if marker_name == "marker_used":
		return Color(0.46, 0.42, 0.36, 0.42)
	if fallback_color.a > 0.0:
		return Color(0.95, 0.66, 0.28, 0.68)
	return Color(0.95, 0.66, 0.28, 0.68)

func get_level_map_variant() -> String:
	var path_type = str(GameState.level_data.get("path", GameState.FLOOR_PATH_NORMAL))
	if path_type == GameState.FLOOR_PATH_ELITE:
		return "ember"
	var floor_number = int(GameState.level_data.get("floor_number", GameState.current_floor))
	if floor_number % 2 == 0:
		return "moss"
	return "crypt"

func register_local_light(grid_pos: Vector2i, marker_name: String) -> void:
	if marker_name == "marker_used" or local_light_positions.size() >= MAX_LOCAL_LIGHTS:
		return
	var level_size = Vector2(ROOM_WIDTH, ROOM_HEIGHT)
	local_light_positions.append((Vector2(grid_pos) + Vector2(0.5, 0.5)) / level_size)

func create_lighting_overlay() -> void:
	if lighting_overlay != null:
		lighting_overlay.queue_free()

	lighting_overlay = ColorRect.new()
	lighting_overlay.name = "LightingOverlay"
	lighting_overlay.position = Vector2.ZERO
	lighting_overlay.size = Vector2(ROOM_WIDTH * TILE_SIZE, ROOM_HEIGHT * TILE_SIZE)
	lighting_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lighting_overlay.z_index = 40

	var shader = Shader.new()
	shader.code = LIGHTING_SHADER_CODE
	lighting_material = ShaderMaterial.new()
	lighting_material.shader = shader
	lighting_overlay.material = lighting_material
	add_child(lighting_overlay)
	apply_lighting_variant_settings()
	update_lighting_local_lights()
	update_lighting_overlay()

func apply_lighting_variant_settings() -> void:
	if lighting_material == null:
		return
	if map_variant == "ember":
		lighting_material.set_shader_parameter("dark_color", Color(0.13, 0.045, 0.025, 0.55))
		lighting_material.set_shader_parameter("player_radius", 0.255)
		lighting_material.set_shader_parameter("local_light_radius", 0.12)
		lighting_material.set_shader_parameter("vignette_strength", 0.17)
	elif map_variant == "moss":
		lighting_material.set_shader_parameter("dark_color", Color(0.018, 0.052, 0.042, 0.64))
		lighting_material.set_shader_parameter("player_radius", 0.235)
		lighting_material.set_shader_parameter("local_light_radius", 0.105)
		lighting_material.set_shader_parameter("vignette_strength", 0.22)
	else:
		lighting_material.set_shader_parameter("dark_color", Color(0.012, 0.014, 0.026, 0.65))
		lighting_material.set_shader_parameter("player_radius", 0.225)
		lighting_material.set_shader_parameter("local_light_radius", 0.10)
		lighting_material.set_shader_parameter("vignette_strength", 0.24)

func update_lighting_local_lights() -> void:
	if lighting_material == null:
		return
	lighting_material.set_shader_parameter("light_count", local_light_positions.size())
	for index in range(MAX_LOCAL_LIGHTS):
		var light_position = Vector2(-1.0, -1.0)
		if index < local_light_positions.size():
			light_position = local_light_positions[index]
		lighting_material.set_shader_parameter("light_%d" % index, light_position)

func update_lighting_overlay() -> void:
	if lighting_material == null or player == null:
		return
	var level_size = Vector2(ROOM_WIDTH * TILE_SIZE, ROOM_HEIGHT * TILE_SIZE)
	var player_uv = player.position / level_size
	lighting_material.set_shader_parameter("player_uv", player_uv.clamp(Vector2.ZERO, Vector2.ONE))
	if map_variant == "ember":
		var flicker = sin(Time.get_ticks_msec() / 210.0) * 0.012
		lighting_material.set_shader_parameter("local_light_radius", 0.12 + flicker)
		lighting_material.set_shader_parameter("vignette_strength", 0.17 - flicker)

func create_atmosphere_particles() -> void:
	if atmosphere_particles != null:
		atmosphere_particles.queue_free()

	atmosphere_particles = CPUParticles2D.new()
	atmosphere_particles.name = "AtmosphereParticles"
	atmosphere_particles.position = Vector2(ROOM_WIDTH * TILE_SIZE / 2.0, ROOM_HEIGHT * TILE_SIZE / 2.0)
	atmosphere_particles.z_index = 42
	atmosphere_particles.amount = 28
	atmosphere_particles.lifetime = 7.0
	atmosphere_particles.preprocess = 7.0
	atmosphere_particles.speed_scale = 0.42
	atmosphere_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	atmosphere_particles.emission_rect_extents = Vector2(ROOM_WIDTH * TILE_SIZE / 2.0, ROOM_HEIGHT * TILE_SIZE / 2.0)
	atmosphere_particles.direction = Vector2(0.0, -1.0)
	atmosphere_particles.spread = 180.0
	atmosphere_particles.gravity = Vector2.ZERO
	atmosphere_particles.initial_velocity_min = 2.0
	atmosphere_particles.initial_velocity_max = 9.0
	atmosphere_particles.scale_amount_min = 0.65
	atmosphere_particles.scale_amount_max = 1.35
	atmosphere_particles.angular_velocity_min = -4.0
	atmosphere_particles.angular_velocity_max = 4.0
	atmosphere_particles.texture = create_atmosphere_particle_texture()
	apply_atmosphere_variant_settings()
	add_child(atmosphere_particles)
	atmosphere_particles.emitting = true

func apply_atmosphere_variant_settings() -> void:
	if atmosphere_particles == null:
		return
	if map_variant == "ember":
		atmosphere_particles.color = Color(0.95, 0.42, 0.16, 0.32)
		atmosphere_particles.amount = 34
		atmosphere_particles.speed_scale = 0.50
	elif map_variant == "moss":
		atmosphere_particles.color = Color(0.34, 0.72, 0.48, 0.24)
		atmosphere_particles.amount = 24
		atmosphere_particles.speed_scale = 0.32
	else:
		atmosphere_particles.color = Color(0.56, 0.62, 0.70, 0.20)
		atmosphere_particles.amount = 20
		atmosphere_particles.speed_scale = 0.26

func create_atmosphere_particle_texture() -> ImageTexture:
	var image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(image)

func create_interaction_highlight() -> void:
	if interaction_highlight != null:
		interaction_highlight.queue_free()

	interaction_highlight = ColorRect.new()
	interaction_highlight.name = "InteractionHighlight"
	interaction_highlight.size = Vector2(TILE_SIZE + 10, TILE_SIZE + 10)
	interaction_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interaction_highlight.z_index = 45
	interaction_highlight.visible = false

	var shader = Shader.new()
	shader.code = INTERACTION_HIGHLIGHT_SHADER_CODE
	interaction_highlight_material = ShaderMaterial.new()
	interaction_highlight_material.shader = shader
	interaction_highlight.material = interaction_highlight_material
	add_child(interaction_highlight)
	update_interaction_feedback()

func update_interaction_feedback() -> void:
	if interaction_highlight == null or player == null:
		return
	if interaction_highlight_material != null:
		interaction_highlight_material.set_shader_parameter("pulse", Time.get_ticks_msec() / 1000.0)

	var hint_data = get_nearby_interactable_hint()
	if hint_data.is_empty():
		interaction_highlight.hide()
		set_interaction_hint_label("")
		return

	var grid_pos = hint_data["grid_pos"]
	interaction_highlight.position = Vector2(grid_pos * TILE_SIZE) - Vector2(5.0, 5.0)
	interaction_highlight.show()
	if interaction_highlight_material != null:
		interaction_highlight_material.set_shader_parameter("highlight_color", hint_data["color"])
	set_interaction_hint_label(str(hint_data["label"]))

func get_nearby_interactable_hint() -> Dictionary:
	var player_grid_pos = player.grid_pos
	var candidates = [
		player_grid_pos,
		player_grid_pos + Vector2i(1, 0),
		player_grid_pos + Vector2i(0, 1),
		player_grid_pos + Vector2i(-1, 0),
		player_grid_pos + Vector2i(0, -1)
	]
	for candidate in candidates:
		var key = get_grid_key(candidate)
		if interactable_hints.has(key):
			return interactable_hints[key]
	return {}

func set_interaction_hint_label(text: String) -> void:
	if legend_label == null:
		return
	if text.is_empty():
		legend_label.text = "Осмотр: пусто"
	else:
		legend_label.text = "Осмотр: %s" % text

func create_interaction_flash(grid_pos: Vector2i, color: Color = Color(1.0, 0.72, 0.24, 0.82)) -> void:
	var flash = ColorRect.new()
	flash.name = "InteractionFlash"
	flash.position = Vector2(grid_pos * TILE_SIZE)
	flash.size = Vector2(TILE_SIZE, TILE_SIZE)
	flash.pivot_offset = flash.size / 2.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 46

	var shader = Shader.new()
	shader.code = INTERACTION_HIGHLIGHT_SHADER_CODE
	var flash_material = ShaderMaterial.new()
	flash_material.shader = shader
	flash_material.set_shader_parameter("highlight_color", color)
	flash_material.set_shader_parameter("pulse", 2.0)
	flash.material = flash_material
	add_child(flash)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.55, 1.55), 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(flash.queue_free)

func create_interaction_feedback_effect(grid_pos: Vector2i) -> void:
	var marker_name = get_interactable_feedback_marker(grid_pos)
	var color = get_interactable_feedback_color(grid_pos)
	create_interaction_flash(grid_pos, color)
	create_interaction_particles(grid_pos, marker_name, color)

func get_interactable_feedback_marker(grid_pos: Vector2i) -> String:
	var key = get_grid_key(grid_pos)
	if interactable_hints.has(key):
		return str(interactable_hints[key].get("marker_name", ""))
	return ""

func create_interaction_particles(grid_pos: Vector2i, marker_name: String, color: Color) -> void:
	var particles = CPUParticles2D.new()
	particles.name = "InteractionParticles"
	particles.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	particles.z_index = 50
	particles.one_shot = true
	particles.amount = get_interaction_particle_amount(marker_name)
	particles.lifetime = 0.48
	particles.explosiveness = 0.92
	particles.speed_scale = 1.1
	particles.texture = create_interaction_particle_texture()
	particles.color = color.lightened(0.18)
	particles.direction = get_interaction_particle_direction(marker_name)
	particles.spread = get_interaction_particle_spread(marker_name)
	particles.gravity = get_interaction_particle_gravity(marker_name)
	particles.initial_velocity_min = 18.0
	particles.initial_velocity_max = 42.0
	particles.scale_amount_min = 0.8
	particles.scale_amount_max = 1.65
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(0.9).timeout.connect(particles.queue_free)

func get_interaction_particle_amount(marker_name: String) -> int:
	if marker_name == "marker_fountain":
		return 18
	if marker_name == "marker_exit" or marker_name == "marker_elite":
		return 22
	return 14

func get_interaction_particle_direction(marker_name: String) -> Vector2:
	if marker_name == "marker_exit" or marker_name == "marker_elite":
		return Vector2(0.0, -1.0)
	if marker_name == "marker_fountain":
		return Vector2(0.0, -0.45)
	return Vector2(0.0, -0.8)

func get_interaction_particle_spread(marker_name: String) -> float:
	if marker_name == "marker_exit" or marker_name == "marker_elite":
		return 30.0
	if marker_name == "marker_fountain":
		return 150.0
	return 95.0

func get_interaction_particle_gravity(marker_name: String) -> Vector2:
	if marker_name == "marker_fountain":
		return Vector2(0.0, 32.0)
	if marker_name == "marker_exit" or marker_name == "marker_elite":
		return Vector2(0.0, -20.0)
	return Vector2(0.0, 45.0)

func create_interaction_particle_texture() -> ImageTexture:
	var image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(image)

func get_interactable_feedback_color(grid_pos: Vector2i) -> Color:
	var key = get_grid_key(grid_pos)
	if interactable_hints.has(key):
		return interactable_hints[key]["color"]
	return Color(1.0, 0.72, 0.24, 0.82)

func handle_player_interaction(grid_pos: Vector2i) -> bool:
	for special_room in GameState.get_visible_special_rooms():
		if Vector2i(int(special_room.get("x", -1)), int(special_room.get("y", -1))) == grid_pos:
			create_interaction_feedback_effect(grid_pos)
			var result = GameState.use_special_room(str(special_room.get("id", "")))
			if bool(result.get("needs_choice", false)):
				show_special_room_choices(result)
			else:
				show_map_message(str(result.get("message", get_special_room_message(special_room))))
			return true

	var fountain_data = GameState.get_visible_fountain()
	if not fountain_data.is_empty() and Vector2i(fountain_data["x"], fountain_data["y"]) == grid_pos:
		create_interaction_feedback_effect(grid_pos)
		var healed_amount = GameState.use_level_fountain()
		show_map_message("Фонтан: восстановлено %d HP" % healed_amount)
		rebuild_interactables()
		return true

	var chest_data = GameState.get_visible_chest()
	if not chest_data.is_empty() and Vector2i(chest_data["x"], chest_data["y"]) == grid_pos:
		create_interaction_feedback_effect(grid_pos)
		var reward = GameState.open_level_chest()
		if bool(reward.get(ResultData.KEY_OPENED, false)):
			show_map_message(get_chest_reward_message(reward))
			rebuild_interactables()
			update_hud()
		return true

	for exit_data in GameState.get_visible_exits():
		if Vector2i(exit_data["x"], exit_data["y"]) == grid_pos:
			create_interaction_feedback_effect(grid_pos)
			show_exit_choice(exit_data)
			return true

	return false

func create_choice_panel() -> void:
	choice_panel = Panel.new()
	choice_panel.visible = false
	choice_panel.offset_left = 336.0
	choice_panel.offset_top = 92.0
	choice_panel.offset_right = 820.0
	choice_panel.offset_bottom = 286.0
	$UI.add_child(choice_panel)

	var content = VBoxContainer.new()
	content.offset_left = 12.0
	content.offset_top = 10.0
	content.offset_right = 472.0
	content.offset_bottom = 182.0
	content.add_theme_constant_override("separation", 8)
	choice_panel.add_child(content)

	choice_title = Label.new()
	choice_title.text = "Выбор"
	choice_title.add_theme_font_size_override("font_size", 18)
	content.add_child(choice_title)

	choice_message = Label.new()
	choice_message.custom_minimum_size = Vector2(460, 34)
	choice_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(choice_message)

	for index in range(3):
		var button = Button.new()
		button.custom_minimum_size = Vector2(460, 32)
		button.pressed.connect(_on_choice_option_pressed.bind(index))
		choice_buttons.append(button)
		content.add_child(button)

	choice_cancel_button = Button.new()
	choice_cancel_button.custom_minimum_size = Vector2(460, 30)
	choice_cancel_button.text = "Отмена"
	choice_cancel_button.pressed.connect(_on_choice_cancel_pressed)
	content.add_child(choice_cancel_button)

func show_special_room_choices(result: Dictionary) -> void:
	pending_choice_room_id = str(result.get("room", {}).get("id", ""))
	pending_exit_id = ""
	var option_labels = result.get("option_labels", [])
	choice_title.text = str(result.get("room", {}).get("label", "Особая комната"))
	choice_message.text = str(result.get("message", "Выберите вариант."))
	for index in range(choice_buttons.size()):
		var button = choice_buttons[index]
		if index < option_labels.size():
			button.text = str(option_labels[index])
			button.visible = true
			button.disabled = false
		else:
			button.visible = false
	show_choice_panel()

func show_exit_choice(exit_data: Dictionary) -> void:
	pending_choice_room_id = ""
	pending_exit_id = str(exit_data.get("id", ""))
	choice_title.text = "Переход"
	choice_message.text = get_exit_consequence_text(exit_data)
	for index in range(choice_buttons.size()):
		var button = choice_buttons[index]
		button.visible = index == 0
		button.disabled = index != 0
		if index == 0:
			button.text = "Перейти"
	show_choice_panel()

func show_choice_panel() -> void:
	choice_panel.show()
	player.input_locked = true

func close_choice_panel() -> void:
	pending_choice_room_id = ""
	pending_exit_id = ""
	choice_panel.hide()
	if not inventory_ui.visible:
		player.input_locked = false

func _on_choice_option_pressed(index: int) -> void:
	if not pending_choice_room_id.is_empty():
		var result = GameState.use_special_room_option(pending_choice_room_id, index)
		show_map_message(str(result.get("message", "")))
		if bool(result.get("changed", false)):
			rebuild_interactables()
			update_hud()
		close_choice_panel()
		return

	if not pending_exit_id.is_empty():
		var exit_id = pending_exit_id
		close_choice_panel()
		if GameState.advance_to_next_floor(exit_id):
			get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)

func _on_choice_cancel_pressed() -> void:
	close_choice_panel()

func get_exit_consequence_text(exit_data: Dictionary) -> String:
	var path_type = str(exit_data.get("path", GameState.FLOOR_PATH_NORMAL))
	var to_floor = int(exit_data.get("to_floor", GameState.current_floor + 1))
	return GameState.get_path_consequence_text(path_type, to_floor)

func get_special_room_message(special_room: Dictionary) -> String:
	var room_type = str(special_room.get("type", ""))
	if room_type == DungeonGenerator.ROOM_TYPE_ARTIFACT:
		return "Артефактная комната: %s." % GameState.get_item_name(str(special_room.get("item_id", "")))
	if room_type == DungeonGenerator.ROOM_TYPE_SHOP:
		return "Магазин: %s за %d золота." % [
			GameState.get_item_name(str(special_room.get("item_id", ""))),
			int(special_room.get("price", 0))
		]
	return "%s: пока пусто." % str(special_room.get("label", "Особая комната"))

func rebuild_interactables() -> void:
	for child in interactables_container.get_children():
		child.queue_free()
	local_light_positions.clear()
	interactable_hints.clear()
	build_interactables()
	update_lighting_local_lights()
	update_interaction_feedback()

func update_hud() -> void:
	floor_label.text = "Этаж %d/%d" % [GameState.current_floor, GameState.MAX_FLOOR]
	var modifier_label = GameState.get_current_path_modifier_label()
	if modifier_label.is_empty():
		path_label.text = GameState.get_current_path_label()
	else:
		path_label.text = "%s - %s" % [GameState.get_current_path_label(), modifier_label]
	gold_label.text = "Золото %d" % GameState.gold
	enemies_label.text = "Враги %d" % GameState.get_remaining_enemy_count()

func show_map_message(message: String, duration: float = 3.0) -> void:
	message_sequence += 1
	var current_message = message_sequence
	message_label.text = message
	message_panel.show()
	await get_tree().create_timer(duration).timeout
	if current_message == message_sequence:
		message_panel.hide()

func get_chest_reward_message(reward: Dictionary) -> String:
	var gold_amount = int(reward.get(ResultData.KEY_GOLD, 0))
	var item_id = str(reward.get(ResultData.KEY_ITEM_ID, ""))
	if item_id.is_empty():
		return "Сундук: %d золота" % gold_amount

	var item_name = GameState.get_item_name(item_id)
	if bool(reward.get(ResultData.KEY_ITEM_ADDED, false)):
		return "Сундук: %s и %d золота" % [item_name, gold_amount]

	return "Сундук: %d золота. Инвентарь полон, %s потерян." % [gold_amount, item_name]

func is_grid_position_blocked(grid_pos: Vector2i) -> bool:
	return not floor_positions.has(get_grid_key(grid_pos))

func get_grid_key(grid_pos: Vector2i) -> String:
	return "%d:%d" % [grid_pos.x, grid_pos.y]

func get_grid_pos_from_key(key: String) -> Vector2i:
	var parts = key.split(":")
	if parts.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(parts[0]), int(parts[1]))

func _draw():
	pass

func get_room_bounds() -> Rect2:
	return Rect2(0, 0, ROOM_WIDTH * TILE_SIZE, ROOM_HEIGHT * TILE_SIZE)

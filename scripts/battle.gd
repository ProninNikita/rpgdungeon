extends Node2D

const CombatResolver = preload("res://scripts/combat_resolver.gd")
const ScenePaths = preload("res://scripts/scene_paths.gd")
const ResultData = preload("res://scripts/result_data.gd")
const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")

var player_stats: Dictionary
var enemy_stats: Dictionary
var is_battle_active: bool = true
var battle_log: Array = []
var used_passives: Dictionary = {}
var arena_container: Node2D
var arena_player_light: Sprite2D
var arena_enemy_light: Sprite2D
var battle_log_panel: Panel
var player_plate_panel: Panel
var enemy_plate_panel: Panel
var player_hp_ticks: Array[ColorRect] = []
var enemy_hp_ticks: Array[ColorRect] = []

@onready var player_hp_label = $PlayerHP
@onready var enemy_hp_label = $EnemyHP
@onready var log_label = $BattleLog
@onready var result_label = $ResultLabel
@onready var player_hp_bar = $PlayerHPBar
@onready var enemy_hp_bar = $EnemyHPBar
@onready var status_label = $StatusLabel
@onready var effect_label = $EffectLabel
@onready var speed_button = $SpeedButton
@onready var player_sprite = $PlayerSprite
@onready var enemy_sprite = $EnemySprite

const NORMAL_ATTACK_DELAY = 1.5
const FAST_ATTACK_DELAY = 0.55
const LARGE_PLAYER_FRAME_THRESHOLD = 96.0
const LARGE_PLAYER_TARGET_HEIGHT = 330.0
const DEFAULT_PLAYER_TARGET_HEIGHT = 214.0
const LARGE_ENEMY_FRAME_THRESHOLD = 256.0
const LARGE_ENEMY_TARGET_HEIGHT = 300.0
const DEFAULT_ENEMY_TARGET_HEIGHT = 200.0
const ATTACK_LUNGE_DISTANCE = 28.0
const DEATH_SCREEN_PATH = ScenePaths.DEATH_SCREEN
const MAIN_LEVEL_PATH = ScenePaths.MAIN_LEVEL
const RESULT_SCREEN_PATH = ScenePaths.RESULT_SCREEN
var attack_delay: float = NORMAL_ATTACK_DELAY

func _ready():
	player_stats = GameState.get_player_battle_stats()
	enemy_stats = GameState.get_current_enemy_battle_stats()
	speed_button.pressed.connect(_on_speed_button_pressed)
	configure_battle_sprites()
	create_battle_arena()
	apply_battle_ui_style()
	layout_battle_ui()
	
	update_ui()
	add_log("Бой начался.")
	add_log("%s против %s" % [player_stats["name"], enemy_stats["name"]])
	var traits_text = get_enemy_traits_text()
	if not traits_text.is_empty():
		add_log("Особенности врага: " + traits_text)
	
	if not is_battle_active:
		return
	await get_tree().create_timer(1.5).timeout
	if not is_battle_active:
		return
	battle_loop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and is_inside_tree():
		layout_battle_ui()

func layout_battle_ui() -> void:
	if not is_inside_tree():
		return
	if player_hp_label == null or speed_button == null:
		return
	var viewport_size = get_viewport().get_visible_rect().size
	$Background.size = viewport_size
	var margin = 20.0
	var plate_size = Vector2(318.0, 82.0)
	var player_plate_position = Vector2(margin, 20.0)
	var enemy_plate_position = Vector2(viewport_size.x - plate_size.x - margin, 20.0)
	if player_plate_panel != null:
		player_plate_panel.position = player_plate_position
		player_plate_panel.size = plate_size
	if enemy_plate_panel != null:
		enemy_plate_panel.position = enemy_plate_position
		enemy_plate_panel.size = plate_size
	player_hp_label.position = player_plate_position + Vector2(14.0, 9.0)
	player_hp_label.size = Vector2(plate_size.x - 28.0, 34.0)
	player_hp_bar.position = player_plate_position + Vector2(14.0, 50.0)
	player_hp_bar.size = Vector2(plate_size.x - 28.0, 14.0)
	enemy_hp_label.position = enemy_plate_position + Vector2(14.0, 9.0)
	enemy_hp_label.size = Vector2(plate_size.x - 28.0, 34.0)
	enemy_hp_bar.position = enemy_plate_position + Vector2(14.0, 50.0)
	enemy_hp_bar.size = Vector2(plate_size.x - 28.0, 14.0)
	layout_hp_bar_ticks(player_hp_ticks, player_hp_bar.size)
	layout_hp_bar_ticks(enemy_hp_ticks, enemy_hp_bar.size)
	status_label.position = Vector2((viewport_size.x - 304.0) * 0.5, 24.0)
	status_label.size = Vector2(304.0, 32.0)
	effect_label.position = Vector2((viewport_size.x - 360.0) * 0.5, 58.0)
	effect_label.size = Vector2(360.0, 28.0)
	speed_button.position = Vector2((viewport_size.x - 116.0) * 0.5, 92.0)
	speed_button.size = Vector2(116.0, 32.0)
	player_sprite.position = Vector2(viewport_size.x * 0.32, viewport_size.y * 0.60)
	enemy_sprite.position = Vector2(viewport_size.x * 0.70, viewport_size.y * 0.60)
	player_sprite.scale = get_battle_sprite_scale(player_sprite, get_player_sprite_target_height())
	enemy_sprite.scale = get_battle_sprite_scale(enemy_sprite, get_enemy_sprite_target_height())
	layout_battle_arena(viewport_size)
	log_label.position = Vector2(46.0, max(172.0, viewport_size.y - 126.0))
	log_label.size = Vector2(min(560.0, viewport_size.x - 92.0), 92.0)
	if battle_log_panel != null:
		battle_log_panel.position = log_label.position - Vector2(14.0, 12.0)
		battle_log_panel.size = log_label.size + Vector2(28.0, 24.0)
	result_label.position = Vector2((viewport_size.x - 600.0) * 0.5, viewport_size.y * 0.38)
	result_label.size = Vector2(600.0, 150.0)

func apply_battle_ui_style() -> void:
	$Background.color = get_arena_backdrop_color()
	$Background.z_index = -100
	create_battle_plates()
	create_battle_log_panel()
	for label in [player_hp_label, enemy_hp_label, status_label, log_label]:
		apply_battle_label_style(label, Color(0.90, 0.84, 0.74, 1.0))
	apply_battle_label_style(effect_label, Color(1.0, 0.78, 0.36, 1.0))
	apply_battle_label_style(result_label, Color(0.86, 0.95, 0.70, 1.0))
	apply_progress_style(player_hp_bar, Color(0.25, 0.58, 0.32, 1.0))
	apply_progress_style(enemy_hp_bar, Color(0.56, 0.17, 0.15, 1.0))
	player_hp_bar.show_percentage = false
	enemy_hp_bar.show_percentage = false
	create_hp_bar_ticks(player_hp_bar, player_hp_ticks)
	create_hp_bar_ticks(enemy_hp_bar, enemy_hp_ticks)
	apply_battle_button_style(speed_button)
	for control in [player_hp_label, player_hp_bar, enemy_hp_label, enemy_hp_bar, status_label, effect_label, speed_button, log_label, result_label]:
		control.z_index = 20
	player_hp_label.add_theme_font_size_override("font_size", 17)
	enemy_hp_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_font_size_override("font_size", 18)
	effect_label.add_theme_font_size_override("font_size", 16)

func create_battle_arena() -> void:
	if arena_container != null:
		return
	arena_container = Node2D.new()
	arena_container.name = "BattleArena"
	arena_container.z_index = -30
	add_child(arena_container)
	move_child(arena_container, $Background.get_index() + 1)

	arena_player_light = Sprite2D.new()
	arena_player_light.name = "PlayerGroundLight"
	arena_player_light.texture = create_ground_light_texture(get_arena_light_color())
	arena_player_light.z_index = -3
	arena_container.add_child(arena_player_light)

	arena_enemy_light = Sprite2D.new()
	arena_enemy_light.name = "EnemyGroundLight"
	arena_enemy_light.texture = create_ground_light_texture(get_arena_light_color())
	arena_enemy_light.z_index = -3
	arena_container.add_child(arena_enemy_light)

func layout_battle_arena(viewport_size: Vector2) -> void:
	if arena_container == null:
		return
	for child in arena_container.get_children():
		if child != arena_player_light and child != arena_enemy_light:
			arena_container.remove_child(child)
			child.queue_free()

	var variant = get_battle_environment_variant()
	var wall_top = viewport_size.y * 0.23
	var wall_height = viewport_size.y * 0.32
	var floor_top = viewport_size.y * 0.53
	var floor_height = viewport_size.y * 0.29
	add_arena_texture("BackWall", Vector2(0.0, wall_top), Vector2(viewport_size.x, wall_height), create_arena_wall_texture(variant), -24)
	add_arena_texture("WallDepth", Vector2(0.0, wall_top + wall_height * 0.62), Vector2(viewport_size.x, wall_height * 0.42), create_horizontal_fade_texture(Color(0.0, 0.0, 0.0, 0.45), false), -21)

	for index in range(7):
		var column_width = 44.0 + float(index % 2) * 18.0
		var column_height = viewport_size.y * (0.22 + float(index % 3) * 0.015)
		var column_position = Vector2(viewport_size.x * (0.08 + float(index) * 0.14), wall_top + wall_height * 0.12)
		add_arena_texture("Column%d" % index, column_position, Vector2(column_width, column_height), create_arena_column_texture(variant, index), -20)

	add_variant_wall_details(variant, viewport_size, wall_top, wall_height)
	add_arena_texture("ArenaFloor", Vector2(0.0, floor_top), Vector2(viewport_size.x, floor_height), create_arena_floor_texture(variant), -18)
	add_variant_floor_details(variant, viewport_size, floor_top, floor_height)

	add_arena_texture("HorizonGlow", Vector2(0.0, floor_top - 22.0), Vector2(viewport_size.x, 44.0), create_horizontal_fade_texture(get_arena_accent_color(variant), true), -16)
	add_arena_texture("MapLinkedFloorEdge", Vector2(0.0, floor_top - 4.0), Vector2(viewport_size.x, 18.0), create_horizontal_fade_texture(get_arena_edge_shadow_color(variant), false), -15)
	add_arena_texture("RoomSightline", Vector2(0.0, floor_top + floor_height * 0.10), Vector2(viewport_size.x, 2.0), create_horizontal_line_texture(get_arena_room_line_color(variant)), -15)
	add_arena_texture("ForegroundTileShade", Vector2(0.0, floor_top + floor_height * 0.72), Vector2(viewport_size.x, floor_height * 0.40), create_horizontal_fade_texture(Color(0.0, 0.0, 0.0, 0.34), false), -13)
	add_arena_texture("ForegroundVignette", Vector2(0.0, 0.0), viewport_size, create_battle_vignette_texture(variant), -12)

	arena_player_light.position = player_sprite.position + Vector2(0.0, get_player_sprite_target_height() * 0.42)
	arena_enemy_light.position = enemy_sprite.position + Vector2(0.0, get_enemy_sprite_target_height() * 0.42)
	arena_player_light.scale = Vector2(4.5, 1.25)
	arena_enemy_light.scale = Vector2(4.2, 1.18)

func add_arena_texture(node_name: String, position: Vector2, size: Vector2, texture: Texture2D, z_index: int) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.name = node_name
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.position = position
	texture_rect.size = size
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.z_index = z_index
	arena_container.add_child(texture_rect)
	return texture_rect

func add_arena_rect(node_name: String, position: Vector2, size: Vector2, color: Color, z_index: int) -> ColorRect:
	var rect = ColorRect.new()
	rect.name = node_name
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.position = position
	rect.size = size
	rect.color = color
	rect.z_index = z_index
	arena_container.add_child(rect)
	return rect

func add_variant_wall_details(variant: String, viewport_size: Vector2, wall_top: float, wall_height: float) -> void:
	if variant == "ember":
		for index in range(4):
			var x = viewport_size.x * (0.16 + float(index) * 0.22)
			add_arena_texture("EmberWallGlow%d" % index, Vector2(x - 80.0, wall_top + wall_height * 0.18), Vector2(160.0, wall_height * 0.72), create_soft_round_texture(Color(1.0, 0.20, 0.06, 0.20), 1.8), -19)
	elif variant == "moss":
		for index in range(6):
			var x = viewport_size.x * (0.10 + float(index) * 0.15)
			add_arena_rect("MossVine%d" % index, Vector2(x, wall_top + 14.0 + float(index % 2) * 26.0), Vector2(4.0, wall_height * 0.62), Color(0.06, 0.16, 0.08, 0.42), -17)
			add_arena_rect("MossLeaf%d" % index, Vector2(x - 9.0, wall_top + wall_height * 0.40 + float(index % 3) * 14.0), Vector2(22.0, 5.0), Color(0.15, 0.30, 0.13, 0.46), -16)
	else:
		for index in range(5):
			var x = viewport_size.x * (0.13 + float(index) * 0.18)
			add_arena_rect("CryptRune%d" % index, Vector2(x, wall_top + wall_height * 0.34 + float(index % 2) * 22.0), Vector2(18.0, 3.0), Color(0.33, 0.38, 0.46, 0.34), -16)
			add_arena_rect("CryptRuneVert%d" % index, Vector2(x + 8.0, wall_top + wall_height * 0.34 - 7.0 + float(index % 2) * 22.0), Vector2(3.0, 18.0), Color(0.25, 0.31, 0.42, 0.24), -16)

func add_variant_floor_details(variant: String, viewport_size: Vector2, floor_top: float, floor_height: float) -> void:
	if variant == "ember":
		for index in range(8):
			var start_x = viewport_size.x * (0.05 + float(index) * 0.12)
			var y = floor_top + floor_height * (0.24 + float((index * 5) % 7) * 0.065)
			add_arena_rect("LavaCrack%d" % index, Vector2(start_x, y), Vector2(76.0, 3.0), Color(1.0, 0.25, 0.05, 0.55), -14)
			add_arena_rect("LavaCore%d" % index, Vector2(start_x + 18.0, y + 4.0), Vector2(44.0, 2.0), Color(1.0, 0.68, 0.18, 0.38), -13)
	elif variant == "moss":
		for index in range(10):
			var x = viewport_size.x * (0.04 + float(index) * 0.095)
			var y = floor_top + floor_height * (0.18 + float((index * 3) % 8) * 0.062)
			add_arena_rect("MossPatch%d" % index, Vector2(x, y), Vector2(58.0, 8.0), Color(0.06, 0.16, 0.09, 0.46), -14)
			if index % 3 == 0:
				add_arena_texture("Puddle%d" % index, Vector2(x + 16.0, y + 10.0), Vector2(74.0, 20.0), create_soft_round_texture(Color(0.10, 0.22, 0.20, 0.34), 2.6), -13)
	else:
		for index in range(9):
			var x = viewport_size.x * (0.05 + float(index) * 0.105)
			var y = floor_top + floor_height * (0.22 + float((index * 4) % 7) * 0.070)
			add_arena_rect("CryptFloorCrack%d" % index, Vector2(x, y), Vector2(54.0, 3.0), Color(0.10, 0.12, 0.15, 0.70), -14)
			if index % 2 == 0:
				add_arena_rect("CryptChip%d" % index, Vector2(x + 22.0, y + 12.0), Vector2(8.0, 5.0), Color(0.19, 0.20, 0.22, 0.36), -13)

func get_battle_environment_variant() -> String:
	var path_type = str(GameState.level_data.get("path", GameState.FLOOR_PATH_NORMAL))
	if path_type == GameState.FLOOR_PATH_ELITE:
		return "ember"
	var floor_number = int(GameState.level_data.get("floor_number", GameState.current_floor))
	if floor_number % 2 == 0:
		return "moss"
	return "crypt"

func get_arena_backdrop_color() -> Color:
	var variant = get_battle_environment_variant()
	if variant == "ember":
		return Color(0.035, 0.006, 0.004, 1.0)
	if variant == "moss":
		return Color(0.006, 0.018, 0.014, 1.0)
	return Color(0.010, 0.010, 0.015, 1.0)

func get_arena_wall_color(variant: String) -> Color:
	if variant == "ember":
		return Color(0.105, 0.035, 0.024, 1.0)
	if variant == "moss":
		return Color(0.030, 0.058, 0.046, 1.0)
	return Color(0.035, 0.040, 0.050, 1.0)

func get_arena_column_color(variant: String) -> Color:
	if variant == "ember":
		return Color(0.060, 0.020, 0.016, 1.0)
	if variant == "moss":
		return Color(0.016, 0.035, 0.028, 1.0)
	return Color(0.020, 0.024, 0.032, 1.0)

func get_arena_floor_color(variant: String) -> Color:
	if variant == "ember":
		return Color(0.120, 0.044, 0.026, 1.0)
	if variant == "moss":
		return Color(0.042, 0.068, 0.052, 1.0)
	return Color(0.046, 0.050, 0.058, 1.0)

func get_arena_tile_color(variant: String, x: int, y: int) -> Color:
	var offset = 0.010 if (x + y) % 2 == 0 else -0.006
	if variant == "ember":
		return Color(0.105 + offset, 0.034 + offset * 0.4, 0.024, 1.0)
	if variant == "moss":
		return Color(0.038 + offset, 0.060 + offset, 0.046 + offset * 0.6, 1.0)
	return Color(0.042 + offset, 0.046 + offset, 0.054 + offset, 1.0)

func get_arena_accent_color(variant: String) -> Color:
	if variant == "ember":
		return Color(0.68, 0.18, 0.06, 0.38)
	if variant == "moss":
		return Color(0.20, 0.38, 0.26, 0.32)
	return Color(0.26, 0.32, 0.42, 0.28)

func get_arena_edge_shadow_color(variant: String) -> Color:
	if variant == "ember":
		return Color(0.22, 0.055, 0.025, 0.50)
	if variant == "moss":
		return Color(0.018, 0.070, 0.052, 0.46)
	return Color(0.020, 0.026, 0.040, 0.48)

func get_arena_room_line_color(variant: String) -> Color:
	if variant == "ember":
		return Color(0.44, 0.16, 0.07, 0.48)
	if variant == "moss":
		return Color(0.12, 0.22, 0.14, 0.44)
	return Color(0.15, 0.17, 0.22, 0.46)

func get_arena_light_color() -> Color:
	var variant = get_battle_environment_variant()
	if variant == "ember":
		return Color(1.0, 0.40, 0.16, 0.46)
	if variant == "moss":
		return Color(0.42, 0.85, 0.58, 0.34)
	return Color(0.70, 0.78, 0.92, 0.30)

func create_arena_wall_texture(variant: String) -> ImageTexture:
	var width = 320
	var height = 108
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var base = get_arena_wall_color(variant)
	var mortar = get_arena_column_color(variant).darkened(0.18)
	var accent = get_arena_accent_color(variant)
	for y in range(height):
		for x in range(width):
			var row = int(y / 18)
			var offset = 18 if row % 2 == 1 else 0
			var brick_x = int((x + offset) / 36)
			var joint = (x + offset) % 36 < 2 or y % 18 < 2
			var grain = pseudo_noise(x, y, 17) * 0.040 - 0.020
			var shade = float(y) / float(height - 1) * 0.20
			var color = base.lightened(grain).darkened(shade)
			if joint:
				color = mortar
			if (brick_x + row) % 7 == 0 and not joint:
				color = color.lerp(accent, 0.08)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

func create_arena_column_texture(variant: String, column_index: int) -> ImageTexture:
	var width = 32
	var height = 128
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var base = get_arena_column_color(variant)
	var edge = get_arena_wall_color(variant).lightened(0.08)
	for y in range(height):
		for x in range(width):
			var side = min(float(x), float(width - 1 - x)) / float(width)
			var band = 0.045 if y % 28 < 3 else 0.0
			var chip = 0.08 if int(pseudo_noise(x + column_index * 13, y, 29) * 18.0) == 0 else 0.0
			var color = base.lightened(side * 0.18 + band + chip).darkened(float(y) / float(height) * 0.12)
			if x < 2 or x > width - 4:
				color = edge.darkened(0.18)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

func create_arena_floor_texture(variant: String) -> ImageTexture:
	var width = 320
	var height = 96
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var base = get_arena_floor_color(variant)
	var seam = base.darkened(0.34)
	var accent = get_arena_accent_color(variant)
	for y in range(height):
		var row_height = 17 + int(float(y) / float(height) * 12.0)
		for x in range(width):
			var perspective_y = float(y) / float(height - 1)
			var tile_w = 32 + int(perspective_y * 34.0)
			var row = int(y / max(1, row_height))
			var offset = int(float(row % 2) * float(tile_w) * 0.5)
			var local_x = (x + offset) % tile_w
			var joint = local_x < 2 or y % row_height < 2
			var noise = pseudo_noise(x, y, 41) * 0.060 - 0.030
			var color = base.lightened(noise).darkened((1.0 - perspective_y) * 0.10)
			if joint:
				color = seam
			if int(pseudo_noise(x, y, 71) * 60.0) == 0:
				color = color.lerp(accent, 0.12)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)

func create_horizontal_fade_texture(color: Color, centered: bool) -> ImageTexture:
	var width = 128
	var height = 32
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var vertical = float(y) / float(height - 1)
			var amount = 1.0 - abs(vertical - 0.5) * 2.0 if centered else vertical
			var alpha = color.a * pow(clamp(amount, 0.0, 1.0), 1.7)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	return ImageTexture.create_from_image(image)

func create_horizontal_line_texture(color: Color) -> ImageTexture:
	var width = 128
	var height = 2
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var noise = pseudo_noise(x, y, 97) * 0.22
			var alpha = color.a * (0.70 + noise)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	return ImageTexture.create_from_image(image)

func create_battle_vignette_texture(variant: String) -> ImageTexture:
	var width = 320
	var height = 180
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	var tint = Color(0.20, 0.06, 0.02, 1.0) if variant == "ember" else Color(0.04, 0.10, 0.07, 1.0) if variant == "moss" else Color(0.05, 0.06, 0.08, 1.0)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(float(x) / float(width - 1), float(y) / float(height - 1))
			var distance = uv.distance_to(Vector2(0.50, 0.58))
			var edge_alpha = smoothstep(0.34, 0.82, distance) * 0.58
			var top_alpha = max(0.0, 1.0 - uv.y / 0.34) * 0.36
			var bottom_alpha = max(0.0, (uv.y - 0.74) / 0.26) * 0.46
			image.set_pixel(x, y, Color(tint.r * 0.25, tint.g * 0.25, tint.b * 0.25, max(edge_alpha, max(top_alpha, bottom_alpha))))
	return ImageTexture.create_from_image(image)

func create_soft_round_texture(color: Color, falloff: float) -> ImageTexture:
	var width = 96
	var height = 64
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2((float(x) / float(width - 1) - 0.5) * 2.0, (float(y) / float(height - 1) - 0.5) * 2.0)
			var distance = sqrt(uv.x * uv.x + uv.y * uv.y * 1.8)
			var alpha = pow(max(0.0, 1.0 - distance), falloff) * color.a
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	return ImageTexture.create_from_image(image)

func pseudo_noise(x: int, y: int, seed: int) -> float:
	var value = int(x * 73856093) ^ int(y * 19349663) ^ int(seed * 83492791)
	value = abs(value)
	return float(value % 1000) / 1000.0

func create_ground_light_texture(light_color: Color) -> ImageTexture:
	var width = 96
	var height = 40
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(
				(float(x) / float(width - 1) - 0.5) * 2.0,
				(float(y) / float(height - 1) - 0.5) * 2.0
			)
			var distance = sqrt(uv.x * uv.x + uv.y * uv.y * 3.2)
			var alpha = clamp(1.0 - distance, 0.0, 1.0)
			alpha = alpha * alpha * light_color.a
			image.set_pixel(x, y, Color(light_color.r, light_color.g, light_color.b, alpha))
	return ImageTexture.create_from_image(image)

func create_battle_log_panel() -> void:
	if battle_log_panel != null:
		return
	battle_log_panel = Panel.new()
	battle_log_panel.name = "BattleLogPanel"
	battle_log_panel.z_index = 10
	battle_log_panel.add_theme_stylebox_override("panel", create_panel_style(Color(0.038, 0.032, 0.030, 0.72), Color(0.34, 0.26, 0.18, 0.90), 1, 4))
	add_child(battle_log_panel)
	move_child(battle_log_panel, log_label.get_index())

func create_battle_plates() -> void:
	if player_plate_panel == null:
		player_plate_panel = Panel.new()
		player_plate_panel.name = "PlayerPlate"
		player_plate_panel.z_index = 12
		player_plate_panel.add_theme_stylebox_override("panel", create_panel_style(Color(0.042, 0.052, 0.038, 0.92), Color(0.42, 0.58, 0.32, 1.0), 2, 4))
		add_child(player_plate_panel)
		move_child(player_plate_panel, player_hp_label.get_index())
	if enemy_plate_panel == null:
		enemy_plate_panel = Panel.new()
		enemy_plate_panel.name = "EnemyPlate"
		enemy_plate_panel.z_index = 12
		enemy_plate_panel.add_theme_stylebox_override("panel", create_panel_style(Color(0.060, 0.036, 0.034, 0.92), Color(0.58, 0.24, 0.20, 1.0), 2, 4))
		add_child(enemy_plate_panel)
		move_child(enemy_plate_panel, enemy_hp_label.get_index())

func apply_battle_label_style(label: Label, color: Color) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.025, 0.020, 0.018, 1.0))
	label.add_theme_constant_override("outline_size", 2)

func apply_progress_style(progress_bar: ProgressBar, fill_color: Color) -> void:
	if progress_bar == null:
		return
	progress_bar.add_theme_stylebox_override("background", create_panel_style(Color(0.040, 0.034, 0.031, 0.96), Color(0.43, 0.31, 0.20, 1.0), 2, 3))
	progress_bar.add_theme_stylebox_override("fill", create_panel_style(fill_color, fill_color.darkened(0.30), 1, 2))

func create_hp_bar_ticks(progress_bar: ProgressBar, ticks: Array[ColorRect]) -> void:
	if progress_bar == null or not ticks.is_empty():
		return
	for index in range(1, 10):
		var tick = ColorRect.new()
		tick.name = "HpTick%d" % index
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tick.color = Color(0.020, 0.016, 0.014, 0.62)
		progress_bar.add_child(tick)
		ticks.append(tick)

func layout_hp_bar_ticks(ticks: Array[ColorRect], bar_size: Vector2) -> void:
	if ticks.is_empty():
		return
	for index in range(ticks.size()):
		var tick = ticks[index]
		tick.position = Vector2(bar_size.x * float(index + 1) / 10.0 - 1.0, 2.0)
		tick.size = Vector2(2.0, max(4.0, bar_size.y - 4.0))

func apply_battle_button_style(button: Button) -> void:
	if button == null:
		return
	button.add_theme_color_override("font_color", Color(0.92, 0.84, 0.70, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.66, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.70, 0.95, 0.78, 1.0))
	button.add_theme_stylebox_override("normal", create_panel_style(Color(0.10, 0.075, 0.055, 0.96), Color(0.40, 0.28, 0.17, 1.0), 1, 3))
	button.add_theme_stylebox_override("hover", create_panel_style(Color(0.16, 0.105, 0.065, 0.98), Color(0.70, 0.47, 0.24, 1.0), 1, 3))
	button.add_theme_stylebox_override("pressed", create_panel_style(Color(0.07, 0.09, 0.065, 1.0), Color(0.54, 0.70, 0.46, 1.0), 1, 3))

func create_panel_style(background_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func get_player_sprite_target_height() -> float:
	var frame_size = get_battle_sprite_frame_size(player_sprite)
	if frame_size.y >= LARGE_PLAYER_FRAME_THRESHOLD:
		return LARGE_PLAYER_TARGET_HEIGHT
	return DEFAULT_PLAYER_TARGET_HEIGHT

func get_enemy_sprite_target_height() -> float:
	var frame_size = get_battle_sprite_frame_size(enemy_sprite)
	if frame_size.y >= LARGE_ENEMY_FRAME_THRESHOLD:
		return LARGE_ENEMY_TARGET_HEIGHT
	return DEFAULT_ENEMY_TARGET_HEIGHT

func get_battle_sprite_scale(sprite: Sprite2D, target_height: float) -> Vector2:
	var frame_size = get_battle_sprite_frame_size(sprite)
	var scale_value = target_height / max(1.0, frame_size.y)
	return Vector2(scale_value, scale_value)

func get_battle_sprite_frame_size(sprite: Sprite2D) -> Vector2:
	if sprite == null or sprite.texture == null:
		return Vector2(64.0, 64.0)
	return Vector2(
		float(sprite.texture.get_width()) / float(max(1, sprite.hframes)),
		float(sprite.texture.get_height()) / float(max(1, sprite.vframes))
	)

func battle_loop():
	while is_battle_active:
		if is_battle_active:
			status_label.text = "Ход: %s" % player_stats["name"]
			await player_attack()
			await get_tree().create_timer(attack_delay).timeout

		if is_battle_active:
			status_label.text = "Ход: %s" % enemy_stats["name"]
			await enemy_attack()
			await get_tree().create_timer(attack_delay).timeout

func configure_battle_sprites() -> void:
	player_sprite.texture = PixelAssetPaths.hero_battle_sheet(GameState.selected_character_id)
	enemy_sprite.texture = PixelAssetPaths.enemy_battle_sheet(str(enemy_stats.get("type", "goblin")))
	player_sprite.flip_h = false
	enemy_sprite.flip_h = false
	for sprite in [player_sprite, enemy_sprite]:
		sprite.hframes = 3
		sprite.frame = 0
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func player_attack():
	var result = CombatResolver.resolve_player_attack(player_stats, enemy_stats)
	if bool(result.get(CombatResolver.RESULT_EVADED, false)):
		add_log("%s уклоняется от атаки." % enemy_stats["name"])
		show_effect("Уклонение")
		await play_attack_animation(player_sprite, enemy_sprite, false)
		update_ui()
		return

	var damage = int(result.get(CombatResolver.RESULT_DAMAGE, 0))
	add_log("%s наносит %d урона." % [player_stats["name"], damage])
	await play_attack_animation(player_sprite, enemy_sprite, true)
	var heal_amount = int(result.get(CombatResolver.RESULT_HEAL, 0))
	if heal_amount > 0:
		add_log("%s восстанавливает %d HP от вампиризма." % [player_stats["name"], heal_amount])
		show_effect("Вампиризм +%d HP" % heal_amount)
	update_ui()
	
	if bool(result.get(CombatResolver.RESULT_DEFEATED, false)):
		end_battle("win")

func enemy_attack():
	var result = CombatResolver.resolve_enemy_attack(player_stats, enemy_stats, used_passives)
	var armor_pierce = int(result.get(CombatResolver.RESULT_ARMOR_PIERCE, 0))
	var damage = int(result.get(CombatResolver.RESULT_DAMAGE, 0))
	if armor_pierce > 0:
		add_log("%s пробивает броню и наносит %d урона." % [enemy_stats["name"], damage])
		show_effect("Пробитие брони")
	else:
		add_log("%s наносит %d урона." % [enemy_stats["name"], damage])
	await play_attack_animation(enemy_sprite, player_sprite, true)

	var heal_amount = int(result.get(CombatResolver.RESULT_HEAL, 0))
	if heal_amount > 0:
		add_log("%s проявляет стойкость и лечится на %d HP." % [player_stats["name"], heal_amount])
		show_effect("Стойкость +%d HP" % heal_amount)
	update_ui()
	
	if bool(result.get(CombatResolver.RESULT_DEFEATED, false)):
		end_battle("lose")
		return

	var regeneration_amount = int(result.get(CombatResolver.RESULT_REGENERATION, 0))
	if regeneration_amount > 0:
		add_log("%s регенерирует %d HP." % [enemy_stats["name"], regeneration_amount])
		show_effect("Регенерация +%d HP" % regeneration_amount)
		update_ui()

func get_enemy_feature(feature_id: String) -> Dictionary:
	return CombatResolver.get_enemy_feature(enemy_stats, feature_id)

func get_enemy_traits_text() -> String:
	var traits = []
	for feature in enemy_stats.get("features", []):
		var feature_id = feature.get("id", "")
		if feature_id == "armor_pierce":
			traits.append("пробитие брони %d" % int(feature.get("pierce", 0)))
		elif feature_id == "evasion":
			traits.append("уклонение %d%%" % int(round(float(feature.get("chance", 0.0)) * 100.0)))
		elif feature_id == "regeneration":
			traits.append("регенерация %d HP" % int(feature.get("heal", 0)))

	return ", ".join(traits)

func add_log(message: String):
	battle_log.append(message)
	if battle_log.size() > 4:
		battle_log.pop_front()
	update_log_display()

func update_log_display():
	log_label.text = "\n".join(battle_log)

func update_ui():
	player_hp_label.text = "%s   HP %d/%d" % [player_stats["name"], int(player_stats["hp"]), int(player_stats["max_hp"])]
	enemy_hp_label.text = "%s   HP %d/%d" % [enemy_stats["name"], int(enemy_stats["hp"]), int(enemy_stats["max_hp"])]
	
	var player_hp_percent = float(player_stats["hp"]) / player_stats["max_hp"]
	var enemy_hp_percent = float(enemy_stats["hp"]) / enemy_stats["max_hp"]
	
	player_hp_bar.value = player_hp_percent * 100
	enemy_hp_bar.value = enemy_hp_percent * 100

func show_effect(message: String) -> void:
	effect_label.text = message
	effect_label.show()

func play_attack_animation(attacker: Sprite2D, defender: Sprite2D, hit: bool) -> void:
	var start_position = attacker.position
	var attack_direction = (defender.position - attacker.position).normalized()
	attacker.frame = 1
	attacker.position = start_position + attack_direction * ATTACK_LUNGE_DISTANCE
	if hit:
		defender.frame = 2
	await get_tree().create_timer(min(0.25, attack_delay * 0.45)).timeout
	attacker.position = start_position
	attacker.frame = 0
	defender.frame = 0

func _on_speed_button_pressed() -> void:
	if attack_delay == NORMAL_ATTACK_DELAY:
		attack_delay = FAST_ATTACK_DELAY
		speed_button.text = "Скорость x2"
	else:
		attack_delay = NORMAL_ATTACK_DELAY
		speed_button.text = "Скорость x1"

func end_battle(result: String):
	is_battle_active = false
	var should_show_result_screen = false
	
	if result == "win":
		GameState.set_player_battle_stats(player_stats)
		result_label.text = "ПОБЕДА!"
		status_label.text = "Бой завершен"
		effect_label.hide()
		result_label.modulate = Color.GREEN
		add_log("Победа.")
		grant_drop_reward()
		GameState.mark_current_enemy_defeated()
		if GameState.is_run_complete():
			GameState.complete_run()
			should_show_result_screen = true
		elif GameState.is_final_floor_cleared():
			add_log("Финальный этаж зачищен. Заберите награду из сундука.")
	else:
		result_label.text = "ПОРАЖЕНИЕ"
		status_label.text = "Бой завершен"
		effect_label.hide()
		result_label.modulate = Color.RED
		add_log("Герой пал.")
		GameState.handle_player_defeat()
	
	result_label.show()
	
	await get_tree().create_timer(3.0).timeout
	GameState.clear_current_battle()
	if result == "win":
		if should_show_result_screen:
			get_tree().change_scene_to_file(RESULT_SCREEN_PATH)
		else:
			get_tree().change_scene_to_file(MAIN_LEVEL_PATH)
	else:
		get_tree().change_scene_to_file(DEATH_SCREEN_PATH)

func grant_drop_reward() -> void:
	var reward = GameState.grant_current_enemy_reward()
	var gold_amount = int(reward.get(ResultData.KEY_GOLD, 0))
	if gold_amount > 0:
		add_log("Получено золото: %d" % gold_amount)

	var item_id = str(reward.get(ResultData.KEY_ITEM_ID, ""))
	if item_id.is_empty():
		return

	if bool(reward.get(ResultData.KEY_ITEM_ADDED, false)):
		add_log("Найдено: %s" % GameState.get_item_name(item_id))
	else:
		add_log("Инвентарь полон. %s потерян." % GameState.get_item_name(item_id))

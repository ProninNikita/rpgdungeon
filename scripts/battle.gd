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
	var bar_width = max(280.0, (viewport_size.x - margin * 3.0) * 0.5)
	player_hp_label.position = Vector2(margin, 20.0)
	player_hp_label.size = Vector2(bar_width, 30.0)
	player_hp_bar.position = Vector2(margin, 55.0)
	player_hp_bar.size = Vector2(bar_width, 20.0)
	enemy_hp_label.position = Vector2(viewport_size.x - bar_width - margin, 20.0)
	enemy_hp_label.size = Vector2(bar_width, 30.0)
	enemy_hp_bar.position = Vector2(viewport_size.x - bar_width - margin, 55.0)
	enemy_hp_bar.size = Vector2(bar_width, 20.0)
	layout_hp_bar_ticks(player_hp_ticks, player_hp_bar.size)
	layout_hp_bar_ticks(enemy_hp_ticks, enemy_hp_bar.size)
	status_label.position = Vector2((viewport_size.x - 304.0) * 0.5, 94.0)
	status_label.size = Vector2(304.0, 32.0)
	effect_label.position = Vector2((viewport_size.x - 360.0) * 0.5, 126.0)
	effect_label.size = Vector2(360.0, 28.0)
	speed_button.position = Vector2(viewport_size.x - 136.0, 92.0)
	speed_button.size = Vector2(116.0, 36.0)
	player_sprite.position = Vector2(viewport_size.x * 0.32, viewport_size.y * 0.60)
	enemy_sprite.position = Vector2(viewport_size.x * 0.70, viewport_size.y * 0.60)
	player_sprite.scale = get_battle_sprite_scale(player_sprite, get_player_sprite_target_height())
	enemy_sprite.scale = get_battle_sprite_scale(enemy_sprite, get_enemy_sprite_target_height())
	layout_battle_arena(viewport_size)
	log_label.position = Vector2(50.0, max(172.0, viewport_size.y - 170.0))
	log_label.size = Vector2(max(360.0, viewport_size.x - 100.0), 140.0)
	if battle_log_panel != null:
		battle_log_panel.position = log_label.position - Vector2(14.0, 12.0)
		battle_log_panel.size = log_label.size + Vector2(28.0, 24.0)
	result_label.position = Vector2((viewport_size.x - 600.0) * 0.5, viewport_size.y * 0.38)
	result_label.size = Vector2(600.0, 150.0)

func apply_battle_ui_style() -> void:
	$Background.color = get_arena_backdrop_color()
	$Background.z_index = -100
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
			child.queue_free()

	var variant = get_battle_environment_variant()
	var far_wall = ColorRect.new()
	far_wall.position = Vector2(0.0, viewport_size.y * 0.24)
	far_wall.size = Vector2(viewport_size.x, viewport_size.y * 0.24)
	far_wall.color = get_arena_wall_color(variant)
	far_wall.z_index = -20
	arena_container.add_child(far_wall)

	for index in range(7):
		var column = ColorRect.new()
		column.size = Vector2(34.0 + float(index % 2) * 18.0, viewport_size.y * 0.22)
		column.position = Vector2(viewport_size.x * (0.10 + float(index) * 0.135), viewport_size.y * 0.27)
		column.color = get_arena_column_color(variant)
		column.z_index = -18
		arena_container.add_child(column)

	var floor = ColorRect.new()
	floor.position = Vector2(0.0, viewport_size.y * 0.55)
	floor.size = Vector2(viewport_size.x, viewport_size.y * 0.24)
	floor.color = get_arena_floor_color(variant)
	floor.z_index = -16
	arena_container.add_child(floor)

	var tile_size = 64.0
	for y in range(4):
		for x in range(ceili(viewport_size.x / tile_size)):
			var tile = ColorRect.new()
			tile.position = Vector2(float(x) * tile_size, viewport_size.y * 0.55 + float(y) * 36.0)
			tile.size = Vector2(tile_size - 2.0, 34.0)
			tile.color = get_arena_tile_color(variant, x, y)
			tile.z_index = -15
			arena_container.add_child(tile)

	var horizon = ColorRect.new()
	horizon.position = Vector2(0.0, viewport_size.y * 0.535)
	horizon.size = Vector2(viewport_size.x, 3.0)
	horizon.color = get_arena_accent_color(variant)
	horizon.z_index = -14
	arena_container.add_child(horizon)

	arena_player_light.position = player_sprite.position + Vector2(0.0, get_player_sprite_target_height() * 0.42)
	arena_enemy_light.position = enemy_sprite.position + Vector2(0.0, get_enemy_sprite_target_height() * 0.42)
	arena_player_light.scale = Vector2(4.5, 1.25)
	arena_enemy_light.scale = Vector2(4.2, 1.18)

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
		return Color(0.75, 0.22, 0.08, 0.45)
	if variant == "moss":
		return Color(0.28, 0.55, 0.36, 0.36)
	return Color(0.35, 0.42, 0.52, 0.32)

func get_arena_light_color() -> Color:
	var variant = get_battle_environment_variant()
	if variant == "ember":
		return Color(1.0, 0.40, 0.16, 0.46)
	if variant == "moss":
		return Color(0.42, 0.85, 0.58, 0.34)
	return Color(0.70, 0.78, 0.92, 0.30)

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
	battle_log_panel.add_theme_stylebox_override("panel", create_panel_style(Color(0.038, 0.032, 0.030, 0.88), Color(0.46, 0.34, 0.21, 1.0), 2, 4))
	add_child(battle_log_panel)
	move_child(battle_log_panel, log_label.get_index())

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
	if battle_log.size() > 6:
		battle_log.pop_front()
	update_log_display()

func update_log_display():
	log_label.text = "\n".join(battle_log)

func update_ui():
	player_hp_label.text = "%s HP: %d/%d" % [player_stats["name"], int(player_stats["hp"]), int(player_stats["max_hp"])]
	enemy_hp_label.text = "%s HP: %d/%d" % [enemy_stats["name"], int(enemy_stats["hp"]), int(enemy_stats["max_hp"])]
	
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

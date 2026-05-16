extends Control

const ScenePaths = preload("res://scripts/scene_paths.gd")
const ShellUIStyle = preload("res://scripts/shell_ui_style.gd")
const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")

@onready var content = $Content
@onready var title_label = $Content/Title
@onready var subtitle_label = $Content/Subtitle
@onready var summary_label = $Content/Summary
@onready var actions = $Content/Actions
@onready var new_game_button = $Content/Actions/NewGameButton
@onready var main_menu_button = $Content/Actions/MainMenuButton

var hero_portrait: TextureRect
var victory_light: TextureRect
var summary_panel: Panel
var stats_grid: GridContainer
var equipment_container: HBoxContainer
var stat_value_labels: Dictionary = {}

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	apply_result_style()
	build_result_layout()
	refresh_summary()
	layout_result_screen()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		layout_result_screen()

func apply_result_style() -> void:
	ShellUIStyle.apply_screen(self)
	ShellUIStyle.apply_title(title_label, 48)
	ShellUIStyle.apply_label(subtitle_label, Color(0.90, 0.80, 0.62, 1.0), 18)
	ShellUIStyle.apply_button(new_game_button, "primary")
	ShellUIStyle.apply_button(main_menu_button)
	content.add_theme_constant_override("separation", 14)
	actions.add_theme_constant_override("separation", 10)
	summary_label.hide()

func build_result_layout() -> void:
	if victory_light == null:
		victory_light = TextureRect.new()
		victory_light.name = "VictoryLight"
		victory_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		victory_light.texture = create_victory_light_texture()
		victory_light.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		victory_light.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(victory_light)
		move_child(victory_light, $Background.get_index() + 3)

	if hero_portrait == null:
		hero_portrait = ShellUIStyle.make_character_portrait("base", 310.0)
		hero_portrait.name = "VictoryHero"
		hero_portrait.modulate = Color(1.0, 0.92, 0.78, 0.96)
		add_child(hero_portrait)
		move_child(hero_portrait, content.get_index())

	if summary_panel != null:
		return

	summary_panel = Panel.new()
	summary_panel.name = "SummaryCard"
	summary_panel.custom_minimum_size = Vector2(620.0, 300.0)
	ShellUIStyle.apply_panel(summary_panel, true)
	content.add_child(summary_panel)
	content.move_child(summary_panel, summary_label.get_index())

	var panel_content = VBoxContainer.new()
	panel_content.name = "SummaryContent"
	panel_content.position = Vector2(18.0, 16.0)
	panel_content.size = Vector2(584.0, 268.0)
	panel_content.add_theme_constant_override("separation", 14)
	summary_panel.add_child(panel_content)

	var stats_title = Label.new()
	stats_title.text = "Итоги забега"
	stats_title.custom_minimum_size = Vector2(584.0, 28.0)
	ShellUIStyle.apply_label(stats_title, Color(0.96, 0.78, 0.46, 1.0), 21)
	panel_content.add_child(stats_title)

	stats_grid = GridContainer.new()
	stats_grid.columns = 3
	stats_grid.custom_minimum_size = Vector2(584.0, 104.0)
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 8)
	panel_content.add_child(stats_grid)

	for stat_key in ["character", "path", "floor", "gold", "defeated"]:
		var stat_panel = Panel.new()
		stat_panel.custom_minimum_size = Vector2(188.0, 48.0)
		stat_panel.add_theme_stylebox_override("panel", ShellUIStyle.create_panel_style(Color(0.060, 0.050, 0.042, 0.86), Color(0.34, 0.25, 0.16, 0.92), 1, 3))
		stats_grid.add_child(stat_panel)

		var stat_label = Label.new()
		stat_label.position = Vector2(10.0, 5.0)
		stat_label.size = Vector2(168.0, 38.0)
		stat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ShellUIStyle.apply_label(stat_label, Color(0.89, 0.82, 0.70, 1.0), 15)
		stat_panel.add_child(stat_label)
		stat_value_labels[stat_key] = stat_label

	var equipment_title = Label.new()
	equipment_title.text = "Найденное снаряжение"
	equipment_title.custom_minimum_size = Vector2(584.0, 24.0)
	ShellUIStyle.apply_label(equipment_title, Color(0.86, 0.78, 0.66, 1.0), 17)
	panel_content.add_child(equipment_title)

	equipment_container = HBoxContainer.new()
	equipment_container.custom_minimum_size = Vector2(584.0, 70.0)
	equipment_container.add_theme_constant_override("separation", 8)
	panel_content.add_child(equipment_container)

func layout_result_screen() -> void:
	if content == null:
		return
	var viewport_size = get_viewport_rect().size
	var edge_margin = 24.0
	var content_width = min(660.0, max(320.0, viewport_size.x - edge_margin * 2.0))
	var content_height = min(660.0, max(500.0, viewport_size.y - edge_margin * 2.0))
	content_width = min(content_width, viewport_size.x)
	content_height = min(content_height, viewport_size.y)
	var content_min_x = 0.0 if content_width >= viewport_size.x - edge_margin * 2.0 else edge_margin
	var content_min_y = 0.0 if content_height >= viewport_size.y - edge_margin * 2.0 else edge_margin
	content.position = Vector2(
		clamp(viewport_size.x * 0.5 - content_width * 0.5, content_min_x, max(content_min_x, viewport_size.x - content_width - content_min_x)),
		clamp(viewport_size.y * 0.5 - content_height * 0.5, content_min_y, max(content_min_y, viewport_size.y - content_height - content_min_y))
	)
	content.size = Vector2(content_width, content_height)
	title_label.custom_minimum_size = Vector2(content_width, 70.0)
	subtitle_label.custom_minimum_size = Vector2(content_width, 44.0)
	if summary_panel != null:
		summary_panel.custom_minimum_size = Vector2(content_width, 320.0)
		var panel_content = summary_panel.get_node("SummaryContent")
		panel_content.position = Vector2(18.0, 16.0)
		panel_content.size = Vector2(max(0.0, content_width - 36.0), 288.0)
		stats_grid.custom_minimum_size = Vector2(max(0.0, content_width - 36.0), 104.0)
		var stat_width = max(84.0, (content_width - 56.0) / 3.0)
		for stat_panel in stats_grid.get_children():
			stat_panel.custom_minimum_size = Vector2(stat_width, 48.0)
			if stat_panel.get_child_count() > 0:
				var stat_label = stat_panel.get_child(0) as Label
				stat_label.size = Vector2(max(0.0, stat_width - 20.0), 38.0)
		equipment_container.custom_minimum_size = Vector2(max(0.0, content_width - 36.0), 70.0)
		layout_equipment_cards(content_width)
	new_game_button.custom_minimum_size = Vector2(content_width, 48.0)
	main_menu_button.custom_minimum_size = Vector2(content_width, 48.0)
	ShellUIStyle.fit_control_to_viewport(content, viewport_size, edge_margin)
	if hero_portrait != null:
		var portrait_size = min(320.0, max(160.0, viewport_size.x * 0.30))
		var portrait_x = content.position.x + content_width + 60.0
		if portrait_x + portrait_size > viewport_size.x - edge_margin:
			portrait_x = viewport_size.x - portrait_size - edge_margin
		hero_portrait.position = Vector2(clamp(portrait_x, edge_margin, max(edge_margin, viewport_size.x - portrait_size - edge_margin)), clamp(viewport_size.y * 0.5 - portrait_size * 0.5, edge_margin, max(edge_margin, viewport_size.y - portrait_size - edge_margin)))
		hero_portrait.size = Vector2(portrait_size, portrait_size)
	if victory_light != null:
		victory_light.position = Vector2(max(0.0, viewport_size.x * 0.50), viewport_size.y * 0.22)
		victory_light.size = Vector2(viewport_size.x - victory_light.position.x, viewport_size.y * 0.56)

func layout_equipment_cards(content_width: float) -> void:
	if equipment_container == null:
		return
	var card_count = max(1, equipment_container.get_child_count())
	var card_width = max(84.0, (content_width - 36.0 - float(card_count - 1) * 8.0) / float(card_count))
	for card in equipment_container.get_children():
		card.custom_minimum_size = Vector2(card_width, 64.0)
		if card.get_child_count() > 0:
			var label = card.get_child(0) as Label
			label.size = Vector2(max(0.0, card_width - 20.0), 52.0)

func refresh_summary() -> void:
	var summary = GameState.get_completed_run_summary()
	title_label.text = "Подземелье покорено"
	subtitle_label.text = "Финальный костер горит. Забег завершен."
	set_stat_text("character", "Персонаж", str(summary.get("character", "Герой")))
	set_stat_text("path", "Путь", str(summary.get("path", "Обычный")))
	set_stat_text("floor", "Этаж", "%d/%d" % [int(summary.get("floor", 1)), int(summary.get("max_floor", 1))])
	set_stat_text("gold", "Золото", "%d" % int(summary.get("gold", 0)))
	set_stat_text("defeated", "Побеждено", "%d врагов" % int(summary.get("defeated_enemies", 0)))
	refresh_equipment_cards(summary.get("equipment", []))
	refresh_victory_portrait(summary)

func set_stat_text(stat_key: String, label_text: String, value_text: String) -> void:
	var label = stat_value_labels.get(stat_key)
	if label == null:
		return
	label.text = "%s\n%s" % [label_text, value_text]

func refresh_equipment_cards(equipment_lines: Array) -> void:
	if equipment_container == null:
		return
	for child in equipment_container.get_children():
		child.queue_free()

	var lines = equipment_lines.duplicate()
	if lines.is_empty():
		lines.append("Снаряжение: Нет")

	for line in lines:
		equipment_container.add_child(create_equipment_card(str(line)))
	layout_result_screen()

func create_equipment_card(line: String) -> Panel:
	var card = Panel.new()
	card.custom_minimum_size = Vector2(188.0, 64.0)
	card.add_theme_stylebox_override("panel", ShellUIStyle.create_panel_style(Color(0.070, 0.055, 0.042, 0.90), Color(0.52, 0.37, 0.20, 0.95), 1, 3))

	var label = Label.new()
	label.position = Vector2(10.0, 6.0)
	label.size = Vector2(168.0, 52.0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = line
	ShellUIStyle.apply_label(label, Color(0.88, 0.80, 0.68, 1.0), 13)
	card.add_child(label)
	return card

func refresh_victory_portrait(summary: Dictionary) -> void:
	if hero_portrait == null:
		return
	var character_name = str(summary.get("character", "Герой")).to_lower()
	var character_id = "vampire" if character_name.contains("вампир") else "base"
	var texture = PixelAssetPaths.hero_battle_sheet(character_id)
	if texture == null:
		return
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(0.0, 0.0, float(texture.get_width()) / 3.0, float(texture.get_height()))
	hero_portrait.texture = atlas

func create_victory_light_texture() -> ImageTexture:
	var width = 128
	var height = 128
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(float(x) / float(width - 1), float(y) / float(height - 1))
			var distance = uv.distance_to(Vector2(0.48, 0.48))
			var alpha = pow(max(0.0, 1.0 - distance / 0.72), 2.2) * 0.38
			var ray = max(0.0, 1.0 - abs(uv.x - 0.50) * 4.0) * max(0.0, 1.0 - uv.y)
			alpha = max(alpha, ray * 0.10)
			image.set_pixel(x, y, Color(0.95, 0.60, 0.22, alpha))
	return ImageTexture.create_from_image(image)

func _on_new_game_pressed() -> void:
	GameState.clear_current_battle()
	get_tree().change_scene_to_file(ScenePaths.CHARACTER_SELECT)

func _on_main_menu_pressed() -> void:
	GameState.clear_current_battle()
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

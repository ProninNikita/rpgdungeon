extends Control

const ScenePaths = preload("res://scripts/scene_paths.gd")
const ShellUIStyle = preload("res://scripts/shell_ui_style.gd")
const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")

@onready var content = $Content
@onready var title_label = $Content/Title
@onready var subtitle_label = $Content/Subtitle
@onready var actions = $Content/Actions
@onready var new_game_button = $Content/Actions/NewGameButton
@onready var main_menu_button = $Content/Actions/MainMenuButton

var fallen_panel: Panel
var stats_grid: GridContainer
var stat_value_labels: Dictionary = {}
var fallen_portrait: TextureRect
var defeat_light: TextureRect
var broken_blade: TextureRect

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	apply_death_style()
	build_death_layout()
	refresh_death_summary()
	layout_death_screen()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		layout_death_screen()

func apply_death_style() -> void:
	ShellUIStyle.apply_screen(self)
	ShellUIStyle.apply_title(title_label, 52)
	ShellUIStyle.apply_label(subtitle_label, Color(0.80, 0.68, 0.60, 1.0), 18)
	ShellUIStyle.apply_button(new_game_button, "danger")
	ShellUIStyle.apply_button(main_menu_button, "back")
	content.add_theme_constant_override("separation", 14)
	actions.add_theme_constant_override("separation", 10)

func build_death_layout() -> void:
	if defeat_light == null:
		defeat_light = TextureRect.new()
		defeat_light.name = "DefeatLight"
		defeat_light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		defeat_light.texture = create_defeat_light_texture()
		defeat_light.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		defeat_light.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(defeat_light)
		move_child(defeat_light, $Background.get_index() + 3)

	if broken_blade == null:
		broken_blade = TextureRect.new()
		broken_blade.name = "BrokenBlade"
		broken_blade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		broken_blade.texture = create_broken_blade_texture()
		broken_blade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		broken_blade.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(broken_blade)
		move_child(broken_blade, content.get_index())

	if fallen_portrait == null:
		fallen_portrait = ShellUIStyle.make_character_portrait(GameState.selected_character_id, 280.0)
		fallen_portrait.name = "FallenHero"
		fallen_portrait.modulate = Color(0.62, 0.55, 0.52, 0.58)
		fallen_portrait.rotation_degrees = -9.0
		add_child(fallen_portrait)
		move_child(fallen_portrait, content.get_index())

	if fallen_panel != null:
		return

	fallen_panel = Panel.new()
	fallen_panel.name = "DeathSummaryCard"
	fallen_panel.custom_minimum_size = Vector2(620.0, 220.0)
	fallen_panel.add_theme_stylebox_override("panel", ShellUIStyle.create_panel_style(Color(0.048, 0.032, 0.030, 0.96), Color(0.50, 0.22, 0.18, 1.0), 2, 4))
	content.add_child(fallen_panel)
	content.move_child(fallen_panel, actions.get_index())

	var panel_content = VBoxContainer.new()
	panel_content.name = "DeathSummaryContent"
	panel_content.position = Vector2(18.0, 16.0)
	panel_content.size = Vector2(584.0, 188.0)
	panel_content.add_theme_constant_override("separation", 14)
	fallen_panel.add_child(panel_content)

	var summary_title = Label.new()
	summary_title.text = "Следы последнего похода"
	summary_title.custom_minimum_size = Vector2(584.0, 28.0)
	ShellUIStyle.apply_label(summary_title, Color(0.94, 0.62, 0.46, 1.0), 21)
	panel_content.add_child(summary_title)

	stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.custom_minimum_size = Vector2(584.0, 132.0)
	stats_grid.add_theme_constant_override("h_separation", 10)
	stats_grid.add_theme_constant_override("v_separation", 8)
	panel_content.add_child(stats_grid)

	for stat_key in ["character", "floor", "gold", "defeated"]:
		var stat_panel = Panel.new()
		stat_panel.custom_minimum_size = Vector2(286.0, 56.0)
		stat_panel.add_theme_stylebox_override("panel", ShellUIStyle.create_panel_style(Color(0.060, 0.045, 0.040, 0.88), Color(0.30, 0.20, 0.16, 0.95), 1, 3))
		stats_grid.add_child(stat_panel)

		var stat_label = Label.new()
		stat_label.position = Vector2(10.0, 6.0)
		stat_label.size = Vector2(266.0, 44.0)
		stat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ShellUIStyle.apply_label(stat_label, Color(0.86, 0.78, 0.68, 1.0), 15)
		stat_panel.add_child(stat_label)
		stat_value_labels[stat_key] = stat_label

func layout_death_screen() -> void:
	if content == null:
		return
	var viewport_size = get_viewport_rect().size
	var edge_margin = 24.0
	var content_width = min(660.0, max(320.0, viewport_size.x - edge_margin * 2.0))
	var content_height = min(540.0, max(420.0, viewport_size.y - edge_margin * 2.0))
	content_width = min(content_width, viewport_size.x)
	content_height = min(content_height, viewport_size.y)
	var content_min_x = 0.0 if content_width >= viewport_size.x - edge_margin * 2.0 else edge_margin
	var content_min_y = 0.0 if content_height >= viewport_size.y - edge_margin * 2.0 else edge_margin
	content.position = Vector2(
		clamp(viewport_size.x * 0.5 - content_width * 0.5, content_min_x, max(content_min_x, viewport_size.x - content_width - content_min_x)),
		clamp(viewport_size.y * 0.5 - content_height * 0.5, content_min_y, max(content_min_y, viewport_size.y - content_height - content_min_y))
	)
	content.size = Vector2(content_width, content_height)
	title_label.custom_minimum_size = Vector2(content_width, 72.0)
	subtitle_label.custom_minimum_size = Vector2(content_width, 56.0)
	if fallen_panel != null:
		fallen_panel.custom_minimum_size = Vector2(content_width, 224.0)
		var panel_content = fallen_panel.get_node("DeathSummaryContent")
		panel_content.position = Vector2(18.0, 16.0)
		panel_content.size = Vector2(max(0.0, content_width - 36.0), 190.0)
		stats_grid.custom_minimum_size = Vector2(max(0.0, content_width - 36.0), 132.0)
		var stat_width = max(130.0, (content_width - 46.0) * 0.5)
		for stat_panel in stats_grid.get_children():
			stat_panel.custom_minimum_size = Vector2(stat_width, 56.0)
			if stat_panel.get_child_count() > 0:
				var stat_label = stat_panel.get_child(0) as Label
				stat_label.size = Vector2(max(0.0, stat_width - 20.0), 44.0)
	new_game_button.custom_minimum_size = Vector2(content_width, 48.0)
	main_menu_button.custom_minimum_size = Vector2(content_width, 48.0)
	ShellUIStyle.fit_control_to_viewport(content, viewport_size, edge_margin)
	if fallen_portrait != null:
		var portrait_size = min(300.0, max(150.0, viewport_size.x * 0.30))
		var portrait_x = clamp(content.position.x - portrait_size - 30.0, edge_margin, max(edge_margin, viewport_size.x - portrait_size - edge_margin))
		if content.position.x < portrait_size + edge_margin * 2.0:
			portrait_x = edge_margin
		fallen_portrait.position = Vector2(portrait_x, clamp(viewport_size.y * 0.5 - portrait_size * 0.5, edge_margin, max(edge_margin, viewport_size.y - portrait_size - edge_margin)))
		fallen_portrait.size = Vector2(portrait_size, portrait_size)
	if defeat_light != null:
		defeat_light.position = Vector2(0.0, viewport_size.y * 0.16)
		defeat_light.size = Vector2(viewport_size.x, viewport_size.y * 0.70)
	if broken_blade != null:
		var blade_size = min(176.0, max(96.0, viewport_size.x * 0.18))
		broken_blade.position = Vector2(clamp(content.position.x + content_width - blade_size - 14.0, edge_margin, max(edge_margin, viewport_size.x - blade_size - edge_margin)), content.position.y + 64.0)
		broken_blade.size = Vector2(blade_size, blade_size)
		broken_blade.rotation_degrees = -18.0

func refresh_death_summary() -> void:
	title_label.text = "Свет погас"
	subtitle_label.text = "Подземелье забрало поход, но следы битвы остались на камне."
	var player_stats = GameState.get_player_battle_stats()
	set_stat_text("character", "Персонаж", str(player_stats.get("name", "Герой")))
	set_stat_text("floor", "Этаж", "%d/%d" % [GameState.current_floor, GameState.MAX_FLOOR])
	set_stat_text("gold", "Золото", "%d" % GameState.gold)
	set_stat_text("defeated", "Побеждено", "%d врагов" % GameState.defeated_enemies.size())
	refresh_fallen_portrait()

func set_stat_text(stat_key: String, label_text: String, value_text: String) -> void:
	var label = stat_value_labels.get(stat_key)
	if label == null:
		return
	label.text = "%s\n%s" % [label_text, value_text]

func refresh_fallen_portrait() -> void:
	if fallen_portrait == null:
		return
	var texture = PixelAssetPaths.hero_battle_sheet(GameState.selected_character_id)
	if texture == null:
		return
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(float(texture.get_width()) / 3.0 * 2.0, 0.0, float(texture.get_width()) / 3.0, float(texture.get_height()))
	fallen_portrait.texture = atlas

func create_defeat_light_texture() -> ImageTexture:
	var width = 160
	var height = 96
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(float(x) / float(width - 1), float(y) / float(height - 1))
			var left = max(0.0, 1.0 - uv.distance_to(Vector2(0.24, 0.58)) / 0.52)
			var center = max(0.0, 1.0 - uv.distance_to(Vector2(0.54, 0.44)) / 0.74)
			var alpha = pow(max(left, center * 0.68), 2.0) * 0.34
			var ash = max(0.0, 1.0 - abs(uv.y - 0.62) * 7.0) * 0.05
			image.set_pixel(x, y, Color(0.58, 0.12, 0.08, alpha + ash))
	return ImageTexture.create_from_image(image)

func create_broken_blade_texture() -> ImageTexture:
	var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for i in range(6, 46):
		var x = i
		var y = 52 - i
		draw_pixel_rect(image, x, y, 3, 9, Color(0.56, 0.60, 0.62, 0.72))
		draw_pixel_rect(image, x + 3, y + 1, 2, 7, Color(0.90, 0.86, 0.74, 0.80))
	for i in range(40, 58):
		draw_pixel_rect(image, i, 15 + int((i - 40) * 0.3), 2, 5, Color(0.40, 0.22, 0.15, 0.72))
	draw_pixel_rect(image, 36, 43, 24, 5, Color(0.30, 0.16, 0.10, 0.82))
	draw_pixel_rect(image, 46, 34, 5, 24, Color(0.22, 0.12, 0.08, 0.82))
	draw_pixel_rect(image, 9, 48, 12, 5, Color(0.32, 0.08, 0.06, 0.50))
	return ImageTexture.create_from_image(image)

func draw_pixel_rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, y + height):
		for px in range(x, x + width):
			if px >= 0 and px < image.get_width() and py >= 0 and py < image.get_height():
				image.set_pixel(px, py, color)

func _on_new_game_pressed() -> void:
	GameState.clear_current_battle()
	get_tree().change_scene_to_file(ScenePaths.CHARACTER_SELECT)

func _on_main_menu_pressed() -> void:
	GameState.clear_current_battle()
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

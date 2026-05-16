extends Control

const ScenePaths = preload("res://scripts/scene_paths.gd")
const ShellUIStyle = preload("res://scripts/shell_ui_style.gd")

var menu_frame: Panel
var hero_portrait: TextureRect
var hero_glow: TextureRect
var hero_shadow: TextureRect
var subtitle_label: Label
var title_accent: ColorRect
var arch_silhouette: TextureRect
var title_glow: TextureRect
var foreground_fog: TextureRect
var left_torch: TextureRect
var right_torch: TextureRect

func _ready() -> void:
	$MenuPanel/NewGameButton.pressed.connect(_on_new_game_pressed)
	$MenuPanel/LoadGameButton.pressed.connect(_on_load_game_pressed)
	$MenuPanel/ExitButton.pressed.connect(_on_exit_pressed)
	apply_menu_style()
	layout_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		layout_menu()

func apply_menu_style() -> void:
	ShellUIStyle.apply_screen(self)
	$Title.text = "Тени подземелья"
	ShellUIStyle.apply_title($Title, 54)
	ShellUIStyle.apply_button($MenuPanel/NewGameButton, "primary")
	ShellUIStyle.apply_button($MenuPanel/LoadGameButton)
	ShellUIStyle.apply_button($MenuPanel/ExitButton)
	$MenuPanel.add_theme_constant_override("separation", 14)
	if menu_frame == null:
		menu_frame = Panel.new()
		menu_frame.name = "MenuFrame"
		menu_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(menu_frame)
		move_child(menu_frame, $Title.get_index())
	ShellUIStyle.apply_panel(menu_frame, true)
	if arch_silhouette == null:
		arch_silhouette = TextureRect.new()
		arch_silhouette.name = "CoverArch"
		arch_silhouette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arch_silhouette.texture = create_arch_silhouette_texture()
		arch_silhouette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		arch_silhouette.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(arch_silhouette)
		move_child(arch_silhouette, $Title.get_index())
	if title_glow == null:
		title_glow = TextureRect.new()
		title_glow.name = "TitleGlow"
		title_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_glow.texture = create_soft_light_texture(Color(0.80, 0.42, 0.16, 1.0), 0.26, 2.1, Vector2(0.50, 0.50), Vector2(1.0, 0.35))
		title_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_glow.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(title_glow)
		move_child(title_glow, $Title.get_index())
	if foreground_fog == null:
		foreground_fog = TextureRect.new()
		foreground_fog.name = "ForegroundFog"
		foreground_fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
		foreground_fog.texture = create_foreground_fog_texture()
		foreground_fog.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		foreground_fog.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(foreground_fog)
		move_child(foreground_fog, $Title.get_index())
	if left_torch == null:
		left_torch = TextureRect.new()
		left_torch.name = "LeftTorchGlow"
		left_torch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		left_torch.texture = create_soft_light_texture(Color(0.95, 0.34, 0.08, 1.0), 0.32, 1.55)
		left_torch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		left_torch.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(left_torch)
		move_child(left_torch, $Title.get_index())
	if right_torch == null:
		right_torch = TextureRect.new()
		right_torch.name = "RightTorchGlow"
		right_torch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		right_torch.texture = create_soft_light_texture(Color(0.95, 0.34, 0.08, 1.0), 0.26, 1.75)
		right_torch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		right_torch.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(right_torch)
		move_child(right_torch, $Title.get_index())
	if hero_portrait == null:
		hero_glow = TextureRect.new()
		hero_glow.name = "HeroBacklight"
		hero_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero_glow.texture = create_soft_light_texture(Color(0.78, 0.30, 0.10, 1.0), 0.38, 1.85)
		hero_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero_glow.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(hero_glow)
		move_child(hero_glow, $Title.get_index())

		hero_shadow = TextureRect.new()
		hero_shadow.name = "HeroFloorShadow"
		hero_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hero_shadow.texture = create_soft_light_texture(Color(0.0, 0.0, 0.0, 1.0), 0.58, 2.4, Vector2(0.50, 0.50), Vector2(1.0, 0.34))
		hero_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hero_shadow.stretch_mode = TextureRect.STRETCH_SCALE
		add_child(hero_shadow)
		move_child(hero_shadow, $Title.get_index())

		hero_portrait = ShellUIStyle.make_character_portrait("base", 250.0)
		hero_portrait.name = "HeroPortrait"
		hero_portrait.modulate = Color(0.95, 0.88, 0.76, 0.92)
		add_child(hero_portrait)
		move_child(hero_portrait, $Title.get_index())
	if subtitle_label == null:
		subtitle_label = Label.new()
		subtitle_label.name = "Subtitle"
		subtitle_label.text = "Короткий забег. Темный данж. Последний костер."
		subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ShellUIStyle.apply_label(subtitle_label, Color(0.74, 0.63, 0.48, 1.0), 15)
		add_child(subtitle_label)
		move_child(subtitle_label, $Title.get_index() + 1)
	if title_accent == null:
		title_accent = ColorRect.new()
		title_accent.name = "TitleAccent"
		title_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		title_accent.color = Color(0.74, 0.42, 0.16, 0.54)
		add_child(title_accent)
		move_child(title_accent, subtitle_label.get_index())

func layout_menu() -> void:
	if menu_frame == null or $Title == null or $MenuPanel == null:
		return
	var viewport_size = get_viewport_rect().size
	var edge_margin = 24.0
	var content_width = min(430.0, max(300.0, viewport_size.x - edge_margin * 2.0))
	content_width = min(content_width, viewport_size.x)
	var content_size = Vector2(content_width, 390.0)
	var content_min_x = 0.0 if content_size.x >= viewport_size.x - edge_margin * 2.0 else edge_margin
	var content_min_y = 0.0 if content_size.y >= viewport_size.y - edge_margin * 2.0 else edge_margin
	var content_position = Vector2(
		clamp(viewport_size.x * 0.5 - content_size.x * 0.5, content_min_x, max(content_min_x, viewport_size.x - content_size.x - content_min_x)),
		clamp(viewport_size.y * 0.5 - content_size.y * 0.46, content_min_y, max(content_min_y, viewport_size.y - content_size.y - content_min_y))
	)
	menu_frame.position = Vector2(max(0.0, content_position.x - 28.0), max(0.0, content_position.y - 22.0))
	menu_frame.size = Vector2(min(viewport_size.x - menu_frame.position.x, content_size.x + 56.0), min(viewport_size.y - menu_frame.position.y, content_size.y + 48.0))
	if arch_silhouette != null:
		arch_silhouette.position = Vector2(max(0.0, content_position.x - 118.0), max(0.0, content_position.y - 86.0))
		arch_silhouette.size = Vector2(min(690.0, viewport_size.x - arch_silhouette.position.x), min(522.0, viewport_size.y - arch_silhouette.position.y))
	if title_glow != null:
		title_glow.position = Vector2(max(0.0, content_position.x - 90.0), max(0.0, content_position.y - 56.0))
		title_glow.size = Vector2(min(content_size.x + 180.0, viewport_size.x - title_glow.position.x), 158.0)
	if foreground_fog != null:
		foreground_fog.position = Vector2(0.0, viewport_size.y * 0.55)
		foreground_fog.size = Vector2(viewport_size.x, viewport_size.y * 0.45)
	if left_torch != null:
		left_torch.position = Vector2(max(0.0, content_position.x - 172.0), content_position.y + 118.0)
		left_torch.size = Vector2(220.0, 220.0)
	if right_torch != null:
		right_torch.position = Vector2(min(viewport_size.x - 180.0, content_position.x + content_size.x + 170.0), content_position.y + 126.0)
		right_torch.size = Vector2(180.0, 180.0)
	$Title.position = content_position
	$Title.size = Vector2(content_size.x, 76.0)
	if subtitle_label != null:
		subtitle_label.position = content_position + Vector2(0.0, 72.0)
		subtitle_label.size = Vector2(content_size.x, 26.0)
	if title_accent != null:
		var accent_inset = min(86.0, content_size.x * 0.20)
		title_accent.position = content_position + Vector2(accent_inset, 66.0)
		title_accent.size = Vector2(max(80.0, content_size.x - accent_inset * 2.0), 2.0)
	var menu_width = min(300.0, content_size.x)
	$MenuPanel.position = content_position + Vector2((content_size.x - menu_width) * 0.5, 158.0)
	$MenuPanel.size = Vector2(menu_width, 190.0)
	if hero_portrait != null:
		var hero_size = min(260.0, max(150.0, viewport_size.x * 0.28))
		var hero_x = content_position.x + content_size.x + 82.0
		if hero_x + hero_size > viewport_size.x - edge_margin:
			hero_x = viewport_size.x - hero_size - edge_margin
		if hero_x < content_position.x + content_size.x - 20.0:
			hero_x = viewport_size.x - hero_size - edge_margin
		var hero_position = Vector2(clamp(hero_x, edge_margin, max(edge_margin, viewport_size.x - hero_size - edge_margin)), clamp(viewport_size.y * 0.5 - hero_size * 0.5, edge_margin, max(edge_margin, viewport_size.y - hero_size - edge_margin)))
		hero_portrait.position = hero_position
		hero_portrait.size = Vector2(hero_size, hero_size)
		if hero_glow != null:
			hero_glow.position = Vector2(max(0.0, hero_position.x - hero_size * 0.36), max(0.0, hero_position.y - hero_size * 0.33))
			hero_glow.size = Vector2(min(hero_size * 1.73, viewport_size.x - hero_glow.position.x), min(hero_size * 1.62, viewport_size.y - hero_glow.position.y))
		if hero_shadow != null:
			hero_shadow.position = Vector2(hero_position.x + hero_size * 0.03, min(viewport_size.y - 48.0, hero_position.y + hero_size * 0.84))
			hero_shadow.size = Vector2(hero_size * 0.96, 64.0)

func create_soft_light_texture(color: Color, max_alpha: float, falloff: float, center: Vector2 = Vector2(0.50, 0.50), scale: Vector2 = Vector2.ONE) -> ImageTexture:
	var width = 128
	var height = 128
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(float(x) / float(width - 1), float(y) / float(height - 1))
			var delta = Vector2((uv.x - center.x) / max(0.01, scale.x), (uv.y - center.y) / max(0.01, scale.y))
			var distance = delta.length()
			var alpha = pow(max(0.0, 1.0 - distance / 0.56), falloff) * max_alpha
			image.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
	return ImageTexture.create_from_image(image)

func create_arch_silhouette_texture() -> ImageTexture:
	var width = 192
	var height = 144
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(height):
		for x in range(width):
			var uv = Vector2(float(x) / float(width - 1), float(y) / float(height - 1))
			var arch_center = Vector2(0.50, 0.52)
			var arch_distance = Vector2((uv.x - arch_center.x) / 0.42, (uv.y - arch_center.y) / 0.64).length()
			var inner_distance = Vector2((uv.x - arch_center.x) / 0.28, (uv.y - arch_center.y) / 0.48).length()
			var pillars = (uv.x < 0.18 or uv.x > 0.82) and uv.y > 0.34
			var arch = arch_distance < 1.0 and inner_distance > 0.82 and uv.y > 0.08
			var floor = uv.y > 0.82
			var alpha = 0.0
			if arch or pillars:
				alpha = 0.38
			if floor:
				alpha = max(alpha, 0.28)
			if alpha <= 0.0:
				continue
			var noise = (float((x * 37 + y * 91) % 17) / 17.0) * 0.06
			image.set_pixel(x, y, Color(0.020 + noise, 0.016 + noise, 0.014 + noise, alpha))
	return ImageTexture.create_from_image(image)

func create_foreground_fog_texture() -> ImageTexture:
	var width = 192
	var height = 64
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(float(x) / float(width - 1), float(y) / float(height - 1))
			var band = max(0.0, 1.0 - abs(uv.y - 0.45) * 3.4)
			var noise = sin(float(x) * 0.12) * 0.04 + sin(float(x) * 0.035 + float(y) * 0.18) * 0.03
			var alpha = max(0.0, band + noise) * 0.16
			image.set_pixel(x, y, Color(0.14, 0.10, 0.07, alpha))
	return ImageTexture.create_from_image(image)

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(ScenePaths.CHARACTER_SELECT)

func _on_load_game_pressed() -> void:
	get_tree().change_scene_to_file(ScenePaths.LOAD_MENU)

func _on_exit_pressed() -> void:
	get_tree().quit()

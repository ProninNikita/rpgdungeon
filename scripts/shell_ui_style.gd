extends RefCounted

const HERO_BASE_SHEET = "res://assets/pixel/battle/hero_base_sheet.png"
const HERO_VAMPIRE_SHEET = "res://assets/pixel/battle/hero_vampire_sheet.png"
const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")

static func apply_screen(root: Control) -> void:
	var background = root.get_node_or_null("Background")
	if background is ColorRect:
		background.color = Color(0.010, 0.011, 0.014, 1.0)

	if root.get_node_or_null("ShellBackdrop") != null:
		return

	var backdrop = TextureRect.new()
	backdrop.name = "ShellBackdrop"
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.texture = create_backdrop_texture()
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_SCALE
	root.add_child(backdrop)
	root.move_child(backdrop, 1)

	var shade = ColorRect.new()
	shade.name = "ShellBackdropShade"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	shade.color = Color(0.0, 0.0, 0.0, 0.38)
	root.add_child(shade)
	root.move_child(shade, 2)

static func apply_title(label: Label, font_size: int = 48) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.76, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.025, 0.018, 0.014, 1.0))
	label.add_theme_constant_override("outline_size", 3)

static func apply_label(label: Label, color: Color = Color(0.84, 0.78, 0.68, 1.0), font_size: int = 16) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.018, 0.014, 0.012, 1.0))
	label.add_theme_constant_override("outline_size", 1)

static func apply_panel(panel: Control, strong: bool = false) -> void:
	if panel == null:
		return
	var background = Color(0.040, 0.033, 0.030, 0.95) if strong else Color(0.030, 0.026, 0.024, 0.88)
	var border = Color(0.55, 0.39, 0.23, 1.0) if strong else Color(0.36, 0.27, 0.19, 0.95)
	panel.add_theme_stylebox_override("panel", create_panel_style(background, border, 2 if strong else 1, 4))

static func fit_control_to_viewport(control: Control, viewport_size: Vector2, edge_margin: float) -> void:
	if control == null:
		return
	control.scale = Vector2.ONE
	var required_size = control.get_combined_minimum_size()
	required_size.x = max(required_size.x, control.size.x)
	required_size.y = max(required_size.y, control.size.y)
	var available_size = Vector2(
		max(1.0, viewport_size.x - edge_margin * 2.0),
		max(1.0, viewport_size.y - edge_margin * 2.0)
	)
	var scale_factor = min(
		1.0,
		available_size.x / max(1.0, required_size.x),
		available_size.y / max(1.0, required_size.y)
	)
	control.size = required_size
	control.scale = Vector2(scale_factor, scale_factor)
	var scaled_size = required_size * scale_factor
	control.position = Vector2(
		max(0.0, (viewport_size.x - scaled_size.x) * 0.5),
		max(0.0, (viewport_size.y - scaled_size.y) * 0.5)
	)

static func apply_button(button: Button, variant: String = "normal") -> void:
	if button == null:
		return
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color(0.91, 0.84, 0.72, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.91, 0.66, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.70, 0.95, 0.78, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.46, 0.42, 0.36, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0.018, 0.014, 0.012, 1.0))
	button.add_theme_constant_override("outline_size", 1)
	var border = Color(0.42, 0.30, 0.18, 1.0)
	var background = Color(0.085, 0.065, 0.048, 0.96)
	if variant == "primary":
		border = Color(0.66, 0.46, 0.22, 1.0)
		background = Color(0.125, 0.083, 0.052, 0.98)
	elif variant == "danger":
		border = Color(0.58, 0.22, 0.18, 1.0)
		background = Color(0.090, 0.040, 0.036, 0.96)
	elif variant == "back":
		border = Color(0.32, 0.24, 0.17, 0.92)
		background = Color(0.060, 0.050, 0.044, 0.88)
	button.add_theme_stylebox_override("normal", create_panel_style(background, border, 1, 3))
	button.add_theme_stylebox_override("hover", create_panel_style(background.lightened(0.08), border.lightened(0.28), 1, 3))
	button.add_theme_stylebox_override("pressed", create_panel_style(background.darkened(0.16), Color(0.52, 0.66, 0.40, 1.0), 1, 3))
	button.add_theme_stylebox_override("disabled", create_panel_style(Color(0.036, 0.033, 0.031, 0.70), Color(0.16, 0.14, 0.13, 0.85), 1, 3))

static func create_panel_style(background_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
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
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style

static func make_character_portrait(character_id: String, target_height: float = 150.0) -> TextureRect:
	var portrait = TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var texture = PixelAssetPaths.hero_battle_sheet(character_id)
	if texture == null:
		return portrait
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	var frame_width = float(texture.get_width()) / 3.0
	atlas.region = Rect2(0.0, 0.0, frame_width, float(texture.get_height()))
	portrait.texture = atlas
	portrait.custom_minimum_size = Vector2(target_height, target_height)
	return portrait

static func create_backdrop_texture() -> ImageTexture:
	var width = 320
	var height = 180
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(float(x) / float(width - 1), float(y) / float(height - 1))
			var base = Color(0.012, 0.011, 0.014, 1.0)
			if uv.y > 0.54:
				var tile = 0.012 if (int(x / 16) + int(y / 10)) % 2 == 0 else -0.004
				base = Color(0.036 + tile, 0.032 + tile, 0.034 + tile, 1.0)
			elif uv.y > 0.30:
				base = Color(0.024, 0.021, 0.022, 1.0)
				if x % 45 < 6:
					base = Color(0.012, 0.010, 0.011, 1.0)
			var torch_left = max(0.0, 1.0 - uv.distance_to(Vector2(0.18, 0.42)) / 0.22)
			var torch_right = max(0.0, 1.0 - uv.distance_to(Vector2(0.82, 0.42)) / 0.22)
			var torch = pow(max(torch_left, torch_right), 2.0)
			base = base.lerp(Color(0.55, 0.20, 0.07, 1.0), torch * 0.34)
			var vignette = smoothstep(0.20, 0.82, uv.distance_to(Vector2(0.5, 0.52)))
			base = base.darkened(vignette * 0.48)
			image.set_pixel(x, y, base)
	return ImageTexture.create_from_image(image)

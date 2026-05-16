extends SceneTree

const VARIANTS = ["crypt", "moss", "ember"]
const FRAME_COUNT = 4

func _init() -> void:
	for variant in VARIANTS:
		generate_variant_sheet(variant)
	print("Generated map walk sheets.")
	quit(0)

func generate_variant_sheet(variant: String) -> void:
	var source_path = "res://assets/pixel/map/%s/player.png" % variant
	var source = Image.new()
	var error = source.load(ProjectSettings.globalize_path(source_path))
	if error != OK:
		push_error("Could not load player map source: %s" % source_path)
		return
	source.convert(Image.FORMAT_RGBA8)
	save_sheet(create_walk_sheet(source, false), "res://assets/pixel/map/%s/player_sheet.png" % variant)
	save_sheet(create_walk_sheet(source, true), "res://assets/pixel/map/%s/player_vampire_sheet.png" % variant)

func save_sheet(sheet: Image, path: String) -> void:
	var error = sheet.save_png(ProjectSettings.globalize_path(path))
	if error != OK:
		push_error("Could not save map walk sheet: %s" % path)

func create_walk_sheet(source: Image, vampire: bool) -> Image:
	var frame_width = source.get_width()
	var frame_height = source.get_height()
	var sheet = Image.create(frame_width * FRAME_COUNT, frame_height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for frame_index in range(FRAME_COUNT):
		var frame = create_actor_frame(source, frame_index)
		if vampire:
			recolor_vampire_frame(frame)
			draw_vampire_cape(frame, frame_index)
		else:
			draw_base_step_accents(frame, frame_index)
		sheet.blit_rect(frame, Rect2i(Vector2i.ZERO, Vector2i(frame_width, frame_height)), Vector2i(frame_width * frame_index, 0))
	return sheet

func create_actor_frame(source: Image, frame_index: int) -> Image:
	if frame_index == 3:
		return create_bump_frame(source)
	return create_walk_frame(source, frame_index)

func create_walk_frame(source: Image, frame_index: int) -> Image:
	var frame_width = source.get_width()
	var frame_height = source.get_height()
	var frame = Image.create(frame_width, frame_height, false, Image.FORMAT_RGBA8)
	frame.fill(Color(0, 0, 0, 0))
	if frame_index == 0:
		frame.blit_rect(source, Rect2i(Vector2i.ZERO, Vector2i(frame_width, frame_height)), Vector2i.ZERO)
		return frame

	var step_direction = -1 if frame_index == 1 else 1
	for y in range(frame_height):
		for x in range(frame_width):
			var pixel = source.get_pixel(x, y)
			if pixel.a <= 0.02:
				continue
			var shifted = get_walk_pixel_offset(x, y, frame_width, frame_height, step_direction)
			put_pixel(frame, x + shifted.x, y + shifted.y, pixel)
	draw_step_shadow(frame, step_direction)
	return frame

func create_bump_frame(source: Image) -> Image:
	var frame_width = source.get_width()
	var frame_height = source.get_height()
	var frame = Image.create(frame_width, frame_height, false, Image.FORMAT_RGBA8)
	frame.fill(Color(0, 0, 0, 0))
	for y in range(frame_height):
		for x in range(frame_width):
			var pixel = source.get_pixel(x, y)
			if pixel.a <= 0.02:
				continue
			var shifted = get_bump_pixel_offset(x, y, frame_width, frame_height)
			put_pixel(frame, x + shifted.x, y + shifted.y, pixel)
	draw_bump_shadow(frame)
	return frame

func get_bump_pixel_offset(x: int, y: int, frame_width: int, frame_height: int) -> Vector2i:
	var upper_line = int(float(frame_height) * 0.42)
	var body_line = int(float(frame_height) * 0.68)
	if y < upper_line:
		return Vector2i(1, 1)
	if y < body_line:
		return Vector2i(0, 1)
	var side = -1 if x < int(float(frame_width) * 0.50) else 1
	return Vector2i(side, 0)

func get_walk_pixel_offset(x: int, y: int, frame_width: int, frame_height: int, step_direction: int) -> Vector2i:
	var body_line = int(float(frame_height) * 0.60)
	var foot_line = int(float(frame_height) * 0.78)
	if y < body_line:
		return Vector2i(step_direction, -1 if y < int(float(frame_height) * 0.36) else 0)
	var side = -1 if x < int(float(frame_width) * 0.50) else 1
	var leg_push = side * step_direction
	var foot_drop = 1 if y >= foot_line and side == step_direction else 0
	return Vector2i(leg_push, foot_drop)

func draw_step_shadow(frame: Image, step_direction: int) -> void:
	var width = frame.get_width()
	var height = frame.get_height()
	var y = int(height * 0.82)
	var center = int(width * 0.50)
	draw_rect(frame, center - 8 - step_direction, y + 2, 7, 2, Color(0.030, 0.025, 0.022, 0.46))
	draw_rect(frame, center + 2 + step_direction, y + 1, 8, 2, Color(0.030, 0.025, 0.022, 0.42))

func draw_bump_shadow(frame: Image) -> void:
	var width = frame.get_width()
	var height = frame.get_height()
	var y = int(height * 0.84)
	var center = int(width * 0.50)
	draw_rect(frame, center - 10, y + 1, 20, 3, Color(0.025, 0.020, 0.018, 0.50))
	draw_rect(frame, center - 6, y, 12, 2, Color(0.045, 0.035, 0.030, 0.38))

func draw_base_step_accents(frame: Image, frame_index: int) -> void:
	if frame_index == 0:
		return
	if frame_index == 3:
		draw_rect(frame, int(frame.get_width() * 0.34), int(frame.get_height() * 0.76), 15, 2, Color(0.08, 0.06, 0.05, 0.82))
		return
	var width = frame.get_width()
	var height = frame.get_height()
	var step_direction = -1 if frame_index == 1 else 1
	var boot_y = int(height * 0.80)
	var boot_x = int(width * 0.50) + step_direction * 8
	draw_rect(frame, boot_x - 2, boot_y, 5, 2, Color(0.10, 0.08, 0.07, 0.95))

func recolor_vampire_frame(frame: Image) -> void:
	for y in range(frame.get_height()):
		for x in range(frame.get_width()):
			var pixel = frame.get_pixel(x, y)
			if pixel.a <= 0.02:
				continue
			if is_skin_pixel(pixel):
				frame.set_pixel(x, y, pixel.lerp(Color(0.82, 0.76, 0.84, pixel.a), 0.45))
			elif is_leather_pixel(pixel):
				frame.set_pixel(x, y, pixel.lerp(Color(0.34, 0.035, 0.080, pixel.a), 0.54))

func is_skin_pixel(pixel: Color) -> bool:
	return pixel.r > 0.48 and pixel.g > 0.30 and pixel.b > 0.20 and pixel.r > pixel.b * 1.35

func is_leather_pixel(pixel: Color) -> bool:
	return pixel.r > 0.22 and pixel.g > 0.10 and pixel.b < 0.22 and pixel.r >= pixel.g

func draw_vampire_cape(frame: Image, frame_index: int) -> void:
	var width = frame.get_width()
	var height = frame.get_height()
	var wave = -2 if frame_index == 3 else frame_index - 1
	for y in range(int(height * 0.33), int(height * 0.90)):
		var t = float(y) / float(max(1, height - 1))
		var cape_width = int(lerp(4.0, 9.0, t))
		var start_x = int(width * 0.24) + wave - int(sin(float(y) * 0.55 + float(frame_index)) * 1.5)
		for x in range(start_x, start_x + cape_width):
			if x < 1 or x >= width - 1:
				continue
			var existing = frame.get_pixel(x, y)
			if existing.a > 0.72:
				continue
			var edge = 1.0 if x == start_x or x == start_x + cape_width - 1 else 0.0
			var cape_color = Color(0.17 + edge * 0.08, 0.012, 0.045, 0.88 - t * 0.18)
			frame.set_pixel(x, y, cape_color)
	draw_rect(frame, int(width * 0.34), int(height * 0.40), 2, 12, Color(0.58, 0.07, 0.10, 0.95))
	if frame_index == 3:
		draw_rect(frame, int(width * 0.28), int(height * 0.72), 8, 3, Color(0.24, 0.015, 0.045, 0.82))

func draw_rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, y + height):
		for px in range(x, x + width):
			put_pixel(image, px, py, color)

func put_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
		image.set_pixel(x, y, color)

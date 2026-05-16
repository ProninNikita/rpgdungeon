extends SceneTree

const BASE_SHEET = "res://assets/pixel/battle/hero_base_sheet.png"
const OUT_SHEET = "res://assets/pixel/battle/hero_vampire_sheet.png"
const SOURCE_COPY = "res://assets/source/generated/hero_vampire_from_base_source.png"

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var source = Image.new()
	var load_error = source.load(ProjectSettings.globalize_path(BASE_SHEET))
	if load_error != OK:
		push_error("Failed to load base hero sheet: %s" % BASE_SHEET)
		quit(1)
		return

	var output = Image.create(source.get_width(), source.get_height(), false, Image.FORMAT_RGBA8)
	var frame_width = source.get_width() / 3
	draw_all_capes(output, source, frame_width)

	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var pixel = source.get_pixel(x, y)
			if pixel.a <= 0.01:
				continue
			var frame_index = int(x / frame_width)
			var local_x = x - frame_index * frame_width
			output.set_pixel(x, y, recolor_pixel(pixel, frame_index, local_x, y, frame_width, source.get_height()))

	var save_error = output.save_png(ProjectSettings.globalize_path(OUT_SHEET))
	if save_error != OK:
		push_error("Failed to save vampire sheet: %s" % OUT_SHEET)
		quit(1)
		return
	output.save_png(ProjectSettings.globalize_path(SOURCE_COPY))
	print("Generated vampire sheet from base hero: %s" % OUT_SHEET)
	quit(0)

func recolor_pixel(pixel: Color, frame_index: int, local_x: int, y: int, frame_width: int, frame_height: int) -> Color:
	var h = pixel.h
	var s = pixel.s
	var v = pixel.v
	var luminance = pixel.r * 0.299 + pixel.g * 0.587 + pixel.b * 0.114

	if is_skin(pixel, h, s, v):
		var pale = Color(0.74, 0.68, 0.63, pixel.a)
		var warm_shadow = Color(0.37, 0.27, 0.25, pixel.a)
		var amount = clamp((luminance - 0.18) / 0.62, 0.0, 1.0)
		return warm_shadow.lerp(pale, amount)

	if is_leather(pixel, h, s, v):
		var low = Color(0.080, 0.025, 0.040, pixel.a)
		var high = Color(0.42, 0.085, 0.105, pixel.a)
		var amount = clamp((v - 0.10) / 0.50, 0.0, 1.0)
		return low.lerp(high, amount)

	if is_cloth(pixel, h, s, v):
		var low = Color(0.070, 0.074, 0.082, pixel.a)
		var high = Color(0.38, 0.37, 0.38, pixel.a)
		var amount = clamp((v - 0.12) / 0.58, 0.0, 1.0)
		return low.lerp(high, amount)

	if is_gold(pixel, h, s, v):
		return pixel.lerp(Color(0.72, 0.18, 0.24, pixel.a), 0.36)

	if is_attack_slash(pixel, h, s, v, frame_index, local_x, y, frame_width, frame_height):
		var amount = clamp((v - 0.55) / 0.42, 0.0, 1.0)
		return Color(0.50, 0.035, 0.075, pixel.a).lerp(Color(1.0, 0.34, 0.32, pixel.a), amount)

	if s < 0.18 and v < 0.28:
		return pixel.lerp(Color(0.018, 0.018, 0.024, pixel.a), 0.24)

	return pixel

func is_skin(pixel: Color, h: float, s: float, v: float) -> bool:
	return h >= 0.045 and h <= 0.105 and s >= 0.25 and s <= 0.72 and v >= 0.40 and pixel.r > pixel.g and pixel.g > pixel.b

func is_leather(_pixel: Color, h: float, s: float, v: float) -> bool:
	return h >= 0.035 and h <= 0.105 and s >= 0.36 and v <= 0.58

func is_cloth(_pixel: Color, h: float, s: float, v: float) -> bool:
	return h >= 0.095 and h <= 0.170 and s >= 0.16 and s <= 0.55 and v >= 0.18 and v <= 0.72

func is_gold(_pixel: Color, h: float, s: float, v: float) -> bool:
	return h >= 0.105 and h <= 0.155 and s >= 0.42 and v >= 0.44

func is_attack_slash(_pixel: Color, h: float, s: float, v: float, frame_index: int, local_x: int, y: int, frame_width: int, frame_height: int) -> bool:
	if frame_index != 1:
		return false
	if v < 0.70 or s > 0.28:
		return false
	var normalized_x = float(local_x) / float(frame_width)
	var normalized_y = float(y) / float(frame_height)
	return normalized_x < 0.70 and normalized_y > 0.14 and normalized_y < 0.72

func draw_all_capes(output: Image, source: Image, frame_width: int) -> void:
	for frame_index in range(3):
		var bounds = find_frame_bounds(source, frame_index, frame_width)
		if bounds.size.x <= 0.0:
			continue
		draw_cape(output, frame_index, frame_width, bounds)

func find_frame_bounds(source: Image, frame_index: int, frame_width: int) -> Rect2i:
	var min_x = frame_width
	var min_y = source.get_height()
	var max_x = 0
	var max_y = 0
	for y in range(source.get_height()):
		for local_x in range(frame_width):
			var x = frame_index * frame_width + local_x
			if source.get_pixel(x, y).a > 0.05:
				min_x = min(min_x, local_x)
				min_y = min(min_y, y)
				max_x = max(max_x, local_x)
				max_y = max(max_y, y)
	if max_x <= min_x or max_y <= min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func draw_cape(output: Image, frame_index: int, frame_width: int, bounds: Rect2i) -> void:
	var cape_color = Color(0.075, 0.012, 0.028, 0.92)
	var cape_edge = Color(0.34, 0.045, 0.070, 0.90)
	var origin_x = frame_index * frame_width
	var start_x = int(bounds.position.x + bounds.size.x * 0.24)
	var end_x = int(bounds.position.x + bounds.size.x * 0.62)
	var top_y = int(bounds.position.y + bounds.size.y * 0.16)
	var bottom_y = int(bounds.position.y + bounds.size.y * 0.80)
	for y in range(top_y, bottom_y):
		var t = float(y - top_y) / max(1.0, float(bottom_y - top_y))
		var left = int(lerp(float(start_x), float(bounds.position.x + bounds.size.x * 0.05), t))
		var right = int(lerp(float(end_x), float(bounds.position.x + bounds.size.x * 0.38), t))
		for local_x in range(left, right):
			if local_x < 0 or local_x >= frame_width:
				continue
			var wave = sin(float(y) * 0.045 + float(frame_index) * 1.7) * 8.0
			if float(local_x) < float(left) + wave:
				continue
			var current = output.get_pixel(origin_x + local_x, y)
			if current.a > 0.01:
				continue
			var edge_amount = 1.0 if local_x == left or local_x >= right - 2 else 0.0
			output.set_pixel(origin_x + local_x, y, cape_color.lerp(cape_edge, edge_amount))

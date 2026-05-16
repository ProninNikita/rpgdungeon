extends SceneTree

const OUT_DIR = "res://assets/pixel"
const OUTLINE = Color(0.035, 0.032, 0.045, 1)
const SHADOW = Color(0.0, 0.0, 0.0, 0.30)
const HILITE = Color(1.0, 0.92, 0.70, 1)
const EXTERNAL_ASSET_PATHS = {
	"res://assets/pixel/battle/hero_base_sheet.png": true,
	"res://assets/pixel/battle/hero_vampire_sheet.png": true,
	"res://assets/pixel/battle/goblin_sheet.png": true,
	"res://assets/pixel/battle/skeleton_sheet.png": true,
	"res://assets/pixel/battle/bat_sheet.png": true,
	"res://assets/pixel/battle/slime_sheet.png": true,
	"res://assets/pixel/map/crypt/floor.png": true,
	"res://assets/pixel/map/crypt/floor_1.png": true,
	"res://assets/pixel/map/crypt/floor_2.png": true,
	"res://assets/pixel/map/crypt/floor_3.png": true,
	"res://assets/pixel/map/crypt/wall.png": true,
	"res://assets/pixel/map/crypt/wall_1.png": true,
	"res://assets/pixel/map/crypt/wall_2.png": true,
	"res://assets/pixel/map/crypt/artifact_floor.png": true,
	"res://assets/pixel/map/crypt/shop_floor.png": true,
	"res://assets/pixel/map/crypt/detail_crack.png": true,
	"res://assets/pixel/map/crypt/detail_rubble.png": true,
	"res://assets/pixel/map/crypt/detail_accent.png": true,
	"res://assets/pixel/map/crypt/player.png": true,
	"res://assets/pixel/map/crypt/player_sheet.png": true,
	"res://assets/pixel/map/crypt/player_vampire_sheet.png": true,
	"res://assets/pixel/map/crypt/enemy_goblin.png": true,
	"res://assets/pixel/map/crypt/enemy_skeleton.png": true,
	"res://assets/pixel/map/crypt/enemy_bat.png": true,
	"res://assets/pixel/map/crypt/enemy_slime.png": true,
	"res://assets/pixel/map/ember/floor.png": true,
	"res://assets/pixel/map/ember/floor_1.png": true,
	"res://assets/pixel/map/ember/floor_2.png": true,
	"res://assets/pixel/map/ember/floor_3.png": true,
	"res://assets/pixel/map/ember/wall.png": true,
	"res://assets/pixel/map/ember/wall_1.png": true,
	"res://assets/pixel/map/ember/wall_2.png": true,
	"res://assets/pixel/map/ember/artifact_floor.png": true,
	"res://assets/pixel/map/ember/shop_floor.png": true,
	"res://assets/pixel/map/ember/detail_crack.png": true,
	"res://assets/pixel/map/ember/detail_rubble.png": true,
	"res://assets/pixel/map/ember/detail_accent.png": true,
	"res://assets/pixel/map/ember/player.png": true,
	"res://assets/pixel/map/ember/player_sheet.png": true,
	"res://assets/pixel/map/ember/player_vampire_sheet.png": true,
	"res://assets/pixel/map/ember/enemy_goblin.png": true,
	"res://assets/pixel/map/ember/enemy_skeleton.png": true,
	"res://assets/pixel/map/ember/enemy_bat.png": true,
	"res://assets/pixel/map/ember/enemy_slime.png": true,
	"res://assets/pixel/map/moss/floor.png": true,
	"res://assets/pixel/map/moss/floor_1.png": true,
	"res://assets/pixel/map/moss/floor_2.png": true,
	"res://assets/pixel/map/moss/floor_3.png": true,
	"res://assets/pixel/map/moss/wall.png": true,
	"res://assets/pixel/map/moss/wall_1.png": true,
	"res://assets/pixel/map/moss/wall_2.png": true,
	"res://assets/pixel/map/moss/artifact_floor.png": true,
	"res://assets/pixel/map/moss/shop_floor.png": true,
	"res://assets/pixel/map/moss/detail_crack.png": true,
	"res://assets/pixel/map/moss/detail_rubble.png": true,
	"res://assets/pixel/map/moss/detail_accent.png": true,
	"res://assets/pixel/map/moss/player.png": true,
	"res://assets/pixel/map/moss/player_sheet.png": true,
	"res://assets/pixel/map/moss/player_vampire_sheet.png": true,
	"res://assets/pixel/map/moss/enemy_goblin.png": true,
	"res://assets/pixel/map/moss/enemy_skeleton.png": true,
	"res://assets/pixel/map/moss/enemy_bat.png": true,
	"res://assets/pixel/map/moss/enemy_slime.png": true
}
const EXTERNAL_MAP_ASSET_PREFIXES = [
	"floor_",
	"wall_",
	"detail_",
	"object_",
	"prop_",
	"scene_"
]

const MAP_VARIANTS = {
	"crypt": {
		"floor": Color(0.105, 0.110, 0.145, 1),
		"floor_mid": Color(0.150, 0.155, 0.205, 1),
		"floor_hi": Color(0.210, 0.205, 0.255, 1),
		"wall": Color(0.255, 0.260, 0.330, 1),
		"wall_mid": Color(0.175, 0.180, 0.235, 1),
		"wall_dark": Color(0.070, 0.072, 0.100, 1),
		"gold": Color(0.88, 0.62, 0.22, 1),
		"shop": Color(0.48, 0.25, 0.14, 1)
	},
	"ember": {
		"floor": Color(0.145, 0.075, 0.070, 1),
		"floor_mid": Color(0.225, 0.125, 0.105, 1),
		"floor_hi": Color(0.340, 0.180, 0.130, 1),
		"wall": Color(0.410, 0.215, 0.160, 1),
		"wall_mid": Color(0.245, 0.125, 0.105, 1),
		"wall_dark": Color(0.090, 0.045, 0.045, 1),
		"gold": Color(0.98, 0.48, 0.16, 1),
		"shop": Color(0.54, 0.18, 0.12, 1)
	},
	"moss": {
		"floor": Color(0.080, 0.125, 0.095, 1),
		"floor_mid": Color(0.130, 0.185, 0.135, 1),
		"floor_hi": Color(0.210, 0.265, 0.185, 1),
		"wall": Color(0.225, 0.310, 0.245, 1),
		"wall_mid": Color(0.130, 0.195, 0.145, 1),
		"wall_dark": Color(0.045, 0.075, 0.055, 1),
		"gold": Color(0.76, 0.70, 0.30, 1),
		"shop": Color(0.34, 0.235, 0.125, 1)
	}
}

func _init() -> void:
	generate_all()
	print("Generated polished pixel assets.")
	quit(0)

func generate_all() -> void:
	ensure_dir(OUT_DIR)
	ensure_dir("%s/map" % OUT_DIR)
	ensure_dir("%s/battle" % OUT_DIR)
	for variant in MAP_VARIANTS.keys():
		generate_map_variant(str(variant), MAP_VARIANTS[variant])
	generate_battle_sprites()

func ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))

func make_image(width: int, height: int, fill_color: Color = Color(0, 0, 0, 0)) -> Image:
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(fill_color)
	return image

func save_image(image: Image, path: String) -> void:
	if should_preserve_external_asset(path):
		preserve_external_asset(path)
		return
	image.save_png(path)

func should_preserve_external_asset(path: String) -> bool:
	if EXTERNAL_ASSET_PATHS.has(path):
		return true
	if not path.begins_with("res://assets/pixel/map/"):
		return false
	var file_name = path.get_file()
	for prefix in EXTERNAL_MAP_ASSET_PREFIXES:
		if file_name.begins_with(prefix):
			return true
	return false

func preserve_external_asset(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("External pixel asset is missing and will not be generated: %s" % path)

func put_pixel(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
		image.set_pixel(x, y, color)

func draw_rect(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	for py in range(y, y + height):
		for px in range(x, x + width):
			put_pixel(image, px, py, color)

func draw_line(image: Image, from_pos: Vector2i, to_pos: Vector2i, color: Color, thickness: int = 1) -> void:
	var x0 = from_pos.x
	var y0 = from_pos.y
	var x1 = to_pos.x
	var y1 = to_pos.y
	var dx = abs(x1 - x0)
	var sx = 1 if x0 < x1 else -1
	var dy = -abs(y1 - y0)
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	while true:
		draw_rect(image, x0 - floori(thickness / 2.0), y0 - floori(thickness / 2.0), thickness, thickness, color)
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

func draw_arc(
	image: Image,
	center: Vector2i,
	rx: int,
	ry: int,
	start_deg: float,
	end_deg: float,
	color: Color,
	thickness: int = 1,
	segments: int = 24
) -> void:
	var previous = Vector2i(
		center.x + int(round(cos(deg_to_rad(start_deg)) * rx)),
		center.y + int(round(sin(deg_to_rad(start_deg)) * ry))
	)
	for i in range(1, segments + 1):
		var t = float(i) / float(segments)
		var angle = deg_to_rad(lerpf(start_deg, end_deg, t))
		var current = Vector2i(
			center.x + int(round(cos(angle) * rx)),
			center.y + int(round(sin(angle) * ry))
		)
		draw_line(image, previous, current, color, thickness)
		previous = current

func draw_outline(image: Image, x: int, y: int, width: int, height: int, color: Color) -> void:
	draw_rect(image, x, y, width, 1, color)
	draw_rect(image, x, y + height - 1, width, 1, color)
	draw_rect(image, x, y, 1, height, color)
	draw_rect(image, x + width - 1, y, 1, height, color)

func draw_rect_outline(image: Image, x: int, y: int, width: int, height: int, fill: Color, outline: Color = OUTLINE) -> void:
	draw_rect(image, x - 1, y - 1, width + 2, height + 2, outline)
	draw_rect(image, x, y, width, height, fill)

func draw_lit_rect(image: Image, rect: Rect2i, fill: Color, light: Color, dark: Color) -> void:
	draw_rect(image, rect.position.x, rect.position.y, rect.size.x, rect.size.y, fill)
	draw_line(image, rect.position, Vector2i(rect.position.x + rect.size.x - 1, rect.position.y), light)
	draw_line(image, rect.position, Vector2i(rect.position.x, rect.position.y + rect.size.y - 1), light.darkened(0.15))
	draw_line(image, Vector2i(rect.position.x, rect.position.y + rect.size.y - 1), Vector2i(rect.position.x + rect.size.x - 1, rect.position.y + rect.size.y - 1), dark)
	draw_line(image, Vector2i(rect.position.x + rect.size.x - 1, rect.position.y), Vector2i(rect.position.x + rect.size.x - 1, rect.position.y + rect.size.y - 1), dark)

func draw_glint(image: Image, center: Vector2i, color: Color) -> void:
	put_pixel(image, center.x, center.y, color)
	put_pixel(image, center.x - 1, center.y, color.darkened(0.08))
	put_pixel(image, center.x + 1, center.y, color.darkened(0.08))
	put_pixel(image, center.x, center.y - 1, color.darkened(0.08))
	put_pixel(image, center.x, center.y + 1, color.darkened(0.08))

func draw_ellipse(image: Image, center: Vector2i, rx: int, ry: int, color: Color) -> void:
	for y in range(center.y - ry, center.y + ry + 1):
		for x in range(center.x - rx, center.x + rx + 1):
			var nx = float(x - center.x) / float(max(1, rx))
			var ny = float(y - center.y) / float(max(1, ry))
			if nx * nx + ny * ny <= 1.0:
				put_pixel(image, x, y, color)

func draw_ellipse_outline(image: Image, center: Vector2i, rx: int, ry: int, color: Color) -> void:
	for y in range(center.y - ry, center.y + ry + 1):
		for x in range(center.x - rx, center.x + rx + 1):
			var nx = float(x - center.x) / float(max(1, rx))
			var ny = float(y - center.y) / float(max(1, ry))
			var value = nx * nx + ny * ny
			if value <= 1.05 and value >= 0.78:
				put_pixel(image, x, y, color)

func draw_diamond(image: Image, center: Vector2i, radius: int, color: Color) -> void:
	for y in range(-radius, radius + 1):
		var half_width = radius - abs(y)
		draw_rect(image, center.x - half_width, center.y + y, half_width * 2 + 1, 1, color)

func draw_triangle(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, color: Color) -> void:
	var min_x = mini(a.x, mini(b.x, c.x))
	var max_x = maxi(a.x, maxi(b.x, c.x))
	var min_y = mini(a.y, mini(b.y, c.y))
	var max_y = maxi(a.y, maxi(b.y, c.y))
	var denom = float((b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y))
	if denom == 0.0:
		return
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var alpha = float((b.y - c.y) * (x - c.x) + (c.x - b.x) * (y - c.y)) / denom
			var beta = float((c.y - a.y) * (x - c.x) + (a.x - c.x) * (y - c.y)) / denom
			var gamma = 1.0 - alpha - beta
			if alpha >= 0.0 and beta >= 0.0 and gamma >= 0.0:
				put_pixel(image, x, y, color)

func draw_quad(image: Image, a: Vector2i, b: Vector2i, c: Vector2i, d: Vector2i, color: Color) -> void:
	draw_triangle(image, a, b, c, color)
	draw_triangle(image, a, c, d, color)

func generate_map_variant(variant: String, palette: Dictionary) -> void:
	var dir = "%s/map/%s" % [OUT_DIR, variant]
	ensure_dir(dir)
	generate_floor_tile("%s/floor.png" % dir, palette)
	generate_wall_tile("%s/wall.png" % dir, palette)
	generate_room_tile("%s/artifact_floor.png" % dir, palette, palette["gold"], true)
	generate_room_tile("%s/shop_floor.png" % dir, palette, palette["shop"], false)
	generate_marker_set(dir, palette)
	preserve_external_asset("%s/player.png" % dir)
	generate_map_actor("%s/enemy_goblin.png" % dir, "goblin")
	generate_map_actor("%s/enemy_skeleton.png" % dir, "skeleton")
	generate_map_actor("%s/enemy_bat.png" % dir, "bat")
	generate_map_actor("%s/enemy_slime.png" % dir, "slime")

func generate_floor_tile(path: String, palette: Dictionary) -> void:
	var image = make_image(32, 32, palette["floor"])
	var stones = [
		Rect2i(0, 1, 10, 7), Rect2i(11, 0, 11, 9), Rect2i(23, 2, 9, 7),
		Rect2i(2, 10, 13, 8), Rect2i(16, 11, 13, 7),
		Rect2i(0, 20, 12, 8), Rect2i(13, 21, 10, 9), Rect2i(24, 20, 8, 8)
	]
	for i in range(stones.size()):
		var stone = stones[i]
		var fill = palette["floor_mid"] if i % 3 != 1 else palette["floor"]
		draw_lit_rect(image, stone, fill, palette["floor_hi"], palette["wall_dark"])
	draw_line(image, Vector2i(6, 16), Vector2i(11, 15), palette["wall_dark"])
	draw_line(image, Vector2i(22, 7), Vector2i(28, 8), palette["wall_dark"])
	draw_line(image, Vector2i(19, 24), Vector2i(16, 28), palette["wall_dark"])
	put_pixel(image, 5, 5, palette["floor_hi"])
	put_pixel(image, 27, 15, palette["floor_hi"])
	put_pixel(image, 9, 27, palette["floor_hi"].darkened(0.1))
	save_image(image, path)

func generate_wall_tile(path: String, palette: Dictionary) -> void:
	var image = make_image(32, 32, palette["wall_dark"])
	draw_rect(image, 1, 1, 30, 30, palette["wall_mid"])
	var rows = [2, 9, 16, 23]
	for row_index in range(rows.size()):
		var y = rows[row_index]
		var offset = 0 if row_index % 2 == 0 else 5
		for x in range(-offset, 32, 10):
			draw_lit_rect(image, Rect2i(x, y, 9, 6), palette["wall"], palette["floor_hi"], palette["wall_dark"])
	draw_line(image, Vector2i(6, 5), Vector2i(13, 13), palette["wall_dark"])
	draw_line(image, Vector2i(23, 17), Vector2i(18, 25), palette["wall_dark"])
	draw_line(image, Vector2i(2, 15), Vector2i(30, 15), palette["wall_dark"].lightened(0.06))
	draw_rect(image, 3, 26, 3, 3, palette["wall_mid"].lightened(0.10))
	draw_rect(image, 25, 4, 4, 2, palette["wall_mid"].lightened(0.12))
	draw_outline(image, 1, 1, 30, 30, OUTLINE)
	save_image(image, path)

func generate_room_tile(path: String, palette: Dictionary, accent: Color, artifact: bool) -> void:
	var image = make_image(32, 32, palette["floor"])
	generate_floor_details(image, palette)
	draw_outline(image, 2, 2, 28, 28, OUTLINE)
	draw_outline(image, 3, 3, 26, 26, accent.darkened(0.25))
	draw_outline(image, 6, 6, 20, 20, accent.lightened(0.14))
	if artifact:
		draw_ellipse_outline(image, Vector2i(16, 16), 10, 8, accent.darkened(0.10))
		draw_diamond(image, Vector2i(16, 16), 7, accent)
		draw_diamond(image, Vector2i(16, 16), 4, accent.lightened(0.18))
		draw_diamond(image, Vector2i(16, 16), 2, HILITE)
		draw_glint(image, Vector2i(16, 9), HILITE)
	else:
		draw_rect_outline(image, 8, 13, 16, 9, accent.darkened(0.22), OUTLINE)
		draw_rect(image, 10, 11, 12, 3, accent.lightened(0.15))
		draw_rect(image, 12, 8, 8, 4, accent)
		draw_rect(image, 13, 16, 6, 2, HILITE.darkened(0.05))
		draw_rect(image, 10, 20, 12, 1, accent.lightened(0.20))
	save_image(image, path)

func generate_floor_details(image: Image, palette: Dictionary) -> void:
	draw_lit_rect(image, Rect2i(4, 4, 9, 5), palette["floor_mid"], palette["floor_hi"], palette["wall_dark"])
	draw_lit_rect(image, Rect2i(17, 5, 10, 6), palette["floor_mid"], palette["floor_hi"], palette["wall_dark"])
	draw_lit_rect(image, Rect2i(5, 18, 12, 6), palette["floor_mid"], palette["floor_hi"], palette["wall_dark"])
	draw_lit_rect(image, Rect2i(20, 20, 8, 5), palette["floor_mid"], palette["floor_hi"], palette["wall_dark"])
	draw_line(image, Vector2i(4, 9), Vector2i(13, 9), palette["wall_dark"])
	draw_line(image, Vector2i(17, 11), Vector2i(27, 11), palette["wall_dark"])

func generate_marker_set(dir: String, palette: Dictionary) -> void:
	generate_marker("%s/marker_artifact.png" % dir, palette["gold"], "artifact")
	generate_marker("%s/marker_shop.png" % dir, palette["shop"], "shop")
	generate_marker("%s/marker_used.png" % dir, Color(0.24, 0.24, 0.28, 1), "used")
	generate_marker("%s/marker_fountain.png" % dir, Color(0.20, 0.58, 0.92, 1), "fountain")
	generate_marker("%s/marker_chest.png" % dir, Color(0.78, 0.48, 0.18, 1), "chest")
	generate_marker("%s/marker_exit.png" % dir, Color(0.18, 0.68, 0.32, 1), "exit")
	generate_marker("%s/marker_elite.png" % dir, Color(0.82, 0.18, 0.18, 1), "elite")

func generate_marker(path: String, color: Color, kind: String) -> void:
	var image = make_image(32, 32)
	draw_ellipse(image, Vector2i(16, 18), 12, 9, OUTLINE)
	draw_ellipse(image, Vector2i(16, 17), 11, 9, color.darkened(0.35))
	draw_ellipse_outline(image, Vector2i(16, 17), 11, 9, color.lightened(0.22))
	if kind == "artifact":
		draw_diamond(image, Vector2i(16, 15), 8, OUTLINE)
		draw_diamond(image, Vector2i(16, 15), 6, HILITE)
		draw_diamond(image, Vector2i(16, 15), 3, color)
		draw_glint(image, Vector2i(16, 8), HILITE)
	elif kind == "shop":
		draw_rect_outline(image, 9, 14, 14, 9, Color(0.34, 0.17, 0.08, 1))
		draw_rect(image, 10, 10, 12, 5, color.lightened(0.15))
		draw_line(image, Vector2i(10, 15), Vector2i(22, 15), HILITE.darkened(0.2))
		draw_rect(image, 13, 18, 6, 2, HILITE)
	elif kind == "fountain":
		draw_rect_outline(image, 12, 10, 8, 13, color.darkened(0.20))
		draw_ellipse(image, Vector2i(16, 12), 7, 3, color.lightened(0.30))
		draw_line(image, Vector2i(16, 5), Vector2i(16, 21), HILITE, 2)
		draw_line(image, Vector2i(13, 18), Vector2i(19, 18), color.lightened(0.22))
	elif kind == "chest":
		draw_rect_outline(image, 9, 13, 14, 10, Color(0.45, 0.22, 0.08, 1))
		draw_rect(image, 10, 10, 12, 5, color)
		draw_line(image, Vector2i(10, 15), Vector2i(22, 15), OUTLINE)
		draw_rect(image, 15, 15, 3, 4, HILITE)
	elif kind == "exit":
		draw_rect_outline(image, 12, 8, 5, 16, HILITE.darkened(0.05))
		draw_triangle(image, Vector2i(17, 9), Vector2i(26, 16), Vector2i(17, 23), OUTLINE)
		draw_triangle(image, Vector2i(18, 11), Vector2i(24, 16), Vector2i(18, 21), HILITE)
	elif kind == "elite":
		draw_triangle(image, Vector2i(16, 4), Vector2i(25, 27), Vector2i(7, 27), color.darkened(0.25))
		draw_line(image, Vector2i(16, 5), Vector2i(25, 27), OUTLINE)
		draw_line(image, Vector2i(16, 5), Vector2i(7, 27), OUTLINE)
		draw_rect(image, 15, 8, 3, 12, HILITE)
		draw_rect(image, 15, 23, 3, 3, HILITE)
	else:
		draw_rect_outline(image, 12, 13, 8, 7, Color(0.70, 0.70, 0.75, 1))
	save_image(image, path)

func generate_map_actor(path: String, kind: String) -> void:
	var image = make_image(32, 32)
	draw_ellipse(image, Vector2i(16, 27), 9, 3, SHADOW)
	if kind == "hero":
		draw_map_sword_hero(image)
	elif kind == "goblin":
		draw_goblin(image, 0, Vector2i(0, 0), 0.48)
	elif kind == "skeleton":
		draw_skeleton(image, 0, Vector2i(0, 0), 0.48)
	elif kind == "bat":
		draw_bat(image, 0, Vector2i(0, 0), 0.48)
	else:
		draw_slime(image, 0, Vector2i(0, 0), 0.48)
	save_image(image, path)

func draw_map_sword_hero(image: Image) -> void:
	var skin = Color(0.76, 0.50, 0.36, 1)
	var hair = Color(0.035, 0.036, 0.050, 1)
	var leather = Color(0.36, 0.22, 0.13, 1)
	var leather_light = Color(0.54, 0.36, 0.22, 1)
	var cloth = Color(0.48, 0.43, 0.33, 1)
	var boot = Color(0.055, 0.060, 0.075, 1)
	var steel = Color(0.73, 0.82, 0.84, 1)
	var brass = Color(0.66, 0.48, 0.25, 1)
	draw_line(image, Vector2i(20, 10), Vector2i(29, 3), OUTLINE, 4)
	draw_line(image, Vector2i(20, 10), Vector2i(29, 3), steel, 2)
	draw_line(image, Vector2i(18, 11), Vector2i(22, 8), brass, 2)
	draw_line(image, Vector2i(18, 7), Vector2i(23, 12), brass, 1)
	draw_rect_outline(image, 12, 15, 8, 8, leather, OUTLINE)
	draw_rect(image, 15, 15, 5, 4, leather_light)
	draw_line(image, Vector2i(11, 16), Vector2i(8, 21), cloth, 3)
	draw_line(image, Vector2i(21, 16), Vector2i(24, 21), cloth, 3)
	draw_ellipse(image, Vector2i(11, 21), 3, 3, skin)
	draw_ellipse(image, Vector2i(24, 21), 3, 3, skin)
	draw_rect(image, 13, 23, 3, 5, cloth.darkened(0.16))
	draw_rect(image, 18, 23, 3, 5, cloth.darkened(0.20))
	draw_rect(image, 11, 27, 6, 3, boot)
	draw_rect(image, 18, 27, 7, 3, boot)
	draw_ellipse(image, Vector2i(16, 11), 6, 6, OUTLINE)
	draw_ellipse(image, Vector2i(16, 11), 4, 5, skin)
	draw_line(image, Vector2i(11, 8), Vector2i(21, 6), hair, 4)
	draw_line(image, Vector2i(12, 7), Vector2i(9, 13), hair, 3)
	draw_line(image, Vector2i(19, 7), Vector2i(24, 12), hair, 2)
	draw_rect(image, 14, 10, 1, 1, OUTLINE)
	draw_rect(image, 18, 10, 1, 1, OUTLINE)
	draw_line(image, Vector2i(14, 14), Vector2i(19, 14), Color(0.22, 0.10, 0.08, 1), 1)
	draw_rect(image, 14, 18, 4, 1, brass)

func generate_battle_sprites() -> void:
	generate_battle_sheet("hero_base", "hero")
	generate_battle_sheet("hero_vampire", "vampire")
	generate_battle_sheet("goblin", "goblin")
	generate_battle_sheet("skeleton", "skeleton")
	generate_battle_sheet("bat", "bat")
	generate_battle_sheet("slime", "slime")

func generate_battle_sheet(name: String, kind: String) -> void:
	if kind == "hero":
		preserve_external_asset("%s/battle/%s_sheet.png" % [OUT_DIR, name])
		return

	var image = make_image(192, 64)
	for frame in range(3):
		var ox = frame * 64
		draw_ellipse(image, Vector2i(ox + 32, 56), 18, 5, SHADOW)
		if kind == "hero":
			draw_hooded_figure(image, ox, frame, Color(0.22, 0.43, 0.82, 1), Color(0.78, 0.86, 0.96, 1), Color(0.88, 0.72, 0.40, 1))
		elif kind == "vampire":
			draw_hooded_figure(image, ox, frame, Color(0.40, 0.08, 0.16, 1), Color(0.84, 0.78, 0.86, 1), Color(0.92, 0.18, 0.24, 1))
		elif kind == "goblin":
			draw_goblin(image, ox, Vector2i(0, 0), 1.0, frame)
		elif kind == "skeleton":
			draw_skeleton(image, ox, Vector2i(0, 0), 1.0, frame)
		elif kind == "bat":
			draw_bat(image, ox, Vector2i(0, 0), 1.0, frame)
		else:
			draw_slime(image, ox, Vector2i(0, 0), 1.0, frame)
	save_image(image, "%s/battle/%s_sheet.png" % [OUT_DIR, name])

func generate_large_hero_sheet(name: String) -> void:
	var image = make_image(576, 192)
	for frame in range(3):
		draw_large_sword_hero(image, frame * 192, frame)
	save_image(image, "%s/battle/%s_sheet.png" % [OUT_DIR, name])

func draw_large_sword_hero(image: Image, ox: int, frame: int) -> void:
	var skin = Color(0.76, 0.50, 0.36, 1)
	var skin_shadow = Color(0.48, 0.28, 0.22, 1)
	var hair = Color(0.035, 0.036, 0.050, 1)
	var hair_hi = Color(0.095, 0.105, 0.135, 1)
	var leather = Color(0.34, 0.205, 0.125, 1)
	var leather_dark = Color(0.16, 0.095, 0.065, 1)
	var leather_light = Color(0.50, 0.34, 0.22, 1)
	var cloth = Color(0.49, 0.44, 0.34, 1)
	var cloth_dark = Color(0.28, 0.25, 0.20, 1)
	var pants = Color(0.34, 0.295, 0.235, 1)
	var boot = Color(0.055, 0.060, 0.075, 1)
	var steel = Color(0.72, 0.80, 0.82, 1)
	var steel_dark = Color(0.34, 0.42, 0.46, 1)
	var steel_hi = Color(0.91, 0.96, 0.95, 1)
	var brass = Color(0.66, 0.48, 0.25, 1)

	var dx = 8 if frame == 1 else (-5 if frame == 2 else 0)
	var dy = 8 if frame == 1 else (2 if frame == 2 else 0)
	var head = Vector2i(ox + 94 + dx, 58 + dy)
	var torso = Vector2i(ox + 91 + dx, 92 + dy)
	var hip = Vector2i(ox + 91 + dx, 121 + dy)
	var left_shoulder = Vector2i(ox + 72 + dx, 78 + dy)
	var right_shoulder = Vector2i(ox + 106 + dx, 78 + dy)

	draw_ellipse(image, Vector2i(ox + 96, 168), 54, 9, SHADOW)
	if frame == 1:
		draw_arc(image, Vector2i(ox + 92, 90), 83, 55, -172, 32, Color(0.92, 0.96, 0.94, 0.58), 6, 34)
		draw_arc(image, Vector2i(ox + 92, 91), 73, 47, -169, 28, Color(0.74, 0.80, 0.78, 0.52), 3, 34)
		draw_arc(image, Vector2i(ox + 91, 92), 92, 65, -164, 25, Color(0.92, 0.96, 0.94, 0.30), 2, 34)

	draw_large_hero_legs(image, ox, frame, hip, pants, cloth_dark, boot)
	draw_large_hero_torso(image, torso, hip, leather, leather_dark, leather_light, cloth, brass)
	draw_large_hero_arms(image, ox, frame, left_shoulder, right_shoulder, cloth, leather, leather_dark, leather_light, skin, brass)
	draw_large_sword_for_pose(image, ox, frame, steel, steel_dark, steel_hi, brass)
	draw_large_hero_head(image, head, skin, skin_shadow, hair, hair_hi)
	draw_large_rivets(image, torso, brass.lightened(0.22))

	if frame == 2:
		draw_line(image, Vector2i(ox + 54, 45), Vector2i(ox + 142, 144), Color(0.95, 0.05, 0.04, 0.62), 7)
		draw_line(image, Vector2i(ox + 58, 42), Vector2i(ox + 146, 140), Color(1.0, 0.74, 0.24, 0.62), 2)

func draw_large_hero_legs(image: Image, ox: int, frame: int, hip: Vector2i, pants: Color, cloth_dark: Color, boot: Color) -> void:
	var left_knee = Vector2i(ox + 70, 136) if frame != 1 else Vector2i(ox + 66, 146)
	var left_foot = Vector2i(ox + 50, 159) if frame != 1 else Vector2i(ox + 43, 166)
	var right_knee = Vector2i(ox + 119, 134) if frame != 1 else Vector2i(ox + 125, 141)
	var right_foot = Vector2i(ox + 145, 158) if frame != 1 else Vector2i(ox + 148, 160)
	if frame == 2:
		left_knee += Vector2i(-5, 0)
		left_foot += Vector2i(-7, -1)
		right_knee += Vector2i(-3, 2)
		right_foot += Vector2i(-3, 2)

	draw_line(image, hip + Vector2i(-11, -2), left_knee, OUTLINE, 18)
	draw_line(image, hip + Vector2i(-11, -2), left_knee, pants, 13)
	draw_line(image, left_knee, left_foot, OUTLINE, 17)
	draw_line(image, left_knee, left_foot, pants.darkened(0.08), 12)
	draw_line(image, hip + Vector2i(11, -2), right_knee, OUTLINE, 18)
	draw_line(image, hip + Vector2i(11, -2), right_knee, pants.lightened(0.04), 13)
	draw_line(image, right_knee, right_foot, OUTLINE, 17)
	draw_line(image, right_knee, right_foot, pants.darkened(0.10), 12)
	draw_line(image, left_knee + Vector2i(-5, -2), left_knee + Vector2i(8, 3), cloth_dark, 4)
	draw_line(image, right_knee + Vector2i(-7, -2), right_knee + Vector2i(8, 2), cloth_dark, 4)
	draw_line(image, left_foot + Vector2i(-12, 4), left_foot + Vector2i(12, 2), OUTLINE, 13)
	draw_line(image, left_foot + Vector2i(-11, 3), left_foot + Vector2i(10, 1), boot, 9)
	draw_line(image, right_foot + Vector2i(-12, 4), right_foot + Vector2i(13, 3), OUTLINE, 13)
	draw_line(image, right_foot + Vector2i(-10, 3), right_foot + Vector2i(11, 2), boot, 9)
	draw_line(image, left_foot + Vector2i(-4, -1), left_foot + Vector2i(7, -2), boot.lightened(0.18), 2)
	draw_line(image, right_foot + Vector2i(-4, -1), right_foot + Vector2i(7, -1), boot.lightened(0.18), 2)

func draw_large_hero_torso(
	image: Image,
	torso: Vector2i,
	hip: Vector2i,
	leather: Color,
	leather_dark: Color,
	leather_light: Color,
	cloth: Color,
	brass: Color
) -> void:
	draw_quad(
		image,
		torso + Vector2i(-27, -22),
		torso + Vector2i(22, -24),
		hip + Vector2i(24, -3),
		hip + Vector2i(-25, -1),
		OUTLINE
	)
	draw_quad(
		image,
		torso + Vector2i(-23, -19),
		torso + Vector2i(19, -21),
		hip + Vector2i(20, -4),
		hip + Vector2i(-22, -3),
		leather_dark
	)
	draw_quad(
		image,
		torso + Vector2i(-14, -18),
		torso + Vector2i(17, -19),
		hip + Vector2i(12, -7),
		hip + Vector2i(-8, -7),
		leather
	)
	draw_quad(
		image,
		torso + Vector2i(-3, -18),
		torso + Vector2i(17, -17),
		hip + Vector2i(12, -8),
		hip + Vector2i(2, -8),
		leather_light
	)
	draw_line(image, torso + Vector2i(-18, -12), hip + Vector2i(17, -7), OUTLINE, 5)
	draw_line(image, torso + Vector2i(-16, -12), hip + Vector2i(15, -7), leather_dark, 3)
	draw_line(image, hip + Vector2i(-25, -3), hip + Vector2i(24, -3), OUTLINE, 7)
	draw_line(image, hip + Vector2i(-22, -3), hip + Vector2i(21, -3), leather_dark, 4)
	draw_rect_outline(image, hip.x - 4, hip.y - 8, 8, 7, brass.darkened(0.05), OUTLINE)
	draw_quad(image, hip + Vector2i(-25, -1), hip + Vector2i(-5, -1), hip + Vector2i(-14, 25), hip + Vector2i(-34, 18), OUTLINE)
	draw_quad(image, hip + Vector2i(-22, 0), hip + Vector2i(-6, 0), hip + Vector2i(-15, 20), hip + Vector2i(-30, 15), leather)
	draw_quad(image, hip + Vector2i(6, -1), hip + Vector2i(26, -2), hip + Vector2i(35, 17), hip + Vector2i(14, 23), OUTLINE)
	draw_quad(image, hip + Vector2i(8, 0), hip + Vector2i(23, -1), hip + Vector2i(30, 14), hip + Vector2i(15, 19), leather_light.darkened(0.08))
	draw_quad(image, hip + Vector2i(-5, 0), hip + Vector2i(7, 0), hip + Vector2i(3, 24), hip + Vector2i(-7, 24), cloth.darkened(0.10))
	draw_rect_outline(image, hip.x + 24, hip.y + 2, 20, 15, leather, OUTLINE)
	draw_rect(image, hip.x + 29, hip.y + 7, 8, 3, brass.darkened(0.05))
	draw_line(image, hip + Vector2i(-37, 15), hip + Vector2i(-7, 20), leather_dark, 2)
	draw_line(image, hip + Vector2i(12, 17), hip + Vector2i(33, 12), leather_dark, 2)

func draw_large_hero_arms(
	image: Image,
	ox: int,
	frame: int,
	left_shoulder: Vector2i,
	right_shoulder: Vector2i,
	cloth: Color,
	leather: Color,
	leather_dark: Color,
	leather_light: Color,
	skin: Color,
	brass: Color
) -> void:
	var left_elbow = Vector2i(ox + 60, 91)
	var left_hand = Vector2i(ox + 70, 78)
	var right_elbow = Vector2i(ox + 83, 83)
	var right_hand = Vector2i(ox + 78, 68)
	if frame == 1:
		left_elbow = Vector2i(ox + 92, 104)
		left_hand = Vector2i(ox + 122, 111)
		right_elbow = Vector2i(ox + 112, 100)
		right_hand = Vector2i(ox + 137, 117)
	elif frame == 2:
		left_elbow = Vector2i(ox + 55, 92)
		left_hand = Vector2i(ox + 66, 88)
		right_elbow = Vector2i(ox + 105, 96)
		right_hand = Vector2i(ox + 118, 115)

	draw_ellipse(image, left_shoulder, 17, 14, OUTLINE)
	draw_ellipse(image, left_shoulder, 14, 11, leather_light.darkened(0.08))
	draw_ellipse(image, right_shoulder, 17, 14, OUTLINE)
	draw_ellipse(image, right_shoulder, 14, 11, leather)
	for band in [0, 6, 12]:
		draw_line(image, left_shoulder + Vector2i(-11, -5 + band), left_shoulder + Vector2i(11, -4 + band), leather_dark, 2)
		draw_line(image, right_shoulder + Vector2i(-11, -5 + band), right_shoulder + Vector2i(11, -4 + band), leather_dark, 2)

	draw_line(image, left_shoulder + Vector2i(-2, 8), left_elbow, OUTLINE, 15)
	draw_line(image, left_shoulder + Vector2i(-2, 8), left_elbow, cloth, 10)
	draw_line(image, left_elbow, left_hand, OUTLINE, 14)
	draw_line(image, left_elbow, left_hand, leather, 10)
	draw_line(image, right_shoulder + Vector2i(1, 8), right_elbow, OUTLINE, 15)
	draw_line(image, right_shoulder + Vector2i(1, 8), right_elbow, cloth.darkened(0.03), 10)
	draw_line(image, right_elbow, right_hand, OUTLINE, 14)
	draw_line(image, right_elbow, right_hand, leather_light.darkened(0.10), 10)
	draw_line(image, left_elbow + Vector2i(-5, 0), left_elbow + Vector2i(6, 4), leather_dark, 3)
	draw_line(image, right_elbow + Vector2i(-5, 0), right_elbow + Vector2i(6, 4), leather_dark, 3)
	draw_ellipse(image, left_hand, 7, 6, OUTLINE)
	draw_ellipse(image, left_hand, 5, 4, skin)
	draw_ellipse(image, right_hand, 7, 6, OUTLINE)
	draw_ellipse(image, right_hand, 5, 4, skin.lightened(0.04))
	draw_rect(image, left_elbow.x - 5, left_elbow.y - 5, 3, 3, brass)
	draw_rect(image, right_elbow.x + 3, right_elbow.y - 5, 3, 3, brass)

func draw_large_sword_for_pose(image: Image, ox: int, frame: int, steel: Color, steel_dark: Color, steel_hi: Color, brass: Color) -> void:
	if frame == 1:
		draw_sword_blade(image, Vector2i(ox + 128, 113), Vector2i(ox + 176, 145), steel, steel_dark, steel_hi)
		draw_line(image, Vector2i(ox + 117, 108), Vector2i(ox + 141, 124), OUTLINE, 9)
		draw_line(image, Vector2i(ox + 118, 109), Vector2i(ox + 140, 123), brass.darkened(0.10), 5)
		draw_line(image, Vector2i(ox + 120, 102), Vector2i(ox + 135, 116), OUTLINE, 5)
		draw_line(image, Vector2i(ox + 121, 103), Vector2i(ox + 134, 115), brass, 3)
	elif frame == 2:
		draw_sword_blade(image, Vector2i(ox + 123, 105), Vector2i(ox + 145, 153), steel, steel_dark, steel_hi)
		draw_line(image, Vector2i(ox + 114, 95), Vector2i(ox + 128, 117), OUTLINE, 9)
		draw_line(image, Vector2i(ox + 115, 96), Vector2i(ox + 127, 116), brass.darkened(0.10), 5)
		draw_line(image, Vector2i(ox + 108, 106), Vector2i(ox + 130, 96), OUTLINE, 5)
		draw_line(image, Vector2i(ox + 109, 105), Vector2i(ox + 129, 97), brass, 3)
	else:
		draw_sword_blade(image, Vector2i(ox + 79, 67), Vector2i(ox + 135, 15), steel, steel_dark, steel_hi)
		draw_line(image, Vector2i(ox + 65, 81), Vector2i(ox + 86, 60), OUTLINE, 9)
		draw_line(image, Vector2i(ox + 66, 80), Vector2i(ox + 85, 61), brass.darkened(0.10), 5)
		draw_line(image, Vector2i(ox + 67, 58), Vector2i(ox + 89, 80), OUTLINE, 5)
		draw_line(image, Vector2i(ox + 68, 59), Vector2i(ox + 88, 79), brass, 3)
		draw_ellipse(image, Vector2i(ox + 62, 85), 5, 5, OUTLINE)
		draw_ellipse(image, Vector2i(ox + 62, 85), 3, 3, brass)

func draw_sword_blade(image: Image, hilt: Vector2i, tip: Vector2i, steel: Color, steel_dark: Color, steel_hi: Color) -> void:
	draw_line(image, hilt, tip, OUTLINE, 13)
	draw_line(image, hilt, tip, steel_dark, 10)
	draw_line(image, hilt + Vector2i(1, 0), tip + Vector2i(1, 0), steel, 7)
	draw_line(image, hilt + Vector2i(-2, 2), tip + Vector2i(-2, 2), steel_hi, 3)
	draw_ellipse(image, tip, 4, 4, OUTLINE)
	draw_ellipse(image, tip, 2, 2, steel_hi)

func draw_large_hero_head(image: Image, head: Vector2i, skin: Color, skin_shadow: Color, hair: Color, hair_hi: Color) -> void:
	draw_ellipse(image, head + Vector2i(0, 0), 13, 16, OUTLINE)
	draw_ellipse(image, head + Vector2i(0, 0), 10, 13, skin)
	draw_rect(image, head.x - 7, head.y + 8, 13, 4, skin_shadow.lightened(0.10))
	draw_line(image, head + Vector2i(-8, -3), head + Vector2i(-2, -2), hair, 3)
	draw_line(image, head + Vector2i(2, -2), head + Vector2i(8, -5), hair, 3)
	draw_rect(image, head.x - 6, head.y - 1, 3, 2, Color(0.05, 0.04, 0.035, 1))
	draw_rect(image, head.x + 4, head.y - 1, 3, 2, Color(0.05, 0.04, 0.035, 1))
	draw_line(image, head + Vector2i(-3, 5), head + Vector2i(6, 4), Color(0.22, 0.10, 0.08, 1), 2)
	draw_line(image, head + Vector2i(-11, -10), head + Vector2i(11, -13), hair, 9)
	draw_line(image, head + Vector2i(-13, -5), head + Vector2i(12, -16), hair, 7)
	draw_line(image, head + Vector2i(-15, -2), head + Vector2i(-6, -18), hair, 6)
	draw_line(image, head + Vector2i(10, -8), head + Vector2i(22, -6), hair, 5)
	draw_line(image, head + Vector2i(13, -3), head + Vector2i(26, 6), hair, 4)
	draw_line(image, head + Vector2i(23, 6), head + Vector2i(30, 3), Color(0.55, 0.04, 0.06, 1), 2)
	draw_line(image, head + Vector2i(-7, -14), head + Vector2i(5, -18), hair_hi, 2)
	draw_line(image, head + Vector2i(-3, -11), head + Vector2i(10, -14), hair_hi, 2)

func draw_large_rivets(image: Image, torso: Vector2i, color: Color) -> void:
	for point in [
		Vector2i(-19, -12), Vector2i(-8, -15), Vector2i(8, -16),
		Vector2i(18, -10), Vector2i(-16, 2), Vector2i(15, 3),
		Vector2i(-21, 12), Vector2i(21, 12)
	]:
		draw_rect(image, torso.x + point.x, torso.y + point.y, 2, 2, color)

func sx(value: int, scale: float) -> int:
	return int(round(value * scale))

func draw_scaled_rect(image: Image, base: Vector2i, x: int, y: int, width: int, height: int, color: Color, scale: float) -> void:
	draw_rect(
		image,
		base.x + sx(x, scale),
		base.y + sx(y, scale),
		max(1, sx(width, scale)),
		max(1, sx(height, scale)),
		color
	)

func draw_scaled_rect_outline(image: Image, base: Vector2i, x: int, y: int, width: int, height: int, fill: Color, outline: Color, scale: float) -> void:
	draw_rect_outline(
		image,
		base.x + sx(x, scale),
		base.y + sx(y, scale),
		max(1, sx(width, scale)),
		max(1, sx(height, scale)),
		fill,
		outline
	)

func draw_scaled_line(image: Image, base: Vector2i, ax: int, ay: int, bx: int, by: int, color: Color, thickness: int, scale: float) -> void:
	draw_line(
		image,
		base + Vector2i(sx(ax, scale), sx(ay, scale)),
		base + Vector2i(sx(bx, scale), sx(by, scale)),
		color,
		max(1, sx(thickness, scale))
	)

func draw_hurt_slash(image: Image, base: Vector2i, scale: float) -> void:
	draw_scaled_line(image, base, -17, -16, 17, 17, Color(1.0, 0.10, 0.07, 0.48), 3, scale)
	draw_scaled_line(image, base, -12, -18, 20, 13, Color(1.0, 0.78, 0.32, 0.58), 1, scale)

func draw_hooded_figure(
	image: Image,
	ox: int,
	frame_or_offset,
	cloak: Color,
	face: Color,
	metal: Color,
	scale: float = 1.0
) -> void:
	var frame = 0
	var map_offset = Vector2i(0, 0)
	if typeof(frame_or_offset) == TYPE_VECTOR2I:
		map_offset = frame_or_offset
	else:
		frame = int(frame_or_offset)
	var lean = 4 if frame == 1 else (-3 if frame == 2 else 0)
	var hurt = frame == 2
	var base = Vector2i(ox + sx(31 + lean, scale) + map_offset.x, sx(38, scale) + map_offset.y)
	var cloak_dark = cloak.darkened(0.32)
	var cloak_mid = cloak.darkened(0.10)
	var cloak_light = cloak.lightened(0.18)
	var leather = Color(0.19, 0.12, 0.075, 1)
	var boot = Color(0.075, 0.065, 0.080, 1)
	draw_scaled_rect_outline(image, base, -8, 13, 5, 8, boot, OUTLINE, scale)
	draw_scaled_rect_outline(image, base, 4, 13, 5, 8, boot, OUTLINE, scale)
	draw_triangle(image, base + Vector2i(sx(-17, scale), sx(18, scale)), base + Vector2i(sx(-2, scale), sx(-15, scale)), base + Vector2i(sx(15, scale), sx(18, scale)), OUTLINE)
	draw_triangle(image, base + Vector2i(sx(-14, scale), sx(17, scale)), base + Vector2i(sx(-1, scale), sx(-13, scale)), base + Vector2i(sx(12, scale), sx(17, scale)), cloak_dark)
	draw_triangle(image, base + Vector2i(sx(-9, scale), sx(17, scale)), base + Vector2i(sx(1, scale), sx(-11, scale)), base + Vector2i(sx(13, scale), sx(17, scale)), cloak_mid)
	draw_scaled_line(image, base, -7, 0, -11, 15, cloak_light, 2, scale)
	draw_scaled_line(image, base, 3, -3, 7, 16, cloak.darkened(0.42), 2, scale)
	draw_scaled_rect_outline(image, base, -7, -1, 14, 13, cloak_light.darkened(0.08), OUTLINE, scale)
	draw_scaled_rect(image, base, -5, 1, 10, 5, cloak_light, scale)
	draw_scaled_rect(image, base, -8, 9, 17, 3, leather, scale)
	draw_scaled_rect(image, base, -1, 9, 3, 3, metal, scale)
	draw_ellipse(image, base + Vector2i(sx(0, scale), sx(-17, scale)), sx(10, scale), sx(9, scale), OUTLINE)
	draw_ellipse(image, base + Vector2i(sx(0, scale), sx(-17, scale)), sx(8, scale), sx(7, scale), cloak_mid)
	draw_triangle(image, base + Vector2i(sx(-8, scale), sx(-18, scale)), base + Vector2i(sx(0, scale), sx(-27, scale)), base + Vector2i(sx(8, scale), sx(-18, scale)), cloak_light.darkened(0.05))
	draw_scaled_rect_outline(image, base, -5, -20, 10, 7, face.darkened(0.12), OUTLINE, scale)
	draw_scaled_rect(image, base, -3, -18, 2, 2, Color(0.08, 0.10, 0.14, 1), scale)
	draw_scaled_rect(image, base, 2, -18, 2, 2, Color(0.08, 0.10, 0.14, 1), scale)
	draw_scaled_rect(image, base, -2, -15, 4, 1, face.lightened(0.16), scale)
	draw_ellipse(image, base + Vector2i(sx(-13, scale), sx(1, scale)), sx(5, scale), sx(8, scale), OUTLINE)
	draw_ellipse(image, base + Vector2i(sx(-13, scale), sx(1, scale)), sx(4, scale), sx(6, scale), metal.darkened(0.12))
	draw_scaled_line(image, base, -15, -3, -10, 5, metal.lightened(0.18), 1, scale)
	if frame == 1:
		draw_scaled_line(image, base, 8, -4, 30, -16, OUTLINE, 5, scale)
		draw_scaled_line(image, base, 9, -5, 29, -15, metal, 3, scale)
		draw_scaled_line(image, base, 25, -18, 33, -22, metal.lightened(0.30), 2, scale)
		draw_scaled_line(image, base, 15, -18, 28, -26, Color(1.0, 0.88, 0.34, 0.44), 1, scale)
	else:
		draw_scaled_line(image, base, 9, -4, 17, 18, OUTLINE, 5, scale)
		draw_scaled_line(image, base, 10, -4, 17, 17, metal, 3, scale)
		draw_scaled_line(image, base, 15, 14, 20, 20, metal.lightened(0.28), 2, scale)
	if hurt:
		draw_hurt_slash(image, base, scale)

func draw_goblin(image: Image, ox: int, offset: Vector2i = Vector2i(0, 0), scale: float = 1.0, frame: int = 0) -> void:
	var lean = 5 if frame == 1 else (-3 if frame == 2 else 0)
	var base = Vector2i(ox + sx(31 + lean, scale) + offset.x, sx(38, scale) + offset.y)
	var skin = Color(0.40, 0.72, 0.26, 1)
	var skin_dark = Color(0.17, 0.38, 0.12, 1)
	var cloth = Color(0.16, 0.30, 0.13, 1)
	var leather = Color(0.55, 0.31, 0.13, 1)
	draw_triangle(image, base + Vector2i(sx(-19, scale), sx(-16, scale)), base + Vector2i(sx(-5, scale), sx(-9, scale)), base + Vector2i(sx(-16, scale), sx(-4, scale)), OUTLINE)
	draw_triangle(image, base + Vector2i(sx(19, scale), sx(-16, scale)), base + Vector2i(sx(5, scale), sx(-9, scale)), base + Vector2i(sx(16, scale), sx(-4, scale)), OUTLINE)
	draw_triangle(image, base + Vector2i(sx(-17, scale), sx(-14, scale)), base + Vector2i(sx(-5, scale), sx(-8, scale)), base + Vector2i(sx(-14, scale), sx(-5, scale)), skin_dark.lightened(0.08))
	draw_triangle(image, base + Vector2i(sx(17, scale), sx(-14, scale)), base + Vector2i(sx(5, scale), sx(-8, scale)), base + Vector2i(sx(14, scale), sx(-5, scale)), skin_dark.lightened(0.08))
	draw_ellipse(image, base + Vector2i(0, sx(-9, scale)), sx(12, scale), sx(9, scale), OUTLINE)
	draw_ellipse(image, base + Vector2i(0, sx(-9, scale)), sx(10, scale), sx(7, scale), skin)
	draw_scaled_rect(image, base, -8, -13, 4, 2, skin.lightened(0.20), scale)
	draw_scaled_rect(image, base, 4, -13, 4, 2, skin.lightened(0.20), scale)
	draw_scaled_rect(image, base, -4, -10, 3, 2, HILITE, scale)
	draw_scaled_rect(image, base, 3, -10, 3, 2, HILITE, scale)
	draw_scaled_rect(image, base, -1, -7, 4, 2, skin_dark, scale)
	draw_scaled_rect(image, base, -5, -4, 11, 2, skin.darkened(0.16), scale)
	draw_scaled_rect_outline(image, base, -8, 0, 16, 14, cloth, OUTLINE, scale)
	draw_scaled_rect(image, base, -6, 2, 12, 6, leather, scale)
	draw_scaled_rect(image, base, -7, 8, 14, 3, leather.darkened(0.22), scale)
	draw_scaled_rect(image, base, -1, 8, 3, 3, HILITE.darkened(0.12), scale)
	draw_scaled_rect_outline(image, base, -10, 14, 6, 7, skin_dark, OUTLINE, scale)
	draw_scaled_rect_outline(image, base, 4, 14, 6, 7, skin_dark, OUTLINE, scale)
	draw_scaled_rect(image, base, -12, 20, 8, 2, leather.darkened(0.18), scale)
	draw_scaled_rect(image, base, 5, 20, 8, 2, leather.darkened(0.18), scale)
	if frame == 1:
		draw_scaled_line(image, base, 8, 0, 25, -12, OUTLINE, 5, scale)
		draw_scaled_line(image, base, 9, 0, 24, -11, Color(0.72, 0.70, 0.58, 1), 3, scale)
		draw_scaled_line(image, base, 20, -13, 29, -17, HILITE, 1, scale)
	else:
		draw_scaled_line(image, base, 8, 1, 17, 13, OUTLINE, 5, scale)
		draw_scaled_line(image, base, 9, 1, 17, 12, Color(0.72, 0.70, 0.58, 1), 3, scale)
	if frame == 2:
		draw_hurt_slash(image, base, scale)

func draw_skeleton(image: Image, ox: int, offset: Vector2i = Vector2i(0, 0), scale: float = 1.0, frame: int = 0) -> void:
	var lean = 4 if frame == 1 else (-3 if frame == 2 else 0)
	var base = Vector2i(ox + sx(32 + lean, scale) + offset.x, sx(36, scale) + offset.y)
	var bone = Color(0.82, 0.80, 0.66, 1)
	var old = Color(0.50, 0.48, 0.38, 1)
	var cloth = Color(0.25, 0.20, 0.17, 1)
	draw_ellipse(image, base + Vector2i(0, sx(-16, scale)), sx(9, scale), sx(8, scale), OUTLINE)
	draw_ellipse(image, base + Vector2i(0, sx(-16, scale)), sx(7, scale), sx(6, scale), bone)
	draw_scaled_rect(image, base, -5, -17, 3, 3, OUTLINE, scale)
	draw_scaled_rect(image, base, 3, -17, 3, 3, OUTLINE, scale)
	draw_scaled_rect(image, base, -3, -12, 7, 2, old, scale)
	draw_scaled_rect(image, base, -2, -10, 4, 3, bone.darkened(0.12), scale)
	draw_scaled_line(image, base, 0, -8, 0, 14, OUTLINE, 5, scale)
	draw_scaled_line(image, base, 0, -8, 0, 14, bone, 3, scale)
	draw_scaled_line(image, base, -10, -5, 10, -4, OUTLINE, 4, scale)
	draw_scaled_line(image, base, -9, -5, 9, -4, bone, 2, scale)
	for rib in [-3, 1, 5]:
		draw_scaled_line(image, base, -9, rib, -2, rib + 1, old, 2, scale)
		draw_scaled_line(image, base, 2, rib + 1, 9, rib, old, 2, scale)
	draw_diamond(image, base + Vector2i(0, sx(12, scale)), max(1, sx(5, scale)), cloth)
	draw_scaled_line(image, base, -6, 14, -13, 23, OUTLINE, 5, scale)
	draw_scaled_line(image, base, -6, 14, -13, 23, bone, 3, scale)
	draw_scaled_line(image, base, 6, 14, 14, 23, OUTLINE, 5, scale)
	draw_scaled_line(image, base, 6, 14, 14, 23, bone, 3, scale)
	if frame == 1:
		draw_scaled_line(image, base, 8, -5, 25, -15, OUTLINE, 5, scale)
		draw_scaled_line(image, base, 9, -5, 24, -15, Color(0.74, 0.74, 0.80, 1), 3, scale)
		draw_scaled_line(image, base, 19, -17, 29, -22, HILITE, 1, scale)
	else:
		draw_scaled_line(image, base, 8, -4, 18, 13, OUTLINE, 5, scale)
		draw_scaled_line(image, base, 9, -4, 18, 12, Color(0.74, 0.74, 0.80, 1), 3, scale)
	if frame == 2:
		draw_hurt_slash(image, base, scale)

func draw_bat(image: Image, ox: int, offset: Vector2i = Vector2i(0, 0), scale: float = 1.0, frame: int = 0) -> void:
	var flap = -4 if frame == 1 else (3 if frame == 2 else 0)
	var base = Vector2i(ox + sx(32, scale) + offset.x, sx(31, scale) + offset.y)
	var wing = Color(0.31, 0.22, 0.50, 1)
	var wing_dark = Color(0.15, 0.10, 0.27, 1)
	var body = Color(0.48, 0.36, 0.66, 1)
	draw_triangle(image, base + Vector2i(sx(-3, scale), sx(0, scale)), base + Vector2i(sx(-29, scale), sx(-11 + flap, scale)), base + Vector2i(sx(-18, scale), sx(16, scale)), OUTLINE)
	draw_triangle(image, base + Vector2i(sx(3, scale), sx(0, scale)), base + Vector2i(sx(29, scale), sx(-11 + flap, scale)), base + Vector2i(sx(18, scale), sx(16, scale)), OUTLINE)
	draw_triangle(image, base + Vector2i(sx(-4, scale), sx(1, scale)), base + Vector2i(sx(-25, scale), sx(-8 + flap, scale)), base + Vector2i(sx(-15, scale), sx(13, scale)), wing)
	draw_triangle(image, base + Vector2i(sx(4, scale), sx(1, scale)), base + Vector2i(sx(25, scale), sx(-8 + flap, scale)), base + Vector2i(sx(15, scale), sx(13, scale)), wing)
	draw_triangle(image, base + Vector2i(sx(-8, scale), sx(3, scale)), base + Vector2i(sx(-19, scale), sx(2 + flap, scale)), base + Vector2i(sx(-15, scale), sx(15, scale)), wing_dark)
	draw_triangle(image, base + Vector2i(sx(8, scale), sx(3, scale)), base + Vector2i(sx(19, scale), sx(2 + flap, scale)), base + Vector2i(sx(15, scale), sx(15, scale)), wing_dark)
	draw_scaled_line(image, base, -5, 1, -25, -8 + flap, wing.lightened(0.16), 1, scale)
	draw_scaled_line(image, base, 5, 1, 25, -8 + flap, wing.lightened(0.16), 1, scale)
	draw_scaled_line(image, base, -5, 2, -15, 13, wing_dark.darkened(0.08), 1, scale)
	draw_scaled_line(image, base, 5, 2, 15, 13, wing_dark.darkened(0.08), 1, scale)
	draw_ellipse(image, base + Vector2i(0, sx(4, scale)), sx(9, scale), sx(11, scale), OUTLINE)
	draw_ellipse(image, base + Vector2i(0, sx(4, scale)), sx(7, scale), sx(9, scale), body)
	draw_ellipse(image, base + Vector2i(sx(0, scale), sx(-3, scale)), sx(7, scale), sx(6, scale), OUTLINE)
	draw_ellipse(image, base + Vector2i(sx(0, scale), sx(-3, scale)), sx(5, scale), sx(4, scale), body.lightened(0.05))
	draw_triangle(image, base + Vector2i(sx(-6, scale), sx(-5, scale)), base + Vector2i(sx(-2, scale), sx(-16, scale)), base + Vector2i(sx(0, scale), sx(-5, scale)), body.lightened(0.12))
	draw_triangle(image, base + Vector2i(sx(6, scale), sx(-5, scale)), base + Vector2i(sx(2, scale), sx(-16, scale)), base + Vector2i(sx(0, scale), sx(-5, scale)), body.lightened(0.12))
	draw_scaled_rect(image, base, -4, -4, 2, 2, HILITE, scale)
	draw_scaled_rect(image, base, 3, -4, 2, 2, HILITE, scale)
	draw_scaled_line(image, base, -3, 12, -5, 17, OUTLINE, 2, scale)
	draw_scaled_line(image, base, 3, 12, 5, 17, OUTLINE, 2, scale)
	if frame == 2:
		draw_hurt_slash(image, base, scale)

func draw_slime(image: Image, ox: int, offset: Vector2i = Vector2i(0, 0), scale: float = 1.0, frame: int = 0) -> void:
	var squash = 2 if frame == 1 else (-2 if frame == 2 else 0)
	var base = Vector2i(ox + sx(32, scale) + offset.x, sx(39, scale) + offset.y)
	var slime = Color(0.24, 0.76, 0.66, 1)
	var dark = Color(0.08, 0.32, 0.28, 1)
	var glow = Color(0.60, 0.98, 0.88, 1)
	draw_ellipse(image, base + Vector2i(0, sx(6, scale)), sx(19, scale), sx(14 + squash, scale), OUTLINE)
	draw_ellipse(image, base + Vector2i(0, sx(5, scale)), sx(17, scale), sx(12 + squash, scale), slime.darkened(0.14))
	draw_ellipse(image, base + Vector2i(0, sx(2, scale)), sx(14, scale), sx(9 + squash, scale), slime)
	draw_ellipse(image, base + Vector2i(sx(-6, scale), sx(-3, scale)), sx(6, scale), sx(4, scale), glow)
	draw_ellipse(image, base + Vector2i(sx(6, scale), sx(0, scale)), sx(3, scale), sx(2, scale), slime.lightened(0.18))
	draw_scaled_rect(image, base, -6, 4, 3, 3, dark, scale)
	draw_scaled_rect(image, base, 4, 4, 3, 3, dark, scale)
	draw_scaled_line(image, base, -6, 11, 7, 11, dark, 2, scale)
	draw_scaled_line(image, base, -11, 15, -5, 17, slime.darkened(0.25), 2, scale)
	draw_scaled_line(image, base, 4, 17, 12, 15, slime.darkened(0.25), 2, scale)
	draw_scaled_rect(image, base, 0, 0, 2, 2, Color(0.86, 1.0, 0.94, 1), scale)
	if frame == 1:
		draw_ellipse(image, base + Vector2i(sx(17, scale), sx(3, scale)), sx(6, scale), sx(4, scale), slime.lightened(0.20))
		draw_scaled_line(image, base, 9, 0, 25, -3, Color(0.74, 1.0, 0.88, 0.52), 2, scale)
	if frame == 2:
		draw_hurt_slash(image, base, scale)

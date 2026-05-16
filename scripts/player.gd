extends CharacterBody2D

const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")
const ScenePaths = preload("res://scripts/scene_paths.gd")
const TILE_SIZE = 32
const HALF_TILE = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
const MAP_SPRITE_SCALE = 1.14
const STEP_DURATION = 0.16
const BUMP_DURATION = 0.075
const BUMP_DISTANCE = 5.0
const STEP_BOB_HEIGHT = 3.5
const MAP_MIN_WALK_FRAME_COUNT = 3
const MAP_BUMP_FRAME_INDEX = 3

var grid_pos: Vector2i = Vector2i(8, 8)
var input_locked: bool = false
var is_moving: bool = false
var map_variant: String = PixelAssetPaths.MAP_VARIANT
var map_shadow: Sprite2D
var map_presence_glow: Sprite2D
var sprite_base_position: Vector2 = Vector2.ZERO
var shadow_base_scale: Vector2 = Vector2(1.05, 0.52)
var glow_base_scale: Vector2 = Vector2(1.12, 0.86)
var map_frame_count: int = MAP_MIN_WALK_FRAME_COUNT

func _ready():
	create_map_shadow()
	create_map_presence_glow()
	apply_map_texture()
	$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite2D.scale = Vector2(MAP_SPRITE_SCALE, MAP_SPRITE_SCALE)
	$Sprite2D.z_index = 2
	$Sprite2D.modulate = Color(1.14, 1.10, 1.02, 1.0)
	sprite_base_position = $Sprite2D.position
	# Выравниваем позицию на сетку
	set_grid_position(grid_pos)

func set_map_variant(variant: String) -> void:
	map_variant = variant
	apply_map_texture()

func apply_map_texture() -> void:
	if has_node("Sprite2D"):
		var texture = get_player_map_sheet_texture()
		$Sprite2D.texture = texture
		map_frame_count = get_map_frame_count(texture)
		$Sprite2D.hframes = map_frame_count
		$Sprite2D.vframes = 1
		$Sprite2D.frame = 0

func get_map_frame_count(texture: Texture2D) -> int:
	if texture == null or texture.get_height() <= 0:
		return MAP_MIN_WALK_FRAME_COUNT
	var inferred_count = int(texture.get_width() / texture.get_height())
	return maxi(MAP_MIN_WALK_FRAME_COUNT, inferred_count)

func get_player_map_sheet_texture() -> Texture2D:
	var sheet_name = "player_vampire_sheet" if GameState.selected_character_id == "vampire" else "player_sheet"
	var sheet_texture = PixelAssetPaths.map_texture_or_null(sheet_name, map_variant)
	if sheet_texture != null:
		return sheet_texture
	var texture = create_character_map_texture(PixelAssetPaths.map_texture("player", map_variant))
	return create_walk_sheet_from_texture(texture)

func create_character_map_texture(texture: Texture2D) -> Texture2D:
	if texture == null or GameState.selected_character_id != "vampire":
		return texture
	var image = texture.get_image()
	if image == null:
		return texture
	if image.is_compressed():
		image.decompress()
	image.convert(Image.FORMAT_RGBA8)
	recolor_vampire_map_sprite(image)
	return ImageTexture.create_from_image(image)

func recolor_vampire_map_sprite(image: Image) -> void:
	var width = image.get_width()
	var height = image.get_height()
	for y in range(height):
		for x in range(width):
			var pixel = image.get_pixel(x, y)
			if pixel.a <= 0.02:
				continue
			if is_skin_pixel(pixel):
				image.set_pixel(x, y, pixel.lerp(Color(0.82, 0.76, 0.82, pixel.a), 0.42))
			elif is_leather_pixel(pixel):
				image.set_pixel(x, y, pixel.lerp(Color(0.36, 0.05, 0.09, pixel.a), 0.48))
	draw_vampire_map_cape(image, width, height)

func is_skin_pixel(pixel: Color) -> bool:
	return pixel.r > 0.48 and pixel.g > 0.30 and pixel.b > 0.20 and pixel.r > pixel.b * 1.35

func is_leather_pixel(pixel: Color) -> bool:
	return pixel.r > 0.22 and pixel.g > 0.10 and pixel.b < 0.22 and pixel.r >= pixel.g

func draw_vampire_map_cape(image: Image, width: int, height: int) -> void:
	for y in range(int(height * 0.34), int(height * 0.88)):
		var t = float(y) / float(max(1, height - 1))
		var cape_width = int(lerp(3.0, 7.0, t))
		var start_x = int(width * 0.28) - int(sin(float(y) * 0.7) * 1.5)
		for x in range(start_x, start_x + cape_width):
			if x < 1 or x >= width - 1:
				continue
			var existing = image.get_pixel(x, y)
			if existing.a > 0.70:
				continue
			var edge = 1.0 if x == start_x or x == start_x + cape_width - 1 else 0.0
			var cape_color = Color(0.18 + edge * 0.06, 0.015, 0.045, 0.82 - t * 0.18)
			image.set_pixel(x, y, cape_color)

func create_walk_sheet_from_texture(texture: Texture2D) -> Texture2D:
	if texture == null:
		return texture
	if texture.get_width() >= texture.get_height() * MAP_MIN_WALK_FRAME_COUNT and texture.get_width() % MAP_MIN_WALK_FRAME_COUNT == 0:
		return texture

	var source = texture.get_image()
	if source == null:
		return texture
	if source.is_compressed():
		source.decompress()
	source.convert(Image.FORMAT_RGBA8)

	var frame_width = source.get_width()
	var frame_height = source.get_height()
	var frame_count = MAP_BUMP_FRAME_INDEX + 1
	var sheet = Image.create(frame_width * frame_count, frame_height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for frame_index in range(frame_count):
		draw_walk_frame(sheet, source, frame_index, frame_width, frame_height)
	return ImageTexture.create_from_image(sheet)

func draw_walk_frame(sheet: Image, source: Image, frame_index: int, frame_width: int, frame_height: int) -> void:
	var frame_origin_x = frame_index * frame_width
	if frame_index == 0:
		sheet.blit_rect(source, Rect2i(Vector2i.ZERO, Vector2i(frame_width, frame_height)), Vector2i(frame_origin_x, 0))
		return
	if frame_index == MAP_BUMP_FRAME_INDEX:
		draw_bump_frame(sheet, source, frame_origin_x, frame_width, frame_height)
		return

	var step_direction = -1 if frame_index == 1 else 1
	for y in range(frame_height):
		for x in range(frame_width):
			var pixel = source.get_pixel(x, y)
			if pixel.a <= 0.02:
				continue
			var shifted = get_walk_frame_pixel_offset(x, y, frame_width, frame_height, step_direction)
			var target = Vector2i(frame_origin_x + x + shifted.x, y + shifted.y)
			if target.x < frame_origin_x or target.x >= frame_origin_x + frame_width or target.y < 0 or target.y >= frame_height:
				continue
			sheet.set_pixelv(target, pixel)

func get_walk_frame_pixel_offset(x: int, y: int, frame_width: int, frame_height: int, step_direction: int) -> Vector2i:
	var body_line = int(float(frame_height) * 0.62)
	var foot_line = int(float(frame_height) * 0.78)
	if y < body_line:
		return Vector2i(step_direction, -1 if y < int(float(frame_height) * 0.38) else 0)
	var side = -1 if x < int(float(frame_width) * 0.50) else 1
	var leg_push = side * step_direction
	var foot_drop = 1 if y >= foot_line and side == step_direction else 0
	return Vector2i(leg_push, foot_drop)

func draw_bump_frame(sheet: Image, source: Image, frame_origin_x: int, frame_width: int, frame_height: int) -> void:
	for y in range(frame_height):
		for x in range(frame_width):
			var pixel = source.get_pixel(x, y)
			if pixel.a <= 0.02:
				continue
			var shifted = get_bump_frame_pixel_offset(x, y, frame_width, frame_height)
			var target = Vector2i(frame_origin_x + x + shifted.x, y + shifted.y)
			if target.x < frame_origin_x or target.x >= frame_origin_x + frame_width or target.y < 0 or target.y >= frame_height:
				continue
			sheet.set_pixelv(target, pixel)

func get_bump_frame_pixel_offset(x: int, y: int, frame_width: int, frame_height: int) -> Vector2i:
	var upper_line = int(float(frame_height) * 0.42)
	var body_line = int(float(frame_height) * 0.68)
	if y < upper_line:
		return Vector2i(1, 1)
	if y < body_line:
		return Vector2i(0, 1)
	var side = -1 if x < int(float(frame_width) * 0.50) else 1
	return Vector2i(side, 0)

func create_map_shadow() -> void:
	if map_shadow != null:
		return
	map_shadow = Sprite2D.new()
	map_shadow.name = "MapShadow"
	map_shadow.position = Vector2(0.0, 9.0)
	map_shadow.texture = create_shadow_texture(Color(0.0, 0.0, 0.0, 0.42))
	map_shadow.scale = shadow_base_scale
	map_shadow.z_index = -1
	add_child(map_shadow)

func create_map_presence_glow() -> void:
	if map_presence_glow != null:
		return
	map_presence_glow = Sprite2D.new()
	map_presence_glow.name = "MapPresenceGlow"
	map_presence_glow.position = Vector2(0.0, 4.0)
	map_presence_glow.texture = create_presence_glow_texture(Color(0.92, 0.70, 0.34, 0.34))
	map_presence_glow.scale = glow_base_scale
	map_presence_glow.z_index = 0
	add_child(map_presence_glow)

func create_presence_glow_texture(glow_color: Color) -> ImageTexture:
	var width = 34
	var height = 30
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(
				(float(x) / float(width - 1) - 0.5) * 2.0,
				(float(y) / float(height - 1) - 0.5) * 2.0
			)
			var distance = sqrt(uv.x * uv.x + uv.y * uv.y * 1.7)
			var alpha = pow(clamp(1.0 - distance, 0.0, 1.0), 1.8)
			image.set_pixel(x, y, Color(glow_color.r, glow_color.g, glow_color.b, alpha * glow_color.a))
	return ImageTexture.create_from_image(image)

func create_shadow_texture(shadow_color: Color) -> ImageTexture:
	var width = 30
	var height = 14
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(
				(float(x) / float(width - 1) - 0.5) * 2.0,
				(float(y) / float(height - 1) - 0.5) * 2.0
			)
			var distance = sqrt(uv.x * uv.x + uv.y * uv.y * 3.3)
			var alpha = clamp(1.0 - distance, 0.0, 1.0)
			image.set_pixel(x, y, Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha * shadow_color.a))
	return ImageTexture.create_from_image(image)

func set_grid_position(new_grid_pos: Vector2i) -> void:
	grid_pos = new_grid_pos
	position = grid_to_world_position(grid_pos)
	reset_step_visuals()

func grid_to_world_position(pos: Vector2i) -> Vector2:
	return Vector2(pos) * TILE_SIZE + HALF_TILE

func _physics_process(_delta):
	if input_locked or is_moving:
		return
	
	if Input.is_action_just_pressed("ui_up"):
		move_to_grid(grid_pos + Vector2i(0, -1))
	elif Input.is_action_just_pressed("ui_down"):
		move_to_grid(grid_pos + Vector2i(0, 1))
	elif Input.is_action_just_pressed("ui_left"):
		move_to_grid(grid_pos + Vector2i(-1, 0))
	elif Input.is_action_just_pressed("ui_right"):
		move_to_grid(grid_pos + Vector2i(1, 0))

func move_to_grid(new_grid_pos: Vector2i):
	if is_moving:
		return
	var direction = new_grid_pos - grid_pos
	if not is_valid_position(new_grid_pos):
		await play_bump_feedback(direction)
		return

	await move_step_to_grid(new_grid_pos, direction)
	GameState.set_player_grid_position(grid_pos, true)
	check_for_encounter()
	if input_locked:
		return
	check_for_interaction()

func move_step_to_grid(new_grid_pos: Vector2i, direction: Vector2i) -> void:
	is_moving = true
	var start_position = position
	var target_position = grid_to_world_position(new_grid_pos)
	apply_step_facing(direction)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_position, STEP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(set_step_visual_progress, 0.0, 1.0, STEP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	position = target_position
	grid_pos = new_grid_pos
	reset_step_visuals()
	is_moving = false

func play_bump_feedback(direction: Vector2i) -> void:
	if direction == Vector2i.ZERO:
		return
	is_moving = true
	var start_position = position
	var bump_offset = Vector2(direction).normalized() * BUMP_DISTANCE
	apply_step_facing(direction)
	var move_tween = create_tween()
	move_tween.tween_property(self, "position", start_position + bump_offset, BUMP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", start_position, BUMP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	var visual_tween = create_tween()
	visual_tween.tween_method(set_bump_visual_progress, 0.0, 1.0, BUMP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	visual_tween.tween_method(set_bump_visual_progress, 1.0, 0.0, BUMP_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await move_tween.finished
	position = start_position
	reset_step_visuals()
	is_moving = false

func set_step_visual_progress(progress: float) -> void:
	var arc = sin(progress * PI)
	set_walk_frame_for_progress(progress)
	$Sprite2D.position = sprite_base_position + Vector2(0.0, -STEP_BOB_HEIGHT * arc)
	$Sprite2D.rotation_degrees = lerp(-1.35, 1.35, progress) * arc
	$Sprite2D.scale = Vector2(MAP_SPRITE_SCALE * (1.0 + arc * 0.025), MAP_SPRITE_SCALE * (1.0 - arc * 0.018))
	if map_shadow != null:
		map_shadow.scale = shadow_base_scale * (1.0 - arc * 0.12)
		map_shadow.modulate = Color(1.0, 1.0, 1.0, 1.0 - arc * 0.18)
	if map_presence_glow != null:
		map_presence_glow.scale = glow_base_scale * (1.0 + arc * 0.06)

func set_bump_visual_progress(progress: float) -> void:
	var arc = sin(progress * PI)
	if has_node("Sprite2D"):
		$Sprite2D.frame = MAP_BUMP_FRAME_INDEX if map_frame_count > MAP_BUMP_FRAME_INDEX else 0
		$Sprite2D.scale = Vector2(MAP_SPRITE_SCALE * (1.0 + arc * 0.075), MAP_SPRITE_SCALE * (1.0 - arc * 0.06))
		$Sprite2D.position = sprite_base_position + Vector2(0.0, arc * 1.0)
	if map_shadow != null:
		map_shadow.scale = shadow_base_scale * (1.0 + arc * 0.16)
		map_shadow.modulate = Color(1.0, 1.0, 1.0, 1.0 + arc * 0.10)
	if map_presence_glow != null:
		map_presence_glow.scale = glow_base_scale * (1.0 - arc * 0.05)

func set_walk_frame_for_progress(progress: float) -> void:
	if not has_node("Sprite2D"):
		return
	if progress < 0.18 or progress > 0.86:
		$Sprite2D.frame = 0
	elif progress < 0.52:
		$Sprite2D.frame = 1
	else:
		$Sprite2D.frame = 2

func reset_step_visuals() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.position = sprite_base_position
		$Sprite2D.rotation_degrees = 0.0
		$Sprite2D.scale = Vector2(MAP_SPRITE_SCALE, MAP_SPRITE_SCALE)
		$Sprite2D.frame = 0
	if map_shadow != null:
		map_shadow.scale = shadow_base_scale
		map_shadow.modulate = Color.WHITE
	if map_presence_glow != null:
		map_presence_glow.scale = glow_base_scale

func apply_step_facing(direction: Vector2i) -> void:
	if not has_node("Sprite2D"):
		return
	if direction.x < 0:
		$Sprite2D.flip_h = true
	elif direction.x > 0:
		$Sprite2D.flip_h = false

func is_valid_position(pos: Vector2i) -> bool:
	# Границы комнаты 16x16
	if pos.x < 0 or pos.x >= 16 or pos.y < 0 or pos.y >= 16:
		return false
	
	var room = get_parent()
	if room != null and room.has_method("is_grid_position_blocked") and room.is_grid_position_blocked(pos):
		return false
	
	return true

func check_for_encounter():
	# Получаем всех врагов на сцене
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy.has_method("should_start_encounter") and enemy.should_start_encounter(grid_pos):
			# Нашли врага! Начинаем бой
			start_battle(enemy)
			return

func check_for_interaction() -> void:
	var room = get_parent()
	if room != null and room.has_method("handle_player_interaction"):
		room.handle_player_interaction(grid_pos)

func start_battle(enemy):
	if input_locked:
		return
	input_locked = true
	GameState.start_battle(enemy.enemy_id, grid_pos)
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file(ScenePaths.BATTLE)

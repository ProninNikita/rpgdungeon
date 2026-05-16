extends CharacterBody2D

const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")
const TILE_SIZE = 32
const HALF_TILE = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
const NAME_LABEL_RADIUS = 2
const MAP_SPRITE_SCALE = 1.10

@export var enemy_id: String = ""
@export var enemy_type: String = "goblin"
@export var grid_pos: Vector2i = Vector2i(0, 0)
@export var encounter_radius: int = 1

var name_label: String = "Гоблин"
var map_variant: String = PixelAssetPaths.MAP_VARIANT
var map_shadow: Sprite2D
var map_presence_glow: Sprite2D
var map_threat_anchor: Sprite2D

func _ready():
	if enemy_id.is_empty():
		enemy_id = "%s:%s" % [get_tree().current_scene.scene_file_path, get_path()]
	
	if GameState.is_enemy_defeated(enemy_id):
		queue_free()
		return
	
	if position != Vector2.ZERO:
		grid_pos = world_to_grid_position(position)
	set_grid_position(grid_pos)
	create_map_shadow()
	create_map_presence_glow()
	create_map_threat_anchor()
	apply_map_texture()
	$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite2D.scale = Vector2(MAP_SPRITE_SCALE, MAP_SPRITE_SCALE)
	$Sprite2D.z_index = 2
	$Sprite2D.modulate = Color(1.18, 1.12, 1.04, 1.0)
	$Label.text = name_label
	apply_label_style()
	update_name_label_visibility()
	add_to_group("enemies")

func _process(_delta: float) -> void:
	update_name_label_visibility()

func set_map_variant(variant: String) -> void:
	map_variant = variant
	apply_map_texture()

func apply_map_texture() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.texture = PixelAssetPaths.enemy_map_texture(enemy_type, map_variant)

func create_map_shadow() -> void:
	if map_shadow != null:
		return
	map_shadow = Sprite2D.new()
	map_shadow.name = "MapShadow"
	map_shadow.position = Vector2(0.0, 8.5)
	map_shadow.texture = create_shadow_texture(Color(0.0, 0.0, 0.0, 0.38))
	map_shadow.scale = Vector2(0.95, 0.48)
	map_shadow.z_index = -1
	add_child(map_shadow)

func create_map_presence_glow() -> void:
	if map_presence_glow != null:
		return
	map_presence_glow = Sprite2D.new()
	map_presence_glow.name = "MapPresenceGlow"
	map_presence_glow.position = Vector2(0.0, 4.0)
	map_presence_glow.texture = create_presence_glow_texture(get_enemy_presence_color())
	map_presence_glow.scale = Vector2(1.14, 0.84)
	map_presence_glow.z_index = 0
	add_child(map_presence_glow)

func create_map_threat_anchor() -> void:
	if map_threat_anchor != null:
		return
	map_threat_anchor = Sprite2D.new()
	map_threat_anchor.name = "MapThreatAnchor"
	map_threat_anchor.position = Vector2(0.0, 5.0)
	map_threat_anchor.texture = create_threat_anchor_texture(get_enemy_threat_color())
	map_threat_anchor.scale = Vector2(1.02, 0.78)
	map_threat_anchor.z_index = 1
	add_child(map_threat_anchor)

func get_enemy_presence_color() -> Color:
	if enemy_type == "bat":
		return Color(0.62, 0.38, 0.72, 0.38)
	if enemy_type == "skeleton":
		return Color(0.78, 0.66, 0.46, 0.36)
	if enemy_type == "slime":
		return Color(0.34, 0.68, 0.50, 0.38)
	return Color(0.82, 0.28, 0.20, 0.40)

func get_enemy_threat_color() -> Color:
	if enemy_type == "bat":
		return Color(0.50, 0.28, 0.66, 0.44)
	if enemy_type == "skeleton":
		return Color(0.76, 0.56, 0.34, 0.40)
	if enemy_type == "slime":
		return Color(0.26, 0.58, 0.42, 0.42)
	return Color(0.78, 0.18, 0.13, 0.46)

func create_presence_glow_texture(glow_color: Color) -> ImageTexture:
	var width = 32
	var height = 28
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(
				(float(x) / float(width - 1) - 0.5) * 2.0,
				(float(y) / float(height - 1) - 0.5) * 2.0
			)
			var distance = sqrt(uv.x * uv.x + uv.y * uv.y * 1.9)
			var alpha = pow(clamp(1.0 - distance, 0.0, 1.0), 1.7)
			image.set_pixel(x, y, Color(glow_color.r, glow_color.g, glow_color.b, alpha * glow_color.a))
	return ImageTexture.create_from_image(image)

func create_threat_anchor_texture(anchor_color: Color) -> ImageTexture:
	var width = 36
	var height = 28
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(
				(float(x) / float(width - 1) - 0.5) * 2.0,
				(float(y) / float(height - 1) - 0.5) * 2.0
			)
			var distance = sqrt(uv.x * uv.x + uv.y * uv.y * 2.25)
			var ring = pow(clamp(1.0 - abs(distance - 0.72) * 4.2, 0.0, 1.0), 1.4)
			var center = pow(clamp(1.0 - distance, 0.0, 1.0), 2.6) * 0.36
			var alpha = (ring * 0.72 + center) * anchor_color.a
			image.set_pixel(x, y, Color(anchor_color.r, anchor_color.g, anchor_color.b, alpha))
	return ImageTexture.create_from_image(image)

func create_shadow_texture(shadow_color: Color) -> ImageTexture:
	var width = 28
	var height = 12
	var image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var uv = Vector2(
				(float(x) / float(width - 1) - 0.5) * 2.0,
				(float(y) / float(height - 1) - 0.5) * 2.0
			)
			var distance = sqrt(uv.x * uv.x + uv.y * uv.y * 3.4)
			var alpha = clamp(1.0 - distance, 0.0, 1.0)
			image.set_pixel(x, y, Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha * shadow_color.a))
	return ImageTexture.create_from_image(image)

func apply_label_style() -> void:
	$Label.position = Vector2(-36, -36)
	$Label.size = Vector2(72, 18)
	$Label.z_index = 70
	$Label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$Label.add_theme_font_size_override("font_size", 12)
	$Label.add_theme_color_override("font_color", Color(0.90, 0.84, 0.74, 1))
	$Label.add_theme_color_override("font_outline_color", Color(0.03, 0.025, 0.022, 1))
	$Label.add_theme_constant_override("outline_size", 3)

func set_grid_position(new_grid_pos: Vector2i) -> void:
	grid_pos = new_grid_pos
	position = grid_to_world_position(grid_pos)

func grid_to_world_position(pos: Vector2i) -> Vector2:
	return Vector2(pos) * TILE_SIZE + HALF_TILE

func world_to_grid_position(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE_SIZE), floori(world_position.y / TILE_SIZE))

func should_start_encounter(player_grid_pos: Vector2i) -> bool:
	var distance = abs(player_grid_pos.x - grid_pos.x) + abs(player_grid_pos.y - grid_pos.y)
	return distance <= encounter_radius

func update_name_label_visibility() -> void:
	var player_grid_pos = GameState.get_player_grid_position()
	var distance = abs(player_grid_pos.x - grid_pos.x) + abs(player_grid_pos.y - grid_pos.y)
	$Label.visible = distance <= NAME_LABEL_RADIUS

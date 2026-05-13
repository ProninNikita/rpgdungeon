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
	apply_map_texture()
	$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Sprite2D.scale = Vector2(MAP_SPRITE_SCALE, MAP_SPRITE_SCALE)
	$Sprite2D.z_index = 2
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

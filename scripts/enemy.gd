extends CharacterBody2D

const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")
const TILE_SIZE = 32
const HALF_TILE = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

@export var enemy_id: String = ""
@export var enemy_type: String = "goblin"
@export var grid_pos: Vector2i = Vector2i(0, 0)
@export var encounter_radius: int = 1

var name_label: String = "Гоблин"

func _ready():
	if enemy_id.is_empty():
		enemy_id = "%s:%s" % [get_tree().current_scene.scene_file_path, get_path()]
	
	if GameState.is_enemy_defeated(enemy_id):
		queue_free()
		return
	
	if position != Vector2.ZERO:
		grid_pos = world_to_grid_position(position)
	set_grid_position(grid_pos)
	$Sprite2D.texture = PixelAssetPaths.enemy_map_texture(enemy_type)
	$Sprite2D.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Label.text = name_label
	add_to_group("enemies")

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

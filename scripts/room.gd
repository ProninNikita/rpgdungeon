extends Node2D

const ROOM_WIDTH = 16
const ROOM_HEIGHT = 16
const TILE_SIZE = 32
const ENEMY_SCENE = preload("res://scenes/combat/enemy.tscn")

var floor_positions: Dictionary = {}
var wall_positions: Dictionary = {}
var floors_container: Node2D
var walls_container: Node2D
var enemies_container: Node2D

@onready var player = $Player

func _ready():
	GameState.ensure_level_data()
	build_level()

func build_level() -> void:
	floor_positions.clear()
	wall_positions.clear()
	$Background.z_index = -100
	player.z_index = 20

	floors_container = Node2D.new()
	floors_container.name = "GeneratedFloors"
	floors_container.z_index = -10
	add_child(floors_container)

	walls_container = Node2D.new()
	walls_container.name = "GeneratedWalls"
	walls_container.z_index = -5
	add_child(walls_container)

	enemies_container = Node2D.new()
	enemies_container.name = "GeneratedEnemies"
	enemies_container.z_index = 10
	add_child(enemies_container)

	place_player()
	build_floors()
	build_walls()
	spawn_enemies()

func place_player() -> void:
	if player != null and player.has_method("set_grid_position"):
		player.set_grid_position(GameState.get_player_grid_position())

func build_floors() -> void:
	for floor_data in GameState.level_data.get("floor_tiles", []):
		var grid_pos = Vector2i(floor_data["x"], floor_data["y"])
		floor_positions[get_grid_key(grid_pos)] = true

		var floor_tile = ColorRect.new()
		floor_tile.position = grid_pos * TILE_SIZE
		floor_tile.size = Vector2(TILE_SIZE, TILE_SIZE)
		floor_tile.color = Color(0.14, 0.14, 0.18, 1)
		floors_container.add_child(floor_tile)

func build_walls() -> void:
	for wall_data in GameState.level_data.get("walls", []):
		var grid_pos = Vector2i(wall_data["x"], wall_data["y"])
		wall_positions[get_grid_key(grid_pos)] = true

		var wall = ColorRect.new()
		wall.position = grid_pos * TILE_SIZE
		wall.size = Vector2(TILE_SIZE, TILE_SIZE)
		wall.color = Color(0.24, 0.24, 0.3, 1)
		walls_container.add_child(wall)

func spawn_enemies() -> void:
	for enemy_data in GameState.level_data.get("enemies", []):
		var enemy_id = enemy_data["id"]
		if GameState.is_enemy_defeated(enemy_id):
			continue

		var enemy = ENEMY_SCENE.instantiate()
		var grid_pos = Vector2i(enemy_data["x"], enemy_data["y"])
		enemy.name = "Enemy_%s" % enemy_id
		enemy.enemy_id = enemy_id
		enemy.grid_pos = grid_pos
		enemy.name_label = enemy_data.get("name", "Goblin")
		enemies_container.add_child(enemy)

func is_grid_position_blocked(grid_pos: Vector2i) -> bool:
	return not floor_positions.has(get_grid_key(grid_pos))

func get_grid_key(grid_pos: Vector2i) -> String:
	return "%d:%d" % [grid_pos.x, grid_pos.y]

func _draw():
	# Вертикальные линии
	for x in range(ROOM_WIDTH + 1):
		var from = Vector2(x * TILE_SIZE, 0)
		var to = Vector2(x * TILE_SIZE, ROOM_HEIGHT * TILE_SIZE)
		draw_line(from, to, Color(0.3, 0.3, 0.35, 0.5), 1.0)

	# Горизонтальные линии
	for y in range(ROOM_HEIGHT + 1):
		var from = Vector2(0, y * TILE_SIZE)
		var to = Vector2(ROOM_WIDTH * TILE_SIZE, y * TILE_SIZE)
		draw_line(from, to, Color(0.3, 0.3, 0.35, 0.5), 1.0)

func get_room_bounds() -> Rect2:
	return Rect2(0, 0, ROOM_WIDTH * TILE_SIZE, ROOM_HEIGHT * TILE_SIZE)

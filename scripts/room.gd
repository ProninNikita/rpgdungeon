extends Node2D

const ScenePaths = preload("res://scripts/scene_paths.gd")
const ResultData = preload("res://scripts/result_data.gd")
const ROOM_WIDTH = 16
const ROOM_HEIGHT = 16
const TILE_SIZE = 32

var floor_positions: Dictionary = {}
var wall_positions: Dictionary = {}
var floors_container: Node2D
var walls_container: Node2D
var enemies_container: Node2D
var interactables_container: Node2D
var message_sequence: int = 0
var enemy_scene: PackedScene = load(ScenePaths.ENEMY)

@onready var player = $Player
@onready var inventory_ui = $UI/InventoryUI
@onready var floor_label = $UI/Hud/HudContent/FloorLabel
@onready var path_label = $UI/Hud/HudContent/PathLabel
@onready var gold_label = $UI/Hud/HudContent/GoldLabel
@onready var enemies_label = $UI/Hud/HudContent/EnemiesLabel
@onready var message_panel = $UI/MessagePanel
@onready var message_label = $UI/MessagePanel/MessageLabel

func _ready():
	inventory_ui.inventory_toggled.connect(_on_inventory_toggled)
	GameState.ensure_level_data()
	build_level()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		inventory_ui.toggle()
		get_viewport().set_input_as_handled()

func _on_inventory_toggled(is_open: bool) -> void:
	player.input_locked = is_open

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

	interactables_container = Node2D.new()
	interactables_container.name = "GeneratedInteractables"
	interactables_container.z_index = 8
	add_child(interactables_container)

	place_player()
	build_floors()
	build_walls()
	spawn_enemies()
	build_interactables()
	update_hud()
	if GameState.is_level_cleared():
		show_map_message("Этаж зачищен. Сундук и выходы доступны.")

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
	for enemy_encounter in GameState.level_data.get("enemies", []):
		var enemy_id = enemy_encounter["id"]
		if GameState.is_enemy_defeated(enemy_id):
			continue

		var enemy = enemy_scene.instantiate()
		var grid_pos = Vector2i(enemy_encounter["x"], enemy_encounter["y"])
		enemy.name = "Enemy_%s" % enemy_id
		enemy.enemy_id = enemy_id
		enemy.grid_pos = grid_pos
		enemy.name_label = enemy_encounter.get("name", "Гоблин")
		enemies_container.add_child(enemy)

func build_interactables() -> void:
	var fountain_data = GameState.get_visible_fountain()
	if not fountain_data.is_empty():
		create_map_marker(Vector2i(fountain_data["x"], fountain_data["y"]), Color(0.2, 0.55, 0.9, 1), "F")

	var chest_data = GameState.get_visible_chest()
	if not chest_data.is_empty():
		create_map_marker(Vector2i(chest_data["x"], chest_data["y"]), Color(0.85, 0.58, 0.16, 1), "C")

	for exit_data in GameState.get_visible_exits():
		var label = "E" if exit_data.get("path", "") == "elite" else ">"
		var color = Color(0.8, 0.25, 0.25, 1) if exit_data.get("path", "") == "elite" else Color(0.2, 0.7, 0.35, 1)
		create_map_marker(Vector2i(exit_data["x"], exit_data["y"]), color, label)

func create_map_marker(grid_pos: Vector2i, color: Color, label_text: String) -> void:
	var marker = ColorRect.new()
	marker.position = Vector2(grid_pos * TILE_SIZE) + Vector2(4, 4)
	marker.size = Vector2(24, 24)
	marker.color = color
	interactables_container.add_child(marker)

	var label = Label.new()
	label.position = Vector2(grid_pos * TILE_SIZE)
	label.size = Vector2(TILE_SIZE, TILE_SIZE)
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	interactables_container.add_child(label)

func handle_player_interaction(grid_pos: Vector2i) -> bool:
	var fountain_data = GameState.get_visible_fountain()
	if not fountain_data.is_empty() and Vector2i(fountain_data["x"], fountain_data["y"]) == grid_pos:
		var healed_amount = GameState.use_level_fountain()
		show_map_message("Фонтан: восстановлено %d HP" % healed_amount)
		rebuild_interactables()
		return true

	var chest_data = GameState.get_visible_chest()
	if not chest_data.is_empty() and Vector2i(chest_data["x"], chest_data["y"]) == grid_pos:
		var reward = GameState.open_level_chest()
		if bool(reward.get(ResultData.KEY_OPENED, false)):
			show_map_message(get_chest_reward_message(reward))
			rebuild_interactables()
			update_hud()
		return true

	for exit_data in GameState.get_visible_exits():
		if Vector2i(exit_data["x"], exit_data["y"]) == grid_pos:
			show_map_message("Переход: %s." % str(exit_data.get("label", "следующий этаж")))
			if GameState.advance_to_next_floor(str(exit_data.get("id", ""))):
				get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)
			return true

	return false

func rebuild_interactables() -> void:
	for child in interactables_container.get_children():
		child.queue_free()
	build_interactables()

func update_hud() -> void:
	floor_label.text = "Этаж: %d/%d" % [GameState.current_floor, GameState.MAX_FLOOR]
	path_label.text = "Путь: %s" % GameState.get_current_path_label()
	gold_label.text = "Золото: %d" % GameState.gold
	enemies_label.text = "Врагов осталось: %d" % GameState.get_remaining_enemy_count()

func show_map_message(message: String, duration: float = 3.0) -> void:
	message_sequence += 1
	var current_message = message_sequence
	message_label.text = message
	message_panel.show()
	await get_tree().create_timer(duration).timeout
	if current_message == message_sequence:
		message_panel.hide()

func get_chest_reward_message(reward: Dictionary) -> String:
	var gold_amount = int(reward.get(ResultData.KEY_GOLD, 0))
	var item_id = str(reward.get(ResultData.KEY_ITEM_ID, ""))
	if item_id.is_empty():
		return "Сундук: %d золота" % gold_amount

	var item_name = GameState.get_item_name(item_id)
	if bool(reward.get(ResultData.KEY_ITEM_ADDED, false)):
		return "Сундук: %s и %d золота" % [item_name, gold_amount]

	return "Сундук: %d золота. Инвентарь полон, %s потерян." % [gold_amount, item_name]

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

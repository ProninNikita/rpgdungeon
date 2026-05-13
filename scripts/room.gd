extends Node2D

const ScenePaths = preload("res://scripts/scene_paths.gd")
const ResultData = preload("res://scripts/result_data.gd")
const DungeonGenerator = preload("res://scripts/dungeon_generator.gd")
const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")
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
var choice_panel: Panel
var choice_title: Label
var choice_message: Label
var choice_buttons: Array = []
var choice_cancel_button: Button
var pending_choice_room_id: String = ""
var pending_exit_id: String = ""

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
	create_choice_panel()
	layout_overlay_panels()
	GameState.ensure_level_data()
	if GameState.is_run_complete():
		GameState.complete_run()
		get_tree().call_deferred("change_scene_to_file", ScenePaths.RESULT_SCREEN)
		return
	build_level()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and message_panel != null:
		layout_overlay_panels()

func layout_overlay_panels() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_width = min(484.0, max(320.0, viewport_size.x - 360.0))
	message_panel.position = Vector2(min(336.0, max(16.0, viewport_size.x - panel_width - 16.0)), 16.0)
	message_panel.size = Vector2(panel_width, 54.0)
	message_label.position = Vector2(12.0, 8.0)
	message_label.size = Vector2(panel_width - 24.0, 38.0)
	if choice_panel != null:
		choice_panel.position = Vector2(message_panel.position.x, 92.0)
		choice_panel.size = Vector2(panel_width, 214.0)

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
		floor_tile.color = get_floor_tile_color(floor_data)
		floors_container.add_child(floor_tile)

		var floor_sprite = Sprite2D.new()
		floor_sprite.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		floor_sprite.texture = get_floor_tile_texture(floor_data)
		floor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		floors_container.add_child(floor_sprite)

func get_floor_tile_color(floor_data: Dictionary) -> Color:
	var room_type = str(floor_data.get("room_type", ""))
	if room_type == DungeonGenerator.ROOM_TYPE_ARTIFACT:
		return Color(0.62, 0.46, 0.12, 1)
	if room_type == DungeonGenerator.ROOM_TYPE_SHOP:
		return Color(0.34, 0.21, 0.12, 1)
	return Color(0.14, 0.14, 0.18, 1)

func get_floor_tile_texture(floor_data: Dictionary) -> Texture2D:
	var room_type = str(floor_data.get("room_type", ""))
	if room_type == DungeonGenerator.ROOM_TYPE_ARTIFACT:
		return PixelAssetPaths.map_texture("artifact_floor")
	if room_type == DungeonGenerator.ROOM_TYPE_SHOP:
		return PixelAssetPaths.map_texture("shop_floor")
	return PixelAssetPaths.map_texture("floor")

func build_walls() -> void:
	for wall_data in GameState.level_data.get("walls", []):
		var grid_pos = Vector2i(wall_data["x"], wall_data["y"])
		wall_positions[get_grid_key(grid_pos)] = true

		var wall = ColorRect.new()
		wall.position = grid_pos * TILE_SIZE
		wall.size = Vector2(TILE_SIZE, TILE_SIZE)
		wall.color = Color(0.24, 0.24, 0.3, 1)
		walls_container.add_child(wall)

		var wall_sprite = Sprite2D.new()
		wall_sprite.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
		wall_sprite.texture = PixelAssetPaths.map_texture("wall")
		wall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		walls_container.add_child(wall_sprite)

func spawn_enemies() -> void:
	for enemy_encounter in GameState.level_data.get("enemies", []):
		var enemy_id = enemy_encounter["id"]
		if GameState.is_enemy_defeated(enemy_id):
			continue

		var enemy = enemy_scene.instantiate()
		var grid_pos = Vector2i(enemy_encounter["x"], enemy_encounter["y"])
		enemy.name = "Enemy_%s" % enemy_id
		enemy.enemy_id = enemy_id
		enemy.enemy_type = str(enemy_encounter.get("type", "goblin"))
		enemy.grid_pos = grid_pos
		enemy.name_label = enemy_encounter.get("name", "Гоблин")
		enemies_container.add_child(enemy)

func build_interactables() -> void:
	for special_room in GameState.get_visible_special_rooms():
		create_special_room_marker(special_room)

	var fountain_data = GameState.get_visible_fountain()
	if not fountain_data.is_empty():
		create_map_marker(Vector2i(fountain_data["x"], fountain_data["y"]), Color(0.2, 0.55, 0.9, 1), "marker_fountain")

	var chest_data = GameState.get_visible_chest()
	if not chest_data.is_empty():
		create_map_marker(Vector2i(chest_data["x"], chest_data["y"]), Color(0.85, 0.58, 0.16, 1), "marker_chest")

	for exit_data in GameState.get_visible_exits():
		var marker_name = "marker_elite" if exit_data.get("path", "") == "elite" else "marker_exit"
		var color = Color(0.8, 0.25, 0.25, 1) if exit_data.get("path", "") == "elite" else Color(0.2, 0.7, 0.35, 1)
		create_map_marker(Vector2i(exit_data["x"], exit_data["y"]), color, marker_name)

func create_special_room_marker(special_room: Dictionary) -> void:
	var room_type = str(special_room.get("type", ""))
	var color = Color(0.72, 0.52, 0.12, 1)
	if room_type == DungeonGenerator.ROOM_TYPE_SHOP:
		color = Color(0.45, 0.27, 0.13, 1)
	if bool(special_room.get("is_used", false)):
		color = Color(0.28, 0.28, 0.3, 1)
	var marker_name = "marker_shop" if room_type == DungeonGenerator.ROOM_TYPE_SHOP else "marker_artifact"
	if bool(special_room.get("is_used", false)):
		marker_name = "marker_used"
	create_map_marker(
		Vector2i(int(special_room.get("x", 0)), int(special_room.get("y", 0))),
		color,
		marker_name
	)

func create_map_marker(grid_pos: Vector2i, color: Color, marker_name: String) -> void:
	var marker = ColorRect.new()
	marker.position = Vector2(grid_pos * TILE_SIZE) + Vector2(4, 4)
	marker.size = Vector2(24, 24)
	marker.color = color
	interactables_container.add_child(marker)

	var sprite = Sprite2D.new()
	sprite.position = Vector2(grid_pos * TILE_SIZE) + Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)
	sprite.texture = PixelAssetPaths.map_texture(marker_name)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	interactables_container.add_child(sprite)

func handle_player_interaction(grid_pos: Vector2i) -> bool:
	for special_room in GameState.get_visible_special_rooms():
		if Vector2i(int(special_room.get("x", -1)), int(special_room.get("y", -1))) == grid_pos:
			var result = GameState.use_special_room(str(special_room.get("id", "")))
			if bool(result.get("needs_choice", false)):
				show_special_room_choices(result)
			else:
				show_map_message(str(result.get("message", get_special_room_message(special_room))))
			return true

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
			show_exit_choice(exit_data)
			return true

	return false

func create_choice_panel() -> void:
	choice_panel = Panel.new()
	choice_panel.visible = false
	choice_panel.offset_left = 336.0
	choice_panel.offset_top = 92.0
	choice_panel.offset_right = 820.0
	choice_panel.offset_bottom = 286.0
	$UI.add_child(choice_panel)

	var content = VBoxContainer.new()
	content.offset_left = 12.0
	content.offset_top = 10.0
	content.offset_right = 472.0
	content.offset_bottom = 182.0
	content.add_theme_constant_override("separation", 8)
	choice_panel.add_child(content)

	choice_title = Label.new()
	choice_title.text = "Выбор"
	choice_title.add_theme_font_size_override("font_size", 18)
	content.add_child(choice_title)

	choice_message = Label.new()
	choice_message.custom_minimum_size = Vector2(460, 34)
	choice_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(choice_message)

	for index in range(3):
		var button = Button.new()
		button.custom_minimum_size = Vector2(460, 32)
		button.pressed.connect(_on_choice_option_pressed.bind(index))
		choice_buttons.append(button)
		content.add_child(button)

	choice_cancel_button = Button.new()
	choice_cancel_button.custom_minimum_size = Vector2(460, 30)
	choice_cancel_button.text = "Отмена"
	choice_cancel_button.pressed.connect(_on_choice_cancel_pressed)
	content.add_child(choice_cancel_button)

func show_special_room_choices(result: Dictionary) -> void:
	pending_choice_room_id = str(result.get("room", {}).get("id", ""))
	pending_exit_id = ""
	var option_labels = result.get("option_labels", [])
	choice_title.text = str(result.get("room", {}).get("label", "Особая комната"))
	choice_message.text = str(result.get("message", "Выберите вариант."))
	for index in range(choice_buttons.size()):
		var button = choice_buttons[index]
		if index < option_labels.size():
			button.text = str(option_labels[index])
			button.visible = true
			button.disabled = false
		else:
			button.visible = false
	show_choice_panel()

func show_exit_choice(exit_data: Dictionary) -> void:
	pending_choice_room_id = ""
	pending_exit_id = str(exit_data.get("id", ""))
	choice_title.text = "Переход"
	choice_message.text = get_exit_consequence_text(exit_data)
	for index in range(choice_buttons.size()):
		var button = choice_buttons[index]
		button.visible = index == 0
		button.disabled = index != 0
		if index == 0:
			button.text = "Перейти"
	show_choice_panel()

func show_choice_panel() -> void:
	choice_panel.show()
	player.input_locked = true

func close_choice_panel() -> void:
	pending_choice_room_id = ""
	pending_exit_id = ""
	choice_panel.hide()
	if not inventory_ui.visible:
		player.input_locked = false

func _on_choice_option_pressed(index: int) -> void:
	if not pending_choice_room_id.is_empty():
		var result = GameState.use_special_room_option(pending_choice_room_id, index)
		show_map_message(str(result.get("message", "")))
		if bool(result.get("changed", false)):
			rebuild_interactables()
			update_hud()
		close_choice_panel()
		return

	if not pending_exit_id.is_empty():
		var exit_id = pending_exit_id
		close_choice_panel()
		if GameState.advance_to_next_floor(exit_id):
			get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)

func _on_choice_cancel_pressed() -> void:
	close_choice_panel()

func get_exit_consequence_text(exit_data: Dictionary) -> String:
	var path_type = str(exit_data.get("path", GameState.FLOOR_PATH_NORMAL))
	var to_floor = int(exit_data.get("to_floor", GameState.current_floor + 1))
	return GameState.get_path_consequence_text(path_type, to_floor)

func get_special_room_message(special_room: Dictionary) -> String:
	var room_type = str(special_room.get("type", ""))
	if room_type == DungeonGenerator.ROOM_TYPE_ARTIFACT:
		return "Артефактная комната: %s." % GameState.get_item_name(str(special_room.get("item_id", "")))
	if room_type == DungeonGenerator.ROOM_TYPE_SHOP:
		return "Магазин: %s за %d золота." % [
			GameState.get_item_name(str(special_room.get("item_id", ""))),
			int(special_room.get("price", 0))
		]
	return "%s: пока пусто." % str(special_room.get("label", "Особая комната"))

func rebuild_interactables() -> void:
	for child in interactables_container.get_children():
		child.queue_free()
	build_interactables()

func update_hud() -> void:
	floor_label.text = "Этаж: %d/%d" % [GameState.current_floor, GameState.MAX_FLOOR]
	var modifier_label = GameState.get_current_path_modifier_label()
	if modifier_label.is_empty():
		path_label.text = "Путь: %s" % GameState.get_current_path_label()
	else:
		path_label.text = "Путь: %s - %s" % [GameState.get_current_path_label(), modifier_label]
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

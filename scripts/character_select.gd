extends Control

const ScenePaths = preload("res://scripts/scene_paths.gd")
const ShellUIStyle = preload("res://scripts/shell_ui_style.gd")

@onready var content = $Content
@onready var title_label = $Content/Title
@onready var character_list = $Content/CharacterList
@onready var hint_label = $Content/Hint
@onready var overwrite_slots = $Content/OverwriteSlots
@onready var manage_saves_button = $Content/ManageSavesButton
@onready var back_button = $BackButton

var pending_character_id: String = ""
var character_buttons: Dictionary = {}
var confirm_overlay: ColorRect
var confirm_panel: Panel
var confirm_title: Label
var confirm_message: Label
var confirm_cancel_button: Button
var confirm_overwrite_button: Button
var pending_overwrite_slot: int = 0

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	manage_saves_button.pressed.connect(_on_manage_saves_pressed)
	apply_character_select_style()
	rebuild_character_cards()
	create_overwrite_confirmation()
	connect_overwrite_slots()
	refresh_hint()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		layout_character_select()

func apply_character_select_style() -> void:
	ShellUIStyle.apply_screen(self)
	ShellUIStyle.apply_title(title_label, 44)
	ShellUIStyle.apply_label(hint_label, Color(0.86, 0.80, 0.70, 1.0), 16)
	ShellUIStyle.apply_button(back_button, "back")
	ShellUIStyle.apply_button(manage_saves_button)
	content.add_theme_constant_override("separation", 18)
	character_list.add_theme_constant_override("separation", 12)
	overwrite_slots.add_theme_constant_override("separation", 10)
	layout_character_select()

func layout_character_select() -> void:
	if content == null or title_label == null or hint_label == null or back_button == null:
		return
	var viewport_size = get_viewport_rect().size
	var edge_margin = 24.0
	var content_width = min(780.0, max(320.0, viewport_size.x - edge_margin * 2.0))
	var content_height = min(650.0, max(500.0, viewport_size.y - edge_margin * 2.0))
	content_width = min(content_width, viewport_size.x)
	content_height = min(content_height, viewport_size.y)
	var content_min_x = 0.0 if content_width >= viewport_size.x - edge_margin * 2.0 else edge_margin
	var content_min_y = 0.0 if content_height >= viewport_size.y - edge_margin * 2.0 else edge_margin
	content.position = Vector2(
		clamp((viewport_size.x - content_width) * 0.5, content_min_x, max(content_min_x, viewport_size.x - content_width - content_min_x)),
		clamp((viewport_size.y - content_height) * 0.5, content_min_y, max(content_min_y, viewport_size.y - content_height - content_min_y))
	)
	content.size = Vector2(content_width, content_height)
	title_label.custom_minimum_size = Vector2(content_width, 60.0)
	hint_label.custom_minimum_size = Vector2(content_width, 48.0)
	manage_saves_button.custom_minimum_size = Vector2(content_width, 42.0)
	back_button.position = Vector2(24.0, 24.0)
	back_button.size = Vector2(160.0, 42.0)
	layout_character_cards(content_width)
	layout_overwrite_slots(content_width)
	ShellUIStyle.fit_control_to_viewport(content, viewport_size, edge_margin)
	if confirm_overlay != null:
		confirm_overlay.size = viewport_size
	if confirm_panel != null:
		var confirm_size = Vector2(min(560.0, max(300.0, viewport_size.x - edge_margin * 2.0)), min(280.0, max(240.0, viewport_size.y - edge_margin * 2.0)))
		confirm_size.x = min(confirm_size.x, viewport_size.x)
		confirm_size.y = min(confirm_size.y, viewport_size.y)
		confirm_panel.position = Vector2(max(0.0, (viewport_size.x - confirm_size.x) * 0.5), max(0.0, (viewport_size.y - confirm_size.y) * 0.5))
		confirm_panel.size = confirm_size
		var box = confirm_panel.get_child(0) as VBoxContainer
		if box != null:
			box.position = Vector2(22.0, 18.0)
			box.size = confirm_size - Vector2(44.0, 36.0)
			confirm_title.custom_minimum_size = Vector2(box.size.x, 34.0)
			confirm_message.custom_minimum_size = Vector2(box.size.x, max(96.0, box.size.y - 104.0))

func layout_character_cards(content_width: float) -> void:
	var portrait_size = 112.0 if content_width >= 560.0 else 84.0
	var portrait_x = max(196.0, content_width - portrait_size - 36.0)
	for button in character_buttons.values():
		button.custom_minimum_size = Vector2(content_width, 128.0)
		var portrait = button.get_node_or_null("Portrait")
		if portrait != null:
			portrait.position = Vector2(portrait_x, (128.0 - portrait_size) * 0.5)
			portrait.size = Vector2(portrait_size, portrait_size)

func layout_overwrite_slots(content_width: float) -> void:
	if overwrite_slots == null:
		return
	var slot_width = max(96.0, (content_width - 20.0) / 3.0)
	for button in overwrite_slots.get_children():
		button.custom_minimum_size = Vector2(slot_width, 72.0)

func rebuild_character_cards() -> void:
	for child in character_list.get_children():
		child.queue_free()
	character_buttons.clear()
	for character_id in ["base", "vampire"]:
		var button = create_character_card(character_id)
		character_list.add_child(button)
		character_buttons[character_id] = button

func create_character_card(character_id: String) -> Button:
	var stats = GameState.get_character_stats(character_id)
	var button = Button.new()
	button.custom_minimum_size = Vector2(max(320.0, content.size.x), 128.0)
	button.text = get_character_card_text(character_id, stats)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.pressed.connect(start_character_game.bind(character_id))
	ShellUIStyle.apply_button(button, "primary" if character_id == "base" else "normal")

	var portrait = ShellUIStyle.make_character_portrait(character_id, 112.0)
	portrait.name = "Portrait"
	portrait.position = Vector2(626.0, 8.0)
	portrait.size = Vector2(118.0, 112.0)
	button.add_child(portrait)
	return button

func get_character_card_text(character_id: String, stats: Dictionary) -> String:
	if character_id == "vampire":
		return "Вампир\nРоль: рискованный дуэлянт\nHP %d   Атака %d   Защита %d\nПассивка: лечится от нанесенного урона" % [
			int(stats.get("max_hp", stats.get("hp", 100))),
			int(stats.get("attack", 10)),
			int(stats.get("defense", 2))
		]
	return "Герой\nРоль: устойчивый мечник\nHP %d   Атака %d   Защита %d\nПассивка: один раз лечится при низком HP" % [
		int(stats.get("max_hp", stats.get("hp", 100))),
		int(stats.get("attack", 10)),
		int(stats.get("defense", 2))
	]

func connect_overwrite_slots() -> void:
	for index in range(overwrite_slots.get_child_count()):
		var slot = index + 1
		var button = overwrite_slots.get_child(index)
		button.pressed.connect(_on_overwrite_slot_pressed.bind(slot))
		ShellUIStyle.apply_button(button, "danger")

func _on_base_character_pressed() -> void:
	start_character_game("base")

func _on_vampire_pressed() -> void:
	start_character_game("vampire")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

func _on_manage_saves_pressed() -> void:
	get_tree().change_scene_to_file(ScenePaths.LOAD_MENU)

func start_character_game(character_id: String) -> void:
	pending_character_id = character_id
	refresh_character_selection()
	if GameState.start_new_game(character_id):
		get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)
	else:
		hint_label.text = "Свободных слотов нет. Выберите слот для перезаписи или откройте управление сохранениями."
		refresh_overwrite_slots(true)

func _on_overwrite_slot_pressed(slot: int) -> void:
	if pending_character_id.is_empty():
		hint_label.text = "Сначала выберите героя или вампира."
		return
	if not GameState.save_slot_exists(slot):
		return
	show_overwrite_confirmation(slot)

func refresh_hint() -> void:
	if GameState.has_empty_save_slot():
		hint_label.text = "Выберите персонажа, чтобы начать новый забег в свободном слоте."
		refresh_overwrite_slots(false)
	else:
		hint_label.text = "Все слоты заняты. Выберите персонажа, затем подтвердите перезапись одного слота."
		refresh_overwrite_slots(true)
	refresh_character_selection()

func refresh_character_selection() -> void:
	for character_id in character_buttons.keys():
		var button = character_buttons[character_id]
		ShellUIStyle.apply_button(button, "primary" if character_id == pending_character_id else "normal")

func refresh_overwrite_slots(is_visible: bool) -> void:
	overwrite_slots.visible = is_visible
	manage_saves_button.visible = is_visible
	for index in range(overwrite_slots.get_child_count()):
		var slot = index + 1
		var button = overwrite_slots.get_child(index)
		button.disabled = not GameState.save_slot_exists(slot)
		button.text = get_overwrite_button_text(slot)

func get_overwrite_button_text(slot: int) -> String:
	var save_data = GameState.load_save_slot(slot)
	if save_data.is_empty():
		return "Слот %d\nПусто" % slot
	var character_id = str(save_data.get("selected_character_id", "base"))
	var level_data = save_data.get("level_data", {})
	var floor_number = int(save_data.get("current_floor", level_data.get("floor_number", 1)))
	var gold = int(save_data.get("gold", 0))
	return "Слот %d\n%s  Этаж %d/3\nЗолото %d" % [slot, get_character_label(character_id), floor_number, gold]

func get_overwrite_description(slot: int) -> String:
	var save_data = GameState.load_save_slot(slot)
	if save_data.is_empty():
		return "Слот %d пуст." % slot
	var level_data = save_data.get("level_data", {})
	var floor_number = int(save_data.get("current_floor", level_data.get("floor_number", 1)))
	var path_label = get_path_label(str(level_data.get("path", "normal")))
	var gold = int(save_data.get("gold", 0))
	var defeated_count = save_data.get("defeated_enemies", {}).size()
	return "%s / Этаж %d/3 / %s путь\nЗолото %d / Побеждено %d" % [
		get_character_label(str(save_data.get("selected_character_id", "base"))),
		floor_number,
		path_label,
		gold,
		defeated_count
	]

func create_overwrite_confirmation() -> void:
	confirm_overlay = ColorRect.new()
	confirm_overlay.name = "OverwriteConfirmOverlay"
	confirm_overlay.color = Color(0.0, 0.0, 0.0, 0.64)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_overlay.visible = false
	add_child(confirm_overlay)

	confirm_panel = Panel.new()
	confirm_panel.name = "OverwriteConfirmPanel"
	ShellUIStyle.apply_panel(confirm_panel, true)
	confirm_overlay.add_child(confirm_panel)

	var box = VBoxContainer.new()
	box.position = Vector2(22.0, 18.0)
	box.size = Vector2(516.0, 244.0)
	box.add_theme_constant_override("separation", 14)
	confirm_panel.add_child(box)

	confirm_title = Label.new()
	confirm_title.text = "Перезаписать сохранение?"
	confirm_title.custom_minimum_size = Vector2(516.0, 34.0)
	ShellUIStyle.apply_label(confirm_title, Color(0.96, 0.78, 0.46, 1.0), 23)
	box.add_child(confirm_title)

	confirm_message = Label.new()
	confirm_message.custom_minimum_size = Vector2(516.0, 110.0)
	confirm_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ShellUIStyle.apply_label(confirm_message, Color(0.84, 0.78, 0.68, 1.0), 15)
	box.add_child(confirm_message)

	var actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)

	confirm_cancel_button = Button.new()
	confirm_cancel_button.custom_minimum_size = Vector2(140.0, 42.0)
	confirm_cancel_button.text = "Отмена"
	confirm_cancel_button.pressed.connect(hide_overwrite_confirmation)
	ShellUIStyle.apply_button(confirm_cancel_button, "primary")
	actions.add_child(confirm_cancel_button)

	confirm_overwrite_button = Button.new()
	confirm_overwrite_button.custom_minimum_size = Vector2(150.0, 42.0)
	confirm_overwrite_button.text = "Перезаписать"
	confirm_overwrite_button.pressed.connect(confirm_overwrite_slot)
	ShellUIStyle.apply_button(confirm_overwrite_button, "danger")
	actions.add_child(confirm_overwrite_button)
	layout_character_select()

func show_overwrite_confirmation(slot: int) -> void:
	pending_overwrite_slot = slot
	confirm_message.text = "Новый забег: %s.\nСлот %d будет потерян:\n\n%s" % [
		get_character_label(pending_character_id),
		slot,
		get_overwrite_description(slot)
	]
	confirm_overlay.show()

func hide_overwrite_confirmation() -> void:
	pending_overwrite_slot = 0
	confirm_overlay.hide()

func confirm_overwrite_slot() -> void:
	if pending_overwrite_slot == 0 or pending_character_id.is_empty():
		hide_overwrite_confirmation()
		return
	var slot = pending_overwrite_slot
	var character_id = pending_character_id
	hide_overwrite_confirmation()
	if GameState.start_new_game_in_slot(character_id, slot, true):
		get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)

func get_path_label(path_type: String) -> String:
	if path_type == "elite":
		return "Элитный"
	return "Обычный"

func get_character_label(character_id: String) -> String:
	if character_id == "vampire":
		return "Вампир"
	return "Герой"

extends Control

const ScenePaths = preload("res://scripts/scene_paths.gd")
const ShellUIStyle = preload("res://scripts/shell_ui_style.gd")

@onready var content = $Content
@onready var title_label = $Content/Title
@onready var slots_container = $Content/Slots
@onready var back_button = $BackButton

var save_cards: Array = []
var confirm_overlay: ColorRect
var confirm_panel: Panel
var confirm_title: Label
var confirm_message: Label
var confirm_cancel_button: Button
var confirm_delete_button: Button
var pending_delete_slot: int = 0

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	apply_load_menu_style()
	rebuild_save_cards()
	create_delete_confirmation()
	refresh_slots()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_inside_tree():
		layout_load_menu()

func apply_load_menu_style() -> void:
	ShellUIStyle.apply_screen(self)
	ShellUIStyle.apply_title(title_label, 44)
	ShellUIStyle.apply_button(back_button, "back")
	content.add_theme_constant_override("separation", 22)
	slots_container.add_theme_constant_override("separation", 12)
	layout_load_menu()

func layout_load_menu() -> void:
	if content == null or title_label == null or back_button == null:
		return
	var viewport_size = get_viewport_rect().size
	var edge_margin = 24.0
	var content_width = min(920.0, max(320.0, viewport_size.x - edge_margin * 2.0))
	var content_height = min(590.0, max(430.0, viewport_size.y - edge_margin * 2.0))
	content_width = min(content_width, viewport_size.x)
	content_height = min(content_height, viewport_size.y)
	var content_min_x = 0.0 if content_width >= viewport_size.x - edge_margin * 2.0 else edge_margin
	var content_min_y = 0.0 if content_height >= viewport_size.y - edge_margin * 2.0 else edge_margin
	content.position = Vector2(
		clamp((viewport_size.x - content_width) * 0.5, content_min_x, max(content_min_x, viewport_size.x - content_width - content_min_x)),
		clamp((viewport_size.y - content_height) * 0.5, content_min_y, max(content_min_y, viewport_size.y - content_height - content_min_y))
	)
	content.size = Vector2(content_width, content_height)
	title_label.custom_minimum_size = Vector2(content_width, 64.0)
	back_button.position = Vector2(24.0, 24.0)
	back_button.size = Vector2(160.0, 42.0)
	layout_save_cards(content_width)
	ShellUIStyle.fit_control_to_viewport(content, viewport_size, edge_margin)
	if confirm_overlay != null:
		confirm_overlay.size = viewport_size
	if confirm_panel != null:
		var confirm_size = Vector2(min(520.0, max(300.0, viewport_size.x - edge_margin * 2.0)), min(260.0, max(230.0, viewport_size.y - edge_margin * 2.0)))
		confirm_size.x = min(confirm_size.x, viewport_size.x)
		confirm_size.y = min(confirm_size.y, viewport_size.y)
		confirm_panel.position = Vector2(max(0.0, (viewport_size.x - confirm_size.x) * 0.5), max(0.0, (viewport_size.y - confirm_size.y) * 0.5))
		confirm_panel.size = confirm_size
		var box = confirm_panel.get_child(0) as VBoxContainer
		if box != null:
			box.position = Vector2(22.0, 18.0)
			box.size = confirm_size - Vector2(44.0, 36.0)
			confirm_title.custom_minimum_size = Vector2(box.size.x, 34.0)
			confirm_message.custom_minimum_size = Vector2(box.size.x, max(82.0, box.size.y - 104.0))

func layout_save_cards(content_width: float) -> void:
	for card in save_cards:
		var panel = card["panel"] as PanelContainer
		var slot_label = card["slot_label"] as Label
		var headline = card["headline"] as Label
		var details = card["details"] as Label
		var info = card["info"] as VBoxContainer
		var actions = card["actions"] as HBoxContainer
		var load_button = card["load_button"] as Button
		var delete_button = card["delete_button"] as Button
		var compact = content_width < 640.0
		var slot_width = 68.0 if compact else 96.0
		var button_width = 92.0 if compact else 112.0
		var actions_width = button_width * 2.0 + 10.0
		var info_width = max(120.0, content_width - slot_width - actions_width - 56.0)
		panel.custom_minimum_size = Vector2(content_width, 118.0)
		slot_label.custom_minimum_size = Vector2(slot_width, 86.0)
		info.custom_minimum_size = Vector2(info_width, 86.0)
		headline.custom_minimum_size = Vector2(info_width, 26.0)
		details.custom_minimum_size = Vector2(info_width, 48.0)
		actions.custom_minimum_size = Vector2(actions_width, 86.0)
		load_button.custom_minimum_size = Vector2(button_width, 42.0)
		delete_button.custom_minimum_size = Vector2(button_width, 42.0)

func rebuild_save_cards() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	save_cards.clear()
	for slot in range(1, GameState.SAVE_SLOT_COUNT + 1):
		var card = create_save_card(slot)
		slots_container.add_child(card["panel"])
		save_cards.append(card)

func create_save_card(slot: int) -> Dictionary:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(max(320.0, content.size.x), 118.0)
	panel.name = "SaveCard%d" % slot
	ShellUIStyle.apply_panel(panel, false)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)

	var slot_label = Label.new()
	slot_label.custom_minimum_size = Vector2(96.0, 86.0)
	slot_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ShellUIStyle.apply_label(slot_label, Color(0.96, 0.78, 0.46, 1.0), 21)
	row.add_child(slot_label)

	var info = VBoxContainer.new()
	info.custom_minimum_size = Vector2(520.0, 86.0)
	info.add_theme_constant_override("separation", 5)
	row.add_child(info)

	var headline = Label.new()
	headline.custom_minimum_size = Vector2(520.0, 26.0)
	ShellUIStyle.apply_label(headline, Color(0.92, 0.86, 0.76, 1.0), 18)
	info.add_child(headline)

	var details = Label.new()
	details.custom_minimum_size = Vector2(520.0, 48.0)
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ShellUIStyle.apply_label(details, Color(0.72, 0.66, 0.56, 1.0), 14)
	info.add_child(details)

	var actions = HBoxContainer.new()
	actions.custom_minimum_size = Vector2(240.0, 86.0)
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	row.add_child(actions)

	var load_button = Button.new()
	load_button.custom_minimum_size = Vector2(112.0, 42.0)
	load_button.text = "Загрузить"
	load_button.pressed.connect(_on_load_slot_pressed.bind(slot))
	ShellUIStyle.apply_button(load_button, "primary")
	actions.add_child(load_button)

	var delete_button = Button.new()
	delete_button.custom_minimum_size = Vector2(112.0, 42.0)
	delete_button.text = "Удалить"
	delete_button.pressed.connect(_on_delete_slot_pressed.bind(slot))
	ShellUIStyle.apply_button(delete_button, "danger")
	actions.add_child(delete_button)

	return {
		"slot": slot,
		"panel": panel,
		"slot_label": slot_label,
		"info": info,
		"headline": headline,
		"details": details,
		"actions": actions,
		"load_button": load_button,
		"delete_button": delete_button
	}

func refresh_slots() -> void:
	for card in save_cards:
		var slot = int(card["slot"])
		var save_data = GameState.load_save_slot(slot)
		var has_save = not save_data.is_empty()
		card["slot_label"].text = "Слот\n%d" % slot
		card["headline"].text = get_slot_headline(save_data, slot)
		card["details"].text = get_slot_details(save_data)
		card["load_button"].disabled = not has_save
		card["delete_button"].disabled = not has_save
		style_save_card(card, save_data)

func style_save_card(card: Dictionary, save_data: Dictionary) -> void:
	var panel = card["panel"]
	if save_data.is_empty():
		panel.add_theme_stylebox_override("panel", ShellUIStyle.create_panel_style(Color(0.030, 0.027, 0.025, 0.72), Color(0.20, 0.17, 0.14, 0.92), 1, 4))
		return
	var level_data = save_data.get("level_data", {})
	var path_type = str(level_data.get("path", "normal"))
	if path_type == "elite":
		panel.add_theme_stylebox_override("panel", ShellUIStyle.create_panel_style(Color(0.080, 0.035, 0.026, 0.92), Color(0.62, 0.30, 0.18, 1.0), 2, 4))
	else:
		panel.add_theme_stylebox_override("panel", ShellUIStyle.create_panel_style(Color(0.040, 0.034, 0.030, 0.92), Color(0.44, 0.32, 0.20, 1.0), 1, 4))

func get_slot_headline(save_data: Dictionary, slot: int) -> String:
	if save_data.is_empty():
		return "Пустой слот"
	var character_id = str(save_data.get("selected_character_id", "base"))
	var level_data = save_data.get("level_data", {})
	var floor_number = int(save_data.get("current_floor", level_data.get("floor_number", 1)))
	var path_label = get_path_label(str(level_data.get("path", "normal")))
	return "%s  /  Этаж %d/3  /  %s путь" % [get_character_label(character_id), floor_number, path_label]

func get_slot_details(save_data: Dictionary) -> String:
	if save_data.is_empty():
		return "Можно начать новую игру. Здесь появится краткая сводка забега."
	var gold = int(save_data.get("gold", 0))
	var defeated_count = save_data.get("defeated_enemies", {}).size()
	var updated_at = format_save_date(str(save_data.get("updated_at", "")))
	return "Золото %d     Побеждено %d     Сохранено %s" % [gold, defeated_count, updated_at]

func get_delete_description(slot: int) -> String:
	var save_data = GameState.load_save_slot(slot)
	if save_data.is_empty():
		return "Слот %d пуст." % slot
	return "%s\n%s" % [get_slot_headline(save_data, slot), get_slot_details(save_data)]

func get_path_label(path_type: String) -> String:
	if path_type == "elite":
		return "Элитный"
	return "Обычный"

func get_character_label(character_id: String) -> String:
	if character_id == "vampire":
		return "Вампир"
	return "Герой"

func format_save_date(raw_date: String) -> String:
	if raw_date.is_empty():
		return "неизвестно"
	var parts = raw_date.replace("T", " ").split(" ", false)
	if parts.size() >= 2:
		return "%s %s" % [parts[0], str(parts[1]).substr(0, 5)]
	return raw_date

func create_delete_confirmation() -> void:
	confirm_overlay = ColorRect.new()
	confirm_overlay.name = "DeleteConfirmOverlay"
	confirm_overlay.color = Color(0.0, 0.0, 0.0, 0.64)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_overlay.visible = false
	add_child(confirm_overlay)

	confirm_panel = Panel.new()
	confirm_panel.name = "DeleteConfirmPanel"
	ShellUIStyle.apply_panel(confirm_panel, true)
	confirm_overlay.add_child(confirm_panel)

	var box = VBoxContainer.new()
	box.position = Vector2(22.0, 18.0)
	box.size = Vector2(476.0, 224.0)
	box.add_theme_constant_override("separation", 14)
	confirm_panel.add_child(box)

	confirm_title = Label.new()
	confirm_title.text = "Удалить сохранение?"
	confirm_title.custom_minimum_size = Vector2(476.0, 34.0)
	ShellUIStyle.apply_label(confirm_title, Color(0.96, 0.78, 0.46, 1.0), 23)
	box.add_child(confirm_title)

	confirm_message = Label.new()
	confirm_message.custom_minimum_size = Vector2(476.0, 92.0)
	confirm_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ShellUIStyle.apply_label(confirm_message, Color(0.84, 0.78, 0.68, 1.0), 15)
	box.add_child(confirm_message)

	var actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)

	confirm_cancel_button = Button.new()
	confirm_cancel_button.custom_minimum_size = Vector2(132.0, 42.0)
	confirm_cancel_button.text = "Отмена"
	confirm_cancel_button.pressed.connect(hide_delete_confirmation)
	ShellUIStyle.apply_button(confirm_cancel_button, "primary")
	actions.add_child(confirm_cancel_button)

	confirm_delete_button = Button.new()
	confirm_delete_button.custom_minimum_size = Vector2(132.0, 42.0)
	confirm_delete_button.text = "Удалить"
	confirm_delete_button.pressed.connect(confirm_delete_slot)
	ShellUIStyle.apply_button(confirm_delete_button, "danger")
	actions.add_child(confirm_delete_button)
	layout_load_menu()

func show_delete_confirmation(slot: int) -> void:
	pending_delete_slot = slot
	confirm_message.text = "Слот %d будет удален без восстановления.\n\n%s" % [slot, get_delete_description(slot)]
	confirm_overlay.show()

func hide_delete_confirmation() -> void:
	pending_delete_slot = 0
	confirm_overlay.hide()

func confirm_delete_slot() -> void:
	if pending_delete_slot != 0:
		GameState.delete_save_slot(pending_delete_slot)
	hide_delete_confirmation()
	refresh_slots()

func _on_load_slot_pressed(slot: int) -> void:
	if GameState.load_game(slot):
		get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)

func _on_delete_slot_pressed(slot: int) -> void:
	if not GameState.save_slot_exists(slot):
		return
	show_delete_confirmation(slot)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

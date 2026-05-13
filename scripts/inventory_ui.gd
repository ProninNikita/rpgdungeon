extends Control

signal inventory_toggled(is_open: bool)

const ITEM_ACTION_EQUIP = 0
const ITEM_ACTION_DISCARD = 1
const ITEM_ACTION_UNEQUIP = 2

@onready var close_button = $Window/Header/CloseButton
@onready var window_panel = $Window
@onready var tabs = $Window/Tabs
@onready var character_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/CharacterLabel
@onready var gold_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/GoldLabel
@onready var hp_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/HpLabel
@onready var attack_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/AttackLabel
@onready var defense_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/DefenseLabel
@onready var passives_label = $Window/Tabs/Passives/PassivesContent/EmptyState
@onready var weapon_slot = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/EquipmentSlots/WeaponSlot
@onready var armor_slot = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/EquipmentSlots/ArmorSlot
@onready var accessory_slot = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/EquipmentSlots/AccessorySlot
@onready var inventory_grid = $Window/Tabs/Equipment/Content/InventoryPanel/InventoryContent/InventoryGrid

var inventory_slots: Array = []
var item_action_menu: PopupMenu
var selected_inventory_index: int = -1
var selected_equipment_slot: String = ""

func _ready() -> void:
	layout_window()
	tabs.set_tab_title(0, "Снаряжение")
	tabs.set_tab_title(1, "Пассивки")
	close_button.pressed.connect(close)
	create_item_action_menu()
	collect_inventory_slots()
	connect_inventory_slots()
	connect_equipment_slots()
	apply_inventory_style()
	hide()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and window_panel != null:
		layout_window()

func layout_window() -> void:
	var viewport_size = get_viewport_rect().size
	var window_size = Vector2(
		min(800.0, max(720.0, viewport_size.x - 96.0)),
		min(624.0, max(560.0, viewport_size.y - 96.0))
	)
	window_panel.position = (viewport_size - window_size) * 0.5
	window_panel.size = window_size

func apply_inventory_style() -> void:
	$Dim.color = Color(0.0, 0.0, 0.0, 0.62)
	window_panel.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.040, 0.033, 0.030, 0.98), Color(0.55, 0.40, 0.25, 1.0), 2, 5))
	$Window/Tabs/Equipment/Content/EquipmentPanel.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.055, 0.048, 0.043, 0.94), Color(0.36, 0.27, 0.19, 1.0), 1, 4))
	$Window/Tabs/Equipment/Content/InventoryPanel.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.055, 0.048, 0.043, 0.94), Color(0.36, 0.27, 0.19, 1.0), 1, 4))
	tabs.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.030, 0.027, 0.026, 0.80), Color(0.25, 0.21, 0.17, 1.0), 1, 4))
	tabs.add_theme_stylebox_override("tab_selected", create_inventory_panel_style(Color(0.13, 0.09, 0.055, 0.98), Color(0.64, 0.44, 0.22, 1.0), 1, 3))
	tabs.add_theme_stylebox_override("tab_unselected", create_inventory_panel_style(Color(0.065, 0.055, 0.050, 0.94), Color(0.30, 0.24, 0.19, 1.0), 1, 3))
	tabs.add_theme_color_override("font_selected_color", Color(0.96, 0.78, 0.46, 1.0))
	tabs.add_theme_color_override("font_unselected_color", Color(0.66, 0.58, 0.48, 1.0))
	tabs.add_theme_color_override("font_hovered_color", Color(1.0, 0.88, 0.62, 1.0))
	tabs.add_theme_font_size_override("font_size", 14)
	apply_inventory_label_style(self)
	apply_inventory_button_style(close_button)
	for slot_button in inventory_slots:
		apply_inventory_button_style(slot_button)
	for slot_button in [weapon_slot, armor_slot, accessory_slot]:
		apply_inventory_button_style(slot_button)
	item_action_menu.add_theme_stylebox_override("panel", create_inventory_panel_style(Color(0.050, 0.042, 0.038, 0.98), Color(0.52, 0.38, 0.23, 1.0), 2, 4))
	item_action_menu.add_theme_color_override("font_color", Color(0.91, 0.84, 0.72, 1.0))
	item_action_menu.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.66, 1.0))

func apply_inventory_label_style(node: Node) -> void:
	if node is Label:
		var label = node as Label
		label.add_theme_color_override("font_color", Color(0.88, 0.82, 0.72, 1.0))
		label.add_theme_color_override("font_outline_color", Color(0.025, 0.020, 0.018, 1.0))
		label.add_theme_constant_override("outline_size", 1)
	for child in node.get_children():
		apply_inventory_label_style(child)

func apply_inventory_button_style(button: Button) -> void:
	if button == null:
		return
	button.add_theme_color_override("font_color", Color(0.90, 0.82, 0.68, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.90, 0.66, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.70, 0.95, 0.78, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.47, 0.40, 1.0))
	button.add_theme_color_override("font_outline_color", Color(0.018, 0.014, 0.012, 1.0))
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_stylebox_override("normal", create_inventory_panel_style(Color(0.085, 0.068, 0.052, 0.96), Color(0.34, 0.25, 0.17, 1.0), 1, 3))
	button.add_theme_stylebox_override("hover", create_inventory_panel_style(Color(0.14, 0.095, 0.060, 0.98), Color(0.68, 0.46, 0.24, 1.0), 1, 3))
	button.add_theme_stylebox_override("pressed", create_inventory_panel_style(Color(0.065, 0.082, 0.060, 1.0), Color(0.52, 0.68, 0.44, 1.0), 1, 3))
	button.add_theme_stylebox_override("disabled", create_inventory_panel_style(Color(0.042, 0.038, 0.036, 0.88), Color(0.18, 0.16, 0.14, 1.0), 1, 3))

func create_inventory_panel_style(background_color: Color, border_color: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8
	style.content_margin_top = 6
	style.content_margin_right = 8
	style.content_margin_bottom = 6
	return style

func toggle() -> void:
	if visible:
		close()
	else:
		open()

func open() -> void:
	refresh_character_info()
	show()
	inventory_toggled.emit(true)

func close() -> void:
	hide()
	inventory_toggled.emit(false)

func refresh_character_info() -> void:
	var player_stats = GameState.get_player_battle_stats()
	var equipment_bonuses = GameState.get_equipment_stat_bonuses()
	character_label.text = "Персонаж: %s" % player_stats.get("name", "Герой")
	gold_label.text = "Золото: %d" % GameState.gold
	hp_label.text = "HP: %d/%d" % [int(player_stats.get("hp", 100)), int(player_stats.get("max_hp", 100))]
	attack_label.text = get_stat_text("Атака", int(player_stats.get("attack", 10)), int(equipment_bonuses.get("attack", 0)))
	defense_label.text = get_stat_text("Защита", int(player_stats.get("defense", 2)), int(equipment_bonuses.get("defense", 0)))
	passives_label.text = get_passives_text(player_stats.get("passives", []))
	refresh_equipment_slots()
	refresh_inventory_slots()

func get_stat_text(stat_name: String, total_value: int, bonus_value: int) -> String:
	if bonus_value <= 0:
		return "%s: %d" % [stat_name, total_value]
	return "%s: %d (+%d)" % [stat_name, total_value, bonus_value]

func collect_inventory_slots() -> void:
	inventory_slots.clear()
	for child in inventory_grid.get_children():
		if child is Button:
			inventory_slots.append(child)

func connect_inventory_slots() -> void:
	for index in range(inventory_slots.size()):
		var slot_button = inventory_slots[index]
		slot_button.pressed.connect(_on_inventory_slot_pressed.bind(index))

func connect_equipment_slots() -> void:
	weapon_slot.pressed.connect(_on_equipment_slot_pressed.bind("weapon"))
	armor_slot.pressed.connect(_on_equipment_slot_pressed.bind("armor"))
	accessory_slot.pressed.connect(_on_equipment_slot_pressed.bind("accessory"))

func create_item_action_menu() -> void:
	item_action_menu = PopupMenu.new()
	item_action_menu.id_pressed.connect(_on_item_action_selected)
	add_child(item_action_menu)

func refresh_equipment_slots() -> void:
	refresh_equipment_slot_button(weapon_slot, "weapon")
	refresh_equipment_slot_button(armor_slot, "armor")
	refresh_equipment_slot_button(accessory_slot, "accessory")

func refresh_equipment_slot_button(slot_button: Button, slot: String) -> void:
	var item_id = str(GameState.equipment.get(slot, ""))
	slot_button.text = get_equipment_slot_text(slot)
	slot_button.disabled = item_id.is_empty()

func get_equipment_slot_text(slot: String) -> String:
	var item_id = str(GameState.equipment.get(slot, ""))
	if item_id.is_empty():
		return "-"
	return format_item_button_text(item_id)

func refresh_inventory_slots() -> void:
	for index in range(inventory_slots.size()):
		var slot_button = inventory_slots[index]
		if index >= GameState.inventory.size():
			slot_button.text = ""
			slot_button.disabled = true
			continue

		var item_id = str(GameState.inventory[index])
		slot_button.text = format_item_button_text(item_id)
		slot_button.disabled = false

func format_item_button_text(item_id: String) -> String:
	var item_name = GameState.get_item_name(item_id).replace(" ", "\n")
	var bonus_text = GameState.get_item_bonus_text(item_id)
	if bonus_text.is_empty():
		return item_name
	return "%s\n%s" % [item_name, bonus_text]

func _on_inventory_slot_pressed(index: int) -> void:
	if index < 0 or index >= GameState.inventory.size():
		return

	selected_inventory_index = index
	selected_equipment_slot = ""
	item_action_menu.clear()
	item_action_menu.add_item("Надеть", ITEM_ACTION_EQUIP)
	item_action_menu.add_item("Выбросить", ITEM_ACTION_DISCARD)
	item_action_menu.position = Vector2i(get_viewport().get_mouse_position())
	item_action_menu.popup()

func _on_equipment_slot_pressed(slot: String) -> void:
	var item_id = str(GameState.equipment.get(slot, ""))
	if item_id.is_empty():
		return

	selected_inventory_index = -1
	selected_equipment_slot = slot
	item_action_menu.clear()
	item_action_menu.add_item("Снять", ITEM_ACTION_UNEQUIP)
	item_action_menu.position = Vector2i(get_viewport().get_mouse_position())
	item_action_menu.popup()

func _on_item_action_selected(action_id: int) -> void:
	if selected_inventory_index < 0 and selected_equipment_slot.is_empty():
		return

	if action_id == ITEM_ACTION_EQUIP:
		GameState.equip_inventory_item(selected_inventory_index)
	elif action_id == ITEM_ACTION_DISCARD:
		GameState.discard_inventory_item(selected_inventory_index)
	elif action_id == ITEM_ACTION_UNEQUIP:
		GameState.unequip_equipment_slot(selected_equipment_slot)

	selected_inventory_index = -1
	selected_equipment_slot = ""
	refresh_character_info()

func get_passives_text(passives: Array) -> String:
	if passives.is_empty():
		return "Пока нет пассивных способностей"

	var descriptions = []
	for passive in passives:
		descriptions.append(format_passive(passive))
	return "\n\n".join(descriptions)

func format_passive(passive: Dictionary) -> String:
	if passive.get("id", "") == "resolve":
		var trigger_percent = int(round(float(passive.get("trigger_hp_percent", 0.0)) * 100.0))
		var heal_percent = int(round(float(passive.get("heal_percent", 0.0)) * 100.0))
		return "%s\nОдин раз за бой лечит на %d%% HP, когда здоровье падает до %d%% или ниже." % [passive.get("name", "Стойкость"), heal_percent, trigger_percent]

	if passive.get("id", "") == "vampirism":
		var heal_percent = int(round(float(passive.get("heal_percent", 0.0)) * 100.0))
		return "%s\nЛечит на %d%% от нанесённого урона после атаки." % [passive.get("name", "Vampirism"), heal_percent]

	return "%s" % passive.get("name", "Неизвестная пассивка")

extends Control

signal inventory_toggled(is_open: bool)

const ITEM_ACTION_EQUIP = 0
const ITEM_ACTION_DISCARD = 1

@onready var close_button = $Window/Header/CloseButton
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

func _ready() -> void:
	tabs.set_tab_title(0, "Снаряжение")
	tabs.set_tab_title(1, "Пассивки")
	close_button.pressed.connect(close)
	create_item_action_menu()
	collect_inventory_slots()
	connect_inventory_slots()
	hide()

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
	character_label.text = "Персонаж: %s" % player_stats.get("name", "Player")
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

func create_item_action_menu() -> void:
	item_action_menu = PopupMenu.new()
	item_action_menu.id_pressed.connect(_on_item_action_selected)
	add_child(item_action_menu)

func refresh_equipment_slots() -> void:
	weapon_slot.text = get_equipment_slot_text("weapon")
	armor_slot.text = get_equipment_slot_text("armor")
	accessory_slot.text = get_equipment_slot_text("accessory")

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
	item_action_menu.clear()
	item_action_menu.add_item("Надеть", ITEM_ACTION_EQUIP)
	item_action_menu.add_item("Выбросить", ITEM_ACTION_DISCARD)
	item_action_menu.position = Vector2i(get_viewport().get_mouse_position())
	item_action_menu.popup()

func _on_item_action_selected(action_id: int) -> void:
	if selected_inventory_index < 0:
		return

	if action_id == ITEM_ACTION_EQUIP:
		GameState.equip_inventory_item(selected_inventory_index)
	elif action_id == ITEM_ACTION_DISCARD:
		GameState.discard_inventory_item(selected_inventory_index)

	selected_inventory_index = -1
	refresh_character_info()

func get_passives_text(passives: Array) -> String:
	if passives.is_empty():
		return "Пока нет пассивных способностей"

	var descriptions = []
	for passive in passives:
		descriptions.append(format_passive(passive))
	return "\n\n".join(descriptions)

func format_passive(passive: Dictionary) -> String:
	if passive.get("id", "") == "vampirism":
		var heal_percent = int(round(float(passive.get("heal_percent", 0.0)) * 100.0))
		return "%s\nЛечит на %d%% от нанесённого урона после атаки." % [passive.get("name", "Vampirism"), heal_percent]

	return "%s" % passive.get("name", "Unknown passive")

extends Control

signal inventory_toggled(is_open: bool)

@onready var close_button = $Window/Header/CloseButton
@onready var tabs = $Window/Tabs
@onready var character_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/CharacterLabel
@onready var hp_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/HpLabel
@onready var attack_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/AttackLabel
@onready var defense_label = $Window/Tabs/Equipment/Content/EquipmentPanel/EquipmentContent/DefenseLabel
@onready var passives_label = $Window/Tabs/Passives/PassivesContent/EmptyState

func _ready() -> void:
	tabs.set_tab_title(0, "Снаряжение")
	tabs.set_tab_title(1, "Пассивки")
	close_button.pressed.connect(close)
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
	character_label.text = "Персонаж: %s" % player_stats.get("name", "Player")
	hp_label.text = "HP: %d/%d" % [int(player_stats.get("hp", 100)), int(player_stats.get("max_hp", 100))]
	attack_label.text = "Атака: %d" % int(player_stats.get("attack", 10))
	defense_label.text = "Защита: %d" % int(player_stats.get("defense", 2))
	passives_label.text = get_passives_text(player_stats.get("passives", []))

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

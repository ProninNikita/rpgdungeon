extends Control

const ScenePaths = preload("res://scripts/scene_paths.gd")

@onready var title_label = $Content/Title
@onready var summary_label = $Content/Summary
@onready var new_game_button = $Content/Actions/NewGameButton
@onready var main_menu_button = $Content/Actions/MainMenuButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	refresh_summary()

func refresh_summary() -> void:
	var summary = GameState.get_completed_run_summary()
	title_label.text = "Забег завершен"
	var equipment_lines = summary.get("equipment", [])
	var equipment_text = "Нет" if equipment_lines.is_empty() else "\n".join(equipment_lines)
	summary_label.text = "Персонаж: %s\nПуть: %s\nЭтаж: %d/%d\nЗолото: %d\nПобеждено врагов: %d\nСнаряжение:\n%s" % [
		summary.get("character", "Герой"),
		summary.get("path", "Обычный"),
		int(summary.get("floor", 1)),
		int(summary.get("max_floor", 1)),
		int(summary.get("gold", 0)),
		int(summary.get("defeated_enemies", 0)),
		equipment_text
	]

func _on_new_game_pressed() -> void:
	GameState.clear_current_battle()
	get_tree().change_scene_to_file(ScenePaths.CHARACTER_SELECT)

func _on_main_menu_pressed() -> void:
	GameState.clear_current_battle()
	get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)

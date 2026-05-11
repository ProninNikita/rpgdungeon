extends Control

const ScenePaths = preload("res://scripts/scene_paths.gd")

func _ready() -> void:
	$MenuPanel/NewGameButton.pressed.connect(_on_new_game_pressed)
	$MenuPanel/LoadGameButton.pressed.connect(_on_load_game_pressed)
	$MenuPanel/ExitButton.pressed.connect(_on_exit_pressed)

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(ScenePaths.CHARACTER_SELECT)

func _on_load_game_pressed() -> void:
	get_tree().change_scene_to_file(ScenePaths.LOAD_MENU)

func _on_exit_pressed() -> void:
	get_tree().quit()

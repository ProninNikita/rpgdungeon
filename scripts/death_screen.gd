extends Control

func _ready() -> void:
	$Content/Actions/NewGameButton.pressed.connect(_on_new_game_pressed)
	$Content/Actions/MainMenuButton.pressed.connect(_on_main_menu_pressed)

func _on_new_game_pressed() -> void:
	GameState.clear_current_battle()
	get_tree().change_scene_to_file("res://scenes/ui/character_select.tscn")

func _on_main_menu_pressed() -> void:
	GameState.clear_current_battle()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

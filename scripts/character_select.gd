extends Control

func _ready() -> void:
	$Content/CharacterList/BaseCharacterButton.pressed.connect(_on_base_character_pressed)
	$BackButton.pressed.connect(_on_back_pressed)

func _on_base_character_pressed() -> void:
	GameState.start_new_game("base")
	get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

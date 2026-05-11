extends Control

const ScenePaths = preload("res://scripts/scene_paths.gd")

@onready var hint_label = $Content/Hint
@onready var overwrite_slots = $Content/OverwriteSlots
@onready var manage_saves_button = $Content/ManageSavesButton

var pending_character_id: String = ""

func _ready() -> void:
	$Content/CharacterList/BaseCharacterButton.pressed.connect(_on_base_character_pressed)
	$Content/CharacterList/VampireButton.pressed.connect(_on_vampire_pressed)
	$BackButton.pressed.connect(_on_back_pressed)
	manage_saves_button.pressed.connect(_on_manage_saves_pressed)
	for index in range(overwrite_slots.get_child_count()):
		var slot = index + 1
		overwrite_slots.get_child(index).pressed.connect(_on_overwrite_slot_pressed.bind(slot))
	refresh_hint()

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
	if GameState.start_new_game(character_id):
		get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)
	else:
		hint_label.text = "Все слоты заняты. Выберите слот для перезаписи или откройте управление сохранениями."
		refresh_overwrite_slots(true)

func _on_overwrite_slot_pressed(slot: int) -> void:
	if pending_character_id.is_empty():
		hint_label.text = "Сначала выберите персонажа."
		return

	if GameState.start_new_game_in_slot(pending_character_id, slot, true):
		get_tree().change_scene_to_file(GameState.MAIN_LEVEL_PATH)

func refresh_hint() -> void:
	if GameState.has_empty_save_slot():
		hint_label.text = "Базовый герой лечится при низком HP. Вампир лечится от урона."
		refresh_overwrite_slots(false)
	else:
		hint_label.text = "Все слоты заняты. Выберите персонажа, затем слот для перезаписи."
		refresh_overwrite_slots(true)

func refresh_overwrite_slots(is_visible: bool) -> void:
	overwrite_slots.visible = is_visible
	manage_saves_button.visible = is_visible
	for index in range(overwrite_slots.get_child_count()):
		var slot = index + 1
		var button = overwrite_slots.get_child(index)
		button.disabled = not GameState.save_slot_exists(slot)

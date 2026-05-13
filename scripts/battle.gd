extends Node2D

const CombatResolver = preload("res://scripts/combat_resolver.gd")
const ScenePaths = preload("res://scripts/scene_paths.gd")
const ResultData = preload("res://scripts/result_data.gd")
const PixelAssetPaths = preload("res://scripts/pixel_asset_paths.gd")

var player_stats: Dictionary
var enemy_stats: Dictionary
var is_battle_active: bool = true
var battle_log: Array = []
var used_passives: Dictionary = {}

@onready var player_hp_label = $PlayerHP
@onready var enemy_hp_label = $EnemyHP
@onready var log_label = $BattleLog
@onready var result_label = $ResultLabel
@onready var player_hp_bar = $PlayerHPBar
@onready var enemy_hp_bar = $EnemyHPBar
@onready var status_label = $StatusLabel
@onready var effect_label = $EffectLabel
@onready var speed_button = $SpeedButton
@onready var player_sprite = $PlayerSprite
@onready var enemy_sprite = $EnemySprite

const NORMAL_ATTACK_DELAY = 1.5
const FAST_ATTACK_DELAY = 0.55
const LARGE_PLAYER_FRAME_THRESHOLD = 96.0
const LARGE_PLAYER_TARGET_HEIGHT = 330.0
const DEFAULT_PLAYER_TARGET_HEIGHT = 214.0
const ENEMY_TARGET_HEIGHT = 200.0
const DEATH_SCREEN_PATH = ScenePaths.DEATH_SCREEN
const MAIN_LEVEL_PATH = ScenePaths.MAIN_LEVEL
const RESULT_SCREEN_PATH = ScenePaths.RESULT_SCREEN
var attack_delay: float = NORMAL_ATTACK_DELAY

func _ready():
	player_stats = GameState.get_player_battle_stats()
	enemy_stats = GameState.get_current_enemy_battle_stats()
	speed_button.pressed.connect(_on_speed_button_pressed)
	configure_battle_sprites()
	layout_battle_ui()
	
	update_ui()
	add_log("Бой начался.")
	add_log("%s против %s" % [player_stats["name"], enemy_stats["name"]])
	var traits_text = get_enemy_traits_text()
	if not traits_text.is_empty():
		add_log("Особенности врага: " + traits_text)
	
	await get_tree().create_timer(1.5).timeout
	battle_loop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and is_inside_tree():
		layout_battle_ui()

func layout_battle_ui() -> void:
	if not is_inside_tree():
		return
	if player_hp_label == null or speed_button == null:
		return
	var viewport_size = get_viewport().get_visible_rect().size
	$Background.size = viewport_size
	var margin = 20.0
	var bar_width = max(280.0, (viewport_size.x - margin * 3.0) * 0.5)
	player_hp_label.position = Vector2(margin, 20.0)
	player_hp_label.size = Vector2(bar_width, 30.0)
	player_hp_bar.position = Vector2(margin, 55.0)
	player_hp_bar.size = Vector2(bar_width, 20.0)
	enemy_hp_label.position = Vector2(viewport_size.x - bar_width - margin, 20.0)
	enemy_hp_label.size = Vector2(bar_width, 30.0)
	enemy_hp_bar.position = Vector2(viewport_size.x - bar_width - margin, 55.0)
	enemy_hp_bar.size = Vector2(bar_width, 20.0)
	status_label.position = Vector2((viewport_size.x - 304.0) * 0.5, 94.0)
	status_label.size = Vector2(304.0, 32.0)
	effect_label.position = Vector2((viewport_size.x - 360.0) * 0.5, 126.0)
	effect_label.size = Vector2(360.0, 28.0)
	speed_button.position = Vector2(viewport_size.x - 136.0, 92.0)
	speed_button.size = Vector2(116.0, 36.0)
	player_sprite.position = Vector2(viewport_size.x * 0.32, viewport_size.y * 0.60)
	enemy_sprite.position = Vector2(viewport_size.x * 0.70, viewport_size.y * 0.60)
	player_sprite.scale = get_battle_sprite_scale(player_sprite, get_player_sprite_target_height())
	enemy_sprite.scale = get_battle_sprite_scale(enemy_sprite, ENEMY_TARGET_HEIGHT)
	log_label.position = Vector2(50.0, max(172.0, viewport_size.y - 170.0))
	log_label.size = Vector2(max(360.0, viewport_size.x - 100.0), 140.0)
	result_label.position = Vector2((viewport_size.x - 600.0) * 0.5, viewport_size.y * 0.38)
	result_label.size = Vector2(600.0, 150.0)

func get_player_sprite_target_height() -> float:
	var frame_size = get_battle_sprite_frame_size(player_sprite)
	if frame_size.y >= LARGE_PLAYER_FRAME_THRESHOLD:
		return LARGE_PLAYER_TARGET_HEIGHT
	return DEFAULT_PLAYER_TARGET_HEIGHT

func get_battle_sprite_scale(sprite: Sprite2D, target_height: float) -> Vector2:
	var frame_size = get_battle_sprite_frame_size(sprite)
	var scale_value = target_height / max(1.0, frame_size.y)
	return Vector2(scale_value, scale_value)

func get_battle_sprite_frame_size(sprite: Sprite2D) -> Vector2:
	if sprite == null or sprite.texture == null:
		return Vector2(64.0, 64.0)
	return Vector2(
		float(sprite.texture.get_width()) / float(max(1, sprite.hframes)),
		float(sprite.texture.get_height()) / float(max(1, sprite.vframes))
	)

func battle_loop():
	while is_battle_active:
		if is_battle_active:
			status_label.text = "Ход: %s" % player_stats["name"]
			await player_attack()
			await get_tree().create_timer(attack_delay).timeout

		if is_battle_active:
			status_label.text = "Ход: %s" % enemy_stats["name"]
			await enemy_attack()
			await get_tree().create_timer(attack_delay).timeout

func configure_battle_sprites() -> void:
	player_sprite.texture = PixelAssetPaths.hero_battle_sheet(GameState.selected_character_id)
	enemy_sprite.texture = PixelAssetPaths.enemy_battle_sheet(str(enemy_stats.get("type", "goblin")))
	for sprite in [player_sprite, enemy_sprite]:
		sprite.hframes = 3
		sprite.frame = 0
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func player_attack():
	var result = CombatResolver.resolve_player_attack(player_stats, enemy_stats)
	if bool(result.get(CombatResolver.RESULT_EVADED, false)):
		add_log("%s уклоняется от атаки." % enemy_stats["name"])
		show_effect("Уклонение")
		await play_attack_animation(player_sprite, enemy_sprite, false)
		update_ui()
		return

	var damage = int(result.get(CombatResolver.RESULT_DAMAGE, 0))
	add_log("%s наносит %d урона." % [player_stats["name"], damage])
	await play_attack_animation(player_sprite, enemy_sprite, true)
	var heal_amount = int(result.get(CombatResolver.RESULT_HEAL, 0))
	if heal_amount > 0:
		add_log("%s восстанавливает %d HP от вампиризма." % [player_stats["name"], heal_amount])
		show_effect("Вампиризм +%d HP" % heal_amount)
	update_ui()
	
	if bool(result.get(CombatResolver.RESULT_DEFEATED, false)):
		end_battle("win")

func enemy_attack():
	var result = CombatResolver.resolve_enemy_attack(player_stats, enemy_stats, used_passives)
	var armor_pierce = int(result.get(CombatResolver.RESULT_ARMOR_PIERCE, 0))
	var damage = int(result.get(CombatResolver.RESULT_DAMAGE, 0))
	if armor_pierce > 0:
		add_log("%s пробивает броню и наносит %d урона." % [enemy_stats["name"], damage])
		show_effect("Пробитие брони")
	else:
		add_log("%s наносит %d урона." % [enemy_stats["name"], damage])
	await play_attack_animation(enemy_sprite, player_sprite, true)

	var heal_amount = int(result.get(CombatResolver.RESULT_HEAL, 0))
	if heal_amount > 0:
		add_log("%s проявляет стойкость и лечится на %d HP." % [player_stats["name"], heal_amount])
		show_effect("Стойкость +%d HP" % heal_amount)
	update_ui()
	
	if bool(result.get(CombatResolver.RESULT_DEFEATED, false)):
		end_battle("lose")
		return

	var regeneration_amount = int(result.get(CombatResolver.RESULT_REGENERATION, 0))
	if regeneration_amount > 0:
		add_log("%s регенерирует %d HP." % [enemy_stats["name"], regeneration_amount])
		show_effect("Регенерация +%d HP" % regeneration_amount)
		update_ui()

func get_enemy_feature(feature_id: String) -> Dictionary:
	return CombatResolver.get_enemy_feature(enemy_stats, feature_id)

func get_enemy_traits_text() -> String:
	var traits = []
	for feature in enemy_stats.get("features", []):
		var feature_id = feature.get("id", "")
		if feature_id == "armor_pierce":
			traits.append("пробитие брони %d" % int(feature.get("pierce", 0)))
		elif feature_id == "evasion":
			traits.append("уклонение %d%%" % int(round(float(feature.get("chance", 0.0)) * 100.0)))
		elif feature_id == "regeneration":
			traits.append("регенерация %d HP" % int(feature.get("heal", 0)))

	return ", ".join(traits)

func add_log(message: String):
	battle_log.append(message)
	if battle_log.size() > 6:
		battle_log.pop_front()
	update_log_display()

func update_log_display():
	log_label.text = "\n".join(battle_log)

func update_ui():
	player_hp_label.text = "%s HP: %d/%d" % [player_stats["name"], int(player_stats["hp"]), int(player_stats["max_hp"])]
	enemy_hp_label.text = "%s HP: %d/%d" % [enemy_stats["name"], int(enemy_stats["hp"]), int(enemy_stats["max_hp"])]
	
	var player_hp_percent = float(player_stats["hp"]) / player_stats["max_hp"]
	var enemy_hp_percent = float(enemy_stats["hp"]) / enemy_stats["max_hp"]
	
	player_hp_bar.value = player_hp_percent * 100
	enemy_hp_bar.value = enemy_hp_percent * 100

func show_effect(message: String) -> void:
	effect_label.text = message
	effect_label.show()

func play_attack_animation(attacker: Sprite2D, defender: Sprite2D, hit: bool) -> void:
	attacker.frame = 1
	if hit:
		defender.frame = 2
	await get_tree().create_timer(min(0.25, attack_delay * 0.45)).timeout
	attacker.frame = 0
	defender.frame = 0

func _on_speed_button_pressed() -> void:
	if attack_delay == NORMAL_ATTACK_DELAY:
		attack_delay = FAST_ATTACK_DELAY
		speed_button.text = "Скорость x2"
	else:
		attack_delay = NORMAL_ATTACK_DELAY
		speed_button.text = "Скорость x1"

func end_battle(result: String):
	is_battle_active = false
	var should_show_result_screen = false
	
	if result == "win":
		GameState.set_player_battle_stats(player_stats)
		result_label.text = "ПОБЕДА!"
		status_label.text = "Бой завершен"
		effect_label.hide()
		result_label.modulate = Color.GREEN
		add_log("Победа.")
		grant_drop_reward()
		GameState.mark_current_enemy_defeated()
		if GameState.is_run_complete():
			GameState.complete_run()
			should_show_result_screen = true
	else:
		result_label.text = "ПОРАЖЕНИЕ"
		status_label.text = "Бой завершен"
		effect_label.hide()
		result_label.modulate = Color.RED
		add_log("Герой пал.")
		GameState.handle_player_defeat()
	
	result_label.show()
	
	await get_tree().create_timer(3.0).timeout
	GameState.clear_current_battle()
	if result == "win":
		if should_show_result_screen:
			get_tree().change_scene_to_file(RESULT_SCREEN_PATH)
		else:
			get_tree().change_scene_to_file(MAIN_LEVEL_PATH)
	else:
		get_tree().change_scene_to_file(DEATH_SCREEN_PATH)

func grant_drop_reward() -> void:
	var reward = GameState.grant_current_enemy_reward()
	var gold_amount = int(reward.get(ResultData.KEY_GOLD, 0))
	if gold_amount > 0:
		add_log("Получено золото: %d" % gold_amount)

	var item_id = str(reward.get(ResultData.KEY_ITEM_ID, ""))
	if item_id.is_empty():
		return

	if bool(reward.get(ResultData.KEY_ITEM_ADDED, false)):
		add_log("Найдено: %s" % GameState.get_item_name(item_id))
	else:
		add_log("Инвентарь полон. %s потерян." % GameState.get_item_name(item_id))

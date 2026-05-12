extends Node2D

const CombatResolver = preload("res://scripts/combat_resolver.gd")
const ScenePaths = preload("res://scripts/scene_paths.gd")
const ResultData = preload("res://scripts/result_data.gd")

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

const ATTACK_SPEED = 1.5
const DEATH_SCREEN_PATH = ScenePaths.DEATH_SCREEN
const MAIN_LEVEL_PATH = ScenePaths.MAIN_LEVEL
const RESULT_SCREEN_PATH = ScenePaths.RESULT_SCREEN

func _ready():
	player_stats = GameState.get_player_battle_stats()
	enemy_stats = GameState.get_current_enemy_battle_stats()
	
	update_ui()
	add_log("Бой начался.")
	add_log("%s против %s" % [player_stats["name"], enemy_stats["name"]])
	var traits_text = get_enemy_traits_text()
	if not traits_text.is_empty():
		add_log("Особенности врага: " + traits_text)
	
	await get_tree().create_timer(1.5).timeout
	battle_loop()

func battle_loop():
	while is_battle_active:
		if is_battle_active:
			player_attack()
			await get_tree().create_timer(ATTACK_SPEED).timeout
		
		if is_battle_active:
			enemy_attack()
			await get_tree().create_timer(ATTACK_SPEED).timeout

func player_attack():
	var result = CombatResolver.resolve_player_attack(player_stats, enemy_stats)
	if bool(result.get(CombatResolver.RESULT_EVADED, false)):
		add_log("%s уклоняется от атаки." % enemy_stats["name"])
		update_ui()
		return

	var damage = int(result.get(CombatResolver.RESULT_DAMAGE, 0))
	add_log("%s наносит %d урона." % [player_stats["name"], damage])
	var heal_amount = int(result.get(CombatResolver.RESULT_HEAL, 0))
	if heal_amount > 0:
		add_log("%s восстанавливает %d HP от вампиризма." % [player_stats["name"], heal_amount])
	update_ui()
	
	if bool(result.get(CombatResolver.RESULT_DEFEATED, false)):
		end_battle("win")

func enemy_attack():
	var result = CombatResolver.resolve_enemy_attack(player_stats, enemy_stats, used_passives)
	var armor_pierce = int(result.get(CombatResolver.RESULT_ARMOR_PIERCE, 0))
	var damage = int(result.get(CombatResolver.RESULT_DAMAGE, 0))
	if armor_pierce > 0:
		add_log("%s пробивает броню и наносит %d урона." % [enemy_stats["name"], damage])
	else:
		add_log("%s наносит %d урона." % [enemy_stats["name"], damage])

	var heal_amount = int(result.get(CombatResolver.RESULT_HEAL, 0))
	if heal_amount > 0:
		add_log("%s проявляет стойкость и лечится на %d HP." % [player_stats["name"], heal_amount])
	update_ui()
	
	if bool(result.get(CombatResolver.RESULT_DEFEATED, false)):
		end_battle("lose")
		return

	var regeneration_amount = int(result.get(CombatResolver.RESULT_REGENERATION, 0))
	if regeneration_amount > 0:
		add_log("%s регенерирует %d HP." % [enemy_stats["name"], regeneration_amount])
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

func end_battle(result: String):
	is_battle_active = false
	var should_show_result_screen = false
	
	if result == "win":
		GameState.set_player_battle_stats(player_stats)
		result_label.text = "ПОБЕДА!"
		result_label.modulate = Color.GREEN
		add_log("Победа.")
		grant_drop_reward()
		GameState.mark_current_enemy_defeated()
		if GameState.is_run_complete():
			GameState.complete_run()
			should_show_result_screen = true
	else:
		result_label.text = "ПОРАЖЕНИЕ"
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

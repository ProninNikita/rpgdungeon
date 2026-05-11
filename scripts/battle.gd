extends Node2D

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
	if should_enemy_evade():
		add_log("%s уклоняется от атаки." % enemy_stats["name"])
		update_ui()
		return

	var damage = calculate_damage(player_stats["attack"], enemy_stats["defense"])
	enemy_stats["hp"] = max(0, enemy_stats["hp"] - damage)
	
	add_log("%s наносит %d урона." % [player_stats["name"], damage])
	apply_attack_passives(damage)
	update_ui()
	
	if enemy_stats["hp"] <= 0:
		end_battle("win")

func apply_attack_passives(damage: int) -> void:
	for passive in player_stats.get("passives", []):
		if passive.get("id", "") == "vampirism":
			apply_vampirism(passive, damage)

func apply_vampirism(passive: Dictionary, damage: int) -> void:
	var heal_percent = float(passive.get("heal_percent", 0.0))
	var heal_amount = ceili(damage * heal_percent)
	if heal_amount <= 0:
		return

	var previous_hp = int(player_stats["hp"])
	player_stats["hp"] = min(int(player_stats["max_hp"]), previous_hp + heal_amount)
	var actual_heal = int(player_stats["hp"]) - previous_hp
	if actual_heal > 0:
		add_log("%s восстанавливает %d HP от вампиризма." % [player_stats["name"], actual_heal])

func enemy_attack():
	var armor_pierce = get_enemy_armor_pierce()
	var effective_defense = max(0, int(player_stats["defense"]) - armor_pierce)
	var damage = calculate_damage(enemy_stats["attack"], effective_defense)
	player_stats["hp"] = max(0, player_stats["hp"] - damage)
	
	if armor_pierce > 0:
		add_log("%s пробивает броню и наносит %d урона." % [enemy_stats["name"], damage])
	else:
		add_log("%s наносит %d урона." % [enemy_stats["name"], damage])
	apply_defensive_passives()
	update_ui()
	
	if player_stats["hp"] <= 0:
		end_battle("lose")
		return

	apply_enemy_regeneration()

func apply_defensive_passives() -> void:
	for passive in player_stats.get("passives", []):
		if passive.get("id", "") == "resolve":
			apply_resolve(passive)

func apply_resolve(passive: Dictionary) -> void:
	if bool(used_passives.get("resolve", false)):
		return

	var max_hp = int(player_stats["max_hp"])
	var trigger_hp = ceili(max_hp * float(passive.get("trigger_hp_percent", 0.0)))
	if int(player_stats["hp"]) > trigger_hp:
		return

	var heal_amount = ceili(max_hp * float(passive.get("heal_percent", 0.0)))
	if heal_amount <= 0:
		return

	var previous_hp = int(player_stats["hp"])
	player_stats["hp"] = min(max_hp, previous_hp + heal_amount)
	var actual_heal = int(player_stats["hp"]) - previous_hp
	used_passives["resolve"] = true
	if actual_heal > 0:
		add_log("%s проявляет стойкость и лечится на %d HP." % [player_stats["name"], actual_heal])

func calculate_damage(attack: int, defense: int) -> int:
	var base_damage = attack + randi_range(-2, 2)
	var actual_damage = max(1, base_damage - defense)
	return actual_damage

func should_enemy_evade() -> bool:
	var evasion_feature = get_enemy_feature("evasion")
	if evasion_feature.is_empty():
		return false

	return randf() < float(evasion_feature.get("chance", 0.0))

func get_enemy_armor_pierce() -> int:
	var armor_pierce_feature = get_enemy_feature("armor_pierce")
	if armor_pierce_feature.is_empty():
		return 0

	return int(armor_pierce_feature.get("pierce", 0))

func apply_enemy_regeneration() -> void:
	var regeneration_feature = get_enemy_feature("regeneration")
	if regeneration_feature.is_empty():
		return

	var heal_amount = int(regeneration_feature.get("heal", 0))
	if heal_amount <= 0 or int(enemy_stats["hp"]) >= int(enemy_stats["max_hp"]):
		return

	var previous_hp = int(enemy_stats["hp"])
	enemy_stats["hp"] = min(int(enemy_stats["max_hp"]), previous_hp + heal_amount)
	var actual_heal = int(enemy_stats["hp"]) - previous_hp
	if actual_heal > 0:
		add_log("%s регенерирует %d HP." % [enemy_stats["name"], actual_heal])
		update_ui()

func get_enemy_feature(feature_id: String) -> Dictionary:
	for feature in enemy_stats.get("features", []):
		if feature.get("id", "") == feature_id:
			return feature
	return {}

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
	
	if result == "win":
		GameState.set_player_battle_stats(player_stats)
		result_label.text = "ПОБЕДА!"
		result_label.modulate = Color.GREEN
		add_log("Победа.")
		grant_drop_reward()
		GameState.mark_current_enemy_defeated()
	else:
		result_label.text = "ПОРАЖЕНИЕ"
		result_label.modulate = Color.RED
		add_log("Герой пал.")
		GameState.handle_player_defeat()
	
	result_label.show()
	
	await get_tree().create_timer(3.0).timeout
	GameState.clear_current_battle()
	if result == "win":
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

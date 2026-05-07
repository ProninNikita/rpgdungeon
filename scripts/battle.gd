extends Node2D

var player_stats: Dictionary
var enemy_stats: Dictionary
var is_battle_active: bool = true
var battle_log: Array = []

@onready var player_hp_label = $PlayerHP
@onready var enemy_hp_label = $EnemyHP
@onready var log_label = $BattleLog
@onready var result_label = $ResultLabel
@onready var player_hp_bar = $PlayerHPBar
@onready var enemy_hp_bar = $EnemyHPBar

const ATTACK_SPEED = 1.5
const DEATH_SCREEN_PATH = "res://scenes/ui/death_screen.tscn"
const MAIN_LEVEL_PATH = "res://scenes/levels/main_level.tscn"

func _ready():
	player_stats = GameState.get_player_battle_stats()
	enemy_stats = GameState.get_current_enemy_battle_stats()
	
	update_ui()
	add_log("Battle started!")
	add_log("Player vs " + enemy_stats["name"])
	
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
	var damage = calculate_damage(player_stats["attack"], enemy_stats["defense"])
	enemy_stats["hp"] = max(0, enemy_stats["hp"] - damage)
	
	add_log("%s attacks for %d damage!" % [player_stats["name"], damage])
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
		add_log("%s heals for %d HP from Vampirism!" % [player_stats["name"], actual_heal])

func enemy_attack():
	var damage = calculate_damage(enemy_stats["attack"], player_stats["defense"])
	player_stats["hp"] = max(0, player_stats["hp"] - damage)
	
	add_log("%s attacks for %d damage!" % [enemy_stats["name"], damage])
	update_ui()
	
	if player_stats["hp"] <= 0:
		end_battle("lose")

func calculate_damage(attack: int, defense: int) -> int:
	var base_damage = attack + randi_range(-2, 2)
	var actual_damage = max(1, base_damage - defense)
	return actual_damage

func add_log(message: String):
	battle_log.append(message)
	if battle_log.size() > 6:
		battle_log.pop_front()
	update_log_display()

func update_log_display():
	log_label.text = "\n".join(battle_log)

func update_ui():
	player_hp_label.text = "Player HP: %d/%d" % [int(player_stats["hp"]), int(player_stats["max_hp"])]
	enemy_hp_label.text = "%s HP: %d/%d" % [enemy_stats["name"], int(enemy_stats["hp"]), int(enemy_stats["max_hp"])]
	
	var player_hp_percent = float(player_stats["hp"]) / player_stats["max_hp"]
	var enemy_hp_percent = float(enemy_stats["hp"]) / enemy_stats["max_hp"]
	
	player_hp_bar.value = player_hp_percent * 100
	enemy_hp_bar.value = enemy_hp_percent * 100

func end_battle(result: String):
	is_battle_active = false
	
	if result == "win":
		GameState.set_player_battle_stats(player_stats)
		result_label.text = "VICTORY!"
		result_label.modulate = Color.GREEN
		add_log("Victory! You won!")
		grant_drop_reward()
		GameState.mark_current_enemy_defeated()
	else:
		result_label.text = "DEFEAT!"
		result_label.modulate = Color.RED
		add_log("Defeat! You lost!")
	
	result_label.show()
	
	await get_tree().create_timer(3.0).timeout
	GameState.clear_current_battle()
	if result == "win":
		get_tree().change_scene_to_file(MAIN_LEVEL_PATH)
	else:
		get_tree().change_scene_to_file(DEATH_SCREEN_PATH)

func grant_drop_reward() -> void:
	var item_id = GameState.grant_current_enemy_drop()
	if item_id.is_empty():
		add_log("No room for loot.")
		return

	add_log("Found: %s" % GameState.get_item_name(item_id))

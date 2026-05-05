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

func _ready():
	player_stats = {
		"hp": 100,
		"max_hp": 100,
		"attack": 10,
		"defense": 2,
		"name": "Player"
	}
	
	enemy_stats = {
		"hp": 30,
		"max_hp": 30,
		"attack": 5,
		"defense": 0,
		"name": "Goblin"
	}
	
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
	enemy_stats["hp"] -= damage
	
	add_log("Player attacks for %d damage!" % damage)
	update_ui()
	
	if enemy_stats["hp"] <= 0:
		end_battle("win")

func enemy_attack():
	var damage = calculate_damage(enemy_stats["attack"], player_stats["defense"])
	player_stats["hp"] -= damage
	
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
	player_hp_label.text = "Player HP: %d/%d" % [player_stats["hp"], player_stats["max_hp"]]
	enemy_hp_label.text = "%s HP: %d/%d" % [enemy_stats["name"], enemy_stats["hp"], enemy_stats["max_hp"]]
	
	var player_hp_percent = float(player_stats["hp"]) / player_stats["max_hp"]
	var enemy_hp_percent = float(enemy_stats["hp"]) / enemy_stats["max_hp"]
	
	player_hp_bar.value = player_hp_percent * 100
	enemy_hp_bar.value = enemy_hp_percent * 100

func end_battle(result: String):
	is_battle_active = false
	
	if result == "win":
		result_label.text = "VICTORY!"
		result_label.modulate = Color.GREEN
		add_log("Victory! You won!")
		GameState.mark_current_enemy_defeated()
	else:
		result_label.text = "DEFEAT!"
		result_label.modulate = Color.RED
		add_log("Defeat! You lost!")
	
	result_label.show()
	
	await get_tree().create_timer(3.0).timeout
	GameState.clear_current_battle()
	get_tree().change_scene_to_file("res://scenes/levels/main_level.tscn")

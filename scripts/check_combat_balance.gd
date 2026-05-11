extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")

const SIMULATIONS_PER_MATCHUP = 300
const MAX_ROUNDS = 80

var failures: Array = []
var game_state = GameStateScript.new()

func _init() -> void:
	randomize()
	for character_id in GameStateScript.CHARACTER_DEFINITIONS.keys():
		for floor_number in range(1, GameStateScript.MAX_FLOOR + 1):
			validate_floor_matchups(str(character_id), floor_number, GameStateScript.FLOOR_PATH_NORMAL)
			if floor_number == GameStateScript.MAX_FLOOR:
				validate_floor_matchups(str(character_id), floor_number, GameStateScript.FLOOR_PATH_ELITE)

	if failures.is_empty():
		print("Combat balance check passed.")
		game_state.free()
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		game_state.free()
		quit(1)

func validate_floor_matchups(character_id: String, floor_number: int, path_type: String) -> void:
	for enemy_type in GameStateScript.DUNGEON_ENEMY_TYPES:
		var wins = 0
		var total_remaining_hp = 0
		for _index in range(SIMULATIONS_PER_MATCHUP):
			var result = simulate_battle(character_id, enemy_type, floor_number, path_type)
			if bool(result.get("win", false)):
				wins += 1
				total_remaining_hp += int(result.get("player_hp", 0))

		var win_rate = float(wins) / float(SIMULATIONS_PER_MATCHUP)
		var average_remaining_hp = float(total_remaining_hp) / max(1.0, float(wins))
		var context = "%s vs %s floor %d %s" % [character_id, enemy_type, floor_number, path_type]

		if win_rate < 0.45:
			failures.append("%s: low win rate %.2f" % [context, win_rate])
		if wins > 0 and average_remaining_hp < 5.0:
			failures.append("%s: average remaining HP too low %.1f" % [context, average_remaining_hp])

func simulate_battle(character_id: String, enemy_type: String, floor_number: int, path_type: String) -> Dictionary:
	var player_stats = game_state.get_character_stats(character_id)
	var enemy_stats = game_state.scale_enemy_stats(game_state.get_enemy_stats(enemy_type), floor_number, path_type)
	var used_resolve = false

	for _round_index in range(MAX_ROUNDS):
		if randf() >= get_enemy_evasion(enemy_stats):
			var player_damage = calculate_damage(int(player_stats["attack"]), int(enemy_stats["defense"]))
			enemy_stats["hp"] = max(0, int(enemy_stats["hp"]) - player_damage)
			apply_vampirism(player_stats, player_damage)
		if int(enemy_stats["hp"]) <= 0:
			return {"win": true, "player_hp": int(player_stats["hp"])}

		var armor_pierce = get_enemy_armor_pierce(enemy_stats)
		var effective_defense = max(0, int(player_stats["defense"]) - armor_pierce)
		var enemy_damage = calculate_damage(int(enemy_stats["attack"]), effective_defense)
		player_stats["hp"] = max(0, int(player_stats["hp"]) - enemy_damage)
		used_resolve = apply_resolve(player_stats, used_resolve)
		if int(player_stats["hp"]) <= 0:
			return {"win": false, "player_hp": 0}

		apply_enemy_regeneration(enemy_stats)

	return {"win": false, "player_hp": int(player_stats["hp"])}

func calculate_damage(attack: int, defense: int) -> int:
	return max(1, attack + randi_range(-2, 2) - defense)

func apply_vampirism(player_stats: Dictionary, damage: int) -> void:
	for passive in player_stats.get("passives", []):
		if passive.get("id", "") != "vampirism":
			continue
		var heal_amount = ceili(damage * float(passive.get("heal_percent", 0.0)))
		player_stats["hp"] = min(int(player_stats["max_hp"]), int(player_stats["hp"]) + heal_amount)

func apply_resolve(player_stats: Dictionary, used_resolve: bool) -> bool:
	if used_resolve:
		return true

	for passive in player_stats.get("passives", []):
		if passive.get("id", "") != "resolve":
			continue
		var max_hp = int(player_stats["max_hp"])
		if int(player_stats["hp"]) > ceili(max_hp * float(passive.get("trigger_hp_percent", 0.0))):
			return false
		player_stats["hp"] = min(max_hp, int(player_stats["hp"]) + ceili(max_hp * float(passive.get("heal_percent", 0.0))))
		return true

	return false

func apply_enemy_regeneration(enemy_stats: Dictionary) -> void:
	for feature in enemy_stats.get("features", []):
		if feature.get("id", "") == "regeneration":
			enemy_stats["hp"] = min(int(enemy_stats["max_hp"]), int(enemy_stats["hp"]) + int(feature.get("heal", 0)))

func get_enemy_evasion(enemy_stats: Dictionary) -> float:
	for feature in enemy_stats.get("features", []):
		if feature.get("id", "") == "evasion":
			return float(feature.get("chance", 0.0))
	return 0.0

func get_enemy_armor_pierce(enemy_stats: Dictionary) -> int:
	for feature in enemy_stats.get("features", []):
		if feature.get("id", "") == "armor_pierce":
			return int(feature.get("pierce", 0))
	return 0

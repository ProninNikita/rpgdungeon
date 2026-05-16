extends SceneTree

const GameStateScript = preload("res://scripts/game_state.gd")
const CombatResolver = preload("res://scripts/combat_resolver.gd")

const SIMULATIONS_PER_MATCHUP = 300
const MAX_ROUNDS = 80
const DEFAULT_RANDOM_SEED = 70415

var failures: Array = []
var game_state = GameStateScript.new()

func _init() -> void:
	var random_seed = get_requested_seed()
	seed(random_seed)
	for character_id in GameStateScript.CHARACTER_DEFINITIONS.keys():
		for floor_number in range(1, GameStateScript.MAX_FLOOR + 1):
			validate_floor_matchups(str(character_id), floor_number, GameStateScript.FLOOR_PATH_NORMAL)
			if floor_number == GameStateScript.MAX_FLOOR:
				validate_floor_matchups(str(character_id), floor_number, GameStateScript.FLOOR_PATH_ELITE)

	if failures.is_empty():
		print("Combat balance check passed with seed %d." % random_seed)
		game_state.free()
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
			game_state.free()
			quit(1)

func get_requested_seed() -> int:
	var user_args = OS.get_cmdline_user_args()
	if not user_args.is_empty() and not str(user_args[0]).strip_edges().is_empty():
		return int(str(user_args[0]).strip_edges())
	return DEFAULT_RANDOM_SEED

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
	var used_passives = {}

	for _round_index in range(MAX_ROUNDS):
		var player_result = CombatResolver.resolve_player_attack(player_stats, enemy_stats)
		if bool(player_result.get(CombatResolver.RESULT_DEFEATED, false)):
			return {"win": true, "player_hp": int(player_stats["hp"])}

		var enemy_result = CombatResolver.resolve_enemy_attack(player_stats, enemy_stats, used_passives)
		if bool(enemy_result.get(CombatResolver.RESULT_DEFEATED, false)):
			return {"win": false, "player_hp": 0}

	return {"win": false, "player_hp": int(player_stats["hp"])}

extends RefCounted

const RESULT_DAMAGE = "damage"
const RESULT_EVADED = "evaded"
const RESULT_HEAL = "heal"
const RESULT_ARMOR_PIERCE = "armor_pierce"
const RESULT_REGENERATION = "regeneration"
const RESULT_RESOLVE_USED = "resolve_used"
const RESULT_DEFEATED = "defeated"

static func resolve_player_attack(player_stats: Dictionary, enemy_stats: Dictionary) -> Dictionary:
	var result = {
		RESULT_DAMAGE: 0,
		RESULT_EVADED: false,
		RESULT_HEAL: 0,
		RESULT_DEFEATED: false
	}
	if should_enemy_evade(enemy_stats):
		result[RESULT_EVADED] = true
		return result

	var damage = calculate_damage(int(player_stats["attack"]), int(enemy_stats["defense"]))
	enemy_stats["hp"] = max(0, int(enemy_stats["hp"]) - damage)
	result[RESULT_DAMAGE] = damage
	result[RESULT_HEAL] = apply_vampirism(player_stats, damage)
	result[RESULT_DEFEATED] = int(enemy_stats["hp"]) <= 0
	return result

static func resolve_enemy_attack(player_stats: Dictionary, enemy_stats: Dictionary, used_passives: Dictionary) -> Dictionary:
	var result = {
		RESULT_DAMAGE: 0,
		RESULT_ARMOR_PIERCE: 0,
		RESULT_HEAL: 0,
		RESULT_REGENERATION: 0,
		RESULT_RESOLVE_USED: false,
		RESULT_DEFEATED: false
	}

	var armor_pierce = get_enemy_armor_pierce(enemy_stats)
	var effective_defense = max(0, int(player_stats["defense"]) - armor_pierce)
	var damage = calculate_damage(int(enemy_stats["attack"]), effective_defense)
	player_stats["hp"] = max(0, int(player_stats["hp"]) - damage)
	result[RESULT_DAMAGE] = damage
	result[RESULT_ARMOR_PIERCE] = armor_pierce

	var resolve_heal = apply_resolve(player_stats, used_passives)
	result[RESULT_HEAL] = resolve_heal
	result[RESULT_RESOLVE_USED] = resolve_heal > 0

	if int(player_stats["hp"]) <= 0:
		result[RESULT_DEFEATED] = true
		return result

	result[RESULT_REGENERATION] = apply_enemy_regeneration(enemy_stats)
	return result

static func calculate_damage(attack: int, defense: int) -> int:
	return max(1, attack + randi_range(-2, 2) - defense)

static func should_enemy_evade(enemy_stats: Dictionary) -> bool:
	var evasion_feature = get_enemy_feature(enemy_stats, "evasion")
	if evasion_feature.is_empty():
		return false
	return randf() < float(evasion_feature.get("chance", 0.0))

static func apply_vampirism(player_stats: Dictionary, damage: int) -> int:
	for passive in player_stats.get("passives", []):
		if passive.get("id", "") != "vampirism":
			continue
		var heal_amount = ceili(damage * float(passive.get("heal_percent", 0.0)))
		if heal_amount <= 0:
			return 0
		var previous_hp = int(player_stats["hp"])
		player_stats["hp"] = min(int(player_stats["max_hp"]), previous_hp + heal_amount)
		return int(player_stats["hp"]) - previous_hp
	return 0

static func apply_resolve(player_stats: Dictionary, used_passives: Dictionary) -> int:
	if bool(used_passives.get("resolve", false)):
		return 0

	for passive in player_stats.get("passives", []):
		if passive.get("id", "") != "resolve":
			continue
		var max_hp = int(player_stats["max_hp"])
		var trigger_hp = ceili(max_hp * float(passive.get("trigger_hp_percent", 0.0)))
		if int(player_stats["hp"]) > trigger_hp:
			return 0
		var heal_amount = ceili(max_hp * float(passive.get("heal_percent", 0.0)))
		if heal_amount <= 0:
			return 0
		var previous_hp = int(player_stats["hp"])
		player_stats["hp"] = min(max_hp, previous_hp + heal_amount)
		used_passives["resolve"] = true
		return int(player_stats["hp"]) - previous_hp

	return 0

static func apply_enemy_regeneration(enemy_stats: Dictionary) -> int:
	var regeneration_feature = get_enemy_feature(enemy_stats, "regeneration")
	if regeneration_feature.is_empty():
		return 0

	var heal_amount = int(regeneration_feature.get("heal", 0))
	if heal_amount <= 0 or int(enemy_stats["hp"]) >= int(enemy_stats["max_hp"]):
		return 0

	var previous_hp = int(enemy_stats["hp"])
	enemy_stats["hp"] = min(int(enemy_stats["max_hp"]), previous_hp + heal_amount)
	return int(enemy_stats["hp"]) - previous_hp

static func get_enemy_armor_pierce(enemy_stats: Dictionary) -> int:
	var armor_pierce_feature = get_enemy_feature(enemy_stats, "armor_pierce")
	if armor_pierce_feature.is_empty():
		return 0
	return int(armor_pierce_feature.get("pierce", 0))

static func get_enemy_feature(enemy_stats: Dictionary, feature_id: String) -> Dictionary:
	for feature in enemy_stats.get("features", []):
		if feature.get("id", "") == feature_id:
			return feature
	return {}

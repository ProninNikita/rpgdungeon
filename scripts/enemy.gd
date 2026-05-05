extends CharacterBody2D

const TILE_SIZE = 32
const HALF_TILE = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

@export var enemy_id: String = ""
@export var grid_pos: Vector2i = Vector2i(0, 0)
@export var encounter_radius: int = 1

var name_label: String = "Goblin"

# Enemy stats
var max_hp: int = 30
var current_hp: int = 30
var attack_power: int = 5
var defense: int = 0

func _ready():
	if enemy_id.is_empty():
		enemy_id = "%s:%s" % [get_tree().current_scene.scene_file_path, get_path()]
	
	if GameState.is_enemy_defeated(enemy_id):
		queue_free()
		return
	
	if position != Vector2.ZERO:
		grid_pos = world_to_grid_position(position)
	set_grid_position(grid_pos)
	add_to_group("enemies")

func set_grid_position(new_grid_pos: Vector2i) -> void:
	grid_pos = new_grid_pos
	position = grid_to_world_position(grid_pos)

func grid_to_world_position(pos: Vector2i) -> Vector2:
	return Vector2(pos) * TILE_SIZE + HALF_TILE

func world_to_grid_position(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE_SIZE), floori(world_position.y / TILE_SIZE))

func should_start_encounter(player_grid_pos: Vector2i) -> bool:
	var distance = abs(player_grid_pos.x - grid_pos.x) + abs(player_grid_pos.y - grid_pos.y)
	return distance <= encounter_radius

func take_damage(damage: int) -> void:
	var actual_damage = max(1, damage - defense)
	current_hp -= actual_damage
	print("%s takes %d damage! HP: %d/%d" % [name_label, actual_damage, current_hp, max_hp])

func attack() -> int:
	var damage = attack_power + randi_range(-1, 1)
	return damage

func is_alive() -> bool:
	return current_hp > 0

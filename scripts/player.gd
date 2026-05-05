extends CharacterBody2D

const TILE_SIZE = 32
const SPEED = 200
const HALF_TILE = Vector2(TILE_SIZE / 2.0, TILE_SIZE / 2.0)

var grid_pos: Vector2i = Vector2i(8, 8)
var input_locked: bool = false

# Player stats
var max_hp: int = 100
var current_hp: int = 100
var attack_power: int = 10
var defense: int = 2

func _ready():
	# Выравниваем позицию на сетку
	set_grid_position(grid_pos)

func set_grid_position(new_grid_pos: Vector2i) -> void:
	grid_pos = new_grid_pos
	position = grid_to_world_position(grid_pos)

func grid_to_world_position(pos: Vector2i) -> Vector2:
	return Vector2(pos) * TILE_SIZE + HALF_TILE

func _physics_process(_delta):
	if input_locked:
		return
	
	if Input.is_action_just_pressed("ui_up"):
		move_to_grid(grid_pos + Vector2i(0, -1))
	elif Input.is_action_just_pressed("ui_down"):
		move_to_grid(grid_pos + Vector2i(0, 1))
	elif Input.is_action_just_pressed("ui_left"):
		move_to_grid(grid_pos + Vector2i(-1, 0))
	elif Input.is_action_just_pressed("ui_right"):
		move_to_grid(grid_pos + Vector2i(1, 0))

func move_to_grid(new_grid_pos: Vector2i):
	# Проверяем столкновения и границы
	if is_valid_position(new_grid_pos):
		set_grid_position(new_grid_pos)
		GameState.set_player_grid_position(grid_pos, true)
		
		# Проверяем встречу с врагом
		check_for_encounter()

func is_valid_position(pos: Vector2i) -> bool:
	# Границы комнаты 16x16
	if pos.x < 0 or pos.x >= 16 or pos.y < 0 or pos.y >= 16:
		return false
	
	var room = get_parent()
	if room != null and room.has_method("is_grid_position_blocked") and room.is_grid_position_blocked(pos):
		return false
	
	return true

func check_for_encounter():
	# Получаем всех врагов на сцене
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy.has_method("should_start_encounter") and enemy.should_start_encounter(grid_pos):
			# Нашли врага! Начинаем бой
			start_battle(enemy)
			return

func start_battle(enemy):
	if input_locked:
		return
	input_locked = true
	GameState.start_battle(enemy.enemy_id, grid_pos)
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/combat/battle.tscn")

func take_damage(damage: int) -> void:
	var actual_damage = max(1, damage - defense)
	current_hp -= actual_damage
	print("Player takes %d damage! HP: %d/%d" % [actual_damage, current_hp, max_hp])

func heal(amount: int) -> void:
	current_hp = min(current_hp + amount, max_hp)
	print("Player healed for %d! HP: %d/%d" % [amount, current_hp, max_hp])

func attack() -> int:
	# Рандомный урон в диапазоне
	var damage = attack_power + randi_range(-2, 2)
	return damage
